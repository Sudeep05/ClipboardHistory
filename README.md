**Clipboard History App for macOS**

A minimalist, native macOS menu bar utility that tracks your clipboard history. Built with SwiftUI and SwiftData for persistence.

<p align="left">
<img src="Clipboard-History-Logo.png" width="128" height="128" alt="App Icon">
</p>

**Features** :
Clipboard Monitoring - Automatically saves text and file paths copied to the clipboard.

**Menu Bar Access**: Quick access to your last 10 copied items.
<p align="left">
<img src="Images/Clipboard-History-MenuBar.png" width="256" height="256" alt="App Icon">
</p>

**Persistent History** : Stores up to 30 days of history (configurable) using SwiftData.

**Smart Actions**:

Click Text: Copies text back to the clipboard.

Click File: Opens the file directly.

Option + Click File: Copies the file path instead of opening it.

**Custom Settings** : Configure retention period (7, 30, 90 days, or Forever).
<p align="left">
<img src="Images/Clipboard-History-Settings.png" width="256" height="256" alt="App Icon">
</p>

**Full History View** : A dedicated window to browse and manage your entire history.
<p align="left">
<img src="Images/Clipboard-History-ViewFull-History.png" width="256" height="256" alt="App Icon">
</p>


**Installation :**

Present-Option :  Build from Source

Clone this repository.

Open ClipboardHistory.xcodeproj in Xcode 16+ (macOS 15+ required).

Build and Run (Cmd+R).

**How it Works**

The app uses NSPasteboard polling to detect changes. It filters for sensitive content types (files and plain text) and stores them in a local SQLite database via SwiftData.

**Author
_Pala Sudeep Kumar**_

License
This project is licensed under the MIT License - see the LICENSE file for details.
