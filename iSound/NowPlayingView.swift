import SwiftUI

struct NowPlayingView: View {
    @EnvironmentObject var player: AudioPlayer
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
                    // MARK: - Header with Back Button
                    HStack {
                        Button {
                            dismiss() // 2. Dismiss the view when tapped
                        } label: {
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
                        
                        // Empty view to balance the header symmetry
                        Color.clear.frame(width: 44, height: 44)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)

            // 2. Large Album Art
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

            // 3. Title & Artist
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

            // 4. Progress Slider
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

            // 5. Main Controls
            HStack(spacing: 50) {
                Button(action: { player.playPrevious() }) {
                    Image(systemName: "backward.fill").font(.title)
                }
                
                Button(action: { player.togglePlayPause() }) {
                    Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 80))
                }
                
                Button(action: { player.playNext() }) {
                    Image(systemName: "forward.fill").font(.title)
                }
            }
            .foregroundStyle(.primary)
            
            VStack(spacing: 20) {
                // Volume Control Row
                HStack(spacing: 15) {
                    Image(systemName: "speaker.fill")
                        .font(.caption)
                    
                    SystemVolumeSlider()
                        .frame(height: 30)
                    
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
                
                // Bottom Utility Row
                HStack {
                    
                    Spacer()
                    
                    Button {
                        // Future logic for Shuffle/Repeat
                    } label: {
                        Image(systemName: "shuffle")
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    // Lyrics or Queue button
                    Button { } label: {
                        Image(systemName: "list.bullet")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 10)
            }
            .padding(.horizontal, 30)
            
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
