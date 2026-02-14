# Setup Guide - GDrive Ingest

Complete setup instructions for `gdrive_ingest.sh`.

## Quick Start

```bash
# 1. Clone/copy the script
cd ~/x/ws/scripts/cloud/gdrive-ingest

# 2. Create configuration file
cp .env.example .env

# 3. Edit .env with your credentials
nano .env

# 4. Run the script
./gdrive_ingest.sh https://example.com/file.mp3
```

## Configuration

### 1. Google Drive API Setup

See **[docs/GOOGLE_SETUP.md](docs/GOOGLE_SETUP.md)** for detailed step-by-step instructions.

Summary:
1. Create project at https://console.cloud.google.com/
2. Enable Google Drive API
3. Create OAuth Desktop app credentials
4. Get refresh token using authorization code flow
5. Add credentials to `.env` file

### 2. Telegram Setup (Optional)

Only needed if downloading from Telegram.

See **[docs/TELEGRAM_SETUP.md](docs/TELEGRAM_SETUP.md)** for detailed instructions.

Summary:
1. Get API credentials from https://my.telegram.org
2. Install Telethon: `pip install telethon`
3. Add credentials to `.env` file
4. First run will prompt for phone + verification code

Or use the setup helper:
```bash
./setup_telegram.sh
```

## Dependencies

### Required
- `bash` 4.0+
- `curl`
- `jq` - JSON processor
- `file` - File type detection
- `md5sum` - Checksum calculation
- `unzip` - ZIP extraction

```bash
# Debian/Ubuntu
sudo apt install curl jq file coreutils unzip

# macOS
brew install curl jq coreutils

# Arch
sudo pacman -S curl jq file coreutils unzip
```

### Optional (for music features)
- `ffprobe` - Extract music metadata
- `ffmpeg` - Extract cover art

```bash
# Debian/Ubuntu
sudo apt install ffmpeg

# macOS
brew install ffmpeg

# Arch
sudo pacman -S ffmpeg
```

### Optional (for Telegram)
- `python3` - Python 3.7+
- `telethon` - Telegram API client

```bash
pip install telethon
```

## Configuration File (.env)

### Required Variables
```bash
CLIENT_ID=""           # Google OAuth Client ID
CLIENT_SECRET=""       # Google OAuth Client Secret
REFRESH_TOKEN=""       # Google OAuth Refresh Token
```

### Optional Variables
```bash
# Telegram (only if downloading from Telegram)
TELEGRAM_API_ID=""
TELEGRAM_API_HASH=""

# Script options
DEFAULT_FOLDER=""      # Skip folder selection (e.g., "bckups")
DEBUG=0                # Enable debug mode (0 or 1)
```

## File Locations

### Configuration
- `.env` - Your credentials (not committed to git)
- `.env.example` - Template for .env

### Temporary Files
All temp files are created in `/tmp/` with unique process IDs.

See **[docs/TEMP_FILES.md](docs/TEMP_FILES.md)** for complete documentation.

Quick cleanup:
```bash
./cleanup_temp.sh
```

### Session Files
- `~/.config/gdrive-ingest/telegram/` - Telegram authentication session (persistent)

## Testing Your Setup

### Test 1: Basic Download
```bash
./gdrive_ingest.sh https://example.com/file.txt
```

Expected:
- Interactive folder selector appears
- File downloads with progress bar
- File uploads to selected folder

### Test 2: Debug Mode
```bash
./gdrive_ingest.sh --debug https://example.com/file.txt
```

Expected:
- Shows commands that would run
- No actual download/upload occurs
- Useful for troubleshooting

### Test 3: Music File
```bash
./gdrive_ingest.sh https://example.com/song.mp3
```

Expected:
- Extracts metadata (Artist, Album, Title)
- Creates `Music/Artist/Album (Year)/song.mp3`
- Extracts and uploads cover art

### Test 4: Telegram (if configured)
```bash
./gdrive_ingest.sh https://t.me/channelname/123
```

Expected:
- First run: prompts for phone + code
- Downloads with progress bar
- Organizes and uploads normally

## Troubleshooting

### "Missing credentials in .env file"
- `.env` file doesn't exist or is empty
- Copy `.env.example` to `.env` and fill it in

### "Access token invalid or expired"
- Check your REFRESH_TOKEN
- It should start with `1//`
- Regenerate if needed (see docs/GOOGLE_SETUP.md)

### "TELEGRAM_API_ID not set"
- Only needed for Telegram downloads
- Get from https://my.telegram.org
- Add to `.env` file

### "curl: command not found"
- Install curl: `sudo apt install curl`

### "jq: command not found"
- Install jq: `sudo apt install jq`

### Telegram authentication fails
- Clear session: `rm -rf ~/.config/gdrive-ingest/telegram/`
- Try again - it will prompt for phone + code

### Temp files not cleaning up
- Run: `./cleanup_temp.sh`
- Or manually: `rm -rf /tmp/*_<pid>`

## Security Notes

### Do NOT commit to GitHub:
- `.env` file (contains secrets)
- `~/.config/gdrive-ingest/telegram/` (session files)

### Safe to commit:
- `.env.example` (template without secrets)
- All script files (`.sh`)
- Documentation (`.md`)

### Protecting Credentials
```bash
# Check .gitignore includes .env
cat .gitignore | grep .env

# Should output:
# .env
# .env.local
```

## Next Steps

1. Setup complete? Test with: `./gdrive_ingest.sh --debug`
2. See usage examples: `./gdrive_ingest.sh --help`
3. Start uploading: `./gdrive_ingest.sh <url>`

For more info:
- `QUICK_REFERENCE.md` - Command cheat sheet
- `CHANGELOG.md` - Version history
- `docs/GOOGLE_SETUP.md` - Google Drive setup
- `docs/TELEGRAM_SETUP.md` - Telegram details
- `docs/TEMP_FILES.md` - Temp file management
- `docs/INTERACTIVE_FEATURES.md` - UI guide
