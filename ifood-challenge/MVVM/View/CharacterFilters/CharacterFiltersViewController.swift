import UIKit

final class CharacterFiltersViewController: UIViewController {
    var onApply: ((CharacterFilters) -> Void)?
    private var draft: CharacterFilters
    private var options: [(button: UIButton, keyPath: WritableKeyPath<CharacterFilters, String?>, value: String?)] = []

    // Inicializa o rascunho com os filtros atualmente aplicados.
    init(filters: CharacterFilters = CharacterFilters()) {
        draft = filters
        super.init(nibName: nil, bundle: nil)
    }

    // Impede a criação pelo storyboard; este componente exige inicialização programática.
    required init?(coder: NSCoder) {
        fatalError(AppStrings.Diagnostic.filtersInitializer)
    }

    // Configura a apresentação modal e monta os controles de filtros.
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .dark
        view.backgroundColor = UIColor(white: 0.085, alpha: 1)
        if let sheet = sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
        }
        setupContent()
    }

    // Organiza o cabeçalho, as opções e os botões de aplicar e limpar.
    private func setupContent() {
        let title = UILabel()
        title.text = AppStrings.Text.filters
        title.font = .preferredFont(forTextStyle: .headline)
        title.textColor = .white
        title.adjustsFontForContentSizeCategory = true
        title.accessibilityTraits = .header
        title.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(title)

        let close = UIButton(type: .system)
        close.setImage(UIImage(systemName: AppStrings.Symbol.close, withConfiguration:
            UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)), for: .normal)
        close.tintColor = .white
        close.backgroundColor = UIColor(white: 0.14, alpha: 1)
        close.layer.cornerRadius = 22
        close.accessibilityLabel = AppStrings.Text.closeFilters
        close.addTarget(self, action: #selector(closeFilters), for: .touchUpInside)
        close.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(close)

        let apply = makeAction(AppStrings.Text.applyFilters, primary: true)
        apply.addTarget(self, action: #selector(applyFilters), for: .touchUpInside)
        let clear = makeAction(AppStrings.Text.clearFilters, primary: false)
        clear.addTarget(self, action: #selector(clearFilters), for: .touchUpInside)
        let actions = UIStackView(arrangedSubviews: [apply, clear])
        actions.axis = .vertical
        actions.spacing = 6
        actions.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(actions)

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        let sections = UIStackView(arrangedSubviews: CharacterFilterGroup.allCases.map { group in
            makeSection(group.title, content: makeOptions(group.options, keyPath: group.keyPath))
        })
        sections.axis = .vertical
        sections.spacing = 14
        sections.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(sections)
        updateSelections()

        NSLayoutConstraint.activate([
            title.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            title.centerYAnchor.constraint(equalTo: close.centerYAnchor),
            title.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 60),
            title.trailingAnchor.constraint(lessThanOrEqualTo: close.leadingAnchor, constant: -8),
            close.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 14),
            close.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            close.widthAnchor.constraint(equalToConstant: 44),
            close.heightAnchor.constraint(equalToConstant: 44),
            actions.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            actions.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            actions.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            scrollView.topAnchor.constraint(equalTo: close.bottomAnchor, constant: 14),
            scrollView.leadingAnchor.constraint(equalTo: actions.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: actions.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: actions.topAnchor, constant: -14),
            sections.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            sections.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            sections.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            sections.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            sections.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }

    // Agrupa o título e os controles de uma categoria de filtro.
    private func makeSection(_ title: String, content: UIView) -> UIStackView {
        let label = UILabel()
        label.text = title
        label.font = UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: .systemFont(ofSize: 13, weight: .semibold))
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .lightGray
        label.accessibilityTraits = .header
        let stack = UIStackView(arrangedSubviews: [label, content])
        stack.axis = .vertical
        stack.spacing = 5
        return stack
    }

    // Cria os botões de seleção para as opções de uma categoria.
    private func makeOptions(
        _ options: [CharacterFilterOption], keyPath: WritableKeyPath<CharacterFilters, String?>
    ) -> UIScrollView {
        let scroll = UIScrollView()
        scroll.showsHorizontalScrollIndicator = false
        let row = UIStackView()
        row.spacing = 5
        row.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(row)
        for option in options {
            let title = option.title
            let value = option.value
            let button = makeAction(title, primary: false)
            var config = UIButton.Configuration.plain()
            config.title = title
            config.contentInsets = NSDirectionalEdgeInsets(top: 7, leading: 8, bottom: 7, trailing: 8)
            button.configuration = config
            button.configurationUpdateHandler = { button in
                var config = button.configuration
                config?.baseForegroundColor = button.isSelected ? .black : .white
                let font = UIFontMetrics(forTextStyle: .subheadline).scaledFont(for:
                    .systemFont(ofSize: 11, weight: button.isSelected ? .semibold : .regular))
                config?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
                    var attributes = attributes
                    attributes.font = font
                    return attributes
                }
                button.configuration = config
            }
            button.addAction(UIAction { [weak self] _ in
                self?.draft[keyPath: keyPath] = value
                self?.updateSelections()
            }, for: .touchUpInside)
            self.options.append((button, keyPath, value))
            row.addArrangedSubview(button)
        }
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            row.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            row.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            row.heightAnchor.constraint(equalTo: scroll.frameLayoutGuide.heightAnchor)
        ])
        return scroll
    }

    // Cria um botão com o estilo visual padrão da tela de filtros.
    private func makeAction(_ title: String, primary: Bool) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(primary ? .black : .lightGray, for: .normal)
        button.titleLabel?.font = UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: .systemFont(ofSize: 13, weight: .semibold))
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.backgroundColor = primary ? .white : UIColor(white: 0.14, alpha: 1)
        button.layer.cornerRadius = 12
        button.layer.borderWidth = primary ? 0 : 0.5
        button.layer.borderColor = UIColor(white: 0.23, alpha: 1).cgColor
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 30).isActive = true
        return button
    }

    // Atualiza as cores e a acessibilidade conforme o rascunho selecionado.
    private func updateSelections() {
        for option in options {
            let selected = draft[keyPath: option.keyPath] == option.value
            option.button.isSelected = selected
            option.button.backgroundColor = selected ? .white : UIColor(white: 0.14, alpha: 1)
            option.button.layer.borderWidth = selected ? 0 : 0.5
            option.button.accessibilityTraits = selected ? [.button, .selected] : .button
        }
    }

    // Redefine o rascunho para Qualquer sem aplicar mudanças à lista.
    @objc private func clearFilters() {
        draft = CharacterFilters()
        updateSelections()
    }

    // Fecha a tela e entrega os filtros confirmados ao callback.
    @objc private func applyFilters() {
        let filters = draft
        let callback = onApply
        dismiss(animated: true) { callback?(filters) }
    }

    // Fecha a tela sem confirmar as alterações no rascunho.
    @objc private func closeFilters() {
        dismiss(animated: true)
    }
}
