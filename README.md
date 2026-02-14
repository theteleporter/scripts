# Scripts Collection

A curated collection of bash scripts, automations, and utilities for productivity and system management.

## Structure

```
scripts/
├── cloud/              Cloud storage integrations
│   └── gdrive-ingest/  Interactive Google Drive uploader
├── system/             System utilities and tools
├── templates/          Script templates and starters
└── README.md           You are here
```

## Featured Projects

### [GDrive Ingest](cloud/gdrive-ingest/) 
Interactive Google Drive uploader with arrow key navigation, live progress bars, and smart music organization.

```bash
cd cloud/gdrive-ingest
./gdrive_ingest.sh https://example.com/file.mp3
```

**Features:**
- Arrow key folder navigation
- Live download/upload progress
- Music organization (Artist/Album/Year)
- Auto-extract cover art
- Clean metadata (removes website tags)
- Duplicate detection
- Telegram support

### System Tools

Power management, monitoring, and system utilities in `system/`

## Quick Start

### Clone the repository
```bash
git clone https://github.com/theteleporter/scripts.git ~/scripts
cd ~/scripts
```

### Make scripts executable
```bash
chmod +x cloud/gdrive-ingest/gdrive_ingest.sh
chmod +x system/*.sh
```

### Add to PATH (optional)
```bash
echo 'export PATH="$HOME/scripts/cloud/gdrive-ingest:$PATH"' >> ~/.bashrc
echo 'export PATH="$HOME/scripts/system:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

## Requirements

### General
- **bash** 4.0 or higher
- Standard Unix utilities (find, grep, sed, awk)

### Project-Specific

#### GDrive Ingest
**Core (Required):**
- bash, curl, jq, ffprobe (ffmpeg)

**Optional (for Telegram support):**
- python3 (3.7+)
- pip3
- telethon library

See [cloud/gdrive-ingest/README.md](cloud/gdrive-ingest/README.md#requirements) for detailed installation instructions.

## Categories

### Cloud Integration (`cloud/`)
Scripts for cloud storage services (Google Drive, Dropbox, etc.)

### System Utilities (`system/`)
Power management, monitoring, backups, and system automation

### Templates (`templates/`)
Starter templates for creating new scripts

## Script Standards

All scripts follow these conventions:

- Bash shebang (`#!/bin/bash`)
- Help flag (`--help`)
- Color-coded output
- Error handling
- Documentation header
- Executable permissions

### Example Template
```bash
#!/bin/bash
# script-name.sh - Brief description
# Usage: ./script-name.sh [OPTIONS]

set -eo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Your code here
echo -e "${GREEN}✓ Success${NC}"
```

## Development

### Create a new script
```bash
# Copy template
cp templates/script-template.sh my-new-script.sh
chmod +x my-new-script.sh

# Edit
nano my-new-script.sh

# Test syntax
bash -n my-new-script.sh
```

### Test scripts
```bash
bash -n script.sh          # Syntax check
shellcheck script.sh       # Linting
./script.sh --debug        # Dry run
```

## Documentation

Each project has its own README with:
- Usage examples
- Features list
- Configuration guide
- Troubleshooting

## Contributing

Feel free to:
- Add new scripts
- Improve existing ones
- Fix bugs
- Update documentation

### Guidelines
1. Follow the script standards above
2. Add documentation
3. Test thoroughly
4. Keep it simple and readable

## License

MIT License - see LICENSE file for details

---

**Made with ❤️ and bash**
