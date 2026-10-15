# Noctalia Quran Verse Widget

> A deterministic daily Quran verse widget for the Noctalia desktop shell with English Hilali-Khan translation, offline persistence, and random ayah exploration.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Noctalia API](https://img.shields.io/badge/Noctalia%20API-v24-emerald.svg)](plugin.toml)
[![Translation](https://img.shields.io/badge/Translation-Hilali--Khan-purple.svg)](https://quran.com)
[![Lint](https://img.shields.io/badge/Lint-0%20errors-brightgreen.svg)](plugin.toml)

---

## Table of Contents

- [Overview](#overview)
- [Key Features](#key-features)
- [Desktop Showcase](#desktop-showcase)
- [Usage](#usage)
- [Installation](#installation)
  - [Prerequisites](#prerequisites)
  - [Quickstart](#quickstart-automatic-installation)
  - [Manual Installation](#manual-installation)
- [Technical Architecture](#technical-architecture)
  - [Directory Structure](#directory-structure)
- [Validation and Testing](#validation-and-testing)
- [Uninstallation](#uninstallation)
- [License](#license)

---

## Overview

Noctalia Quran Verse Widget is a native desktop widget for the Noctalia Wayland shell. It provides an uninterrupted spiritual anchor on Linux desktops by presenting a daily verse from the Quran paired with the authoritative English translation by Muhammad Taqi-ud-Din al-Hilali and Muhammad Muhsin Khan.

The widget renders inside a fixed 420x260 card, updates smoothly at midnight, retains full offline capability through local state caching, and provides instant clipboard formatting for research and sharing.

![Noctalia Quran Verse Desktop Widget Preview](assets/preview.png)

---

## Key Features

- **Authoritative Translation**: Exclusively presents the scholarly Hilali-Khan translation sourced directly from Quran.com API (resource ID 203) with automatic fallback to QuranEnc.
- **Deterministic Calendar Sequence**: Maps every day of the calendar year to a distinct ayah across all 6,236 verses of the Quran, ensuring synchronized daily reading.
- **Random Exploration Mode**: Discover any verse across all 114 Surahs with a single click, featuring a persistent "Back to Today" action to restore the daily sequence.
- **Offline Resilience**: Writes today's retrieved verse to a local cache (`verse.json`). Launches instantly on system startup without waiting for network connectivity.
- **Fixed Layout Preservation**: Contains a responsive Luau scroll view that preserves the widget's geometric boundary (420x260 px) even when displaying longer verses.
- **One-Click Share Citations**: Export clean plain text, formatted quote citations (`"..." Surah Al-Baqarah 2:255 · Hilali-Khan`), or direct web references to the system clipboard.
- **Resource Efficient**: Operates on a dynamic event loop (30-second idle polling, 1-second transient banner decay) to maintain near-zero CPU and memory footprint.

---

## Desktop Showcase

The widget integrates into Noctalia's native design system, supporting both dark and light system palettes:

![Desktop Screenshot](assets/desktop.png)

---

## Usage

Interactive controls available on the widget interface:

| Control | Action | Target / Result |
| :--- | :--- | :--- |
| **Verse Body** | Click text area | Copies the plain English translation to clipboard |
| **Copy Icon** | Click | Copies the plain English translation to clipboard |
| **Share Icon** | Click | Copies formatted quotation with Surah name, Ayah reference, and translation credit |
| **Link Icon** | Click | Copies direct `https://quran.com/SURAH:AYAH` URL |
| **Refresh Icon** | Click | Fetches a random verse across all 114 Surahs |
| **Back to Today** | Click | Exits random mode and restores today's scheduled verse |
| **Open Button** | Click | Launches the verse directly in your default browser via `xdg-open` |

---

## Installation

### Prerequisites

- **Noctalia** (version 5.0.0 or higher)
- **Linux Wayland Compositor** (Niri, Hyprland, Sway, River, or DWL)
- **xdg-open** (optional, required for the "Open" in browser button)

### Quickstart (Automatic Installation)

Clone the repository and run the automated installer:

```bash
git clone https://github.com/hamzzaqureshi/noctalia-quran-verse-widget.git
cd noctalia-quran-verse-widget
./install.sh -y
```

The script links the widget into Noctalia's local catalog, registers the source, enables the plugin, and launches Noctalia's interactive layout editor.

### Manual Installation

If you prefer configuring Noctalia manually:

1. Create the local plugins catalog directory:
   ```bash
   mkdir -p ~/.local/share/noctalia/sources/local-plugins
   ```

2. Register the catalog manifest in `~/.local/share/noctalia/sources/local-plugins/catalog.toml`:
   ```toml
   [[plugin]]
   id = "hamzzaqureshi/quran-verse"
   name = "Quran Verse"
   version = "1.0.0"
   author = "hamzzaqureshi"
   license = "MIT"
   icon = "book"
   description = "Daily Quran verse desktop widget with English Hilali-Khan translation."
   plugin_api = 24
   tags = ["desktop", "language", "time", "utility"]
   ```

3. Symlink this repository into the catalog:
   ```bash
   ln -sfn "$(pwd)" ~/.local/share/noctalia/sources/local-plugins/quran-verse
   ```

4. Register the source and enable the widget in Noctalia:
   ```bash
   noctalia msg plugins source add local-plugins path ~/.local/share/noctalia/sources/local-plugins
   noctalia msg plugins enable hamzzaqureshi/quran-verse
   ```

5. Position the widget on your desktop:
   ```bash
   noctalia msg desktop-widgets-toggle-edit
   ```

---

## Technical Architecture

The widget executes inside Noctalia's sandboxed Luau runtime. Network queries execute asynchronously with automatic primary and secondary API failover:

```mermaid
flowchart TD
    A[Widget Initialization] --> B{Cache Exists for Today?}
    B -- Yes --> C[Load verse.json Instant Render]
    B -- No --> D[Calculate Day Index 1-6236]
    D --> E[Query Quran.com API v4]
    E -- 200 OK --> F[Parse Hilali-Khan Translation]
    E -- Failure / Timeout --> G[Query QuranEnc API Fallback]
    G -- 200 OK --> F
    G -- Failure --> H[Display Cached / Error State]
    F --> I[Write to verse.json]
    I --> J[Render Widget Interface]
    J --> K[Set Update Interval 30s]
```

### Directory Structure

```text
noctalia-quran-verse-widget/
├── .gitignore             # Ignores runtime cache and development type files
├── .luaurc                # Luau type checker configuration
├── LICENSE                # MIT License
├── README.md              # Project documentation
├── assets/
│   ├── desktop.png        # Full-screen desktop context screenshot
│   └── preview.png        # Cropped high-resolution widget interface preview
├── install.sh             # One-step automated installer
├── main.luau              # Primary widget logic and reactive UI implementation
├── plugin.toml            # Noctalia plugin manifest
├── thumbnail.webp         # Official 960x540 catalog presentation card
├── translations/
│   └── en.json            # English localization strings
└── uninstall.sh           # Clean removal and unregistration script
```

---

## Validation and Testing

To verify manifest conformance, type definitions, and catalog metadata against Noctalia's official rules:

```bash
noctalia plugins lint .
```

Expected output:

```text
hamzzaqureshi/quran-verse
  ok

0 errors, 0 warnings
```

---

## Uninstallation

To cleanly unregister and remove the widget:

```bash
./uninstall.sh
```

This disables the plugin, removes the catalog symlink, and purges the empty local source definition.

---

## License

This project is licensed under the [MIT License](LICENSE).

Scripture text and translations remain the intellectual property of their respective publishers. English translation by Dr. Muhammad Taqi-ud-Din al-Hilali and Dr. Muhammad Muhsin Khan. APIs provided courtesy of [Quran.com](https://quran.com) and [QuranEnc.com](https://quranenc.com).
