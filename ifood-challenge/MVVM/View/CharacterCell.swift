import UIKit

final class CharacterCell: UITableViewCell {
    static let identifier = "CharacterCell"

    private let portrait = UIImageView()
    private let nameLabel = UILabel()
    private let statusDot = UIView()
    private let statusLabel = UILabel()
    private let originLabel = UILabel()
    private let locationLabel = UILabel()
    private let episodesLabel = UILabel()
    private var imageTask: URLSessionDataTask?
    private var representedID: Int?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .black
        selectionStyle = .none

        portrait.contentMode = .scaleAspectFill
        portrait.clipsToBounds = true
        portrait.layer.cornerRadius = 12
        portrait.backgroundColor = .darkGray

        nameLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        nameLabel.textColor = .white
        statusLabel.textColor = .white
        for label in [statusLabel, originLabel, locationLabel, episodesLabel] {
            label.font = .systemFont(ofSize: 14)
        }
        for label in [originLabel, locationLabel, episodesLabel] {
            label.textColor = .lightGray
        }
        for label in [nameLabel, statusLabel, originLabel, locationLabel, episodesLabel] {
            label.numberOfLines = 0
        }

        statusDot.layer.cornerRadius = 6
        let statusRow = UIStackView(arrangedSubviews: [statusDot, statusLabel])
        statusRow.axis = .horizontal
        statusRow.alignment = .center
        statusRow.spacing = 6

        let details = UIStackView(arrangedSubviews: [
            nameLabel, statusRow, originLabel, locationLabel, episodesLabel
        ])
        details.axis = .vertical
        details.spacing = 6
        details.setCustomSpacing(10, after: nameLabel)
        details.setCustomSpacing(10, after: statusRow)

        for subview in [portrait, details] {
            subview.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(subview)
        }
        let imageWidth = portrait.widthAnchor.constraint(equalToConstant: 136)
        imageWidth.priority = .defaultHigh
        NSLayoutConstraint.activate([
            portrait.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            portrait.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            imageWidth,
            portrait.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.36),
            portrait.heightAnchor.constraint(equalTo: portrait.widthAnchor),
            portrait.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12),
            details.leadingAnchor.constraint(equalTo: portrait.trailingAnchor, constant: 12),
            details.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            details.topAnchor.constraint(equalTo: portrait.topAnchor, constant: 3),
            details.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12),
            statusDot.widthAnchor.constraint(equalToConstant: 12),
            statusDot.heightAnchor.constraint(equalToConstant: 12)
        ])
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
        statusLabel.text = "\(character.status) · \(character.species) · \(character.gender)"
        originLabel.text = "Origem: \(character.origin.name)"
        locationLabel.text = "Localização: \(character.location.name)"
        episodesLabel.text = "\(character.episode.count) episódios no JSON enviado"

        switch character.status.lowercased() {
        case "alive": statusDot.backgroundColor = .systemGreen
        case "dead": statusDot.backgroundColor = .systemRed
        default: statusDot.backgroundColor = .systemGray
        }

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
