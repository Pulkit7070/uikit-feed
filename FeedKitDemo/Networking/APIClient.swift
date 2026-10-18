import Foundation

/// The one thing the feed needs from the network. View models depend on this
/// protocol instead of `APIClient` directly, so tests can pass in a fake.
protocol PhotoFetching: Sendable {
    func fetchPhotos(page: Int, limit: Int) async throws -> [Photo]
}

enum APIError: Error, Equatable {
    case badStatusCode(Int)
}

struct APIClient: PhotoFetching {
    private let session: URLSession
    private let baseURL = URL(string: "https://picsum.photos/v2/list")!

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchPhotos(page: Int, limit: Int) async throws -> [Photo] {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit)),
        ]
        return try await get(components.url!)
    }

    /// Downloads `url` and decodes the JSON body into any `Decodable` type.
    private func get<T: Decodable>(_ url: URL) async throws -> T {
        let (data, response) = try await session.data(from: url)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw APIError.badStatusCode(http.statusCode)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}
