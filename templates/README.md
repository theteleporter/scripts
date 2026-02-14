# 📝 Script Templates

Starter templates for creating new bash scripts quickly.

## 📄 Available Templates

### `script-template.sh`
Full-featured bash script template with:
- ✅ Color-coded output
- ✅ Help flag (`--help`)
- ✅ Debug mode (`--debug`)
- ✅ Verbose option (`--verbose`)
- ✅ Error handling (`set -eo pipefail`)
- ✅ Logging functions (log, success, error, warning, debug)
- ✅ Argument parsing

## 🚀 Quick Start

### Create a new script from template
```bash
# Copy template
cp templates/script-template.sh my-script.sh

# Make executable
chmod +x my-script.sh

# Edit with your favorite editor
nano my-script.sh
```

### Customize the template
1. Change `script-name.sh` to your script name
2. Update the description
3. Modify options and arguments
4. Add your logic in the `main()` function
5. Update the help text

## 🎨 Template Structure

```bash
#!/bin/bash
# Header with description and usage

set -eo pipefail          # Error handling

# Colors                  # Predefined color codes
# Configuration           # Script variables
# Functions              # Helper functions (log, success, error, etc.)
# Arg Parsing            # Command-line argument handling
# Main Logic             # Your code here
# Execution              # Entry point
```

## 💡 Best Practices

### Use the logging functions
```bash
log "Processing file..."           # Blue info message
success "File processed"            # Green success message
error "Failed to read file"         # Red error message
warning "File size is large"        # Yellow warning
debug "Variable value: $VAR"        # Dim debug message (only in debug mode)
```

### Add debug mode support
```bash
if [[ $DEBUG -eq 1 ]]; then
  debug "This will only show in debug mode"
  echo "Would execute: some_command"
else
  some_command
fi
```

### Error handling
```bash
# The template uses 'set -eo pipefail' which:
# -e: Exit on any error
# -o pipefail: Exit on pipe failures

# For commands that might fail:
some_command || {
  error "Command failed"
  exit 1
}
```

## 📖 Examples

### Simple script
```bash
#!/bin/bash
# hello.sh - Greet the user

set -eo pipefail

GREEN='\033[0;32m'
NC='\033[0m'

main() {
  NAME="${1:-World}"
  echo -e "${GREEN}Hello, $NAME!${NC}"
}

main "$@"
```

### Script with options
```bash
#!/bin/bash
# backup.sh - Backup a directory

set -eo pipefail

BACKUP_DIR="/backup"

while [[ $# -gt 0 ]]; do
  case $1 in
    -s|--source)
      SOURCE="$2"
      shift 2
      ;;
    -d|--destination)
      BACKUP_DIR="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

main() {
  tar -czf "$BACKUP_DIR/backup-$(date +%Y%m%d).tar.gz" "$SOURCE"
  echo "✓ Backup created"
}

main
```

## 🔧 Tips

1. **Start with the template** - Don't write from scratch
2. **Update help text** - Keep documentation current
3. **Test with --debug** - Use debug mode during development
4. **Use colors wisely** - Don't overdo it
5. **Add examples** - Show users how to use your script

## 📚 Resources

- [Bash Guide](https://mywiki.wooledge.org/BashGuide)
- [ShellCheck](https://www.shellcheck.net/) - Script linter
- [ANSI Color Codes](https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797)

---

**Happy scripting!** 🚀
