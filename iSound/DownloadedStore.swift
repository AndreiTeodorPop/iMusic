import Foundation

struct DownloadedStore {
    private static let key = "DownloadedYouTubeIDs"

    static func all() -> Set<String> {
        let arr = UserDefaults.standard.array(forKey: key) as? [String] ?? []
        return Set(arr)
    }

    static func contains(_ id: String) -> Bool {
        all().contains(id)
    }

    static func add(_ id: String) {
        var set = all()
        set.insert(id)
        UserDefaults.standard.set(Array(set), forKey: key)
    }

    static func remove(_ id: String) {
        var set = all()
        set.remove(id)
        UserDefaults.standard.set(Array(set), forKey: key)
    }
}
