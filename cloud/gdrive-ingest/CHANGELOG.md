# Changelog

## [2.1.0] - 2026-02-14

### Added
- Real upload progress tracking with percentage display
- Duplicate file detection with URL-encoded queries
- Colors to Telegram download progress bars
- Environment variable auto-export via `set -a` in .env loading

### Fixed
- Silent script exits caused by `set -e` during uploads
- Curl exit code 26 (file read errors) from unquoted file paths with spaces
- Upload progress showing fake percentages - now parses real curl output
- Telegram "database is locked" error from session journal files
- Cover art showing "failed" when duplicate exists (now shows "skipping")

### Changed
- All uploads now use `upload_with_progress()` for consistent tracking
- Cover art and non-music files show real-time progress
- Moved credentials from hardcoded to `.env` file
- Cleaned documentation - removed redundant/outdated files

---

## [2.0.0] - 2026-01-26

### Added
- **Telegram support** via Telethon API
  - Works with public and private channels
  - Session-based authentication
  - Live progress bars
- Python helper script: `telegram_downloader.py`
- Setup helper: `setup_telegram.sh`
- Documentation: `docs/TELEGRAM_SETUP.md`
- Environment variables: `TELEGRAM_API_ID`, `TELEGRAM_API_HASH`

### Changed
- Help text updated with Telegram setup instructions
- Removed yt-dlp dependency for Telegram links

### Fixed
- Process substitution for upload loop
- Silent exit after album folder prompt (read from `/dev/tty`)
- Silent exit after ZIP extraction prompt
- Telegram downloads appearing stuck (now streams with `tee`)

---

## [1.0.0] - 2026-01-25

### Added
- Interactive folder selection with arrow keys (↑/↓/→/←)
- Live download progress bars
- Upload progress with spinners
- Multiple URL support (comma-separated, JSON files)
- ZIP extraction with prompts
- Music organization: Artist/Album(Year) structure
- Cover art extraction and upload
- Duplicate file detection
- Color-coded output
- Debug mode with `--debug` flag

### Changed
- Changed from `set -eo pipefail` to `set -o pipefail`
- Progress bars use ASCII (= and -) characters
- Metadata cleaning removes website tags

### Fixed
- Navigation crashes in interactive mode
- Progress bar rendering issues
- Music folder duplication
- API timeouts added to curl calls

---

## [0.1.0] - Initial Release

### Features
- Basic file download and upload to Google Drive
- Simple categorization (Music, Videos, Images, Docs, Others)
- OAuth2 authentication with Google Drive API
