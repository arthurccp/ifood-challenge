import UIKit

protocol ImageLoading {
    // Obtém a imagem do cache ou faz o download e a armazena.
    func image(from url: URL) async throws -> UIImage
}

struct ImageLoader: ImageLoading {
    static let shared = ImageLoader()
    private let cache: any ImageCaching
    private let session: URLSession

    // Configura as dependências de cache e download das imagens.
    init(cache: any ImageCaching = ImageCache(), session: URLSession = .shared) {
        self.cache = cache
        self.session = session
    }

    // Obtém a imagem do cache ou faz o download e a armazena.
    func image(from url: URL) async throws -> UIImage {
        try Task.checkCancellation()
        if let image = await cache.image(for: url) {
            try Task.checkCancellation()
            return image
        }
        let (data, response) = try await session.data(for: URLRequest(url: url, timeoutInterval: 20))
        try Task.checkCancellation()
        guard let response = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        guard (200...299).contains(response.statusCode) else {
            throw NSError(domain: AppStrings.Identifier.imageErrorDomain, code: response.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: AppStrings.Message.httpError(response.statusCode)])
        }
        guard let image = UIImage(data: data) else { throw URLError(.cannotDecodeContentData) }
        await cache.save(image, data: data, for: url)
        try Task.checkCancellation()
        return image
    }
}
