#!/bin/bash
# Cleanup temporary files created by gdrive_ingest.sh

echo "GDrive Ingest Temp File Cleanup"
echo "================================"
echo ""

# Get script PID pattern
CURRENT_PID=$$

# ==================== LIST TEMP FILES ====================
echo "Scanning for temporary files..."
echo ""

# All temp file patterns used by gdrive_ingest.sh
declare -a PATTERNS=(
  "/tmp/*_$$"           # Current session files
  "/tmp/upload_result_*"
  "/tmp/extract_*"
  "/tmp/tg_download_*"
  "/tmp/tg_output_*"
  "/tmp/single_*"
  "/tmp/covers_*"
  "/tmp/cover_result_*"
  "/tmp/other_result_*"
)

FOUND_FILES=0
TOTAL_SIZE=0

# Find files
for pattern in "${PATTERNS[@]}"; do
  while IFS= read -r file; do
    if [[ -e "$file" ]]; then
      SIZE=$(du -sh "$file" 2>/dev/null | cut -f1)
      SIZE_BYTES=$(du -sb "$file" 2>/dev/null | cut -f1)
      echo "  $file ($SIZE)"
      FOUND_FILES=$((FOUND_FILES + 1))
      TOTAL_SIZE=$((TOTAL_SIZE + SIZE_BYTES))
    fi
  done < <(compgen -G "$pattern" 2>/dev/null || true)
done

if [[ $FOUND_FILES -eq 0 ]]; then
  echo "  No temporary files found."
  echo ""
  echo "Temp files are automatically cleaned up after each run."
  exit 0
fi

echo ""
echo "Found: $FOUND_FILES file(s)"

# Convert bytes to human-readable
if [[ $TOTAL_SIZE -gt 1073741824 ]]; then
  SIZE_HR=$(echo "scale=2; $TOTAL_SIZE / 1073741824" | bc)
  SIZE_UNIT="GB"
elif [[ $TOTAL_SIZE -gt 1048576 ]]; then
  SIZE_HR=$(echo "scale=2; $TOTAL_SIZE / 1048576" | bc)
  SIZE_UNIT="MB"
elif [[ $TOTAL_SIZE -gt 1024 ]]; then
  SIZE_HR=$(echo "scale=2; $TOTAL_SIZE / 1024" | bc)
  SIZE_UNIT="KB"
else
  SIZE_HR=$TOTAL_SIZE
  SIZE_UNIT="bytes"
fi

echo "Total size: ${SIZE_HR}${SIZE_UNIT}"
echo ""

# ==================== CLEANUP PROMPT ====================
read -p "Delete these files? [y/N]: " -r REPLY
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Cleanup cancelled."
  exit 0
fi

# ==================== DELETE FILES ====================
echo "Cleaning up..."
DELETED=0

for pattern in "${PATTERNS[@]}"; do
  while IFS= read -r file; do
    if [[ -e "$file" ]]; then
      rm -rf "$file" 2>/dev/null && {
        echo "  Deleted: $file"
        DELETED=$((DELETED + 1))
      } || {
        echo "  Failed to delete: $file"
      }
    fi
  done < <(compgen -G "$pattern" 2>/dev/null || true)
done

echo ""
echo "Cleanup complete! Deleted $DELETED file(s)"
echo ""

# ==================== SHOW INFO ====================
echo "About temp files:"
echo "  - Created in /tmp/ during downloads and uploads"
echo "  - Auto-cleaned after each successful run"
echo "  - May remain if script is interrupted (Ctrl+C)"
echo "  - Safe to delete manually anytime"
echo ""
echo "Telegram session files (preserved):"
echo "  ~/.config/gdrive-ingest/telegram/"
echo "  (Contains your authentication - don't delete unless needed)"
