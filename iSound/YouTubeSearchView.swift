import SwiftUI

// MARK: - Toast Model

private enum ToastType {
    case success(String)
    case error(String)

    var message: String {
        switch self {
        case .success(let m), .error(let m): return m
        }
    }

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error:   return "xmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .success: return .green
        case .error:   return .red
        }
    }
}

// MARK: - Toast View

private struct ToastView: View {
    let toast: ToastType

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: toast.icon)
                .foregroundStyle(toast.color)
            Text(toast.message)
                .font(.subheadline.weight(.medium))
                .lineLimit(2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(toast.color.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
    }
}

// MARK: - Main View

@MainActor
struct YouTubeSearchView: View {
    @EnvironmentObject private var player: AudioPlayer

    @State private var query           = ""
    @State private var results: [YouTubeResult] = []
    @State private var isSearching     = false
    @State private var isLoadingID: String?    = nil   // streaming
    @State private var downloadingIDs: Set<String> = [] // downloading (supports parallel)
    @State private var downloadedIDs:  Set<String> = [] // already in library this session
    @State private var toast: ToastType?               = nil
    @State private var toastTask: Task<Void, Never>?

    @ObservedObject var library: AudioLibrary

    var body: some View {
        NavigationStack {
            List(results) { result in
                resultRow(result)
                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
            }
            .navigationTitle("YouTube")
            .searchable(text: $query, prompt: "Search songs, artists…")
            .onSubmit(of: .search) {
                Task { await performSearch() }
            }
            .overlay { overlayView }
            .overlay(alignment: .bottom) { toastOverlay }
        }
    }

    // MARK: - Result Row

    private func resultRow(_ result: YouTubeResult) -> some View {
        HStack(spacing: 12) {

            // Leading icon: stream state
            ZStack {
                if isLoadingID == result.id {
                    ProgressView().frame(width: 24, height: 24)
                } else if player.currentTrack?.title == result.title {
                    Image(systemName: "waveform")
                        .foregroundStyle(.red)
                        .frame(width: 24, height: 24)
                } else {
                    Image(systemName: "play.circle")
                        .foregroundStyle(.secondary)
                        .frame(width: 24, height: 24)
                }
            }

            // Title + channel
            VStack(alignment: .leading, spacing: 3) {
                Text(result.title)
                    .font(.headline)
                    .lineLimit(2)
                Text(result.channelTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Trailing: duration + download state
            HStack(spacing: 8) {
                if result.durationSeconds > 0 {
                    Text(timeString(result.durationSeconds))
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                downloadIndicator(for: result)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { Task { await playResult(result) } }
        .contextMenu {
            Button {
                Task { await downloadResult(result) }
            } label: {
                Label("Download to Library", systemImage: "arrow.down.circle")
            }
            .disabled(downloadedIDs.contains(result.id) || downloadingIDs.contains(result.id))
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if !downloadedIDs.contains(result.id) {
                Button {
                    Task { await downloadResult(result) }
                } label: {
                    Label("Download", systemImage: "arrow.down.circle")
                }
                .tint(.blue)
                .disabled(downloadingIDs.contains(result.id))
            }
        }
    }

    // MARK: - Download Indicator

    @ViewBuilder
    private func downloadIndicator(for result: YouTubeResult) -> some View {
        if downloadingIDs.contains(result.id) {
            ProgressView()
                .controlSize(.small)
                .frame(width: 20, height: 20)
        } else if downloadedIDs.contains(result.id) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .frame(width: 20, height: 20)
                .transition(.scale.combined(with: .opacity))
        }
    }

    // MARK: - Download Action

    private func downloadResult(_ result: YouTubeResult) async {
        // Duplicate guard: already downloaded this session
        guard !downloadedIDs.contains(result.id) else {
            showToast(.error("\"\(result.title)\" is already in your library"))
            return
        }
        // Also check the live library by title (cross-session duplicate)
        let alreadySaved = library.tracks.contains { $0.title == result.title }
        if alreadySaved {
            _ = withAnimation { downloadedIDs.insert(result.id) }
            showToast(.error("\"\(result.title)\" is already saved"))
            return
        }

        _ = withAnimation { downloadingIDs.insert(result.id) }

        do {
            let savedURL = try await StreamService.downloadAudio(
                for: result.id,
                title: result.title
            )
            await library.loadExistingTracks()
            withAnimation {
                downloadingIDs.remove(result.id)
                downloadedIDs.insert(result.id)
            }
            showToast(.success("\"\(result.title)\" saved to library"))
            print("Downloaded to: \(savedURL)")
        } catch {
            _ = withAnimation { downloadingIDs.remove(result.id) }
            showToast(.error(error.localizedDescription))
        }
    }

    // MARK: - Stream Action

    private func playResult(_ result: YouTubeResult) async {
        guard isLoadingID == nil else { return }
        isLoadingID = result.id
        do {
            let stream = try await StreamService.getStreamURL(for: result.id)
            guard let url = URL(string: stream.url) else {
                showToast(.error("Invalid stream URL"))
                isLoadingID = nil
                return
            }
            player.playYouTube(
                url: url,
                title: stream.title,
                artist: stream.artist,
                duration: stream.duration
            )
        } catch {
            showToast(.error(error.localizedDescription))
        }
        isLoadingID = nil
    }

    // MARK: - Search

    private func performSearch() async {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isSearching = true
        results = []
        // Sync downloaded state with current library on each search
        let savedTitles = Set(library.tracks.map { $0.title })
        do {
            let fetched = try await YouTubeService.search(query)
            results = fetched
            // Mark any results already in library as downloaded
            downloadedIDs = Set(fetched.filter { savedTitles.contains($0.title) }.map { $0.id })
        } catch {
            showToast(.error(error.localizedDescription))
        }
        isSearching = false
    }

    // MARK: - Toast

    private func showToast(_ type: ToastType) {
        toastTask?.cancel()
        withAnimation(.spring(response: 0.3)) { toast = type }
        toastTask = Task {
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut) { toast = nil }
        }
    }

    // MARK: - Overlay Views

    @ViewBuilder
    private var overlayView: some View {
        if isSearching {
            ProgressView("Searching…")
        } else if results.isEmpty && !query.isEmpty {
            ContentUnavailableView("No results", systemImage: "magnifyingglass")
        } else if results.isEmpty {
            ContentUnavailableView(
                "Search YouTube",
                systemImage: "play.rectangle",
                description: Text("Type a song or artist to get started")
            )
        }
    }

    @ViewBuilder
    private var toastOverlay: some View {
        if let t = toast {
            ToastView(toast: t)
                .padding(.bottom, 100) // clears mini-player
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    // MARK: - Helpers

    private func timeString(_ t: TimeInterval) -> String {
        let total = Int(t); let m = total / 60; let s = total % 60
        return String(format: "%d:%02d", m, s)
    }
}
