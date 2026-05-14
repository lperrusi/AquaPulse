# Password Reset Email Deliverability

This app now sends password reset OTP emails through a transactional provider (SendGrid) from Firebase Cloud Functions.

## Required DNS Records

Configure these records on your sending domain:

- SPF: include your provider's SPF include mechanism
- DKIM: provider-generated DKIM CNAME records
- DMARC: start with `p=quarantine`, monitor, then move to stricter policy if healthy

## Sender Identity

- Use a dedicated sender like `no-reply@yourdomain.com`
- Keep a stable, branded sender name (for example `AquaPulse`)
- Warm up new domains gradually before high-volume sends

## Content Guidelines

- Keep OTP emails short and plain
- Include both text and HTML versions
- Avoid suspicious words and unnecessary links
- Do not include reset links for this flow; only include one-time code and expiration

## Monitoring Checklist

- Enable bounce and complaint event webhooks in your email provider
- Alert on unusual bounce/complaint spikes
- Rotate API keys periodically
- Audit OTP request volume for abuse patterns
