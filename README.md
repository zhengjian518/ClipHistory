# ClipHistory

A lightweight clipboard history manager that lives in your macOS menu bar. Copy text and images throughout the day, then click any past item to paste it back instantly.

Built entirely with native Swift, SwiftUI, and Core Data — no third-party dependencies.

---

## Features

- 📋 **Automatic history** — captures everything you copy (text & images) in the background
- 🖼️ **Text & image support** — image entries show a thumbnail; click to paste into Pages, Keynote, Notes, etc.
- 📌 **Pin** — keep important items at the top; pinned items are never auto-deleted
- 🗑️ **Delete** — remove any entry with one click
- ⚡ **Click to paste** — click a card to paste straight into whatever app is in front
- 🔍 **Search** — instantly filter your text history (case-insensitive)
- ⏳ **Retention control** — keep history for 1, 3, or 5 days; expired items are cleaned up automatically (up to 100 items)
- 🔒 **Privacy aware** — automatically skips passwords from 1Password, Bitwarden, KeePassXC, and other password managers
- 🌗 **Dark mode** — adapts to your system appearance
- 🪶 **Menu-bar only** — no Dock icon, stays out of your way

---

## Requirements

- macOS 13 (Ventura) or later
- Xcode 15+ (only if building from source)

---

## Install

### Option A — Download a release

1. Download `ClipHistory.app` and drag it into your **Applications** folder.
2. Because the app is self-signed (not notarized by Apple), macOS Gatekeeper will block the first launch. To allow it:
   - Open **System Settings → Privacy & Security**, scroll to the **Security** section, and click **Open Anyway**, **or**
   - run this once in Terminal:
     ```bash
     xattr -dr com.apple.quarantine /Applications/ClipHistory.app
     ```
3. Launch the app — a clipboard icon appears in your menu bar.

### Option B — Build from source

```bash
git clone <your-repo-url>
cd ClipHistory
open ClipHistory/ClipHistory.xcodeproj
```

Then press **⌘R** in Xcode, or build from the command line:

```bash
xcodebuild -project ClipHistory/ClipHistory.xcodeproj \
  -scheme ClipHistory -configuration Release build
```

---

## Permissions

The first time you click a card to **paste**, macOS will ask for **Accessibility** access. This is required because ClipHistory simulates a `⌘V` keystroke (via `CGEvent`) to paste into the frontmost app.

Grant it in **System Settings → Privacy & Security → Accessibility** and turn on the **ClipHistory** toggle. You only need to do this once.

The app runs **without the App Sandbox** so it can read the clipboard, detect the source app, and paste into other applications.

---

## Usage

| Action | How |
|---|---|
| Open history | Click the clipboard icon in the menu bar |
| Paste an item | Click the card body |
| Pin / unpin | Click the 📌 button on a card |
| Delete | Click the 🗑 button on a card |
| Search | Type in the search box at the top |
| Settings | Click the ⚙️ button in the footer |

**Tip:** Add ClipHistory to **System Settings → General → Login Items** to launch it automatically at startup.

---

## How it works

| Concern | Approach |
|---|---|
| Clipboard monitoring | Polls `NSPasteboard.changeCount` every 500 ms (macOS provides no change notifications) |
| Storage | Core Data + SQLite; images use Core Data external storage |
| Paste | Writes to `NSPasteboard`, then posts a synthetic `⌘V` via `CGEvent` |
| Privacy | Skips entries with the `org.nspasteboard.ConcealedType` flag and known password-manager bundle IDs |
| Retention | Cleans up on launch and every 24 h; pinned items are exempt |

---

## Project structure

```
ClipHistory/
├── ClipHistoryApp.swift           # @main entry point
├── AppDelegate.swift              # Menu bar item, popover, paste coordination
├── Models/
│   └── ClipItemType.swift         # .text / .image enum
├── Persistence/
│   ├── PersistenceController.swift
│   └── ClipHistory.xcdatamodeld   # Core Data model
├── Services/
│   ├── ClipboardMonitor.swift     # Polling, privacy filter, dedup, writes
│   └── RetentionManager.swift     # Expiry & item-limit cleanup
├── ViewModels/
│   └── ClipHistoryViewModel.swift # Pin / delete / paste / search
├── Views/
│   ├── PopoverRootView.swift
│   ├── ClipCardView.swift
│   ├── SearchBarView.swift
│   └── SettingsView.swift
└── Utilities/
    └── NSImage+Thumbnail.swift
```

---

## Privacy

All clipboard history is stored **locally** on your Mac at
`~/Library/Application Support/ClipHistory/`. Nothing is ever uploaded or sent anywhere — there is no network code in this app.

---

## Tech stack

Swift · SwiftUI · AppKit · Core Data — zero external dependencies.

---

## License

MIT — see [LICENSE](LICENSE).
