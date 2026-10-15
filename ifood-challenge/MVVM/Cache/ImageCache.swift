import UIKit
import CryptoKit

protocol ImageCaching: Actor {
    // Procura a imagem na memória e depois no cache em disco.
    func image(for url: URL) -> UIImage?
    // Armazena a imagem na memória e tenta salvar seus dados em disco.
    func save(_ image: UIImage, data: Data, for url: URL)
}

actor ImageCache: ImageCaching {
    private let memory = NSCache<NSURL, UIImage>()
    private let directory: URL?
    private let fileManager: FileManager

    // Configura o diretório de imagens e o limite do cache em memória.
    init(directory: URL? = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
            .first?.appendingPathComponent(AppStrings.Cache.imageDirectory, isDirectory: true),
         fileManager: FileManager = .default) {
        self.directory = directory
        self.fileManager = fileManager
        memory.totalCostLimit = 20 * 1024 * 1024
    }

    // Procura a imagem na memória e depois no cache em disco.
    func image(for url: URL) -> UIImage? {
        if let image = memory.object(forKey: url as NSURL) { return image }
        guard let file = fileURL(for: url), let data = try? Data(contentsOf: file),
              let image = UIImage(data: data) else { return nil }
        cacheInMemory(image, for: url)
        return image
    }

    // Armazena a imagem na memória e tenta salvar seus dados em disco.
    func save(_ image: UIImage, data: Data, for url: URL) {
        cacheInMemory(image, for: url)
        guard let directory, let file = fileURL(for: url) else { return }
        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            try data.write(to: file, options: .atomic)
        } catch {
            // A foto continua disponível na memória se o cache em disco falhar.
        }
    }

    // Gera um caminho de cache estável a partir da URL da imagem.
    private func fileURL(for url: URL) -> URL? {
        let filename = SHA256.hash(data: Data(url.absoluteString.utf8))
            .map { String(format: AppStrings.Cache.hexByteFormat, $0) }.joined()
        return directory?.appendingPathComponent(filename)
    }

    // Armazena a imagem em memória contabilizando seu custo em bytes.
    private func cacheInMemory(_ image: UIImage, for url: URL) {
        let cost = image.cgImage.map { $0.bytesPerRow * $0.height } ?? 0
        memory.setObject(image, forKey: url as NSURL, cost: cost)
    }
}
