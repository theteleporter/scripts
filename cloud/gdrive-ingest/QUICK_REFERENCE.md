# GDrive Ingest - Quick Reference

## Basic Usage

```bash
# Interactive mode (browse folders with arrow keys)
./gdrive_ingest.sh https://example.com/file.mp3

# Skip folder selection
./gdrive_ingest.sh --folder "Music" https://example.com/song.mp3

# Multiple files
./gdrive_ingest.sh url1.mp3 url2.zip url3.mp4

# Comma-separated
./gdrive_ingest.sh "url1.mp3,url2.mp3,url3.mp3"

# From JSON file
./gdrive_ingest.sh --json downloads.json

# Debug mode
./gdrive_ingest.sh --debug https://example.com/file.mp3
```

## Configuration

### Setup .env File
```bash
cp .env.example .env
nano .env
```

Add your Google Drive credentials:
```bash
CLIENT_ID="your-client-id.apps.googleusercontent.com"
CLIENT_SECRET="GOCSPX-your-secret"
REFRESH_TOKEN="1//04your-refresh-token"
```

See `docs/GOOGLE_SETUP.md` for obtaining credentials.

## Telegram Downloads (Optional)

### First-Time Setup
```bash
# 1. Install Telethon
pip install telethon

# 2. Get API credentials from https://my.telegram.org
# 3. Add to .env file
TELEGRAM_API_ID="12345678"
TELEGRAM_API_HASH="your-api-hash"
```

Or use setup helper:
```bash
./setup_telegram.sh
```

### Download from Telegram
```bash
# Public channel
./gdrive_ingest.sh https://t.me/channelname/123

# Private channel (if you're a member)
./gdrive_ingest.sh https://t.me/c/1234567890/456

# Multiple Telegram links
./gdrive_ingest.sh https://t.me/channel/1 https://t.me/channel/2
```

**First run**: You'll be prompted for phone number + verification code (one-time).

## Music Organization

Music files are automatically organized:
```
Music/
  └── Artist Name/
      └── Album Name (Year)/
          ├── 01 - Song Title.mp3
          ├── 02 - Another Song.mp3
          └── cover.jpg
```

### Album Folder Behavior
When uploading a song to an existing album:
- Script prompts: "Upload to existing folder? [Y/n]:"
- **Press Enter or Y**: Uploads to existing album
- **Press N**: Uploads to Music root (un-nested)

### No Album Info
Songs without album metadata:
- Upload to: `Music/Artist Name/song.mp3`
- No cover art uploaded

## ZIP Files

When a ZIP is detected:
- Script prompts: "Extract and upload files? (y/n):"
- **Y**: Extracts and uploads to `Folders/zipname/`
- **N**: Uploads ZIP as-is

## File Categories

Files are automatically sorted:
- **Music** → `.mp3`, `.flac`, `.m4a`, `.wav`, etc.
- **Videos** → `.mp4`, `.mkv`, `.avi`, `.mov`, etc.
- **Images** → `.jpg`, `.png`, `.gif`, `.webp`, etc.
- **Docs** → `.pdf`, `.txt`, `.docx`, `.xlsx`, etc.
- **Folders** → Extracted ZIP contents
- **Others** → Everything else

## Interactive Navigation

```
╔═══════════════════════════════════════════════════════╗
║  Select Destination Folder                            ║
╠═══════════════════════════════════════════════════════╣
║  ↑/↓: Navigate  →: Open  ←: Back  Enter: Select      ║
╚═══════════════════════════════════════════════════════╝

  ▶ ● Create new folder
  ○ Music
  ○ Videos
  ○ Archives
```

**Controls**:
- `↑` / `↓` - Move selection
- `→` - Open folder
- `←` - Go back
- `Enter` - Select folder
- `q` - Quit

## Debug Mode

```bash
./gdrive_ingest.sh --debug https://example.com/file.mp3
```

**Shows**:
- Commands that would run (dry-run)
- Duplicate file checks
- API queries
- Upload operations

## JSON Format

```json
[
  "https://example.com/file1.mp3",
  "https://example.com/file2.zip",
  "https://t.me/channel/123"
]
```

Usage:
```bash
./gdrive_ingest.sh --json urls.json
```

## Troubleshooting

**"Missing credentials in .env file"**
- Create `.env` from `.env.example` and add credentials

**"TELEGRAM_API_ID required"**
- Add Telegram credentials to `.env` file

**"database is locked" (Telegram)**
```bash
rm ~/.config/gdrive-ingest/telegram/*.session-journal
```

**Upload fails with exit code 26**
- File path contains special characters or doesn't exist

**Cleanup temp files**
```bash
./cleanup_temp.sh
```

## Help

```bash
./gdrive_ingest.sh --help
```
```

## ✨ Features Summary

- ✅ Interactive folder selection (arrow keys)
- ✅ Live download progress bars
- ✅ Upload progress with spinners & size
- ✅ Telegram support (public & private)
- ✅ Smart music organization (Artist/Album/Year)
- ✅ Auto-extracts & uploads cover art
- ✅ ZIP extraction with prompt
- ✅ Duplicate detection (MD5 checksums)
- ✅ Multiple URL formats (args, comma-separated, JSON)
- ✅ Debug mode
- ✅ Color-coded output

## 🆘 Troubleshooting

### "Access token invalid or expired"
```bash
# Re-authenticate with Google Drive
# (Token refresh logic should be in your setup)
```

### "TELEGRAM_API_ID not set"
```bash
export TELEGRAM_API_ID='your_api_id'
export TELEGRAM_API_HASH='your_api_hash'
# Or run: ./setup_telegram.sh
```

### "ERROR: Message not found" (Telegram)
- Message doesn't exist or was deleted
- You don't have access to the channel
- Private channel requires membership

### "Already exists, skipping"
File already uploaded (detected via MD5). To override:
```bash
# Delete from Google Drive first, or
# Upload to different folder
```

### Session Issues (Telegram)
```bash
# Clear session and re-authenticate
rm -rf ~/.config/gdrive-ingest/telegram/
# Next run will prompt for phone + code
```

## 📚 Documentation

- `README.md` - Main documentation
- `CHANGELOG.md` - Version history
- `docs/TELEGRAM_SETUP.md` - Telegram setup guide
- `docs/INTERACTIVE_FEATURES.md` - Interactive UI guide
- `setup_telegram.sh` - Setup helper script

## 🔗 Quick Links

- Telegram API credentials: https://my.telegram.org
- Google Drive API: https://console.cloud.google.com/

## 🎯 Pro Tips

1. **Save API credentials** in `~/.bashrc` for persistence
2. **Use JSON files** for batch downloads
3. **Debug mode** helps troubleshoot upload issues
4. **Existing albums**: Press Enter (default Y) to reuse folders
5. **Telegram auth**: First-time only, then automatic forever
6. **Cover art**: Extracted once per album (saves bandwidth)

---

**Version**: 2.1.0 (2026-02-14)  
**Status**: Production Ready 🚀
