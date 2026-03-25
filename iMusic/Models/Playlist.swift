import Foundation
import SwiftUI

struct Playlist: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var trackIDs: Set<UUID>
    let createdAt: Date

    init(id: UUID = UUID(), name: String, trackIDs: Set<UUID> = [], createdAt: Date = .now) {
        self.id        = id
        self.name      = name
        self.trackIDs  = trackIDs
        self.createdAt = createdAt
    }
}

