const crypto = require("crypto");
const admin = require("firebase-admin");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");

admin.initializeApp();

const openWeatherApiKey = defineSecret("OPENWEATHER_API_KEY");

const OPENWEATHER_BASE_URL =
  "https://api.openweathermap.org/data/2.5/weather";

function parseLatLon(data) {
  const lat = Number(data?.lat);
  const lon = Number(data?.lon);
  if (!Number.isFinite(lat) || !Number.isFinite(lon)) {
    throw new HttpsError(
      "invalid-argument",
      "lat and lon must be finite numbers.",
    );
  }
  if (lat < -90 || lat > 90 || lon < -180 || lon > 180) {
    throw new HttpsError("invalid-argument", "Coordinates out of range.");
  }
  return { lat, lon };
}

function parseUnits(data) {
  const units = String(data?.units || "metric").toLowerCase();
  if (!["metric", "imperial", "standard"].includes(units)) {
    throw new HttpsError("invalid-argument", "units must be metric, imperial, or standard.");
  }
  return units;
}

const db = admin.firestore();

const RESET_COLLECTION = "password_reset_requests";
const OTP_LENGTH = 6;
const OTP_TTL_MINUTES = 10;
const SESSION_TTL_MINUTES = 10;
const MAX_VERIFY_ATTEMPTS = 5;
const RESEND_COOLDOWN_SECONDS = 60;
const MIN_PASSWORD_LENGTH = 6;

function sha256(input) {
  return crypto.createHash("sha256").update(input).digest("hex");
}

function randomDigits(length) {
  let output = "";
  while (output.length < length) {
    output += crypto.randomInt(0, 10).toString();
  }
  return output;
}

function randomToken() {
  return crypto.randomBytes(32).toString("hex");
}

function normalizeEmail(email) {
  return String(email || "").trim().toLowerCase();
}

function validateEmail(email) {
  return /^[\w-.]+@([\w-]+\.)+[\w-]{2,}$/.test(email);
}

async function sendResetCodeEmail({ toEmail, code }) {
  const apiKey = process.env.SENDGRID_API_KEY || "";
  const fromEmail = process.env.RESET_FROM_EMAIL || "";
  const fromName = process.env.RESET_FROM_NAME || "AquaPulse";

  if (!apiKey || !fromEmail) {
    throw new Error(
      "Missing SENDGRID_API_KEY or RESET_FROM_EMAIL environment variables.",
    );
  }

  const payload = {
    personalizations: [
      {
        to: [{ email: toEmail }],
        subject: "Your AquaPulse password reset code",
      },
    ],
    from: {
      email: fromEmail,
      name: fromName,
    },
    content: [
      {
        type: "text/plain",
        value:
          `Your AquaPulse password reset code is ${code}.\n\n` +
          `This code expires in ${OTP_TTL_MINUTES} minutes.\n` +
          "If you did not request this, you can ignore this email.",
      },
      {
        type: "text/html",
        value:
          `<p>Your AquaPulse password reset code is:</p>` +
          `<p style="font-size: 24px; letter-spacing: 4px;"><strong>${code}</strong></p>` +
          `<p>This code expires in ${OTP_TTL_MINUTES} minutes.</p>` +
          "<p>If you did not request this, you can ignore this email.</p>",
      },
    ],
  };

  const response = await fetch("https://api.sendgrid.com/v3/mail/send", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(payload),
  });

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`SendGrid error ${response.status}: ${body}`);
  }
}

exports.requestPasswordResetCode = onCall(async (request) => {
  const email = normalizeEmail(request.data?.email);
  if (!validateEmail(email)) {
    throw new HttpsError("invalid-argument", "Please enter a valid email.");
  }

  const emailHash = sha256(email);
  const docRef = db.collection(RESET_COLLECTION).doc(emailHash);
  const now = admin.firestore.Timestamp.now();

  let userRecord = null;
  try {
    userRecord = await admin.auth().getUserByEmail(email);
  } catch (error) {
    if (error.code !== "auth/user-not-found") {
      throw new HttpsError("internal", "Failed to process reset request.");
    }
  }

  if (!userRecord) {
    return {
      success: true,
      message:
        "If an account exists for this email, a verification code has been sent.",
    };
  }

  const existingDoc = await docRef.get();
  if (existingDoc.exists) {
    const data = existingDoc.data();
    const resendAvailableAt = data?.resendAvailableAt;
    if (
      resendAvailableAt &&
      resendAvailableAt.toMillis() > Date.now()
    ) {
      return {
        success: true,
        message:
          "If an account exists for this email, a verification code has been sent.",
      };
    }
  }

  const code = randomDigits(OTP_LENGTH);
  const codeHash = sha256(`${email}:${code}`);
  const expiresAt = admin.firestore.Timestamp.fromMillis(
    Date.now() + OTP_TTL_MINUTES * 60 * 1000,
  );
  const resendAvailableAt = admin.firestore.Timestamp.fromMillis(
    Date.now() + RESEND_COOLDOWN_SECONDS * 1000,
  );

  await docRef.set(
    {
      email,
      userUid: userRecord.uid,
      codeHash,
      expiresAt,
      verifyAttempts: 0,
      maxVerifyAttempts: MAX_VERIFY_ATTEMPTS,
      resendAvailableAt,
      sessionTokenHash: null,
      sessionExpiresAt: null,
      createdAt: now,
      updatedAt: now,
    },
    { merge: true },
  );

  try {
    await sendResetCodeEmail({ toEmail: email, code });
  } catch (error) {
    throw new HttpsError("internal", "Unable to send verification code.");
  }

  return {
    success: true,
    message:
      "If an account exists for this email, a verification code has been sent.",
  };
});

exports.verifyPasswordResetCode = onCall(async (request) => {
  const email = normalizeEmail(request.data?.email);
  const code = String(request.data?.code || "").trim();

  if (!validateEmail(email) || code.length !== OTP_LENGTH) {
    throw new HttpsError("invalid-argument", "Invalid email or verification code.");
  }

  const docRef = db.collection(RESET_COLLECTION).doc(sha256(email));
  const doc = await docRef.get();
  if (!doc.exists) {
    throw new HttpsError("not-found", "Verification code is invalid or expired.");
  }

  const data = doc.data();
  const now = Date.now();

  if (!data?.expiresAt || data.expiresAt.toMillis() < now) {
    throw new HttpsError("deadline-exceeded", "Verification code has expired.");
  }

  if ((data.verifyAttempts || 0) >= (data.maxVerifyAttempts || MAX_VERIFY_ATTEMPTS)) {
    throw new HttpsError("permission-denied", "Too many attempts. Request a new code.");
  }

  const codeHash = sha256(`${email}:${code}`);
  if (codeHash !== data.codeHash) {
    await docRef.update({
      verifyAttempts: admin.firestore.FieldValue.increment(1),
      updatedAt: admin.firestore.Timestamp.now(),
    });
    throw new HttpsError("invalid-argument", "Verification code is incorrect.");
  }

  const sessionToken = randomToken();
  const sessionTokenHash = sha256(sessionToken);
  const sessionExpiresAt = admin.firestore.Timestamp.fromMillis(
    Date.now() + SESSION_TTL_MINUTES * 60 * 1000,
  );

  await docRef.update({
    sessionTokenHash,
    sessionExpiresAt,
    verifyAttempts: 0,
    updatedAt: admin.firestore.Timestamp.now(),
  });

  return {
    success: true,
    resetSessionToken: sessionToken,
    message: "Verification code accepted.",
  };
});

exports.confirmPasswordResetWithCode = onCall(async (request) => {
  const email = normalizeEmail(request.data?.email);
  const resetSessionToken = String(request.data?.resetSessionToken || "").trim();
  const newPassword = String(request.data?.newPassword || "");

  if (!validateEmail(email) || !resetSessionToken) {
    throw new HttpsError("invalid-argument", "Invalid request.");
  }
  if (newPassword.length < MIN_PASSWORD_LENGTH) {
    throw new HttpsError(
      "invalid-argument",
      `Password must be at least ${MIN_PASSWORD_LENGTH} characters.`,
    );
  }

  const docRef = db.collection(RESET_COLLECTION).doc(sha256(email));
  const doc = await docRef.get();
  if (!doc.exists) {
    throw new HttpsError("not-found", "Reset session not found.");
  }

  const data = doc.data();
  const sessionTokenHash = sha256(resetSessionToken);

  if (!data?.sessionTokenHash || data.sessionTokenHash !== sessionTokenHash) {
    throw new HttpsError("permission-denied", "Reset session is invalid.");
  }

  if (!data?.sessionExpiresAt || data.sessionExpiresAt.toMillis() < Date.now()) {
    throw new HttpsError("deadline-exceeded", "Reset session has expired.");
  }

  const uid = data.userUid;
  if (!uid) {
    throw new HttpsError("internal", "Unable to resolve account for reset.");
  }

  await admin.auth().updateUser(uid, { password: newPassword });
  await docRef.delete();

  return {
    success: true,
    message: "Password updated successfully.",
  };
});

exports.getCurrentWeatherProxy = onCall(
  { secrets: [openWeatherApiKey] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Sign in to load weather.",
      );
    }

    const { lat, lon } = parseLatLon(request.data);
    const units = parseUnits(request.data);
    const appId = openWeatherApiKey.value().trim();
    if (!appId) {
      console.error("OPENWEATHER_API_KEY secret is empty");
      throw new HttpsError(
        "failed-precondition",
        "Weather service is not configured.",
      );
    }

    const url = new URL(OPENWEATHER_BASE_URL);
    url.searchParams.set("lat", String(lat));
    url.searchParams.set("lon", String(lon));
    url.searchParams.set("appid", appId);
    url.searchParams.set("units", units);

    let response;
    try {
      response = await fetch(url);
    } catch (err) {
      console.error("OpenWeather fetch error", err);
      throw new HttpsError("internal", "Weather request failed.");
    }

    if (!response.ok) {
      console.error("OpenWeather HTTP error", response.status);
      throw new HttpsError("internal", "Weather request failed.");
    }

    let body;
    try {
      body = await response.json();
    } catch (err) {
      console.error("OpenWeather JSON parse error", err);
      throw new HttpsError("internal", "Weather response invalid.");
    }

    return { weather: body };
  },
);
