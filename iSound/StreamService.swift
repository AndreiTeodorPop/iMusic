//
//  StreamService.swift
//  iSound
//
//  Created by Pop Andrei on 23.03.2026.
//

import Foundation

struct StreamService {
    static let baseURL = "http://172.20.10.2:8080"

    struct StreamResponse: Decodable {
        let url: String
        let title: String
        let artist: String
        let duration: TimeInterval
    }

    static func getStreamURL(for videoId: String) async throws -> StreamResponse {
        let url = URL(string: "\(baseURL)/stream?id=\(videoId)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(StreamResponse.self, from: data)
    }
    
    static func downloadAudio(for videoId: String, title: String) async throws -> URL {
        let url = URL(string: "\(baseURL)/download?id=\(videoId)")!

        let (tempURL, response) = try await URLSession.shared.download(from: url)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw StreamError.downloadFailed
        }

        // Move to Documents/ImportedAudio so AudioLibrary picks it up
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let importDir = docs.appendingPathComponent("ImportedAudio", isDirectory: true)
        try FileManager.default.createDirectory(at: importDir, withIntermediateDirectories: true)

        let sanitized = title.replacingOccurrences(of: "/", with: "-")
        let destURL = importDir.appendingPathComponent("\(sanitized).m4a")

        if FileManager.default.fileExists(atPath: destURL.path) {
            try FileManager.default.removeItem(at: destURL)
        }
        try FileManager.default.moveItem(at: tempURL, to: destURL)

        return destURL
    }

    enum StreamError: LocalizedError {
        case downloadFailed

        var errorDescription: String? {
            "Download failed. Make sure the server is running."
        }
    }
}
