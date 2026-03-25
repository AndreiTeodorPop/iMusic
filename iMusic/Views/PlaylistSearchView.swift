import SwiftUI

struct PlaylistSearchView: View {
    @ObservedObject var library: AudioLibrary
    @EnvironmentObject var themeManager: ThemeManager

    @State private var searchText = ""
    @State private var selectedPlaylistID: UUID?

    private var filteredPlaylists: [Playlist] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return library.playlists }
        return library.playlists.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        List {
            ForEach(filteredPlaylists) { playlist in
                Button {
                    selectedPlaylistID = playlist.id
                } label: {
                    HStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(themeManager.current.accent.gradient)
                            .frame(width: 50, height: 50)
                            .overlay(Image(systemName: "music.note.list").foregroundColor(.white))
                        Text(playlist.name).font(.headline)
                    }
                    .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle("Playlists")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search playlists in your library...")
        .overlay {
            if library.playlists.isEmpty {
                ContentUnavailableView("No Playlists", systemImage: "music.note.list", description: Text("Create a playlist from the Library tab."))
            } else if filteredPlaylists.isEmpty {
                ContentUnavailableView.search(text: searchText)
            }
        }
        .navigationDestination(item: $selectedPlaylistID) { id in
            PlaylistDetailView(playlistID: id, library: library)
        }
    }
}
