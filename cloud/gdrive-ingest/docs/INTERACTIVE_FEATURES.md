# 🎨 Interactive Features - GDrive Ingest Script

## 🎯 New Interactive UI

### 📁 Folder Selection with Arrow Keys

When you run the script **without** `--folder` flag, you get an interactive folder browser:

```
╔═══════════════════════════════════════════════════════╗
║  📁 Select Destination Folder                         ║
╠═══════════════════════════════════════════════════════╣
║  ↑/↓: Navigate  →: Open  ←: Back  Enter: Select      ║
╚═══════════════════════════════════════════════════════╝

  ▶ ● Create new folder
  ○ Music
  ○ Images
  ○ bckups
  ○ Videos
  ○ Documents
```

**Controls:**
- **↑/↓** - Navigate up/down through folders
- **→** - Open selected folder (navigate into nested folders)
- **←** - Go back to parent folder
- **Enter** - Select highlighted folder
- **q** - Quit/cancel

**Visual Indicators:**
- `▶` - Currently selected (highlighted)
- `○` - Not selected (empty circle)
- `●` - Action items (create, select current)
- `◂` - Back option

### 🎬 Live Progress Bars

#### Download Progress
```
⬇  [████████████████████░░░░░░░░░░░░░░] 65%
✓ Download complete
```

#### Upload Progress with Spinner
```
   ⬆  Uploading 8.52MB... ⠸
   ✓ Uploaded 8.52MB
   
   🖼  Cover art... ⠇
   ✓ Cover art uploaded
```

**Spinner Characters:**
`⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏` (Braille pattern dots)

### 🌈 Color-Coded Output

- 🔴 **Red** - Errors, failures
- 🟢 **Green** - Success, checkmarks
- 🟡 **Yellow** - Warnings, downloads
- 🔵 **Blue** - Info, metadata
- 🟣 **Magenta** - Headers, music info
- 🔷 **Cyan** - Progress, actions
- **Bold** - Important text
- **Dim** - Secondary info

## 🎮 Usage Modes

### Interactive Mode (No --folder flag)
```bash
./gdrive_ingest.sh https://example.com/song.mp3
```
Opens interactive folder browser with arrow key navigation.

### Command-Line Mode (With --folder flag)
```bash
./gdrive_ingest.sh --folder "Music" https://example.com/song.mp3
```
Skips interactive mode, uses specified folder directly.

### Debug Mode
```bash
./gdrive_ingest.sh --debug --folder "test" https://example.com/file.mp3
```
Shows commands without executing them.

## 🎨 Example Session

```
✓ Using cached access token
📦 Processing 1 URL(s)
Fetching your GDrive folders...

╔═══════════════════════════════════════════════════════╗
║  📁 Select Destination Folder                         ║
╠═══════════════════════════════════════════════════════╣
║  ↑/↓: Navigate  →: Open  ←: Back  Enter: Select      ║
╚═══════════════════════════════════════════════════════╝

  ○ ● Create new folder
  ▶ Music
  ○ Images
  ○ bckups

[User presses Enter]

✓ Selected: Music (ID: 1hU4H0PO_ifwGP47UZHwbc2w89Y7V_YPn)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[1/1] Processing: https://example.com/song.mp3
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⬇  [██████████████████████████████████████] 100%
✓ Download complete
🔐 MD5: 6d2300f6a025e07ad87991b31023da6a
📄 Single file
Organizing and uploading files...
📀 Don Toliver - Tiramisu (2025) - Tiramisu
   ⬆  Uploading 8.52MB... ✓ Uploaded 8.52MB
   🖼  Cover art... ✓ Cover art uploaded

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ Done! Files uploaded to GDrive: Music
🔗 Check: https://drive.google.com/drive/folders/...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## 🔧 Technical Details

### Terminal Controls
- **Cursor hiding/showing** - Clean UI without cursor flicker
- **ANSI escape codes** - Colors and formatting
- **tput commands** - Terminal capability detection
- **Raw input mode** - Single keypress detection
- **Cleanup trap** - Ensures cursor restored on exit

### Progress Implementations
- **Download**: Live percentage bar using curl output parsing
- **Upload**: Spinner animation with background process monitoring
- **Process tracking**: Using PID monitoring with `kill -0`

### Navigation
- **Recursive navigation** - Dive into nested folder structures
- **Breadcrumb tracking** - Know where you are in the hierarchy
- **Parent navigation** - Easy back button functionality
- **Root detection** - Special handling for top-level folders

## 🚀 Performance

- Folder list cached from single API call
- Background uploads with foreground progress indicators
- Non-blocking animations
- Efficient terminal redraws using `clear` and cursor positioning

## 🎓 Tips

1. **For automation**: Use `--folder` flag to skip interactive mode
2. **For exploration**: Omit `--folder` to browse interactively
3. **Quick navigation**: Use → to dive deep, ← to go back quickly
4. **Create on the fly**: Select "● Create new folder" to make folders instantly
5. **Visual feedback**: Watch spinners to know uploads are working

---

**Enjoy the smooth, interactive experience!** 🎉
