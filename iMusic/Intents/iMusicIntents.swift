import AppIntents

// MARK: - Play YouTube (search + auto-play first result)

struct PlayYouTubeIntent: AppIntent {
    static var title: LocalizedStringResource = "Play a Song on YouTube"
    static var description = IntentDescription("Search YouTube and immediately play the top result in iMusic")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Song or Artist", description: "What to play on YouTube")
    var songName: String

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            IntentBridge.shared.pendingYouTubePlay = songName
        }
        return .result()
    }
}

// MARK: - Play Saved Song

struct PlaySavedSongIntent: AppIntent {
    static var title: LocalizedStringResource = "Play a Saved Song"
    static var description = IntentDescription("Play a song from your iMusic library")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Song Name", description: "Name of the saved song to play")
    var songName: String

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            IntentBridge.shared.pendingSavedSongSearch = songName
        }
        return .result()
    }
}

// MARK: - Pause

struct PauseMusicIntent: AppIntent {
    static var title: LocalizedStringResource = "Pause Music"
    static var description = IntentDescription("Pause the currently playing song in iMusic")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            IntentBridge.shared.pendingPlayerAction = .pause
        }
        return .result()
    }
}

// MARK: - Resume

struct ResumeMusicIntent: AppIntent {
    static var title: LocalizedStringResource = "Resume Music"
    static var description = IntentDescription("Resume playing music in iMusic")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            IntentBridge.shared.pendingPlayerAction = .resume
        }
        return .result()
    }
}

// MARK: - Skip

struct SkipTrackIntent: AppIntent {
    static var title: LocalizedStringResource = "Skip Track"
    static var description = IntentDescription("Skip to the next song in iMusic")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            IntentBridge.shared.pendingPlayerAction = .skip
        }
        return .result()
    }
}

// MARK: - Previous Track

struct PreviousTrackIntent: AppIntent {
    static var title: LocalizedStringResource = "Previous Track"
    static var description = IntentDescription("Go back to the previous song in iMusic")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            IntentBridge.shared.pendingPlayerAction = .previous
        }
        return .result()
    }
}

// MARK: - Siri Shortcuts

struct iMusicShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: PlayYouTubeIntent(),
            phrases: [
                "Play a song on YouTube in \(.applicationName)",
                "Play music on YouTube in \(.applicationName)"
            ],
            shortTitle: "Play on YouTube",
            systemImageName: "play.circle"
        )
        AppShortcut(
            intent: PlaySavedSongIntent(),
            phrases: [
                "Play saved song in \(.applicationName)",
                "Play a saved song in \(.applicationName)"
            ],
            shortTitle: "Play Saved Song",
            systemImageName: "music.note"
        )
        AppShortcut(
            intent: PauseMusicIntent(),
            phrases: [
                "Pause \(.applicationName)",
                "Pause music in \(.applicationName)"
            ],
            shortTitle: "Pause",
            systemImageName: "pause.fill"
        )
        AppShortcut(
            intent: ResumeMusicIntent(),
            phrases: [
                "Resume \(.applicationName)",
                "Resume music in \(.applicationName)"
            ],
            shortTitle: "Resume",
            systemImageName: "play.fill"
        )
        AppShortcut(
            intent: SkipTrackIntent(),
            phrases: [
                "Skip in \(.applicationName)",
                "Next song in \(.applicationName)"
            ],
            shortTitle: "Skip Track",
            systemImageName: "forward.fill"
        )
        AppShortcut(
            intent: PreviousTrackIntent(),
            phrases: [
                "Previous in \(.applicationName)",
                "Previous song in \(.applicationName)"
            ],
            shortTitle: "Previous Track",
            systemImageName: "backward.fill"
        )
    }
}
