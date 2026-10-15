import UIKit

final class CharacterCell: UITableViewCell {
    static let identifier = "CharacterCell"

    private let card = UIView()
    private let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
    private let portrait = UIImageView()
    private let nameLabel = UILabel()
    private var imageTask: URLSessionDataTask?
    private var representedID: Int?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .black
        selectionStyle = .none

        card.backgroundColor = UIColor(white: 0.045, alpha: 1)
        card.layer.cornerRadius = 16
        card.layer.borderWidth = 0.5
        card.layer.borderColor = UIColor(white: 0.09, alpha: 1).cgColor
        card.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(card)

        portrait.contentMode = .scaleAspectFill
        portrait.clipsToBounds = true
        portrait.layer.cornerRadius = 12
        portrait.backgroundColor = .darkGray

        nameLabel.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 22, weight: .bold))
        nameLabel.adjustsFontForContentSizeCategory = true
        nameLabel.textColor = .white
        nameLabel.numberOfLines = 2
        nameLabel.lineBreakMode = .byTruncatingTail

        chevron.tintColor = UIColor(white: 0.35, alpha: 1)
        chevron.contentMode = .scaleAspectFit
        chevron.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)
        chevron.isAccessibilityElement = false
        for subview in [portrait, nameLabel, chevron] {
            subview.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(subview)
        }
        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            portrait.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 8),
            portrait.widthAnchor.constraint(equalToConstant: 76),
            portrait.heightAnchor.constraint(equalTo: portrait.widthAnchor),
            portrait.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            portrait.topAnchor.constraint(greaterThanOrEqualTo: card.topAnchor, constant: 6),
            portrait.bottomAnchor.constraint(lessThanOrEqualTo: card.bottomAnchor, constant: -6),
            nameLabel.leadingAnchor.constraint(equalTo: portrait.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -12),
            nameLabel.centerYAnchor.constraint(equalTo: portrait.centerYAnchor),
            nameLabel.topAnchor.constraint(greaterThanOrEqualTo: card.topAnchor, constant: 12),
            nameLabel.bottomAnchor.constraint(lessThanOrEqualTo: card.bottomAnchor, constant: -12),
            chevron.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            chevron.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            chevron.widthAnchor.constraint(equalToConstant: 12),
            chevron.heightAnchor.constraint(equalToConstant: 20)
        ])
        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityHint = "Abre os detalhes do personagem"
    }

    required init?(coder: NSCoder) {
        fatalError("Use init(style:reuseIdentifier:)")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageTask?.cancel()
        representedID = nil
        portrait.image = nil
    }

    func configure(with character: Result) {
        imageTask?.cancel()
        representedID = character.id
        portrait.image = nil
        nameLabel.text = character.name
        accessibilityLabel = character.name
        guard let url = URL(string: character.image) else { return }
        imageTask = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                guard let self, self.representedID == character.id else { return }
                self.portrait.image = image
            }
        }
        imageTask?.resume()
    }
}
