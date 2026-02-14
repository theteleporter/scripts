#!/usr/bin/env python3
"""
Telegram downloader using Telethon
Downloads files from Telegram channels (public and private)
"""
import sys
import os
import asyncio
from pathlib import Path
from telethon import TelegramClient
from telethon.tl.types import MessageMediaDocument, MessageMediaPhoto
import re

# Telegram API credentials (get from https://my.telegram.org)
API_ID = os.getenv('TELEGRAM_API_ID')
API_HASH = os.getenv('TELEGRAM_API_HASH')
SESSION_DIR = os.path.expanduser('~/.config/gdrive-ingest/telegram')

def parse_telegram_url(url):
    """Parse Telegram URL to extract channel and message ID"""
    # Patterns: t.me/channel/123 or t.me/c/123456789/456
    match = re.match(r'https?://t\.me/(?:c/)?([^/]+)/(\d+)', url)
    if match:
        return match.group(1), int(match.group(2))
    return None, None

async def download_from_telegram(url, output_dir):
    """Download file from Telegram URL"""
    if not API_ID or not API_HASH:
        print("ERROR: TELEGRAM_API_ID and TELEGRAM_API_HASH environment variables required", file=sys.stderr)
        print("Get them from https://my.telegram.org", file=sys.stderr)
        return None
    
    # Ensure session directory exists
    Path(SESSION_DIR).mkdir(parents=True, exist_ok=True)
    session_file = os.path.join(SESSION_DIR, 'downloader')
    
    # Parse URL
    channel, msg_id = parse_telegram_url(url)
    if not channel or not msg_id:
        print(f"ERROR: Invalid Telegram URL: {url}", file=sys.stderr)
        return None
    
    try:
        # Create client
        client = TelegramClient(session_file, API_ID, API_HASH)
        await client.start()
        
        # Get message
        message = await client.get_messages(channel, ids=msg_id)
        if not message:
            print(f"ERROR: Message not found: {url}", file=sys.stderr)
            await client.disconnect()
            return None
        
        # Check if message has media
        if not message.media:
            print(f"ERROR: No media in message: {url}", file=sys.stderr)
            await client.disconnect()
            return None
        
        # Download with progress
        filename = None
        
        def progress_callback(current, total):
            percent = int((current / total) * 100)
            bar_length = 50
            filled = int(bar_length * current / total)
            # Colors: CYAN for arrow, GREEN for filled, DIM for empty, BOLD for percent
            filled_bar = '\033[0;32m' + '=' * filled + '\033[0m'  # GREEN
            empty_bar = '\033[2m' + '-' * (bar_length - filled) + '\033[0m'  # DIM
            print(f"\r\033[0;36m⬇\033[0m  [{filled_bar}{empty_bar}] \033[1m{percent:3d}%\033[0m", end='', flush=True)
        
        print(f"\033[0;36m⬇\033[0m  Downloading from Telegram...", flush=True)
        
        # Download file
        output_path = Path(output_dir)
        downloaded = await client.download_media(
            message,
            file=output_path,
            progress_callback=progress_callback
        )
        
        print()  # New line after progress
        
        if downloaded:
            # Get actual filename
            filename = os.path.basename(downloaded)
            print(f"\033[0;32m✓ Downloaded:\033[0m {filename}")
            await client.disconnect()
            return filename
        else:
            print("ERROR: Download failed", file=sys.stderr)
            await client.disconnect()
            return None
            
    except Exception as e:
        print(f"ERROR: {str(e)}", file=sys.stderr)
        return None

def main():
    if len(sys.argv) < 3:
        print("Usage: telegram_downloader.py <url> <output_dir>", file=sys.stderr)
        sys.exit(1)
    
    url = sys.argv[1]
    output_dir = sys.argv[2]
    
    # Run async download
    filename = asyncio.run(download_from_telegram(url, output_dir))
    
    if filename:
        # Print filename for script to capture
        print(f"FILENAME:{filename}")
        sys.exit(0)
    else:
        sys.exit(1)

if __name__ == '__main__':
    main()
