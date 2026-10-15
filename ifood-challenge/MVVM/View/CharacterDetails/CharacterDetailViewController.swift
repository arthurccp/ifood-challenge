import UIKit

final class CharacterDetailViewController: UIViewController {
    private let character: Result
    private let portrait = RemoteImageView()

    // Recebe o personagem selecionado para apresentar seus detalhes.
    init(character: Result) {
        self.character = character
        super.init(nibName: nil, bundle: nil)
    }

    // Impede a criação pelo storyboard; este componente exige inicialização programática.
    required init?(coder: NSCoder) {
        fatalError(AppStrings.Diagnostic.characterInitializer)
    }

    // Oculta a barra nativa para usar o botão de voltar sobre a foto.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    // Monta os detalhes e inicia o carregamento da foto do personagem.
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupContent()
        portrait.load(character.image)
    }

    // Organiza a foto, o nome e os cards em uma área com rolagem.
    private func setupContent() {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        portrait.contentMode = .scaleAspectFill
        portrait.backgroundColor = UIColor(white: 0.045, alpha: 1)
        portrait.layer.cornerRadius = 20
        portrait.clipsToBounds = true
        portrait.isAccessibilityElement = true
        portrait.accessibilityLabel = AppStrings.Message.portrait(character.name)

        let photoContainer = UIView()
        portrait.translatesAutoresizingMaskIntoConstraints = false
        photoContainer.addSubview(portrait)
        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(systemName: AppStrings.Symbol.back, withConfiguration:
            UIImage.SymbolConfiguration(pointSize: 21, weight: .medium)), for: .normal)
        backButton.tintColor = .white
        backButton.backgroundColor = UIColor(white: 0.08, alpha: 0.9)
        backButton.layer.cornerRadius = 22
        backButton.accessibilityLabel = AppStrings.Text.back
        backButton.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        photoContainer.addSubview(backButton)

        let nameLabel = UILabel()
        nameLabel.text = character.name
        nameLabel.font = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for:
            .systemFont(ofSize: 36, weight: .bold))
        nameLabel.adjustsFontForContentSizeCategory = true
        nameLabel.textColor = .white
        nameLabel.numberOfLines = 0
        nameLabel.accessibilityTraits = .header

        let information = UIStackView(arrangedSubviews: [nameLabel])
        information.axis = .vertical
        information.spacing = 8
        information.setCustomSpacing(16, after: nameLabel)
        information.isLayoutMarginsRelativeArrangement = true
        information.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4)

        let fields: [(String, String, String, UIColor, CGFloat)] = [
            (AppStrings.Text.id, String(character.id), AppStrings.Symbol.id, UIColor(red: 0.7, green: 0.85, blue: 0.95, alpha: 1), 23),
            (AppStrings.Text.status, character.status, AppStrings.Symbol.status, statusColor, 16),
            (AppStrings.Text.species, character.species, AppStrings.Symbol.species, UIColor(red: 0.7, green: 0.85, blue: 0.95, alpha: 1), 23),
            (AppStrings.Text.type, character.type.isEmpty ? AppStrings.Text.unspecified : character.type, AppStrings.Symbol.type, UIColor(red: 0.7, green: 0.85, blue: 0.95, alpha: 1), 23),
            (AppStrings.Text.gender, character.gender, AppStrings.Symbol.gender, UIColor(red: 0.7, green: 0.85, blue: 0.95, alpha: 1), 23),
            (AppStrings.Text.origin, placeName(character.origin.name), AppStrings.Symbol.origin, UIColor(red: 0.7, green: 0.85, blue: 0.95, alpha: 1), 23),
            (AppStrings.Text.location, placeName(character.location.name), AppStrings.Symbol.location, UIColor(red: 0.7, green: 0.85, blue: 0.95, alpha: 1), 23)
        ]
        for (title, value, symbol, color, size) in fields {
            information.addArrangedSubview(makeCard(title, value: value, symbol: symbol, color: color, iconSize: size))
        }

        let stack = UIStackView(arrangedSubviews: [photoContainer, information])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -24),
            photoContainer.heightAnchor.constraint(equalTo: photoContainer.widthAnchor, multiplier: 0.75),
            portrait.topAnchor.constraint(equalTo: photoContainer.topAnchor),
            portrait.leadingAnchor.constraint(equalTo: photoContainer.leadingAnchor),
            portrait.trailingAnchor.constraint(equalTo: photoContainer.trailingAnchor),
            portrait.bottomAnchor.constraint(equalTo: photoContainer.bottomAnchor),
            backButton.topAnchor.constraint(equalTo: photoContainer.topAnchor, constant: 8),
            backButton.leadingAnchor.constraint(equalTo: photoContainer.leadingAnchor, constant: 8),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    // Retorna à tela anterior pela pilha de navegação.
    @objc private func goBack() {
        navigationController?.popViewController(animated: true)
    }

    // Substitui nomes de lugares vazios ou desconhecidos por um texto legível.
    private func placeName(_ value: String) -> String {
        value.isEmpty || value.lowercased() == AppStrings.API.unknown ? AppStrings.Text.unknownPlace : value
    }

    private var statusColor: UIColor {
        switch character.status.lowercased() {
        case AppStrings.API.alive: return .systemGreen
        case AppStrings.API.dead: return .systemRed
        default: return .systemGray
        }
    }

    // Cria um card acessível com título, valor e aparência do ícone recebida.
    private func makeCard(_ title: String, value: String, symbol: String, color: UIColor, iconSize: CGFloat) -> UIView {
        let card = UIView()
        card.backgroundColor = UIColor(white: 0.045, alpha: 1)
        card.layer.cornerRadius = 16
        card.layer.borderWidth = 0.5
        card.layer.borderColor = UIColor(white: 0.09, alpha: 1).cgColor
        card.isAccessibilityElement = true
        card.accessibilityLabel = AppStrings.Message.detail(title: title, value: value)

        let iconContainer = UIView()
        iconContainer.backgroundColor = UIColor(white: 0.10, alpha: 1)
        iconContainer.layer.cornerRadius = 12
        let icon = UIImageView(image: UIImage(systemName: symbol))
        icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: iconSize, weight: .regular)
        icon.contentMode = .scaleAspectFit
        icon.tintColor = color
        icon.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.addSubview(icon)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFontMetrics(forTextStyle: .caption1).scaledFont(for: .systemFont(ofSize: 13))
        titleLabel.textColor = .lightGray
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 17, weight: .medium))
        valueLabel.textColor = .white
        for label in [titleLabel, valueLabel] {
            label.numberOfLines = 0
            label.adjustsFontForContentSizeCategory = true
        }
        let text = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        text.axis = .vertical
        text.spacing = 4
        for item in [iconContainer, text] {
            item.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(item)
        }
        NSLayoutConstraint.activate([
            card.heightAnchor.constraint(greaterThanOrEqualToConstant: 60),
            iconContainer.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            iconContainer.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: 44),
            iconContainer.heightAnchor.constraint(equalToConstant: 44),
            iconContainer.topAnchor.constraint(greaterThanOrEqualTo: card.topAnchor, constant: 8),
            iconContainer.bottomAnchor.constraint(lessThanOrEqualTo: card.bottomAnchor, constant: -8),
            icon.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            icon.widthAnchor.constraint(lessThanOrEqualToConstant: 28),
            icon.heightAnchor.constraint(lessThanOrEqualToConstant: 28),
            text.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 16),
            text.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            text.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            text.topAnchor.constraint(greaterThanOrEqualTo: card.topAnchor, constant: 10),
            text.bottomAnchor.constraint(lessThanOrEqualTo: card.bottomAnchor, constant: -10)
        ])
        return card
    }

}
