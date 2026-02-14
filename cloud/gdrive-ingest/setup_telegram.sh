#!/bin/bash
# Quick setup helper for Telegram support

echo "🔧 Telegram Support Setup Helper"
echo "================================"
echo ""

# Check Python
if ! command -v python3 &> /dev/null; then
  echo "❌ Python 3 not found"
  echo "   Install: sudo apt install python3 (Debian/Ubuntu)"
  echo "           brew install python3 (macOS)"
  exit 1
else
  echo "✅ Python 3: $(python3 --version)"
fi

# Check pip
if ! command -v pip3 &> /dev/null; then
  echo "❌ pip3 not found"
  echo "   Install: sudo apt install python3-pip"
  exit 1
else
  echo "✅ pip3: $(pip3 --version | head -1)"
fi

# Check Telethon
if python3 -c "import telethon" 2>/dev/null; then
  VERSION=$(python3 -c "import telethon; print(telethon.__version__)" 2>/dev/null)
  echo "✅ Telethon: $VERSION"
else
  echo "❌ Telethon not installed"
  echo ""
  read -p "Install Telethon now? [Y/n]: " install
  if [[ "$install" != "n" && "$install" != "N" ]]; then
    echo "Installing Telethon..."
    pip3 install telethon
    if [ $? -eq 0 ]; then
      echo "✅ Telethon installed successfully"
    else
      echo "❌ Installation failed"
      exit 1
    fi
  else
    echo "Skipping installation"
  fi
fi

echo ""
echo "🔑 API Credentials Check"
echo "========================"

# Check environment variables
if [[ -n "$TELEGRAM_API_ID" ]]; then
  echo "✅ TELEGRAM_API_ID is set"
else
  echo "❌ TELEGRAM_API_ID not set"
  echo ""
  echo "To get API credentials:"
  echo "1. Visit https://my.telegram.org"
  echo "2. Log in with your phone number"
  echo "3. Go to 'API development tools'"
  echo "4. Create an application"
  echo "5. Copy api_id and api_hash"
  echo ""
  read -p "Enter your API ID (or press Enter to skip): " api_id
  if [[ -n "$api_id" ]]; then
    export TELEGRAM_API_ID="$api_id"
    echo "export TELEGRAM_API_ID='$api_id'" >> ~/.bashrc
    echo "✅ Added to current session and ~/.bashrc"
  fi
fi

if [[ -n "$TELEGRAM_API_HASH" ]]; then
  echo "✅ TELEGRAM_API_HASH is set"
else
  echo "❌ TELEGRAM_API_HASH not set"
  echo ""
  read -p "Enter your API HASH (or press Enter to skip): " api_hash
  if [[ -n "$api_hash" ]]; then
    export TELEGRAM_API_HASH="$api_hash"
    echo "export TELEGRAM_API_HASH='$api_hash'" >> ~/.bashrc
    echo "✅ Added to current session and ~/.bashrc"
  fi
fi

echo ""
echo "📋 Summary"
echo "=========="

if [[ -n "$TELEGRAM_API_ID" && -n "$TELEGRAM_API_HASH" ]]; then
  echo "✅ Telegram support is ready!"
  echo ""
  echo "Next steps:"
  echo "1. Run: source ~/.bashrc"
  echo "2. Test: ./gdrive_ingest.sh https://t.me/channelname/123"
  echo "3. First run will prompt for phone number + code"
  echo ""
  echo "📖 Full guide: docs/TELEGRAM_SETUP.md"
else
  echo "⚠️  Setup incomplete"
  echo ""
  echo "Manual setup:"
  echo "1. Get credentials: https://my.telegram.org"
  echo "2. Add to ~/.bashrc:"
  echo "   export TELEGRAM_API_ID='your_api_id'"
  echo "   export TELEGRAM_API_HASH='your_api_hash'"
  echo "3. Run: source ~/.bashrc"
  echo ""
  echo "📖 See: docs/TELEGRAM_SETUP.md"
fi
