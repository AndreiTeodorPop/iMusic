import SwiftUI

struct NowPlayingView: View {
    @EnvironmentObject var player: AudioPlayer
    @Environment(\.dismiss) var dismiss

    @State private var showingQueue = false

    var body: some View {
        VStack(spacing: 20) {

            // MARK: Header
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.down")
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                Spacer()
                Text("Now Playing")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
                Color.clear.frame(width: 44, height: 44)
            }
            .padding(.horizontal)
            .padding(.top, 10)

            // MARK: Album Art
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.accentColor.gradient)
                .aspectRatio(1, contentMode: .fit)
                .overlay(
                    Image(systemName: "music.note")
                        .font(.system(size: 100))
                        .foregroundColor(.white)
                )
                .padding(40)
                .shadow(radius: 20)
                .scaleEffect(player.isPlaying ? 1.0 : 0.92)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: player.isPlaying)

            // MARK: Title & Artist
            VStack(spacing: 8) {
                Text(player.currentTrack?.title ?? "Unknown")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                Text(player.currentTrack?.artist ?? "Unknown Artist")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            Spacer()

            // MARK: Progress
            VStack(spacing: 8) {
                Slider(value: Binding(
                    get: { player.duration > 0 ? player.currentTime / player.duration : 0 },
                    set: { player.seek(to: $0 * player.duration) }
                ))
                .tint(.primary)

                HStack {
                    Text(timeString(player.currentTime)).font(.caption.monospacedDigit())
                    Spacer()
                    Text(timeString(player.duration)).font(.caption.monospacedDigit())
                }
            }
            .padding(.horizontal, 30)

            // MARK: Main Controls
            HStack(spacing: 50) {
                Button { player.playPrevious() } label: {
                    Image(systemName: "backward.fill").font(.title)
                }
                Button { player.togglePlayPause() } label: {
                    Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 80))
                }
                Button { player.playNext() } label: {
                    Image(systemName: "forward.fill").font(.title)
                }
            }
            .foregroundStyle(.primary)

            // MARK: Volume
            HStack(spacing: 12) {
                Image(systemName: "speaker.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                SystemVolumeSlider()
                    .frame(height: 30)
                Image(systemName: "speaker.wave.3.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 30)

            // MARK: Shuffle + Queue
            HStack {
                Spacer()

                // Shuffle
                Button {
                    player.toggleShuffle()
                } label: {
                    Image(systemName: "shuffle")
                        .font(.title3)
                        .foregroundStyle(player.isShuffled ? Color.accentColor : .secondary)
                        .overlay(alignment: .bottom) {
                            // Active dot indicator
                            if player.isShuffled {
                                Circle()
                                    .fill(Color.accentColor)
                                    .frame(width: 5, height: 5)
                                    .offset(y: 8)
                            }
                        }
                }

                Spacer()

                // Queue / Up Next
                Button {
                    showingQueue = true
                } label: {
                    Image(systemName: "list.bullet")
                        .font(.title3)
                        .foregroundStyle(player.upcomingTracks.isEmpty ? .secondary : .primary)
                }
                .sheet(isPresented: $showingQueue) {
                    QueueSheet()
                }

                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 10)

            Spacer()
        }
        .padding(.bottom, 40)
    }

    private func timeString(_ t: TimeInterval) -> String {
        guard t.isFinite else { return "0:00" }
        let total = Int(t.rounded()); let m = total / 60; let s = total % 60
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - Queue Sheet

private struct QueueSheet: View {
    @EnvironmentObject var player: AudioPlayer
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if player.upcomingTracks.isEmpty {
                    ContentUnavailableView(
                        "No upcoming tracks",
                        systemImage: "list.bullet",
                        description: Text("Play a playlist to see the queue")
                    )
                } else {
                    List {
                        Section("Up Next") {
                            ForEach(Array(player.upcomingTracks.enumerated()), id: \.element.id) { index, track in
                                HStack(spacing: 12) {
                                    Text("\(index + 1)")
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                        .frame(width: 24)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(track.title)
                                            .font(.headline)
                                            .lineLimit(1)
                                        Text(track.artist ?? "Unknown Artist")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Queue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
