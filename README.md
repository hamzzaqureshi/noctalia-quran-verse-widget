# Noctalia Quran Verse Widget

<div align="center">

![Quran Verse Desktop Widget](assets/preview.png)

A desktop widget for [Noctalia](https://github.com/noctalia-dev/noctalia) displaying daily Quran verses with the authoritative **English Hilali-Khan** translation, Arabic text, and random verse exploration.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Noctalia API](https://img.shields.io/badge/Noctalia%20API-v24-purple.svg)](https://github.com/noctalia-dev/noctalia)
[![Translation](https://img.shields.io/badge/Translation-Hilali--Khan%20(English)-emerald.svg)](https://quran.com)
[![Luau](https://img.shields.io/badge/Language-Luau-00A2FF.svg)](https://luau-lang.org/)

</div>

---

## Features

- **Pure English Hilali-Khan Translation**: Clear, authentic, and scholarly English translation from Muhammad Taqi-ud-Din al-Hilali and Muhammad Muhsin Khan.
- **Deterministic Daily Ayah**: Automatically syncs each day across all **6,236** verses of the Holy Quran, with automatic midnight day turnover detection.
- **Random Verse Discovery**: Explore verses across all 114 Surahs at any time, with an instant "Back to Today" button to return.
- **Dual-Engine API Resilience**: Queries **Quran.com v4 API** (Resource ID 203) as the primary provider with automatic fallback to **QuranEnc API**.
- **Quick Actions**:
  - **Copy Verse**: Copies clean verse text directly to clipboard.
  - **Copy Share Citation**: Formats a quote block with Surah name, chapter:verse reference, translation author, and Quran.com link.
  - **Copy Link**: Copies the direct Quran.com verse URL.
  - **Random Verse**: Rolls a random verse from any of the 114 Surahs.
  - **Open in Browser**: Launches the verse directly in your default browser.
- **Native Noctalia Styling**: Built using Noctalia's native design system tokens (`surface_variant`, `primary`, `on_surface`), matching your desktop theme.
- **Overflow-Proof Layout**: Fixed 420x260 dimensions with internal smooth-scrolling for long verses, ensuring zero desktop layout shift.
- **Battery & Resource Optimized**: Dynamic update intervals (30s idle sleep gate, 1s tick during transient badge animations) for minimal CPU consumption.
- **Offline & Cold-Start Caching**: Persists current verses locally to `verse.json` for immediate loading on boot without network lag.

---

## Installation

### Method 1: Clone into Custom Plugins (Recommended)

1. Clone this repository directly into your Noctalia custom plugins directory:
   ```bash
   git clone https://github.com/hamzzaqureshi/noctalia-quran-verse.git ~/.local/share/noctalia/custom-plugins/noctalia-quran-verse
   ```

2. Reload or restart Noctalia:
   ```bash
   noctalia reload
   ```

3. Add the **Quran Verse** widget to your desktop layout via the Noctalia desktop settings.

### Method 2: Development / Symlink Setup

If you prefer keeping your source code in a dedicated `Projects` folder:

```bash
# Clone the repository
git clone https://github.com/hamzzaqureshi/noctalia-quran-verse.git ~/Projects/noctalia-quran-verse

# Symlink into Noctalia's custom-plugins directory
ln -s ~/Projects/noctalia-quran-verse ~/.local/share/noctalia/custom-plugins/noctalia-quran-verse

# Reload Noctalia
noctalia reload
```

---

## Project Structure

```
noctalia-quran-verse/
├── main.luau           # Core widget logic, UI components, and API client
├── plugin.toml         # Noctalia plugin manifest and widget registration
├── thumbnail.webp      # Plugin catalog visual thumbnail
├── LICENSE             # MIT License
├── README.md           # Documentation and preview
├── .gitignore          # Cache and build ignores
└── assets/
    ├── preview.png     # High-resolution desktop screenshot
    └── thumbnail.webp  # Catalog card asset
```

---

## How It Works

### Deterministic Daily Sequence
The daily verse index is calculated deterministically from the current calendar year and day of the year (`%Y-%j`):
$$\text{Verse Index} = ((\text{Days Since Epoch}) \pmod{6236}) + 1$$
This is mapped across the exact verse counts of all 114 Surahs to provide a smooth, continuous sequence through the entire Quran.

### Dual API Fallback
1. **Quran.com v4**: Requests `https://api.quran.com/api/v4/verses/by_key/{surah}:{ayah}?translations=203&fields=text_uthmani`.
2. **QuranEnc**: If Quran.com is unavailable or encounters network issues, seamlessly falls back to `https://quranenc.com/api/v1/translation/aya/english_hilali_khan/{surah}/{ayah}`.

---

## Acknowledgements & Data Sources

- [Quran.com API](https://quran.com) - Noble Quran content and API v4.
- [QuranEnc](https://quranenc.com) - Authentic Quran translations encyclopedia.
- [Noctalia](https://github.com/noctalia-dev/noctalia) - The modern desktop shell and widget ecosystem.

---

## License

This project is licensed under the [MIT License](LICENSE) (c) 2026 [Hamza Qureshi](https://github.com/hamzzaqureshi).
