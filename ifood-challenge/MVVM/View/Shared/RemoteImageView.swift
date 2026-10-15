import UIKit

final class RemoteImageView: UIImageView {
    private let imageLoader: any ImageLoading
    private var imageTask: Task<Void, Never>?

    // Inicializa a imagem com um carregador injetado ou com o padrão do app.
    init(imageLoader: any ImageLoading = ImageLoader.shared) {
        self.imageLoader = imageLoader
        super.init(frame: .zero)
    }

    // Inicializa a view decodificada com o carregador padrão.
    required init?(coder: NSCoder) {
        imageLoader = ImageLoader.shared
        super.init(coder: coder)
    }

    // Cancela o carregamento pendente ao liberar a view.
    deinit { imageTask?.cancel() }

    // Carrega a foto e mantém o placeholder em caso de falha.
    func load(_ value: String) {
        reset()
        guard let url = URL(string: value), [AppStrings.API.https, AppStrings.API.http].contains(url.scheme) else {
            return
        }
        imageTask = Task { [weak self, imageLoader] in
            do {
                let image = try await imageLoader.image(from: url)
                try Task.checkCancellation()
                self?.image = image
                self?.contentMode = .scaleAspectFill
            } catch {
                // Mantém o placeholder quando o download falha ou é cancelado.
            }
        }
    }

    // Cancela a tarefa atual e apresenta o placeholder da imagem.
    func reset() {
        imageTask?.cancel()
        imageTask = nil
        image = UIImage(systemName: AppStrings.Symbol.portrait, withConfiguration:
            UIImage.SymbolConfiguration(pointSize: 32, weight: .light))
        tintColor = .lightGray
        contentMode = .center
    }
}
