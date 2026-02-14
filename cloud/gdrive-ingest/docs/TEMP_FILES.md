# Temporary Files - Location Reference

## Overview

The script creates temporary files in `/tmp/` during operation. All temp files include the process ID (`$$`) for uniqueness and to allow concurrent runs.

## Temp File Locations

### Download Stage
| File/Directory | Purpose | Cleanup |
|----------------|---------|---------|
| `/tmp/<filename>_$$` | Downloaded file before processing | After upload |
| `/tmp/tg_download_$$/ ` | Telegram download staging directory | After upload |
| `/tmp/tg_output_$$` | Telegram download logs (stdout/stderr) | After upload |

### Extraction Stage
| File/Directory | Purpose | Cleanup |
|----------------|---------|---------|
| `/tmp/extract_$$/ ` | ZIP extraction directory | After upload |
| `/tmp/single_$$/ ` | Single file staging directory | After upload |

### Music Processing
| File/Directory | Purpose | Cleanup |
|----------------|---------|---------|
| `/tmp/covers_$$/ ` | Extracted cover art files | After upload |

### Upload Stage
| File/Directory | Purpose | Cleanup |
|----------------|---------|---------|
| `/tmp/upload_result_$$` | Music file upload API response | After processing |
| `/tmp/cover_result_$$` | Cover art upload API response | After processing |
| `/tmp/other_result_$$` | Other file upload API response | After processing |

## Auto Cleanup

The script automatically cleans up temp files at the end of each URL processing:

```bash
# Line 1140 in gdrive_ingest.sh
rm -rf "$TEMP_FILE" "$EXTRACT_DIR" "$FILES_DIR" /tmp/covers_$$ 2>/dev/null
```

This happens:
- ✅ After successful upload
- ✅ After failed upload (continues to next URL)
- ✅ On normal script exit

## When Files Remain

Temp files may remain if:
- ❌ Script is killed (`kill -9`, system crash)
- ❌ Terminal closed during operation
- ❌ Script interrupted with `Ctrl+C` during upload

## Manual Cleanup

### Quick Clean (Current Session)
```bash
# Clean only current process's files
rm -rf /tmp/*_$$
```

### Full Clean (All Sessions)
```bash
# Use the cleanup script
./cleanup_temp.sh
```

The cleanup script will:
1. Scan for all temp files
2. Show file count and total size
3. Ask for confirmation
4. Delete all orphaned temp files

### Aggressive Clean (All /tmp/)
```bash
# WARNING: Clears ALL gdrive_ingest temp files from all sessions
rm -rf /tmp/upload_result_*
rm -rf /tmp/extract_*
rm -rf /tmp/tg_download_*
rm -rf /tmp/tg_output_*
rm -rf /tmp/single_*
rm -rf /tmp/covers_*
rm -rf /tmp/cover_result_*
rm -rf /tmp/other_result_*
```

## Persistent Files (NOT Auto-Cleaned)

### Telegram Session
```
~/.config/gdrive-ingest/telegram/downloader.session
```

**Purpose**: Stores Telegram authentication  
**Size**: ~1-2 KB  
**Cleanup**: Only delete if you want to re-authenticate

```bash
# To force re-authentication:
rm -rf ~/.config/gdrive-ingest/telegram/
```

## Disk Space Usage

Typical usage per file:
- **Small file (1-5MB)**: ~5-10MB temp space (original + staging)
- **Large file (100MB+)**: ~200MB+ temp space (original + extracted + staging)
- **Music album (10 songs)**: ~100-200MB temp space (songs + covers + extraction)

The script processes files sequentially and cleans up after each, so peak disk usage = size of largest single file being processed.

## Monitoring Temp Files

### Check current temp files
```bash
ls -lah /tmp/ | grep -E "extract_|upload_result_|tg_download_|single_|covers_"
```

### Check disk usage
```bash
du -sh /tmp/extract_* /tmp/single_* /tmp/covers_* 2>/dev/null | sort -h
```

### Watch in real-time
```bash
# In another terminal while script runs
watch -n 1 'ls -lah /tmp/ | grep -E "extract_|upload_result_|tg_download_|single_|covers_"'
```

## System Temp Directory

On most Linux systems, `/tmp/` is automatically cleaned:
- **On reboot**: All files cleared
- **Daily/Weekly**: Old files removed by `tmpwatch` or `systemd-tmpfiles`

So even if cleanup fails, temp files won't accumulate forever.

## Best Practices

1. **Run cleanup periodically** if you use the script frequently:
   ```bash
   ./cleanup_temp.sh
   ```

2. **Don't delete files mid-run** - let the script finish and clean up

3. **Check /tmp/ if script crashed**:
   ```bash
   ls -lah /tmp/ | grep $$
   ```

4. **Preserve Telegram session** - don't delete `~/.config/gdrive-ingest/`

## Environment Variables

You can customize temp location (advanced):

```bash
# In .env file
TMPDIR="/custom/temp/dir"
export TMPDIR
```

Then temp files go to `$TMPDIR` instead of `/tmp/`.

## Troubleshooting

### "No space left on device"
```bash
# Check disk space
df -h /tmp

# Clean up manually
./cleanup_temp.sh

# Or use different temp location with more space
export TMPDIR="/path/to/larger/disk/tmp"
```

### "Permission denied" when cleaning
```bash
# Temp files owned by different user
sudo rm -rf /tmp/*_<PID>

# Or run cleanup as your user
./cleanup_temp.sh
```

### Temp files keep accumulating
- Script might be getting killed before cleanup
- Check logs for errors
- Add manual cleanup to cron:
  ```bash
  # Add to crontab: clean daily at 3am
  0 3 * * * /path/to/cleanup_temp.sh
  ```

## Summary

| What | Where | When Cleaned |
|------|-------|--------------|
| Downloads | `/tmp/<file>_$$` | After upload |
| ZIP extracts | `/tmp/extract_$$/` | After upload |
| Cover art | `/tmp/covers_$$/` | After upload |
| Upload results | `/tmp/*_result_$$` | Immediately after use |
| Telegram session | `~/.config/gdrive-ingest/` | **Never** (persistent) |

**Quick cleanup**: `./cleanup_temp.sh`  
**Emergency**: `rm -rf /tmp/*_$$`  
**Full nuclear**: System reboot (clears all `/tmp/`)
