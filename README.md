# File Search Tools

A Flutter application for searching and previewing files from filesearch.tools API.

## Features

- Search files by name with filters (category, sort, order)
- Browse latest indexed files
- Preview images, videos, and other file types
- Video thumbnail carousel with lazy loading
- Browser selection (DuckDuckGo, Chrome, Firefox)
- Search history with local storage
- Optimized for slow internet connections (6 Mbit/s)

## Screenshots

Coming soon

## Installation

### Requirements

- Flutter 3.32.0+
- Android SDK 21+

### Build from source

```bash
# Clone the repository
git clone https://github.com/dawutnur/file_search_tools.git
cd file_search_tools

# Get dependencies
flutter pub get

# Run the app
flutter run

# Build release APK
flutter build apk --release --obfuscate --split-debug-info=build/debug-info
```

### Download APK

Download the latest release from the [Releases](https://github.com/dawutnur/file_search_tools/releases) page.

## Tech Stack

- **Flutter** - UI framework
- **GetX** - State management and navigation
- **Dio** - HTTP client
- **Hive CE** - Local storage
- **Chewie** - Video player
- **CachedNetworkImage** - Image caching
- **video_thumbnail** - Video thumbnail extraction

## API

This app uses the [filesearch.tools](https://filesearch.tools) API.

## License

MIT License
