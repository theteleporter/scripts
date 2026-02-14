# Scripts Workspace

Personal collection of bash automation scripts and utilities.

## Structure

```
scripts/
├── cloud/gdrive-ingest/   Google Drive uploader with interactive UI
├── system/                System utilities
├── templates/             Script templates
└── README.md
```

## Featured Project

**GDrive Ingest** - Interactive Google Drive uploader with arrow-key navigation, live progress tracking, smart music organization, and Telegram support.

```bash
cd cloud/gdrive-ingest
./gdrive_ingest.sh https://example.com/file.mp3
```

## Guidelines

### Script Standards
- Include `#!/bin/bash` shebang
- Add `--help` flag
- Use color-coded output
- Error handling with `set -eo pipefail`
- Make executable: `chmod +x script.sh`

### Organization
- Group by category (cloud/, system/, etc.)
- Keep related files together
- Document in README files

### Style Template
```bash
#!/bin/bash
# script-name.sh - Brief description
# Usage: ./script-name.sh [OPTIONS]

set -eo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Your code here
```

## Development

```bash
# Create new script
touch my-script.sh
chmod +x my-script.sh

# Test syntax
bash -n my-script.sh

# Run with debug
./my-script.sh --debug
```

## Resources

- [Bash Guide](https://mywiki.wooledge.org/BashGuide)
- [ShellCheck](https://www.shellcheck.net/)
- [ANSI Colors](https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797)
