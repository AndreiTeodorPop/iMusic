import Foundation

struct LyricsResult {
    let original: String
    let translated: String?
    let language: String

    /// True if the lyrics are already in English (or translation was unavailable).
    var isEnglish: Bool { language == "en" || (translated == nil && language != "en") }

    /// The English text to display by default.
    var englishText: String { translated ?? original }
}

actor LyricsService {
    static let shared = LyricsService()

    private var cache: [String: LyricsResult] = [:]

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
            let decoded = try JSONDecoder().decode(Response.self, from: data)
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

    private struct Response: Decodable {
        let lyrics: String
        let translated: String?
        let language: String
    }
}
