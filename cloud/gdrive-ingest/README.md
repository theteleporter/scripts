# GDrive Ingest - Ultimate Cloud Uploader

A powerful, interactive bash script for downloading and organizing files to Google Drive with a beautiful CLI interface.

## Features

- **Interactive folder browser** with arrow key navigation (↑/↓/→/←)
- **Live progress tracking** for downloads and uploads
- **Smart music organization** by Artist/Album/Year with auto-extracted cover art
- **Telegram support** for downloading from public/private channels
- **Duplicate detection** to prevent re-uploading files
- **Metadata cleaning** to remove website tags
- **Multi-URL support** via command-line, comma-separated, or JSON files
- **Color-coded output** with visual indicators

## Quick Start

```bash
# Interactive mode (with folder browser)
./gdrive_ingest.sh https://example.com/song.mp3

# Direct upload to folder
./gdrive_ingest.sh --folder "Music" https://example.com/song.mp3

# Multiple URLs
./gdrive_ingest.sh url1.mp3 url2.mp3 url3.mp3

# From JSON file
./gdrive_ingest.sh --json urls.json

# Telegram support
./gdrive_ingest.sh https://t.me/channelname/123
```

## Setup

### 1. Create `.env` file

```bash
cp .env.example .env
nano .env
```

### 2. Configure Google Drive API

Follow **[docs/GOOGLE_SETUP.md](docs/GOOGLE_SETUP.md)** for complete instructions to:
- Create Google Cloud project
- Enable Drive API
- Get OAuth credentials
- Generate refresh token

Add to `.env`:
```bash
CLIENT_ID="your-client-id.apps.googleusercontent.com"
CLIENT_SECRET="GOCSPX-your-secret"
REFRESH_TOKEN="1//04your-refresh-token"
```

### 3. Configure Telegram (Optional)

Only needed for Telegram downloads.

Get credentials from https://my.telegram.org and add to `.env`:
```bash
TELEGRAM_API_ID="12345678"
TELEGRAM_API_HASH="your-api-hash-here"
```

Install Telethon:
```bash
pip install telethon
```

See **[docs/TELEGRAM_SETUP.md](docs/TELEGRAM_SETUP.md)** for details.

## Usage

```
./gdrive_ingest.sh [OPTIONS] [URL...]

OPTIONS:
  -h, --help              Show help message
  -d, --debug             Debug mode (dry-run)
  -f, --folder <name>     Destination folder (skips interactive)
  -j, --json <file>       Load URLs from JSON file
```

## Interactive Controls

| Key | Action |
|-----|--------|
| `↑` `↓` | Navigate up/down |
| `→` | Enter folder |
| `←` | Go back |
| `Enter` | Select folder |
| `q` | Quit |

## File Organization

### Music Files
Organized with smart metadata extraction:
```
Music/
└── Artist Name/
    └── Album Title (Year)/
        ├── 01 - Track.mp3
        └── cover.jpg
```

### Other Files
- Images → `Images/`
- Videos → `Videos/`
- Documents → `Docs/`
- Archives → `Folders/archive-name/`
- Others → `Others/`

## Documentation

- **[SETUP.md](SETUP.md)** - Configuration guide
- **[docs/GOOGLE_SETUP.md](docs/GOOGLE_SETUP.md)** - Google Drive API setup
- **[docs/TELEGRAM_SETUP.md](docs/TELEGRAM_SETUP.md)** - Telegram configuration
- **[docs/INTERACTIVE_FEATURES.md](docs/INTERACTIVE_FEATURES.md)** - UI guide
- **[docs/TEMP_FILES.md](docs/TEMP_FILES.md)** - Temp file management
- **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - Command cheat sheet
- **[CHANGELOG.md](CHANGELOG.md)** - Version history

## Utilities

### Cleanup Temp Files
```bash
./cleanup_temp.sh
```
Removes leftover temp files from `/tmp/gdrive_*` and `~/.config/gdrive-ingest/`

### Telegram Setup Helper
```bash
./setup_telegram.sh
```
Interactive setup for Telegram credentials

## Requirements

### Core Dependencies (Required)

- **bash** 4.0 or higher
- **curl** - For HTTP requests and file downloads
- **jq** - JSON parsing for Google Drive API responses
- **ffprobe** (part of ffmpeg) - Music metadata extraction and cover art

Installation:
```bash
# Ubuntu/Debian
sudo apt install bash curl jq ffmpeg

# macOS (Homebrew)
brew install bash curl jq ffmpeg

# Arch Linux
sudo pacman -S bash curl jq ffmpeg
```

### Optional Dependencies

#### For Telegram Support (Optional)

Only needed if downloading from Telegram channels/groups.

**Requirements:**
- **python3** 3.7 or higher
- **pip3** - Python package manager
- **telethon** - Python library for Telegram

Installation:
```bash
# Install Python and pip (if not already installed)
# Ubuntu/Debian
sudo apt install python3 python3-pip

# macOS (usually pre-installed)
brew install python3

# Install Telethon
pip3 install telethon

# Or install with user flag
pip3 install --user telethon
```

**Setup:**
1. Get API credentials from https://my.telegram.org
2. Add to `.env` file:
   ```bash
   TELEGRAM_API_ID="12345678"
   TELEGRAM_API_HASH="your-api-hash"
   ```
3. First run will prompt for phone number and verification code

See **[docs/TELEGRAM_SETUP.md](docs/TELEGRAM_SETUP.md)** for detailed instructions.

## Troubleshooting

**"Missing credentials in .env file"**
- Create `.env` from `.env.example` and add your credentials

**"TELEGRAM_API_ID required"**
- Add Telegram credentials to `.env` (see docs/TELEGRAM_SETUP.md)

**"database is locked" (Telegram)**
- Remove session lock: `rm ~/.config/gdrive-ingest/telegram/*.session-journal`

**Upload fails with exit code 26**
- File path issue - ensure no special characters or verify file exists

See **[docs/TEMP_FILES.md](docs/TEMP_FILES.md)** for temp file cleanup.

## License

MIT License - see LICENSE file for details

---

**Made with ❤️ and bash**
