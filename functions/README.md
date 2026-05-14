# Firebase Functions (AquaPulse)

Callable functions for password reset OTP and **OpenWeather proxy** (keeps API key off the client).

## Deployed Callable Functions

- `requestPasswordResetCode`
- `verifyPasswordResetCode`
- `confirmPasswordResetWithCode`
- `getCurrentWeatherProxy` — authenticated users only; reads lat/lon and returns OpenWeather-shaped JSON

## Secrets and environment variables

### OpenWeather (production)

Store the OpenWeatherMap API key in Secret Manager and bind it to the function.

Use **`functions:secrets:set`** (note the plural **`secrets`**). There is no `functions:secret:set` command.

From the repo root (or any directory with your `firebase.json`):

```bash
firebase functions:secrets:set OPENWEATHER_API_KEY
```

Non-interactive / CI: pipe or use `--data-file` per `firebase functions:secrets:set --help`.

Redeploy after setting or rotating the secret:

```bash
npm run deploy
```

The Flutter app calls this callable when the user is signed in; release builds do **not** need `--dart-define=OPEN_WEATHER_API_KEY`.

### Password reset (existing)

Set these before deployment (or via your hosting provider’s env config):

- `SENDGRID_API_KEY`
- `RESET_FROM_EMAIL`
- `RESET_FROM_NAME` (optional, defaults to `AquaPulse`)

## Local development

Install dependencies:

```bash
npm install
```

For the **emulator**, provide the weather secret locally. Option A: create `functions/.secret.local` (do not commit) with:

```
OPENWEATHER_API_KEY=your_openweather_key
```

Option B: set `OPENWEATHER_API_KEY` in the environment used when starting the emulator.

Run emulator:

```bash
npm run serve
```

Deploy functions:

```bash
npm run deploy
```

## Troubleshooting deploy: “missing permission on the build service account”

Gen 2 functions build with Cloud Build and push images to Artifact Registry. If the default service accounts lack roles, the build can fail (often the first function in the batch, e.g. `requestPasswordResetCode`).

See [Cloud Functions troubleshooting – Build service account](https://cloud.google.com/functions/docs/troubleshooting#build-service-account).

Replace `PROJECT_ID` with your Firebase/GCP project id and `PROJECT_NUMBER` with the numeric project id (Firebase console → Project settings, or `gcloud projects describe PROJECT_ID --format='value(projectNumber)'`):

```bash
# Cloud Build can write images and logs
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:PROJECT_NUMBER@cloudbuild.gserviceaccount.com" \
  --role="roles/artifactregistry.writer"

gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:PROJECT_NUMBER@cloudbuild.gserviceaccount.com" \
  --role="roles/logging.logWriter"

# Default Compute SA: builder role (per Google doc) + read GCF source buckets
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
  --role="roles/cloudbuild.builds.builder"

gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
  --role="roles/storage.objectViewer"
```

Then redeploy: `firebase deploy --only functions --project PROJECT_ID`.
