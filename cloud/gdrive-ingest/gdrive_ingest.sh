#!/bin/bash
# gdrive_ingest.sh - Ultimate cloud ingestor for Google Drive
# Downloads → unzips → smart organizes (especially music with tags) → uploads
# All cloud-based, no local heavy lifting beyond temp files
#
# Usage:
#   ./gdrive_ingest.sh [--debug] [--folder "Name"] [URL]
#   --debug   : Show commands, skip real execution
#   --folder  : Skip prompt for destination folder
#   --json    : Load URLs from JSON file
#   URL       : Optional; prompts if missing
#
# Examples:
#   ./gdrive_ingest.sh --folder "bckups" "url1.mp3,url2.mp3"
#   ./gdrive_ingest.sh --folder "bckups" url1.mp3 url2.mp3
#   ./gdrive_ingest.sh --folder "bckups" --json urls.json

set -o pipefail

# ==================== LOAD CONFIGURATION ====================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

if [[ -f "$ENV_FILE" ]]; then
  # shellcheck source=/dev/null
  set -a  # automatically export all variables
  source "$ENV_FILE"
  set +a
  # Validate required variables
  if [[ -z "$CLIENT_ID" ]] || [[ -z "$CLIENT_SECRET" ]]; then
    echo -e "\033[0;31m✗ Missing credentials in .env file\033[0m"
    echo -e "\033[1;33mRequired: CLIENT_ID, CLIENT_SECRET, REFRESH_TOKEN\033[0m"
    echo -e "\033[2mCopy .env.example to .env and fill in your credentials\033[0m"
    exit 1
  fi
else
  echo -e "\033[0;31m✗ .env file not found\033[0m"
  echo -e "\033[1;33mCreate one from .env.example:\033[0m"
  echo -e "\033[2m  cp .env.example .env\033[0m"
  echo -e "\033[2m  # Then edit .env with your credentials\033[0m"
  exit 1
fi

# ==================== COLORS ====================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Color

# ==================== INTERACTIVE UI HELPERS ====================
# Hide cursor
hide_cursor() { tput civis 2>/dev/null || printf '\033[?25l'; }
# Show cursor
show_cursor() { tput cnorm 2>/dev/null || printf '\033[?25h'; }
# Move cursor up N lines
move_up() { tput cuu "${1:-1}" 2>/dev/null || printf '\033[%sA' "${1:-1}"; }
# Clear from cursor to end of line
clear_line() { tput el 2>/dev/null || printf '\033[K'; }
# Save cursor position
save_cursor() { tput sc 2>/dev/null || printf '\033[s'; }
# Restore cursor position
restore_cursor() { tput rc 2>/dev/null || printf '\033[u'; }

# Cleanup on exit
cleanup() {
  show_cursor
  stty echo 2>/dev/null || true
}
trap cleanup EXIT INT TERM

# ==================== HELP ====================
show_help() {
  cat << EOF
${BOLD}${CYAN}gdrive_ingest.sh${NC} - Ultimate Google Drive cloud ingestor

${BOLD}USAGE:${NC}
  ./gdrive_ingest.sh [OPTIONS] [URL...]

${BOLD}OPTIONS:${NC}
  ${GREEN}-h, --help${NC}              Show this help message
  ${GREEN}-d, --debug${NC}             Debug mode (dry-run, show commands)
  ${GREEN}-f, --folder${NC} <name>     Destination folder (skips interactive mode)
  ${GREEN}-j, --json${NC} <file>       Load URLs from JSON file

${BOLD}INTERACTIVE MODE:${NC}
  When run without ${GREEN}--folder${NC}, an interactive folder browser opens:
  • ${CYAN}↑/↓${NC} - Navigate folders
  • ${CYAN}→${NC}   - Open/enter folder
  • ${CYAN}←${NC}   - Go back to parent
  • ${CYAN}Enter${NC} - Select folder
  • ${CYAN}q${NC}   - Quit

${BOLD}URL FORMATS:${NC}
  Single URL:              ./gdrive_ingest.sh https://example.com/file.mp3
  Multiple URLs:           ./gdrive_ingest.sh url1.mp3 url2.zip url3.mp4
  Comma-separated:         ./gdrive_ingest.sh "url1.mp3,url2.mp3,url3.mp3"
  Telegram links:          ./gdrive_ingest.sh https://t.me/channelname/123
  JSON file:               ./gdrive_ingest.sh --json urls.json
  
${BOLD}JSON FORMAT:${NC}
  ["https://example.com/file1.mp3", "https://example.com/file2.zip"]

${BOLD}EXAMPLES:${NC}
  ${DIM}# Interactive mode - browse folders with arrow keys${NC}
  ./gdrive_ingest.sh https://example.com/song.mp3
  
  ${DIM}# Telegram file${NC}
  ./gdrive_ingest.sh https://t.me/channelname/123
  
  ${DIM}# Skip interactive mode${NC}
  ./gdrive_ingest.sh --folder "Music" https://example.com/song.mp3
  
  ${DIM}# Multiple files${NC}
  ./gdrive_ingest.sh --folder "bckups" url1.mp3 url2.zip
  
  ${DIM}# From JSON file${NC}
  ./gdrive_ingest.sh --folder "Archive" --json downloads.json

${BOLD}FEATURES:${NC}
  ✓ Interactive folder selection (arrow keys)
  ✓ Live download progress bars
  ✓ Upload progress with spinners
  ✓ Telegram support (Telethon API - public & private)
  ✓ Auto-extracts ZIPs (with prompt)
  ✓ Smart categorization (Images, Music, Videos, Docs)
  ✓ Music: Artist/Album(Year) structure
  ✓ Auto-extracts & uploads cover art
  ✓ Duplicate detection
  ✓ MD5 checksums
  ✓ Color-coded output

${BOLD}TELEGRAM SETUP:${NC}
  For Telegram downloads, you need:
  1. ${GREEN}pip install telethon${NC}
  2. Get API credentials from ${CYAN}https://my.telegram.org${NC}
  3. Set environment variables:
     ${DIM}export TELEGRAM_API_ID='your_api_id'${NC}
     ${DIM}export TELEGRAM_API_HASH='your_api_hash'${NC}
  
  See: ${CYAN}docs/TELEGRAM_SETUP.md${NC} for detailed setup

${BOLD}REQUIREMENTS:${NC}
  • curl, jq, unzip, file
  • ffmpeg, ffprobe (for music metadata)
  • yt-dlp (for Telegram links: ${DIM}pip install yt-dlp${NC})

EOF
  exit 0
}

# ==================== CREDENTIALS ====================
# Credentials are loaded from .env file (see lines 20-41)
# The .env file should contain:
#   CLIENT_ID="your-client-id"
#   CLIENT_SECRET="your-client-secret"
#   REFRESH_TOKEN="your-refresh-token"

TOKEN_FILE="$HOME/.gdrive_token"

# ==================== ARG PARSING ====================
DEBUG=0
FOLDER_ARG=""
declare -a URLS=()
JSON_FILE=""

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_help
      ;;
    --debug|-d) 
      DEBUG=1
      shift 
      ;;
    --folder|-f)
      FOLDER_ARG="${2:-}"
      shift 2
      ;;
    --json|-j)
      JSON_FILE="${2:-}"
      shift 2
      ;;
    *)
      # Handle comma-separated URLs or individual URLs
      if [[ "$1" =~ , ]]; then
        IFS=',' read -ra SPLIT_URLS <<< "$1"
        URLS+=("${SPLIT_URLS[@]}")
      else
        URLS+=("$1")
      fi
      shift
      ;;
  esac
done

# ==================== CREDENTIAL CHECK ====================
if [[ -z "$CLIENT_ID" || -z "$CLIENT_SECRET" || -z "$REFRESH_TOKEN" ]]; then
  echo -e "${RED}ERROR: Missing credentials.${NC} Edit the script:"
  echo "  CLIENT_ID=..."
  echo "  CLIENT_SECRET=..."
  echo "  REFRESH_TOKEN=1//04..."
  exit 1
fi

# ==================== TOKEN REFRESH / CACHE ====================
refresh_token() {
  echo -e "${CYAN}Refreshing access token...${NC}"
  REFRESH_JSON=$(curl -s -X POST \
    -d "client_id=$CLIENT_ID" \
    -d "client_secret=$CLIENT_SECRET" \
    -d "refresh_token=$REFRESH_TOKEN" \
    -d "grant_type=refresh_token" \
    https://oauth2.googleapis.com/token)

  ACCESS_TOKEN=$(echo "$REFRESH_JSON" | jq -r '.access_token // empty')
  if [[ -z "$ACCESS_TOKEN" || "$ACCESS_TOKEN" == "null" ]]; then
    echo -e "${RED}ERROR: Refresh failed!${NC}"
    echo "$REFRESH_JSON" | jq . 2>/dev/null || echo "$REFRESH_JSON"
    exit 1
  fi

  EXPIRES_IN=$(echo "$REFRESH_JSON" | jq -r '.expires_in // 3600')
  echo "ACCESS_TOKEN=$ACCESS_TOKEN" > "$TOKEN_FILE"
  echo "EXPIRES_AT=$(($(date +%s) + EXPIRES_IN - 300))" >> "$TOKEN_FILE"
  chmod 600 "$TOKEN_FILE"
  echo -e "${GREEN}✓ Token cached successfully${NC}"
}

ACCESS_TOKEN=""
EXPIRES_AT=0
if [[ -f "$TOKEN_FILE" ]]; then
  source "$TOKEN_FILE" 2>/dev/null || true
  if [[ $(date +%s) -lt "${EXPIRES_AT:-0}" ]]; then
    echo -e "${GREEN}✓ Using cached access token${NC} ${DIM}(valid until $(date -d "@$EXPIRES_AT" 2>/dev/null || date))${NC}"
  else
    refresh_token
  fi
else
  refresh_token
fi

# ==================== LOAD URLs ====================
if [[ -n "$JSON_FILE" ]] && [[ -f "$JSON_FILE" ]]; then
  echo -e "${CYAN}Loading URLs from${NC} ${BOLD}$JSON_FILE${NC}..."
  mapfile -t JSON_URLS < <(jq -r '.[]' "$JSON_FILE" 2>/dev/null || cat "$JSON_FILE")
  URLS+=("${JSON_URLS[@]}")
fi

if [[ ${#URLS[@]} -eq 0 ]]; then
  echo -e "${YELLOW}Enter URL(s) to download (comma-separated):${NC}"
  echo -e "${DIM}Paste URLs separated by commas, then press Enter${NC}"
  echo -e "${DIM}Example: url1.mp3, url2.mp3, url3.mp3${NC}"
  
  read -r input_urls
  
  if [[ -n "$input_urls" ]]; then
    # Split by comma and clean whitespace
    IFS=',' read -ra SPLIT_URLS <<< "$input_urls"
    for url in "${SPLIT_URLS[@]}"; do
      url=$(echo "$url" | xargs)  # Trim whitespace
      [[ -n "$url" ]] && URLS+=("$url")
    done
  fi
  
  if [[ ${#URLS[@]} -eq 0 ]]; then
    echo -e "${RED}No URLs provided. Exiting.${NC}"
    exit 1
  fi
fi

echo -e "${BOLD}${MAGENTA}📦 Processing ${#URLS[@]} URL(s)${NC}"

# ==================== LIST FOLDERS ====================
echo -e "${CYAN}Fetching your GDrive folders...${NC}"
FOLDERS_JSON=$(curl -s -H "Authorization: Bearer $ACCESS_TOKEN" \
  "https://www.googleapis.com/drive/v3/files?q=mimeType='application/vnd.google-apps.folder'%20and%20trashed=false&fields=files(id,name,parents)&pageSize=1000")

if echo "$FOLDERS_JSON" | grep -q '"error"'; then
  echo -e "${RED}API error:${NC}"
  echo "$FOLDERS_JSON" | jq . 2>/dev/null || echo "$FOLDERS_JSON"
  exit 1
fi

# ==================== INTERACTIVE FOLDER SELECTOR ====================
interactive_folder_select() {
  local current_parent="${1:-root}"
  local selected=0
  local folder_list=()
  local folder_ids=()
  local folder_parents=()
  
  # Build folder list for current level
  if [[ "$current_parent" == "root" ]]; then
    mapfile -t folder_list < <(echo "$FOLDERS_JSON" | jq -r '.files[] | select(.parents == null or (.parents | length == 0)) | .name' 2>/dev/null | sort)
    mapfile -t folder_ids < <(echo "$FOLDERS_JSON" | jq -r '.files[] | select(.parents == null or (.parents | length == 0)) | .id' 2>/dev/null | sort)
  else
    mapfile -t folder_list < <(echo "$FOLDERS_JSON" | jq -r --arg parent "$current_parent" '.files[] | select(.parents[]? == $parent) | .name' 2>/dev/null | sort)
    mapfile -t folder_ids < <(echo "$FOLDERS_JSON" | jq -r --arg parent "$current_parent" '.files[] | select(.parents[]? == $parent) | .id' 2>/dev/null | sort)
  fi
  
  # Add special options
  if [[ "$current_parent" != "root" ]]; then
    folder_list=("◂ Back" "● Select this folder" "${folder_list[@]}")
    folder_ids=("__BACK__" "__SELECT__" "${folder_ids[@]}")
  else
    folder_list=("✎ Type folder name/ID" "● Create new folder" "${folder_list[@]}")
    folder_ids=("__TYPE__" "__CREATE__" "${folder_ids[@]}")
  fi
  
  local total=${#folder_list[@]}
  
  if [[ $total -eq 0 ]]; then
    echo -e "${YELLOW}No folders found${NC}"
    return 1
  fi
  
  hide_cursor
  
  while true; do
    clear
    echo -e "${BOLD}${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║${NC}  ${MAGENTA}📁 Select Destination Folder${NC}                      ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}╠═══════════════════════════════════════════════════════╣${NC}"
    echo -e "${BOLD}${CYAN}║${NC}  ${DIM}↑/↓: Navigate  →: Open  ←: Back  Enter: Select${NC}    ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Display folders
    for i in "${!folder_list[@]}"; do
      if [[ $i -eq $selected ]]; then
        # Selected item
        if [[ "${folder_list[$i]}" == "◂ Back" ]]; then
          echo -e "  ${YELLOW}▶${NC} ${BOLD}${folder_list[$i]}${NC}"
        elif [[ "${folder_list[$i]}" == "● Select this folder" ]]; then
          echo -e "  ${GREEN}▶${NC} ${BOLD}${GREEN}${folder_list[$i]}${NC}"
        elif [[ "${folder_list[$i]}" == "✎ Type folder name/ID" ]]; then
          echo -e "  ${GREEN}▶${NC} ${BOLD}${GREEN}${folder_list[$i]}${NC}"
        elif [[ "${folder_list[$i]}" == "● Create new folder" ]]; then
          echo -e "  ${GREEN}▶${NC} ${BOLD}${GREEN}${folder_list[$i]}${NC}"
        else
          echo -e "  ${CYAN}▶${NC} ${BOLD}${folder_list[$i]}${NC}"
        fi
      else
        # Unselected item
        if [[ "${folder_list[$i]}" == "◂ Back" ]]; then
          echo -e "  ${DIM}○${NC} ${folder_list[$i]}"
        elif [[ "${folder_list[$i]}" == "● Select this folder" ]]; then
          echo -e "  ${DIM}○${NC} ${folder_list[$i]}"
        elif [[ "${folder_list[$i]}" == "✎ Type folder name/ID" ]]; then
          echo -e "  ${DIM}○${NC} ${folder_list[$i]}"
        elif [[ "${folder_list[$i]}" == "● Create new folder" ]]; then
          echo -e "  ${DIM}○${NC} ${folder_list[$i]}"
        else
          echo -e "  ${DIM}○${NC} ${folder_list[$i]}"
        fi
      fi
    done
    
    # Read single key
    read -rsn1 key
    
    case "$key" in
      $'\x1b')  # ESC sequence
        read -rsn2 -t 0.1 key
        case "$key" in
          '[A') # Up arrow
            selected=$((selected - 1))
            if [[ $selected -lt 0 ]]; then
              selected=$((total - 1))
            fi
            ;;
          '[B') # Down arrow
            selected=$((selected + 1))
            if [[ $selected -ge $total ]]; then
              selected=0
            fi
            ;;
          '[C') # Right arrow - enter folder
            if [[ "${folder_ids[$selected]}" != "__BACK__" ]] && \
               [[ "${folder_ids[$selected]}" != "__SELECT__" ]] && \
               [[ "${folder_ids[$selected]}" != "__CREATE__" ]] && \
               [[ "${folder_ids[$selected]}" != "__TYPE__" ]]; then
              show_cursor
              interactive_folder_select "${folder_ids[$selected]}"
              local result=$?
              if [[ $result -eq 0 ]]; then
                return 0  # Folder selected successfully
              fi
              # If result is 2 (back), just continue the loop
              hide_cursor
            fi
            ;;
          '[D') # Left arrow - go back
            if [[ "$current_parent" != "root" ]]; then
              show_cursor
              return 2
            fi
            # At root level, ignore back arrow
            ;;
        esac
        ;;
      '') # Enter key
        show_cursor
        
        if [[ "${folder_ids[$selected]}" == "__BACK__" ]]; then
          return 2  # Go back
        elif [[ "${folder_ids[$selected]}" == "__SELECT__" ]]; then
          SELECTED_FOLDER_ID="$current_parent"
          return 0  # Selected current folder
        elif [[ "${folder_ids[$selected]}" == "__TYPE__" ]]; then
          clear
          echo -e "${YELLOW}Enter folder name or ID:${NC} "
          read -r typed_input
          if [[ -n "$typed_input" ]]; then
            # Check if it's an ID or name
            if [[ "$typed_input" =~ ^[a-zA-Z0-9_-]{28,}$ ]]; then
              SELECTED_FOLDER_ID="$typed_input"
              return 0
            else
              # Search for folder by name
              echo -e "${CYAN}Searching for folder...${NC}"
              SELECTED_FOLDER_ID=$(echo "$FOLDERS_JSON" | jq -r --arg name "$typed_input" '.files[] | select(.name == $name) | .id' 2>/dev/null | head -1)
              
              if [[ -z "$SELECTED_FOLDER_ID" ]]; then
                echo -e "${YELLOW}Folder not found. Create it? (y/n)${NC} "
                read -r create_choice
                if [[ "$create_choice" =~ ^[Yy]$ ]]; then
                  echo -e "${CYAN}Creating folder...${NC}"
                  CREATE_RESULT=$(curl -s -X POST -H "Authorization: Bearer $ACCESS_TOKEN" \
                    -H "Content-Type: application/json" \
                    -d "{\"name\": \"$typed_input\", \"mimeType\": \"application/vnd.google-apps.folder\"}" \
                    https://www.googleapis.com/drive/v3/files)
                  
                  SELECTED_FOLDER_ID=$(echo "$CREATE_RESULT" | jq -r '.id // empty')
                  
                  if [[ -n "$SELECTED_FOLDER_ID" ]]; then
                    echo -e "${GREEN}✓ Created folder${NC}"
                    sleep 1
                    return 0
                  else
                    echo -e "${RED}✗ Failed to create folder${NC}"
                    sleep 2
                    hide_cursor
                    continue
                  fi
                else
                  hide_cursor
                  continue
                fi
              else
                echo -e "${GREEN}✓ Found folder${NC}"
                sleep 1
                return 0
              fi
            fi
          fi
          hide_cursor
        elif [[ "${folder_ids[$selected]}" == "__CREATE__" ]]; then
          clear
          echo -e "${YELLOW}Enter new folder name:${NC} "
          read -r new_folder_name
          if [[ -n "$new_folder_name" ]]; then
            echo -e "${CYAN}Creating folder...${NC}"
            CREATE_RESULT=$(curl -s -X POST -H "Authorization: Bearer $ACCESS_TOKEN" \
              -H "Content-Type: application/json" \
              -d "{\"name\": \"$new_folder_name\", \"mimeType\": \"application/vnd.google-apps.folder\"}" \
              https://www.googleapis.com/drive/v3/files)
            
            SELECTED_FOLDER_ID=$(echo "$CREATE_RESULT" | jq -r '.id // empty')
            
            if [[ -n "$SELECTED_FOLDER_ID" ]]; then
              echo -e "${GREEN}✓ Created folder${NC}"
              sleep 1
              return 0
            else
              echo -e "${RED}✗ Failed to create folder${NC}"
              sleep 2
              return 1
            fi
          fi
        else
          SELECTED_FOLDER_ID="${folder_ids[$selected]}"
          return 0  # Selected a folder
        fi
        ;;
      q|Q)  # Quit
        show_cursor
        echo -e "${RED}Cancelled${NC}"
        exit 0
        ;;
    esac
  done
}

# ==================== CHOOSE DESTINATION ====================
if [[ -z "$FOLDER_ARG" ]]; then
  # Interactive mode
  interactive_folder_select
  select_result=$?
  
  if [[ $select_result -eq 0 ]]; then
    PARENT_ID="$SELECTED_FOLDER_ID"
  else
    echo -e "${RED}Selection cancelled${NC}"
    exit 0
  fi
  
  # Get folder name for display
  DEST_INPUT=$(echo "$FOLDERS_JSON" | jq -r --arg id "$PARENT_ID" '.files[] | select(.id == $id) | .name' 2>/dev/null | head -1)
  [[ -z "$DEST_INPUT" ]] && DEST_INPUT="$PARENT_ID"
  
  clear
  echo -e "${GREEN}✓ Selected:${NC} ${BOLD}$DEST_INPUT${NC} ${DIM}(ID: $PARENT_ID)${NC}"
else
  # Command-line argument mode
  DEST_INPUT="$FOLDER_ARG"
  echo -e "${GREEN}Using folder:${NC} ${BOLD}$DEST_INPUT${NC}"
  
  # Detect if input is an ID (28+ chars, alphanumeric with _ and -)
  if [[ "$DEST_INPUT" =~ ^[a-zA-Z0-9_-]{28,}$ ]]; then
    echo -e "${BLUE}Detected as folder ID${NC}"
    PARENT_ID="$DEST_INPUT"
  else
    echo -e "${BLUE}Searching for folder named:${NC} $DEST_INPUT"
    PARENT_ID=$(curl -s -H "Authorization: Bearer $ACCESS_TOKEN" \
      "https://www.googleapis.com/drive/v3/files?q=name='$DEST_INPUT'%20and%20mimeType='application/vnd.google-apps.folder'%20and%20trashed=false&fields=files(id)" \
      | jq -r '.files[0].id // empty')

    if [[ -z "$PARENT_ID" ]]; then
      echo -e "${YELLOW}Folder not found. Creating${NC} ${BOLD}'$DEST_INPUT'${NC}..."
      CREATE_RESULT=$(curl -s -X POST -H "Authorization: Bearer $ACCESS_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"name\": \"$DEST_INPUT\", \"mimeType\": \"application/vnd.google-apps.folder\"}" \
        https://www.googleapis.com/drive/v3/files)
      
      PARENT_ID=$(echo "$CREATE_RESULT" | jq -r '.id // empty')
      
      if [[ -z "$PARENT_ID" ]]; then
        echo -e "${RED}Failed to create folder!${NC}"
        echo "$CREATE_RESULT" | jq . 2>/dev/null || echo "$CREATE_RESULT"
        exit 1
      fi
      echo -e "${GREEN}✓ Created folder${NC} (ID: $PARENT_ID)"
    else
      echo -e "${GREEN}✓ Found folder${NC} (ID: $PARENT_ID)"
    fi
  fi
fi

# ==================== HELPER FUNCTIONS ====================
# ==================== HELPER FUNCTIONS ====================

# Upload file with spinner and percentage
upload_with_progress() {
  local file_path="$1"
  local file_name="$2"
  local parent_id="$3"
  local mime_type="$4"
  local label="$5"
  
  # Check if file exists
  if [[ ! -f "$file_path" ]]; then
    echo -e "   ${RED}✗ File not found: $file_path${NC}"
    if [[ $DEBUG -eq 1 ]]; then
      echo -e "   ${DIM}PWD: $(pwd)${NC}"
      echo -e "   ${DIM}File check failed: test -f '$file_path'${NC}"
    fi
    return 1
  fi
  
  local file_size=$(stat -f%z "$file_path" 2>/dev/null || stat -c%s "$file_path" 2>/dev/null || echo "0")
  local file_size_mb=$(echo "scale=2; $file_size / 1048576" | bc 2>/dev/null || echo "?")
  
  UPLOAD_TMP="/tmp/upload_result_$$"
  
  # Debug output
  if [[ $DEBUG -eq 1 ]]; then
    echo -e "   ${DIM}Uploading: $file_path${NC}"
    echo -e "   ${DIM}Name: $file_name, Size: $file_size_mb MB${NC}"
    echo -e "   ${DIM}Mime: $mime_type, Parent: $parent_id${NC}"
  fi
  
  PROGRESS_FILE="/tmp/upload_progress_$$"
  
  # Start upload in background with progress bar
  curl -X POST -H "Authorization: Bearer $ACCESS_TOKEN" \
    -F "metadata={\"name\":\"$file_name\",\"parents\":[\"$parent_id\"]};type=application/json" \
    -F "file=@\"$file_path\";type=$mime_type" \
    "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart" \
    -o "$UPLOAD_TMP" \
    --progress-bar 2>"$PROGRESS_FILE" &
  
  local upload_pid=$!
  
  # Show spinner with REAL percentage from curl
  local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  local i=0
  local last_percent=0
  
  while kill -0 $upload_pid 2>/dev/null; do
    # Parse actual progress from curl's output
    if [[ -f "$PROGRESS_FILE" ]]; then
      # Progress bar format: "######## 45.2%" with \r characters
      # tail -c gets last 200 bytes, tr converts \r to \n, grep extracts percentage
      percent=$(tail -c 200 "$PROGRESS_FILE" 2>/dev/null | tr '\r' '\n' | tail -1 | grep -oE '[0-9]+\.[0-9]+%' | grep -oE '^[0-9]+' | head -1)
      if [[ -n "$percent" ]] && [[ "$percent" =~ ^[0-9]+$ ]] && [[ $percent -le 100 ]]; then
        last_percent=$percent
      fi
    fi
    
    printf "\r   ${YELLOW}⬆  ${label} ${file_size_mb}MB...${NC} ${BOLD}%3d%%${NC} ${CYAN}%s${NC}" "$last_percent" "${spin:$i:1}"
    i=$(( (i+1) % ${#spin} ))
    sleep 0.5
  done
  
  # Wait for upload to finish and capture exit code
  wait $upload_pid
  local upload_exit=$?
  
  # Read result
  if [[ -f "$UPLOAD_TMP" ]]; then
    UPLOAD_RESULT=$(cat "$UPLOAD_TMP")
  else
    UPLOAD_RESULT="{}"
  fi
  
  # Check if successful
  if [[ $upload_exit -eq 0 ]] && echo "$UPLOAD_RESULT" | jq -e '.id' >/dev/null 2>&1; then
    printf "\r   ${GREEN}✓ Uploaded ${file_size_mb}MB          ${NC}\n"
    rm -f "$UPLOAD_TMP" "$PROGRESS_FILE" /tmp/curl_err_$$
    return 0
  else
    printf "\r   ${RED}✗ Upload failed            ${NC}\n"
    local error_msg=$(echo "$UPLOAD_RESULT" | jq -r '.error.message // empty' 2>/dev/null)
    if [[ -n "$error_msg" ]]; then
      echo -e "   ${DIM}API Error: $error_msg${NC}"
    fi
    if [[ $upload_exit -ne 0 ]]; then
      echo -e "   ${DIM}Curl exit code: $upload_exit${NC}"
      if [[ -f /tmp/curl_err_$$ ]]; then
        local curl_err=$(cat /tmp/curl_err_$$ 2>/dev/null)
        if [[ -n "$curl_err" ]]; then
          echo -e "   ${DIM}Curl error: ${curl_err:0:200}${NC}"
        fi
      fi
    fi
    if [[ $DEBUG -eq 1 ]]; then
      echo -e "   ${DIM}Response: ${UPLOAD_RESULT:0:500}${NC}"
    fi
    rm -f "$UPLOAD_TMP" "$PROGRESS_FILE" /tmp/curl_err_$$
    return 1
  fi
}

check_duplicate() {
  local filename="$1"
  local parent_id="$2"
  
  if [[ $DEBUG -eq 1 ]]; then
    echo -e "   ${DIM}→ Checking for duplicate: $filename in $parent_id${NC}"
  fi
  
  # Escape single quotes in filename for query
  local escaped_name="${filename//\'/\\\'}"
  
  # Build query and URL-encode it
  local query="name='$escaped_name' and '$parent_id' in parents and trashed=false"
  local encoded_query=$(echo "$query" | jq -sRr @uri)
  
  if [[ $DEBUG -eq 1 ]]; then
    echo -e "   ${DIM}→ Query: $query${NC}"
  fi
  
  # Add timeout
  local file_id=$(curl -s --max-time 10 -H "Authorization: Bearer $ACCESS_TOKEN" \
    "https://www.googleapis.com/drive/v3/files?q=${encoded_query}&fields=files(id)" \
    2>/dev/null | jq -r '.files[0].id // empty' 2>/dev/null)
  
  if [[ -n "$file_id" ]]; then
    if [[ $DEBUG -eq 1 ]]; then
      echo -e "   ${DIM}→ Duplicate found: $file_id${NC}"
    fi
    return 0  # duplicate exists
  else
    if [[ $DEBUG -eq 1 ]]; then
      echo -e "   ${DIM}→ No duplicate found${NC}"
    fi
    return 1  # no duplicate
  fi
}

get_music_metadata() {
  local file="$1"
  
  if ! command -v ffprobe &> /dev/null; then
    echo "Unknown Artist|Unknown Album|Unknown Title|"
    return
  fi
  
  local artist=$(ffprobe -v quiet -show_entries format_tags=artist -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null | head -1)
  local album=$(ffprobe -v quiet -show_entries format_tags=album -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null | head -1)
  local title=$(ffprobe -v quiet -show_entries format_tags=title -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null | head -1)
  local year=$(ffprobe -v quiet -show_entries format_tags=date -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null | head -1 | grep -oE '[0-9]{4}' | head -1)
  
  # Clean up website tags and weird formatting
  artist=$(echo "$artist" | sed -E 's/\s*[\(\|]?\s*(HipHopKit\.com|Audiomack\.com|SoundCloud|Spotify|YouTube|[A-Za-z0-9]+\.(com|net|org))[^\)]*[\)]?//gi' | sed 's/[[:space:]]*$//')
  album=$(echo "$album" | sed -E 's/\s*[\(\|]?\s*(HipHopKit\.com|Audiomack\.com|SoundCloud|Spotify|YouTube|[A-Za-z0-9]+\.(com|net|org))[^\)]*[\)]?//gi' | sed 's/[[:space:]]*$//')
  title=$(echo "$title" | sed -E 's/\s*[\(\|]?\s*(HipHopKit\.com|Audiomack\.com|SoundCloud|Spotify|YouTube|[A-Za-z0-9]+\.(com|net|org))[^\)]*[\)]?//gi' | sed 's/[[:space:]]*$//')
  
  artist="${artist:-Unknown Artist}"
  album="${album:-Unknown Album}"
  title="${title:-Unknown Title}"
  year="${year:-}"
  
  echo "$artist|$album|$title|$year"
}

extract_cover_art() {
  local audio_file="$1"
  local output_dir="$2"
  
  if ! command -v ffmpeg &> /dev/null; then
    return 1
  fi
  
  local cover_file="$output_dir/cover.jpg"
  
  if ffmpeg -y -i "$audio_file" -an -vcodec copy "$cover_file" &>/dev/null; then
    if [[ -f "$cover_file" ]] && [[ -s "$cover_file" ]]; then
      echo "$cover_file"
      return 0
    fi
  fi
  
  rm -f "$cover_file" 2>/dev/null
  return 1
}

ensure_folder() {
  local folder_name="$1"
  local parent_id="$2"
  
  # Escape single quotes in folder name
  local escaped_name="${folder_name//\'/\\\'}"
  
  # Build query with proper escaping
  local query="name='$escaped_name' and '$parent_id' in parents and mimeType='application/vnd.google-apps.folder' and trashed=false"
  
  # Add timeout to avoid hanging - use URI encoding for query
  local folder_id=$(curl -s --max-time 10 -H "Authorization: Bearer $ACCESS_TOKEN" \
    "https://www.googleapis.com/drive/v3/files?q=$(echo "$query" | jq -sRr @uri)&fields=files(id)" \
    2>/dev/null | jq -r '.files[0].id // empty' 2>/dev/null)
  
  if [[ -z "$folder_id" ]]; then
    folder_id=$(curl -s --max-time 15 -X POST -H "Authorization: Bearer $ACCESS_TOKEN" \
      -H "Content-Type: application/json" \
      -d "{\"name\": \"$folder_name\", \"mimeType\": \"application/vnd.google-apps.folder\", \"parents\": [\"$parent_id\"]}" \
      https://www.googleapis.com/drive/v3/files 2>/dev/null | jq -r '.id // empty' 2>/dev/null)
  fi
  
  echo "$folder_id"
}

check_album_folder_exists() {
  local folder_name="$1"
  local parent_id="$2"
  
  # Escape single quotes in folder name for API query
  local escaped_name="${folder_name//\'/\\\'}"
  
  # Add timeout and error handling - also add debug output
  local query="name='$escaped_name' and '$parent_id' in parents and mimeType='application/vnd.google-apps.folder' and trashed=false"
  
  local response=$(curl -s --max-time 10 -H "Authorization: Bearer $ACCESS_TOKEN" \
    "https://www.googleapis.com/drive/v3/files?q=$(echo "$query" | jq -sRr @uri)&fields=files(id,name)" \
    2>/dev/null)
  
  local folder_id=$(echo "$response" | jq -r '.files[0].id // empty' 2>/dev/null)
  
  # Debug output
  if [[ -n "$DEBUG_API" ]]; then
    echo "DEBUG: Query: $query" >&2
    echo "DEBUG: Response: $response" >&2
    echo "DEBUG: Found ID: $folder_id" >&2
  fi
  
  if [[ -n "$folder_id" ]]; then
    echo "$folder_id"
    return 0  # Exists
  else
    return 1  # Does not exist
  fi
}

# ==================== PROCESS EACH URL ====================
CURRENT=0
TOTAL=${#URLS[@]}

for URL in "${URLS[@]}"; do
  [[ -z "$URL" ]] && continue
  
  CURRENT=$((CURRENT + 1))
  
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${MAGENTA}[$CURRENT/$TOTAL]${NC} ${CYAN}Processing:${NC} ${DIM}$URL${NC}"
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

  
  FILENAME=$(basename "$URL" | sed 's/[?#].*//')
  TEMP_FILE="/tmp/${FILENAME}_$$"
  EXTRACT_DIR="/tmp/extract_$$"
  
  mkdir -p "$EXTRACT_DIR"
  
  # ==================== TELEGRAM DETECTION ====================
  IS_TELEGRAM=0
  if [[ "$URL" =~ ^https?://(t\.me|telegram\.me|telegram\.dog)/ ]]; then
    IS_TELEGRAM=1
    echo -e "${MAGENTA}📱 Telegram link detected${NC}"
    
    # Check for Telethon downloader
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    TELEGRAM_DOWNLOADER="$SCRIPT_DIR/telegram_downloader.py"
    
    if [[ ! -f "$TELEGRAM_DOWNLOADER" ]]; then
      echo -e "${RED}✗ Telegram downloader not found: $TELEGRAM_DOWNLOADER${NC}"
      continue
    fi
    
    if ! command -v python3 &> /dev/null; then
      echo -e "${RED}✗ Python 3 is required for Telegram downloads${NC}"
      continue
    fi
    
    # Check if Telethon is installed
    if ! python3 -c "import telethon" 2>/dev/null; then
      echo -e "${RED}✗ Telethon library required for Telegram downloads${NC}"
      echo -e "${YELLOW}  Install: ${BOLD}pip install telethon${NC}"
      echo -e "${DIM}  See: https://docs.telethon.dev/en/stable/basic/installation.html${NC}"
      continue
    fi
    
    # Check for API credentials
    if [[ -z "$TELEGRAM_API_ID" ]] || [[ -z "$TELEGRAM_API_HASH" ]]; then
      echo -e "${RED}✗ Telegram API credentials required${NC}"
      echo -e "${YELLOW}  Set environment variables:${NC}"
      echo -e "${DIM}  export TELEGRAM_API_ID='your_api_id'${NC}"
      echo -e "${DIM}  export TELEGRAM_API_HASH='your_api_hash'${NC}"
      echo -e "${DIM}  Get them from: https://my.telegram.org${NC}"
      continue
    fi
  fi
  
  echo -e "${YELLOW}⬇${NC}  ${BOLD}Downloading${NC} $FILENAME..."
  if [[ $DEBUG -eq 1 ]]; then
    if [[ $IS_TELEGRAM -eq 1 ]]; then
      echo -e "${DIM}python3 telegram_downloader.py '$URL' '$EXTRACT_DIR'${NC}"
    else
      echo -e "${DIM}curl -L -o '$TEMP_FILE' '$URL'${NC}"
    fi
    touch "$TEMP_FILE"
  else
    if [[ $IS_TELEGRAM -eq 1 ]]; then
      # Use Telethon downloader
      TG_TEMP_DIR="/tmp/tg_download_$$"
      mkdir -p "$TG_TEMP_DIR"
      
      # Run Python downloader with live output
      TG_OUTPUT_FILE="/tmp/tg_output_$$"
      python3 "$TELEGRAM_DOWNLOADER" "$URL" "$TG_TEMP_DIR" 2>&1 | tee "$TG_OUTPUT_FILE"
      download_exit=${PIPESTATUS[0]}
      
      if [[ $download_exit -eq 0 ]]; then
        # Extract filename from output
        download_output=$(cat "$TG_OUTPUT_FILE")
        if [[ "$download_output" =~ FILENAME:(.+)$ ]]; then
          downloaded_filename="${BASH_REMATCH[1]}"
          downloaded_file="$TG_TEMP_DIR/$downloaded_filename"
          
          if [[ -f "$downloaded_file" ]]; then
            mv "$downloaded_file" "$TEMP_FILE"
            FILENAME="$downloaded_filename"
          else
            echo -e "${RED}✗ Downloaded file not found${NC}"
            rm -rf "$TG_TEMP_DIR" "$TG_OUTPUT_FILE"
            continue
          fi
        else
          echo -e "${RED}✗ Could not determine downloaded filename${NC}"
          rm -rf "$TG_TEMP_DIR" "$TG_OUTPUT_FILE"
          continue
        fi
      else
        echo -e "${RED}✗ Download failed${NC}"
        download_output=$(cat "$TG_OUTPUT_FILE")
        echo "$download_output" | grep -E "(ERROR|error)" | sed 's/^/  /'
        echo -e "${YELLOW}Make sure you have:${NC}"
        echo -e "  ${DIM}1. TELEGRAM_API_ID and TELEGRAM_API_HASH set${NC}"
        echo -e "  ${DIM}2. Authenticated (first run will prompt for phone/code)${NC}"
        echo -e "  ${DIM}3. Access to the channel/message${NC}"
        rm -rf "$TG_TEMP_DIR" "$TG_OUTPUT_FILE"
        continue
      fi
      
      rm -rf "$TG_TEMP_DIR" "$TG_OUTPUT_FILE"
    else
      # Regular curl download with live progress bar using ASCII characters
      curl -L --progress-bar -o "$TEMP_FILE" "$URL" 2>&1 | \
      stdbuf -oL tr '\r' '\n' | \
      stdbuf -oL grep --line-buffered -oP '\d+(?=\.\d)' | \
      while IFS= read -r percent; do
        if [[ -n "$percent" ]] && [[ "$percent" =~ ^[0-9]+$ ]] && [[ $percent -le 100 ]]; then
          bar_len=$((percent / 2))
          filled=$(printf "%-${bar_len}s" | tr ' ' '=')
          empty=$(printf "%-$((50 - bar_len))s" | tr ' ' '-')
          printf "\r${CYAN}⬇${NC}  [${GREEN}%s${DIM}%s${NC}] ${BOLD}%3d%%${NC}" "$filled" "$empty" "$percent"
        fi
      done
      echo ""
    fi
    
    if [[ ! -f "$TEMP_FILE" ]] || [[ ! -s "$TEMP_FILE" ]]; then
      echo -e "${RED}✗ Download failed${NC}"
      continue
    fi
    echo -e "${GREEN}✓ Download complete${NC}"
  fi
  
  # ==================== MD5 CHECKSUM ====================
  if command -v md5sum &> /dev/null; then
    MD5=$(md5sum "$TEMP_FILE" | awk '{print $1}')
    echo -e "${BLUE}🔐 MD5:${NC} ${DIM}$MD5${NC}"
  fi

  
  # ==================== FILE TYPE DETECTION ====================
  FILE_TYPE=$(file -b --mime-type "$TEMP_FILE" 2>/dev/null || echo "unknown")

  
  # ==================== EXTRACT / PREPARE FILES ====================
  IS_EXTRACTED_ZIP=0
  ZIP_FOLDER_NAME=""
  
  if [[ "$FILE_TYPE" == "application/zip" ]]; then
    echo -e "${YELLOW}📦 ZIP detected${NC}"
    
    # Prompt user for extraction
    echo -ne "${CYAN}Extract and upload files? (y/n):${NC} "
    read -r extract_choice < /dev/tty
    
    if [[ "$extract_choice" =~ ^[Yy]$ ]]; then
      echo -e "${YELLOW}Extracting...${NC}"
      if unzip -q "$TEMP_FILE" -d "$EXTRACT_DIR" 2>/dev/null; then
        FILES_DIR="$EXTRACT_DIR"
        IS_EXTRACTED_ZIP=1
        # Get ZIP name without extension for folder name
        ZIP_FOLDER_NAME="${FILENAME%.zip}"
        echo -e "${GREEN}✓ Extracted${NC}"
      else
        echo -e "${YELLOW}⚠ Unzip failed, uploading ZIP as-is${NC}"
        FILES_DIR="/tmp/single_$$"
        mkdir -p "$FILES_DIR"
        cp "$TEMP_FILE" "$FILES_DIR/$FILENAME"
      fi
    else
      echo -e "${CYAN}Uploading ZIP file as-is${NC}"
      FILES_DIR="/tmp/single_$$"
      mkdir -p "$FILES_DIR"
      cp "$TEMP_FILE" "$FILES_DIR/$FILENAME"
    fi
  else
    echo -e "${BLUE}📄 Single file${NC}"
    FILES_DIR="/tmp/single_$$"
    mkdir -p "$FILES_DIR"
    cp "$TEMP_FILE" "$FILES_DIR/$FILENAME"
  fi

  
  # ==================== ORGANIZE & UPLOAD ====================
  echo -e "${CYAN}Organizing and uploading files...${NC}"
  declare -A TYPES=(
    [image]="Images"
    [audio]="Music"
    [video]="Videos"
    [text]="Docs"
    [application/pdf]="Docs"
  )
  
  # Group music files by album for cover art extraction
  declare -A ALBUM_TRACKS
  declare -A ALBUM_COVERS
  
  # First pass: identify all files and extract covers for music
  while IFS= read -r file; do
    [[ ! -f "$file" ]] && continue
    
    mime=$(file -b --mime-type "$file" 2>/dev/null || echo "application/octet-stream")
    category="${TYPES[${mime%%/*}]:-Others}"
    
    if [[ "$category" == "Music" ]]; then
      IFS='|' read -r artist album title year <<< "$(get_music_metadata "$file")"
      
      if [[ -n "$year" ]]; then
        album_key="$artist/$album ($year)"
      else
        album_key="$artist/$album"
      fi
      
      ALBUM_TRACKS["$album_key"]+="$file"$'\n'
      
      # Try to extract cover art (only once per album)
      if [[ -z "${ALBUM_COVERS[$album_key]}" ]]; then
        cover_dir="/tmp/covers_$$"
        mkdir -p "$cover_dir"
        if cover_path=$(extract_cover_art "$file" "$cover_dir"); then
          ALBUM_COVERS["$album_key"]="$cover_path"
        fi
      fi
    fi
  done < <(find "$FILES_DIR" -type f 2>/dev/null)
  
  # Second pass: upload files with proper organization
  while IFS= read -r file; do
    [[ ! -f "$file" ]] && continue
    
    mime=$(file -b --mime-type "$file" 2>/dev/null || echo "application/octet-stream")
    category="${TYPES[${mime%%/*}]:-Others}"
    BASENAME=$(basename "$file")
    
    if [[ "$category" == "Music" ]]; then
      # Parse metadata
      IFS='|' read -r artist album title year <<< "$(get_music_metadata "$file")"
      
      # Skip if no artist
      [[ -z "$artist" ]] && { echo -e "${YELLOW}⚠ No artist metadata, skipping music organization for $BASENAME${NC}"; category="Others"; }
      
      if [[ "$category" == "Music" ]]; then
        echo -e "${MAGENTA}📀 ${BOLD}$artist${NC} ${DIM}-${NC} ${CYAN}${album:-No Album}${year:+ ($year)}${NC} ${DIM}-${NC} $title"
        
        # Create folder structure: Music -> Artist -> Album (Year) OR just Artist if no album
        MUSIC_ID=$(ensure_folder "Music" "$PARENT_ID")
        [[ -z "$MUSIC_ID" ]] && { echo -e "   ${RED}✗ Failed to create Music folder${NC}"; continue; }
        
        ARTIST_ID=$(ensure_folder "$artist" "$MUSIC_ID")
        [[ -z "$ARTIST_ID" ]] && { echo -e "   ${RED}✗ Failed to create Artist folder${NC}"; continue; }
        
        # If album exists, check for existing album folder and prompt
        if [[ -n "$album" ]] && [[ "$album" != "Unknown Album" ]]; then
          if [[ -n "$year" ]]; then
            album_folder="$album ($year)"
          else
            album_folder="$album"
          fi
          
          # Check if album folder already exists
          echo -e "   ${DIM}Checking for existing album: $album_folder...${NC}"
          
          # Try to check for existing folder (with timeout)
          existing_album_id=$(check_album_folder_exists "$album_folder" "$ARTIST_ID" 2>/dev/null)
          check_result=$?
          
          if [[ $check_result -eq 0 ]] && [[ -n "$existing_album_id" ]]; then
            echo -e "   ${YELLOW}⚠ Album folder ${CYAN}\"$album_folder\"${YELLOW} already exists${NC}"
            echo -ne "   ${CYAN}Upload to existing folder? ${DIM}[Y/n]:${NC} "
            read -r upload_choice < /dev/tty
            upload_choice="${upload_choice:-y}"  # Default to yes
            
            if [[ "$upload_choice" =~ ^[Yy]$ ]] || [[ -z "$upload_choice" ]]; then
              UPLOAD_PARENT_ID="$existing_album_id"
              echo -e "   ${GREEN}→ Using existing album folder${NC}"
            else
              # User declined: upload to Music root, no nesting
              UPLOAD_PARENT_ID="$MUSIC_ID"
              echo -e "   ${YELLOW}→ Uploading to Music root (un-nested)${NC}"
              # Skip cover art for un-nested
              album=""  # Clear album to prevent cover upload later
            fi
          else
            # Album folder doesn't exist or check failed, create it
            echo -e "   ${DIM}Creating new album folder...${NC}"
            UPLOAD_PARENT_ID=$(ensure_folder "$album_folder" "$ARTIST_ID")
            [[ -z "$UPLOAD_PARENT_ID" ]] && { echo -e "   ${RED}✗ Failed to create Album folder${NC}"; continue; }
          fi
        else
          # No album or Unknown Album: upload directly to artist folder, no cover art
          UPLOAD_PARENT_ID="$ARTIST_ID"
        fi
        
        # Check for duplicates
        if [[ $DEBUG -eq 1 ]]; then
          echo -e "   ${DIM}→ Checking duplicate for: '$BASENAME' in folder: $UPLOAD_PARENT_ID${NC}"
        fi
        
        if check_duplicate "$BASENAME" "$UPLOAD_PARENT_ID"; then
          echo -e "   ${YELLOW}⊘ Already exists, skipping${NC}"
          continue
        fi
        
        # Verify file exists before upload
        if [[ ! -f "$file" ]]; then
          echo -e "   ${RED}✗ File disappeared: $file${NC}"
          if [[ $DEBUG -eq 1 ]]; then
            echo -e "   ${DIM}Expected file: $file${NC}"
            echo -e "   ${DIM}FILES_DIR contents:${NC}"
            ls -la "$FILES_DIR" | head -10
          fi
          continue
        fi
        
        # Upload the music file with progress
        if [[ $DEBUG -eq 1 ]]; then
          echo -e "   ${DIM}→ Would upload $BASENAME from $file${NC}"
        else
          upload_with_progress "$file" "$BASENAME" "$UPLOAD_PARENT_ID" "$mime" "Uploading"
        fi
        
        # Upload cover art (only if album exists and only once per album)
        if [[ -n "$album" ]]; then
          if [[ -n "$year" ]]; then
            album_key="$artist/$album ($year)"
          else
            album_key="$artist/$album"
          fi
          
          cover_path="${ALBUM_COVERS[$album_key]}"
          if [[ -n "$cover_path" ]] && [[ -f "$cover_path" ]]; then
            if check_duplicate "cover.jpg" "$UPLOAD_PARENT_ID"; then
              echo -e "   ${YELLOW}⊘ Cover art (already exists)${NC}"
            else
              if [[ $DEBUG -eq 1 ]]; then
                echo -e "   ${DIM}→ Would upload cover.jpg${NC}"
              else
                cover_size=$(stat -f%z "$cover_path" 2>/dev/null || stat -c%s "$cover_path" 2>/dev/null)
                cover_size_mb=$(awk "BEGIN {printf \"%.2f\", $cover_size/1024/1024}")
                
                upload_with_progress "$cover_path" "cover.jpg" "$UPLOAD_PARENT_ID" "image/jpeg" "${cover_size_mb}MB" "   🖼 "
              fi
            fi
            # Remove cover after uploading (prevent duplicates)
            unset ALBUM_COVERS["$album_key"]
          fi
        fi
      fi
    fi
    
    if [[ "$category" != "Music" ]]; then
      # Non-music files
      if [[ $IS_EXTRACTED_ZIP -eq 1 ]]; then
        # Extracted ZIP files go to Folders/zipname/
        FOLDERS_ID=$(ensure_folder "Folders" "$PARENT_ID")
        [[ -z "$FOLDERS_ID" ]] && { echo -e "${RED}Failed to create Folders category${NC}"; continue; }
        
        ZIP_SUB_ID=$(ensure_folder "$ZIP_FOLDER_NAME" "$FOLDERS_ID")
        [[ -z "$ZIP_SUB_ID" ]] && { echo -e "${RED}Failed to create $ZIP_FOLDER_NAME folder${NC}"; continue; }
        
        SUB_ID="$ZIP_SUB_ID"
      else
        # Regular files: use simple category organization
        SUB_ID=$(ensure_folder "$category" "$PARENT_ID")
        [[ -z "$SUB_ID" ]] && { echo -e "${RED}Failed to create $category folder${NC}"; continue; }
      fi
      
      if check_duplicate "$BASENAME" "$SUB_ID"; then
        echo -e "${YELLOW}⊘ Skipping $BASENAME (already exists)${NC}"
        continue
      fi
      
      if [[ $DEBUG -eq 1 ]]; then
        echo -e "${BLUE}📎 $BASENAME${NC} ${DIM}Would upload to $category${NC}"
      else
        file_size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
        file_size_mb=$(awk "BEGIN {printf \"%.2f\", $file_size/1024/1024}")
        
        upload_with_progress "$file" "$BASENAME" "$SUB_ID" "$mime" "${file_size_mb}MB" "📎 "
      fi
    fi
  done < <(find "$FILES_DIR" -type f 2>/dev/null)
  
  # ==================== CLEANUP ====================
  rm -rf "$TEMP_FILE" "$EXTRACT_DIR" "$FILES_DIR" /tmp/covers_$$ 2>/dev/null
  
done

echo ""
echo -e "${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}${GREEN}✓ Done!${NC} Files uploaded to GDrive: ${BOLD}$DEST_INPUT${NC}"
echo -e "${CYAN}🔗 Check: ${BLUE}https://drive.google.com/drive/folders/$PARENT_ID${NC}"
echo -e "${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

