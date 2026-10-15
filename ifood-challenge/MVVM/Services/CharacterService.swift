import Foundation

protocol CharacterServing {
    // Busca uma página; nextPage é a URL devolvida pela consulta anterior.
    func fetchPage(name: String, filters: CharacterFilters, nextPage: URL?) async throws -> CharacterPage
}

struct CharacterService: CharacterServing {
    private let cache: CodableStore<CharacterPage>
    private let session: URLSession

    init(cache: CodableStore<CharacterPage> = CodableStore(key: AppStrings.Cache.response),
         session: URLSession = .shared) {
        self.cache = cache
        self.session = session
    }

    func fetchPage(name: String, filters: CharacterFilters, nextPage: URL?) async throws -> CharacterPage {
        try Task.checkCancellation()
        let usesCache = nextPage == nil && name.isEmpty && filters.isEmpty
        if usesCache {
            do {
                if let page = try cache.load() { return page }
            } catch {
                // Respostas antigas sem metadados de paginação são recarregadas.
                cache.remove()
            }
        }
        var components = URLComponents()
        components.scheme = AppStrings.API.https
        components.host = AppStrings.API.host
        components.path = AppStrings.API.charactersPath
        var items = filters.queryItems
        if !name.isEmpty { items.insert(URLQueryItem(name: AppStrings.API.name, value: name), at: 0) }
        components.queryItems = items.isEmpty ? nil : items
        guard let url = nextPage ?? components.url,
              url.scheme == AppStrings.API.https,
              url.host == AppStrings.API.host,
              URLComponents(url: url, resolvingAgainstBaseURL: false)?.path == AppStrings.API.charactersPath else {
            throw URLError(.badURL)
        }
        let (data, response) = try await session.data(for: URLRequest(url: url, timeoutInterval: 20))
        try Task.checkCancellation()
        guard let response = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        if response.statusCode == 404 && nextPage == nil && !usesCache {
            return CharacterPage(results: [], info: .init(next: nil))
        }
        guard (200...299).contains(response.statusCode) else {
            throw NSError(domain: AppStrings.Identifier.characterErrorDomain, code: response.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: AppStrings.Message.characterHTTPError(response.statusCode)])
        }
        let page = try JSONDecoder().decode(CharacterPage.self, from: data)
        if usesCache { cache.save(page) }
        return page
    }
}
