# 🧠 Clipboard History App for macOS
> A minimalist, native macOS menu bar utility that tracks your clipboard history — built with **SwiftUI** and **SwiftData**.

<p align="center">
  <img src="Clipboard-History-Logo.png" width="128" height="128" alt="Clipboard History App Icon">
</p>

<p align="center">
  <a href="https://developer.apple.com/macos/">
    <img src="https://img.shields.io/badge/macOS-15%2B-lightgrey?style=for-the-badge&logo=apple" alt="macOS 15+">
  </a>
  <a href="https://developer.apple.com/swift/">
    <img src="https://img.shields.io/badge/Swift-6.0-orange?style=for-the-badge&logo=swift" alt="Swift 6.0">
  </a>
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/License-MIT-blue?style=for-the-badge" alt="MIT License">
  </a>
  <a href="https://developer.apple.com/xcode/">
    <img src="https://img.shields.io/badge/Xcode-16%2B-blue?style=for-the-badge&logo=xcode" alt="Xcode 16+">
  </a>
</p>

---

## ✨ Features

- 📋 **Clipboard Monitoring** — Automatically tracks copied text and file paths.
- 🧭 **Menu Bar Access** — Quickly view your **last 10 copied items** right from the menu bar.  
  <p align="left">
    <img src="Images/Clipboard-History-MenuBar.png" width="320" alt="Clipboard Menu Bar Screenshot">
  </p>
- 💾 **Persistent History** — Stores up to **30 days** of clipboard history *(configurable)* using **SwiftData**.
- ⚡ **Smart Actions**
  - 🖱️ **Click Text** — Copies text back to the clipboard.  
  - 📂 **Click File** — Opens the file directly.  
  - ⌥ **Option + Click File** — Copies file path instead of opening.
- ⚙️ **Custom Settings** — Choose your retention period: **7, 30, 90 days, or Forever**.  
  <p align="left">
    <img src="Images/Clipboard-History-Settings.png" width="320" alt="App Settings Screenshot">
  </p>
- 🔍 **Full History View** — Browse and manage your complete clipboard archive.  
  <p align="left">
    <img src="Images/Clipboard-History-ViewFull-History.png" width="320" alt="Full History View Screenshot">
  </p>

---

## 🚀 Installation

### 🧱 Option 1: Build from Source

Clone this repository
git clone https://github.com/Sudeep05/ClipboardHistoryApp.git

Navigate into the project directory
cd ClipboardHistoryApp

Open in Xcode
open ClipboardHistory.xcodeproj


- Requires **macOS 15+** and **Xcode 16+**.  
- In Xcode, click **Run ▶ (Cmd + R)** to build and launch the app.

---

## 🧩 How It Works

The app continuously monitors macOS’s **NSPasteboard** for new clipboard events. It intelligently filters supported content types:
- ✅ Plain text
- ✅ File paths

Clipboard entries are saved locally using **SwiftData’s SQLite persistence**, enabling:
- Fast access even when offline  
- Configurable retention for privacy-conscious users  
- Efficient data cleanup to conserve memory

---

## 🧠 Design Philosophy

This app embraces **minimalism, privacy, and native design principles**:
- **No external dependencies** — 100% Swift + SwiftUI  
- **No network sync** — all data stored securely on-device  
- **Smooth animations** and **system-level integration** aligned with Apple’s HIG  

---

## 🧑‍💻 Author

**Pala Sudeep Kumar**  
🖋 Beginner to Coding 


---

## 🧾 License

This project is released under the **MIT License**.  
See the [LICENSE](LICENSE) file for complete details.  

---

<p align="center">
  <sub>Made with ❤️ on macOS • Powered by SwiftUI + SwiftData</sub>
</p>
