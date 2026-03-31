# iMusic

A modern iOS music player that brings together your local library and YouTube streaming in one beautifully designed app.

## Features

### Music Playback
- **Stream from YouTube** — Search any song or artist and instantly play the top result, with automatic queue continuation
- **Local Library** — Import and play audio files from your device with full metadata support
- **Background Playback** — Music continues playing when your screen is off or you switch apps
- **AirPlay & Bluetooth** — Seamlessly route audio to any connected device via the native route picker

### Siri Integration
- Works fully from the **lock screen** — no need to unlock your phone
- Voice commands: *"Play [song] in iMusic"*, *"Pause iMusic"*, *"Skip in iMusic"*, *"Play playlist [name] in iMusic"*
- Compatible with **CarPlay** — control playback and use Siri hands-free while driving

### Library Management
- Organized **playlist system** — create, manage, and delete playlists
- **Alphabet index** for fast navigation through large libraries
- Sort by recently added, alphabetically, or by artist
- Import audio files directly from Files or other apps

### Player Controls
- Full **Now Playing** screen with seek bar, shuffle, and queue view
- **Drag-to-reorder** upcoming tracks in the queue
- Lock screen and Control Center integration via `MPRemoteCommandCenter`
- Shuffle support for both local playlists and YouTube queues
- Add currently playing track to any playlist directly from the Now Playing screen

### Themes
- Multiple color themes with accent and gradient customization

## Requirements

- iOS 16+
- Xcode 15+
- YouTube Data API v3 key (add as `YoutubeAPIKey` in `Info.plist`)

## Architecture

- **SwiftUI** with `@MainActor` isolated services
- **AppIntents** framework for Siri Shortcuts (no separate extension required)
- **AVFoundation** — `AVAudioPlayer` for local files, `AVPlayer` for YouTube streams
- **AVAudioSession** with `.playback` category for uninterrupted background audio
- Streaming backend powered by a self-hosted Railway server
