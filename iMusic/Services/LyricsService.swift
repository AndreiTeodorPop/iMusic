import Foundation

struct LyricsResult {
    let original: String
    let translated: String?
    let language: String

    var isEnglish: Bool { language == "en" || (translated == nil && language != "en") }
    var englishText: String { translated ?? original }
}

struct LyricLine: Identifiable {
    let id: Int
    let timestamp: TimeInterval
    let text: String
}

actor LyricsService {
    static let shared = LyricsService()

    private var cache: [String: LyricsResult] = [:]
    private var syncedCache: [String: [LyricLine]] = [:]

    func fetch(title: String, artist: String) async -> LyricsResult? {
        let key = "\(artist)|\(title)".lowercased()
        if let hit = cache[key] { return hit }

        var comps = URLComponents(string: "https://imusic-production-4e58.up.railway.app/lyrics")!
        comps.queryItems = [
            URLQueryItem(name: "title",  value: title),
            URLQueryItem(name: "artist", value: artist),
        ]
        guard let url = comps.url else { return nil }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            let decoded = try JSONDecoder().decode(PlainResponse.self, from: data)
            let result = LyricsResult(
                original:   decoded.lyrics,
                translated: decoded.translated,
                language:   decoded.language
            )
            cache[key] = result
            return result
        } catch {
            return nil
        }
    }

    func fetchSynced(title: String, artist: String) async -> [LyricLine]? {
        let key = "\(artist)|\(title)".lowercased()
        if let hit = syncedCache[key] { return hit.isEmpty ? nil : hit }

        var comps = URLComponents(string: "https://lrclib.net/api/search")!
        comps.queryItems = [
            URLQueryItem(name: "track_name",  value: title),
            URLQueryItem(name: "artist_name", value: artist),
        ]
        guard let url = comps.url else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let results = try JSONDecoder().decode([LRCLibResult].self, from: data)

            // Pick the first result that has real per-line timestamps
            for result in results {
                guard let lrc = result.syncedLyrics, !lrc.isEmpty else { continue }
                let lines = parseLRC(lrc)
                if lines.count > 3 {
                    syncedCache[key] = lines
                    return lines
                }
            }
        } catch {}

        syncedCache[key] = []
        return nil
    }

    private func parseLRC(_ lrc: String) -> [LyricLine] {
        var lines: [LyricLine] = []
        var index = 0

        for rawLine in lrc.components(separatedBy: "\n") {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            // Match [mm:ss.xx] or [mm:ss.xxx]
            guard line.hasPrefix("[") else { continue }

            var cursor = line.startIndex
            while cursor < line.endIndex, line[cursor] == "[" {
                guard let closeRange = line.range(of: "]", range: cursor..<line.endIndex) else { break }
                let tag = String(line[line.index(after: cursor)..<closeRange.lowerBound])
                cursor = closeRange.upperBound

                // Skip metadata tags like [ti:...], [ar:...], etc.
                if tag.contains(":") {
                    let parts = tag.split(separator: ":", maxSplits: 1)
                    guard parts.count == 2,
                          let minutes = Double(parts[0]),
                          let secondsFull = Double(parts[1]) else { continue }
                    let timestamp = minutes * 60 + secondsFull
                    let text = String(line[cursor...]).trimmingCharacters(in: .whitespaces)
                    lines.append(LyricLine(id: index, timestamp: timestamp, text: text))
                    index += 1
                }
            }
        }

        return lines.sorted { $0.timestamp < $1.timestamp }
    }

    private struct PlainResponse: Decodable {
        let lyrics: String
        let translated: String?
        let language: String
    }

    private struct LRCLibResult: Decodable {
        let syncedLyrics: String?
    }
}
