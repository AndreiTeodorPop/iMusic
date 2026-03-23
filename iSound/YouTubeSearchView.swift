import SwiftUI

@MainActor
struct YouTubeSearchView: View {
    @EnvironmentObject private var player: AudioPlayer

    @State private var query        = ""
    @State private var results: [YouTubeResult] = []
    @State private var isSearching  = false
    @State private var isLoadingID: String? = nil
    @State private var errorMessage: String? = nil
    @State private var downloadingID: String? = nil
    @ObservedObject var library: AudioLibrary


    var body: some View {
        NavigationStack {
            List(results) { result in
                resultRow(result)
            }
            .navigationTitle("YouTube")
            .searchable(text: $query, prompt: "Search songs, artists…")
            .onSubmit(of: .search) {
                Task { await performSearch() }
            }
            .overlay { overlayView }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func resultRow(_ result: YouTubeResult) -> some View {
        HStack(spacing: 12) {
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

            VStack(alignment: .leading, spacing: 3) {
                Text(result.title)
                    .font(.headline)
                    .lineLimit(2)
                Text(result.channelTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if result.durationSeconds > 0 {
                Text(timeString(result.durationSeconds))
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
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
        }
        .swipeActions(edge: .trailing) {
            Button {
                Task { await downloadResult(result) }
            } label: {
                Label("Download", systemImage: "arrow.down.circle")
            }
            .tint(.blue)
        }
    }
    
    private func downloadResult(_ result: YouTubeResult) async {
        guard downloadingID == nil else { return }
        downloadingID = result.id
        do {
            let savedURL = try await StreamService.downloadAudio(
                for: result.id,
                title: result.title
            )
            // Reload the library so the track appears in Saved Songs immediately
            await library.loadExistingTracks()
            print("Downloaded to: \(savedURL)")
        } catch {
            errorMessage = error.localizedDescription
        }
        downloadingID = nil
    }
    
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

    private func performSearch() async {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isSearching = true
        results = []
        do {
            results = try await YouTubeService.search(query)
        } catch {
            errorMessage = error.localizedDescription
        }
        isSearching = false
    }

    private func playResult(_ result: YouTubeResult) async {
        guard isLoadingID == nil else { return }
        isLoadingID = result.id
        do {
            let stream = try await StreamService.getStreamURL(for: result.id)
            guard let url = URL(string: stream.url) else {
                errorMessage = "Invalid stream URL"
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
            errorMessage = error.localizedDescription
        }
        isLoadingID = nil
    }

    private func timeString(_ t: TimeInterval) -> String {
        let total = Int(t); let m = total / 60; let s = total % 60
        return String(format: "%d:%02d", m, s)
    }
}
