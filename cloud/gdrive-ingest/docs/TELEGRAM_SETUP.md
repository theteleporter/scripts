# Telegram Support Setup

The script now uses **Telethon** (Telegram API client) for downloading files from Telegram, which works for both public and private channels you have access to.

## Prerequisites

1. **Python 3.7+**
2. **Telethon library**
3. **Telegram API credentials**

## Installation

### 1. Install Telethon

```bash
pip install telethon
# or
pip3 install telethon
```

### 2. Get Telegram API Credentials

You need an API ID and API Hash from Telegram:

1. Go to https://my.telegram.org
2. Log in with your phone number
3. Click on **"API development tools"**
4. Fill in the form:
   - **App title**: `GDrive Ingest` (or any name)
   - **Short name**: `gdrive_ingest`
   - **Platform**: Other
   - **Description**: (optional)
5. Click **"Create application"**
6. You'll see:
   - **api_id**: A number (e.g., `12345678`)
   - **api_hash**: A string (e.g., `abc123def456...`)

### 3. Set Environment Variables

Add to your `~/.bashrc`, `~/.zshrc`, or `~/.profile`:

```bash
export TELEGRAM_API_ID='12345678'
export TELEGRAM_API_HASH='abc123def456...'
```

Then reload:
```bash
source ~/.bashrc  # or ~/.zshrc
```

Or set them temporarily for one session:
```bash
export TELEGRAM_API_ID='12345678'
export TELEGRAM_API_HASH='abc123def456...'
./gdrive_ingest.sh https://t.me/channel/123
```

## First Run - Authentication

The first time you download from Telegram, you'll be prompted to authenticate:

```
Please enter your phone (or bot token): +1234567890
Please enter the code you received: 12345
```

**This only happens once!**

A session file is saved to: `~/.config/gdrive-ingest/telegram/downloader.session`

Future runs will use this session automatically.

## Usage

Once set up, Telegram links work just like any other URL:

```bash
# Single file
./gdrive_ingest.sh https://t.me/channelname/123

# Multiple files
./gdrive_ingest.sh https://t.me/channel/123 https://t.me/channel/456

# With folder selection
./gdrive_ingest.sh https://t.me/channelname/123
```

## Supported Formats

- Public channels: `t.me/channelname/123`
- Private channels (if you're a member): `t.me/c/1234567890/456`
- Any media type: audio, video, photos, documents

## Troubleshooting

### "TELEGRAM_API_ID and TELEGRAM_API_HASH environment variables required"

You haven't set the API credentials. See step 3 above.

### "ERROR: Message not found"

- The message doesn't exist
- You don't have access to the channel
- The link is incorrect

### "ERROR: No media in message"

The Telegram message doesn't contain any file (text-only post).

### Session Issues

If authentication is acting weird:

```bash
rm -rf ~/.config/gdrive-ingest/telegram/
```

Next run will prompt for authentication again.

## Security Notes

- Your API credentials are **personal** - don't share them
- The session file contains your login - keep it private
- Session files are stored in `~/.config/gdrive-ingest/telegram/` (not in the repo)
- Never commit API credentials to git

## Why Telethon Instead of yt-dlp?

Telegram doesn't use traditional web cookies for authentication. Private channels require Telegram's native API with session-based auth. Telethon is the official Python library for this.

yt-dlp works for some public content, but fails on:
- Private channels
- Posts requiring authentication
- Telegram Web embeds (downloads metadata only)

Telethon works reliably for all cases.
