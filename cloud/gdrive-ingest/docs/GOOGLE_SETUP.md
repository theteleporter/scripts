# Google Drive API Setup Guide

This guide walks you through setting up Google Drive API access from creating a project to getting a long-lived refresh token. It uses the **Desktop app** OAuth flow which works reliably for scripts.

**Important notes:**
- Keep the app in **Testing** mode (no verification needed, but limited to test users)
- Always add your own email as a test user **early** — otherwise you'll hit "Access blocked: app not verified"
- Use the `urn:ietf:wg:oauth:2.0:oob` flow (manual code copy-paste) — it works best for scripts

## Step 1: Create a Google Cloud Project

1. Go to https://console.cloud.google.com/
2. Click the project dropdown (top bar) → **New Project**
3. Name it (e.g., `gdrive-ingest-script`)
4. Click **Create** → wait a few seconds
5. Select the new project from the top dropdown

## Step 2: Enable the Google Drive API

1. Left menu: **APIs & Services** → **Library**
2. Search for **Google Drive API**
3. Click it → **Enable**

## Step 3: Create OAuth Consent Screen (Add Test User Here to Avoid "App Not Verified")

1. Left menu: **APIs & Services** → **OAuth consent screen**
2. Choose **External** user type → **Create**
3. Fill in basic info:
   - App name: `GDrive Ingest Script`
   - User support email: your email
   - Developer contact: your email
4. **Scopes** → Add or remove scopes → search **drive** → check **…/auth/drive** (full access) → **Update**
5. **Test users** → **+ Add users** → add your own email address (the one you'll use to sign in)
   - This is **critical** to avoid "Access blocked: app not verified" error later
6. Click **Save and Continue** through all steps → back to dashboard

Your app is now in **Testing** mode (valid for test users only — refresh token still works forever).

## Step 4: Create Desktop OAuth Credentials

1. Left menu: **APIs & Services** → **Credentials**
2. Click **+ Create Credentials** → **OAuth client ID**
3. Application type: **Desktop app**
4. Name: `gdrive-ingest-desktop`
5. Click **Create**
6. You'll see:
   - **Client ID** (long string ending in `.apps.googleusercontent.com`)
   - **Client Secret** (starts with `GOCSPX-`)
7. Copy both and save them for your `.env` file:

```bash
CLIENT_ID="your-client-id.apps.googleusercontent.com"
CLIENT_SECRET="GOCSPX-your-secret-here"
```

## Step 5: Get the Refresh Token (Manual Code Flow)

### 5.1: Build Authorization URL

Replace `YOUR_CLIENT_ID` with your actual Client ID:

```text
https://accounts.google.com/o/oauth2/v2/auth?client_id=YOUR_CLIENT_ID&redirect_uri=urn:ietf:wg:oauth:2.0:oob&scope=https://www.googleapis.com/auth/drive&access_type=offline&response_type=code
```

Example:
```text
https://accounts.google.com/o/oauth2/v2/auth?client_id=123456789012-abcde.apps.googleusercontent.com&redirect_uri=urn:ietf:wg:oauth:2.0:oob&scope=https://www.googleapis.com/auth/drive&access_type=offline&response_type=code
```

### 5.2: Authorize and Get Code

1. Open the URL in your browser
2. Sign in with the **test user email** you added in Step 3
3. Consent screen appears → **Allow**
4. Google shows a **verification code** on the page (long string like `4/0AX4...`)
   - If you see **"Access blocked: app not verified"** → go back to Step 3 and make sure your email is added as a test user
5. Copy the code

### 5.3: Exchange Code for Refresh Token

Run this curl command (replace placeholders):

```bash
curl -X POST \
  -d "code=YOUR_CODE_HERE" \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET" \
  -d "redirect_uri=urn:ietf:wg:oauth:2.0:oob" \
  -d "grant_type=authorization_code" \
  https://oauth2.googleapis.com/token
```

You'll get JSON response:

```json
{
  "access_token": "ya29...",
  "expires_in": 3599,
  "refresh_token": "1//04longlongstring...",
  "scope": "https://www.googleapis.com/auth/drive",
  "token_type": "Bearer"
}
```

### 5.4: Save Refresh Token

Copy the **refresh_token** value (starts with `1//04...` or `1//0g...`) and save it:

```bash
REFRESH_TOKEN="1//04your-refresh-token-here"
```

The refresh token is long-lived (valid until revoked or client secret reset).

## Step 6: Configure the Script

1. Create `.env` file from template:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` and fill in your credentials:
   ```bash
   CLIENT_ID="your-client-id.apps.googleusercontent.com"
   CLIENT_SECRET="GOCSPX-your-secret-here"
   REFRESH_TOKEN="1//04your-refresh-token-here"
   ```

3. Save the file

## Step 7: Test the Script

```bash
./gdrive_ingest.sh https://example.com/test.mp3
```

It should:
- Refresh token automatically if needed
- Show folder list
- Let you pick destination
- Download, organize, and upload

## Troubleshooting

### "Access blocked: app not verified"
- Add your email as a test user in OAuth consent screen (Step 3)
- Wait 1-5 minutes and retry

### "unauthorized_client" or "Unauthorized"
- Refresh token doesn't match client_id/secret
- Regenerate tokens in Step 5

### "redirect_uri_mismatch"
- Make sure you're using `urn:ietf:wg:oauth:2.0:oob` in the auth URL

### "403 access_denied"
- You're not a test user
- Add yourself again in consent screen

### Token expires quickly
- Normal behavior (access token lasts ~1 hour)
- Script auto-refreshes using the long-lived refresh token

### Refresh token stops working
- Regenerate using Step 5
- Or reset client secret (invalidates old tokens)

## Security Notes

- Never commit `CLIENT_ID`, `CLIENT_SECRET`, or `REFRESH_TOKEN` to git
- Use `.env` file (already in `.gitignore`)
- If paranoid: Reset client secret periodically and regenerate refresh token
- Consider using a **dedicated Google account** for this script (not your personal one)

## Alternative Methods

### Using OAuth Playground

1. Go to https://developers.google.com/oauthplayground/
2. Click settings (gear icon) in top right
3. Check **"Use your own OAuth credentials"**
4. Enter your CLIENT_ID and CLIENT_SECRET
5. In Step 1, find **"Drive API v3"**
6. Select `https://www.googleapis.com/auth/drive.file`
7. Click **"Authorize APIs"**
8. Sign in and authorize
9. In Step 2, click **"Exchange authorization code for tokens"**
10. Copy the **refresh_token** value

This is easier but gives you a token with limited scope (`drive.file` only, not full `drive` access).

## Next Steps

Once configured:
- See `QUICK_REFERENCE.md` for usage examples
- See `SETUP.md` for Telegram setup (optional)
- See `CHANGELOG.md` for feature list
