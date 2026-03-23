import Combine
import Foundation
import UniformTypeIdentifiers
import AVFoundation
import SwiftUI
import AVKit

@MainActor
final class AudioLibrary: ObservableObject {
    @Published private(set) var tracks: [Track] = []
    @Published var playlists: [Playlist] = []

    private let fileManager = FileManager.default
    private let importFolderName = "ImportedAudio"

    // MARK: - Persistence

    private var playlistsFileURL: URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("playlists.json")
    }

    init() {
        loadPlaylists()
        Task { await loadExistingTracks() }
    }

    // MARK: - Directory

    var importDirectory: URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent(importFolderName, isDirectory: true)
    }

    private func ensureImportDirectory() throws {
        if !fileManager.fileExists(atPath: importDirectory.path) {
            try fileManager.createDirectory(at: importDirectory, withIntermediateDirectories: true)
        }
    }

    // MARK: - Playlist CRUD

    func createPlaylist(name: String) {
        playlists.append(Playlist(name: name))
        savePlaylists()
    }

    func addTrack(_ track: Track, to playlist: Playlist) {
        guard let index = playlists.firstIndex(where: { $0.id == playlist.id }) else { return }
        playlists[index].trackIDs.insert(track.id)
        savePlaylists()
        objectWillChange.send()
    }

    func removeTrack(_ track: Track, from playlist: Playlist) {
        guard let index = playlists.firstIndex(where: { $0.id == playlist.id }) else { return }
        playlists[index].trackIDs.remove(track.id)
        savePlaylists()
        objectWillChange.send()
    }

    // MARK: - Playlist Persistence

    private func savePlaylists() {
        do {
            let data = try JSONEncoder().encode(playlists)
            try data.write(to: playlistsFileURL, options: .atomic)
        } catch {
            print("Failed to save playlists: \(error)")
        }
    }

    private func loadPlaylists() {
        guard fileManager.fileExists(atPath: playlistsFileURL.path) else { return }
        do {
            let data = try Data(contentsOf: playlistsFileURL)
            playlists = try JSONDecoder().decode([Playlist].self, from: data)
        } catch {
            print("Failed to load playlists: \(error)")
        }
    }

    // MARK: - Track Loading

    func loadExistingTracks() async {
        do {
            try ensureImportDirectory()

            let urls = try fileManager.contentsOfDirectory(
                at: importDirectory,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: .skipsHiddenFiles
            )

            let audioURLs = urls
                .filter { $0.isFileURL }
                .sorted { a, b in
                    // Sort by modification date descending (newest first)
                    let dateA = (try? a.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                    let dateB = (try? b.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                    return dateA > dateB
                }

            let newTracks = await withTaskGroup(of: (Int, Track).self) { group -> [Track] in
                for (index, url) in audioURLs.enumerated() {
                    group.addTask {
                        let track = await self.buildTrack(from: url)
                        return (index, track)
                    }
                }
                var indexed: [(Int, Track)] = []
                for await pair in group { indexed.append(pair) }
                // Restore sort order after concurrent build
                return indexed.sorted { $0.0 < $1.0 }.map { $0.1 }
            }

            self.tracks = newTracks

        } catch {
            print("AudioLibrary load error: \(error)")
        }
    }

    // MARK: - Import (from file picker — security scoped)

    @MainActor
    func importTrack(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            try ensureImportDirectory()
            let destURL = uniqueDestinationURL(forOriginal: url)

            if url.standardizedFileURL != destURL.standardizedFileURL {
                try fileManager.copyItem(at: url, to: destURL)
            }

            // Reload so the new track appears immediately
            Task { await loadExistingTracks() }

        } catch {
            print("Import failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Import (from download — already in importDirectory)

    /// Call this after StreamService.downloadAudio saves a file to ImportedAudio/.
    /// Reloads tracks so the new download appears immediately in the library.
    func reloadAfterDownload() async {
        await loadExistingTracks()
    }

    // MARK: - Helpers

    private func uniqueDestinationURL(forOriginal url: URL) -> URL {
        let base = importDirectory.appendingPathComponent(url.lastPathComponent)
        if !fileManager.fileExists(atPath: base.path) { return base }
        let name = base.deletingPathExtension().lastPathComponent
        let ext  = base.pathExtension
        var counter = 1
        while true {
            let candidate = importDirectory.appendingPathComponent("\(name) (\(counter)).\(ext)")
            if !fileManager.fileExists(atPath: candidate.path) { return candidate }
            counter += 1
        }
    }

    private func buildTrack(from url: URL) async -> Track {
        let asset = AVURLAsset(url: url)
        var title    = url.deletingPathExtension().lastPathComponent
        var artist: String?
        var album: String?
        var duration: TimeInterval?

        do {
            let cmDuration = try await asset.load(.duration)
            duration = cmDuration.seconds

            let metadata = try await asset.load(.commonMetadata)
            for item in metadata {
                if item.commonKey?.rawValue == "title",
                   let v = try await item.load(.stringValue) { title = v }
                if item.commonKey?.rawValue == "artist",
                   let v = try await item.load(.stringValue) { artist = v }
                if item.commonKey?.rawValue == "albumName",
                   let v = try await item.load(.stringValue) { album = v }
            }
        } catch {
            print("Failed loading metadata:", error)
        }

        return Track(url: url, title: title, artist: artist, album: album, duration: duration)
    }
}
