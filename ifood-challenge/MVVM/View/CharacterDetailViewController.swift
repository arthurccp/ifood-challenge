import UIKit

final class CharacterDetailViewController: UIViewController {
    private let character: Result
    private let portrait = UIImageView()
    private var imageTask: URLSessionDataTask?

    init(character: Result) {
        self.character = character
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("Use init(character:)")
    }

    deinit {
        imageTask?.cancel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupContent()
        loadImage()
    }

    private func setupContent() {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        portrait.contentMode = .scaleAspectFill
        portrait.backgroundColor = UIColor(white: 0.045, alpha: 1)
        portrait.layer.cornerRadius = 20
        portrait.clipsToBounds = true
        portrait.isAccessibilityElement = true
        portrait.accessibilityLabel = "Foto de \(character.name)"

        let photoContainer = UIView()
        portrait.translatesAutoresizingMaskIntoConstraints = false
        photoContainer.addSubview(portrait)
        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(systemName: "chevron.left", withConfiguration:
            UIImage.SymbolConfiguration(pointSize: 21, weight: .medium)), for: .normal)
        backButton.tintColor = .white
        backButton.backgroundColor = UIColor(white: 0.08, alpha: 0.9)
        backButton.layer.cornerRadius = 22
        backButton.accessibilityLabel = "Voltar"
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

        let fields: [(String, String, String)] = [
            ("ID", String(character.id), "number"),
            ("Status", character.status, "circle.fill"),
            ("Espécie", character.species, "person.2"),
            ("Tipo", character.type.isEmpty ? "Não informado" : character.type, "fossil.shell"),
            ("Gênero", character.gender, "person"),
            ("Origem", placeName(character.origin.name), "globe.americas"),
            ("Localização", placeName(character.location.name), "mappin.and.ellipse")
        ]
        for (title, value, symbol) in fields {
            information.addArrangedSubview(makeCard(title, value: value, symbol: symbol))
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

    @objc private func goBack() {
        navigationController?.popViewController(animated: true)
    }

    private func placeName(_ value: String) -> String {
        value.isEmpty || value.lowercased() == "unknown" ? "Desconhecida" : value
    }

    private func makeCard(_ title: String, value: String, symbol: String) -> UIView {
        let card = UIView()
        card.backgroundColor = UIColor(white: 0.045, alpha: 1)
        card.layer.cornerRadius = 16
        card.layer.borderWidth = 0.5
        card.layer.borderColor = UIColor(white: 0.09, alpha: 1).cgColor
        card.isAccessibilityElement = true
        card.accessibilityLabel = "\(title): \(value)"

        let iconContainer = UIView()
        iconContainer.backgroundColor = UIColor(white: 0.10, alpha: 1)
        iconContainer.layer.cornerRadius = 12
        let icon = UIImageView(image: UIImage(systemName: symbol))
        icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 23, weight: .regular)
        icon.contentMode = .scaleAspectFit
        icon.tintColor = UIColor(red: 0.7, green: 0.85, blue: 0.95, alpha: 1)
        if title == "Status" {
            switch character.status.lowercased() {
            case "alive": icon.tintColor = .systemGreen
            case "dead": icon.tintColor = .systemRed
            default: icon.tintColor = .systemGray
            }
            icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 16)
        }
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

    private func loadImage() {
        guard let url = URL(string: character.image) else { return }
        imageTask = URLSession.shared.dataTask(with: url) { [weak self] data, response, _ in
            guard let response = response as? HTTPURLResponse,
                  (200...299).contains(response.statusCode),
                  let data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self?.portrait.image = image
            }
        }
        imageTask?.resume()
    }
}
