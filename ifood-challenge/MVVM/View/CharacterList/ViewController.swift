//
//  ViewController.swift
//  ifood-challenge
//
//  Created by Arthur Silva on 14/10/26.
//

import UIKit

final class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let tableView = UITableView()
    private let heading = UIStackView()
    private let searchField = UISearchTextField()
    private let viewModel: CharacterListViewModel
    private var renderedListID: UUID?
    private var isRendering = false
    private var pendingPosition: CharacterListPosition?

    // Inicializa a tela com um ViewModel injetado ou com a implementação padrão.
    init(viewModel: CharacterListViewModel? = nil) {
        self.viewModel = viewModel ?? CharacterListViewModel()
        super.init(nibName: nil, bundle: nil)
    }

    // Inicializa a tela do storyboard com o ViewModel padrão.
    required init?(coder: NSCoder) {
        viewModel = CharacterListViewModel()
        super.init(coder: coder)
    }

    // Remove os observadores de notificações ao liberar a tela.
    deinit { NotificationCenter.default.removeObserver(self) }

    // Configura a interface, conecta o ViewModel e inicia a restauração ou consulta.
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backButtonDisplayMode = .minimal
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .black
        appearance.shadowColor = .clear
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = .white
        
        setupHeader()
        setupTableView()
        NotificationCenter.default.addObserver(self, selector: #selector(saveListPosition),
                                               name: UIApplication.didEnterBackgroundNotification, object: nil)
        viewModel.onChange = { [weak self] in self?.render() }
        viewModel.start()
    }


    // Oculta a barra de navegação ao apresentar a listagem.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    // Restaura uma única vez a posição da lista após calcular o layout.
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let position = pendingPosition, tableView.bounds.height > 0,
              let row = viewModel.characters.firstIndex(where: { $0.id == position.characterID }) else { return }
        // Consume before layout to avoid restoring again on rotation or returning from details.
        pendingPosition = nil
        let indexPath = IndexPath(row: row, section: 0)
        tableView.scrollToRow(at: indexPath, at: .top, animated: false)
        tableView.layoutIfNeeded()
        let rect = tableView.rectForRow(at: indexPath)
        let offset = min(max(CGFloat(position.offset), 0), max(rect.height - 1, 0))
        let minimum = -tableView.adjustedContentInset.top
        let maximum = max(minimum, tableView.contentSize.height - tableView.bounds.height + tableView.adjustedContentInset.bottom)
        let target = rect.minY + offset - tableView.adjustedContentInset.top
        tableView.setContentOffset(CGPoint(x: 0, y: min(max(target, minimum), maximum)), animated: false)
    }

    // Registra a posição da lista antes de sair da tela.
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        saveListPosition()
    }

    // Calcula o personagem visível e encaminha a posição ao ViewModel.
    @objc private func saveListPosition() {
        guard pendingPosition == nil,
              let indexPath = tableView.indexPathsForVisibleRows?.min(),
              viewModel.characters.indices.contains(indexPath.row) else { return }
        let rect = tableView.rectForRow(at: indexPath)
        let offset = max(0, tableView.contentOffset.y + tableView.adjustedContentInset.top - rect.minY)
        viewModel.savePosition(characterID: viewModel.characters[indexPath.row].id, offset: Double(offset))
    }

    // Salva a posição quando o arraste termina sem desaceleração.
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate { saveListPosition() }
    }

    // Salva a posição quando a lista termina de desacelerar.
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        saveListPosition()
    }

    // Monta o título, o botão de filtros e o campo de pesquisa.
    private func setupHeader() {
        let titleLabel = UILabel()
        titleLabel.text = AppStrings.Text.characters
        titleLabel.font = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: .systemFont(ofSize: 34, weight: .bold))
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.75
        titleLabel.textColor = .white

        let filterButton = UIButton(type: .system)
        filterButton.setImage(UIImage(systemName: AppStrings.Symbol.filters), for: .normal)
        filterButton.tintColor = .white
        filterButton.backgroundColor = UIColor(red: 0.065, green: 0.075, blue: 0.095, alpha: 1)
        filterButton.layer.cornerRadius = 22
        filterButton.accessibilityLabel = AppStrings.Text.filters
        filterButton.addTarget(self, action: #selector(openFilters), for: .touchUpInside)
        heading.addArrangedSubview(titleLabel)
        heading.addArrangedSubview(filterButton)
        heading.alignment = .center
        heading.spacing = 12

        searchField.addTarget(self, action: #selector(searchTextChanged), for: .editingChanged)
        searchField.clearButtonMode = .whileEditing
        searchField.placeholder = AppStrings.Text.searchPlaceholder
        searchField.font = .preferredFont(forTextStyle: .body)
        searchField.adjustsFontForContentSizeCategory = true
        searchField.textColor = .white
        searchField.backgroundColor = UIColor(red: 0.065, green: 0.075, blue: 0.095, alpha: 1)
        searchField.borderStyle = .none
        searchField.layer.cornerRadius = 12
        searchField.clipsToBounds = true
        searchField.autocorrectionType = .no
        searchField.autocapitalizationType = .none
        searchField.overrideUserInterfaceStyle = .dark
        searchField.leftView?.tintColor = .lightGray
        for item in [heading, searchField] {
            item.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(item)
        }
        NSLayoutConstraint.activate([
            heading.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            heading.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 14),
            heading.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -14),
            filterButton.widthAnchor.constraint(equalToConstant: 44),
            filterButton.heightAnchor.constraint(equalToConstant: 44),
            searchField.topAnchor.constraint(equalTo: heading.bottomAnchor, constant: 20),
            searchField.leadingAnchor.constraint(equalTo: heading.leadingAnchor),
            searchField.trailingAnchor.constraint(equalTo: heading.trailingAnchor),
            searchField.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
    }

    // Abre os filtros com as seleções atuais e encaminha a aplicação ao ViewModel.
    @objc private func openFilters() {
        view.endEditing(true)
        let controller = CharacterFiltersViewController(filters: viewModel.filters)
        controller.onApply = { [weak self] filters in
            guard let self else { return }
            self.saveListPosition()
            self.viewModel.apply(filters)
        }
        present(controller, animated: true)
    }

    // Configura as células, os delegates e as constraints da tabela.
    func setupTableView() {
        view.backgroundColor = .black
        tableView.backgroundColor = .black
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 96
        tableView.keyboardDismissMode = .onDrag
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 12, right: 0)
        tableView.register(CharacterCell.self, forCellReuseIdentifier: CharacterCell.identifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 12),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    // Registra a rolagem atual e encaminha o texto digitado para pesquisa.
    @objc private func searchTextChanged() {
        saveListPosition()
        viewModel.search(searchField.text ?? String())
    }

    // Atualiza a tabela e apresenta o estado atual de carregamento, resultados ou erro.
    private func render() {
        isRendering = true
        defer { isRendering = false }
        if let position = viewModel.takeRestoredPosition() { pendingPosition = position }
        if !searchField.isFirstResponder { searchField.text = viewModel.query }
        tableView.backgroundView = nil
        let previousCount = tableView.numberOfRows(inSection: 0)
        let sameList = renderedListID == viewModel.listID
        if sameList && viewModel.characters.count > previousCount {
            let rows = (previousCount..<viewModel.characters.count).map { IndexPath(row: $0, section: 0) }
            UIView.performWithoutAnimation { tableView.insertRows(at: rows, with: .none) }
        } else if !sameList || previousCount != viewModel.characters.count {
            tableView.reloadData()
        }
        updatePaginationFooter()
        switch viewModel.state {
        case .initial:
            break
        case .loading:
            let spinner = UIActivityIndicatorView(style: .medium)
            spinner.color = .white
            spinner.startAnimating()
            tableView.backgroundView = spinner
        case .success:
            if !sameList && pendingPosition == nil {
                tableView.setContentOffset(CGPoint(x: 0, y: -tableView.adjustedContentInset.top), animated: false)
            }
        case .empty:
            showSearchMessage(AppStrings.Text.emptyResults)
        case .error(let message):
            showSearchMessage(message, allowsRetry: true)
        }
        if case .success = viewModel.state { renderedListID = viewModel.listID }
        if pendingPosition != nil { view.setNeedsLayout() }
    }

    // Exibe uma mensagem centralizada no fundo da tabela.
    private func showSearchMessage(_ text: String, allowsRetry: Bool = false) {
        tableView.backgroundView = makeMessageView(text, allowsRetry: allowsRetry)
    }

    private func makeMessageView(_ text: String, allowsRetry: Bool) -> UIView {
        let label = UILabel()
        label.text = text
        label.textColor = .lightGray
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.textAlignment = .center
        let container = UIView()
        let content = UIStackView(arrangedSubviews: [label])
        content.axis = .vertical
        content.alignment = .fill
        content.spacing = 16
        if allowsRetry {
            let retryButton = UIButton(type: .system)
            retryButton.setTitle(AppStrings.Text.retry, for: .normal)
            retryButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
            retryButton.titleLabel?.adjustsFontForContentSizeCategory = true
            retryButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
            retryButton.addTarget(self, action: #selector(retryRequest), for: .touchUpInside)
            content.addArrangedSubview(retryButton)
        }
        content.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(content)
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
            content.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24),
            content.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            content.topAnchor.constraint(greaterThanOrEqualTo: container.topAnchor, constant: 16),
            content.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: -16)
        ])
        return container
    }

    private func updatePaginationFooter() {
        if let message = viewModel.nextPageError {
            let footer = makeMessageView(message, allowsRetry: true)
            let width = max(tableView.bounds.width, 1)
            let size = footer.systemLayoutSizeFitting(
                CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
                withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
            footer.frame = CGRect(x: 0, y: 0, width: width, height: size.height)
            tableView.tableFooterView = footer
        } else if viewModel.isLoadingNextPage {
            let spinner = UIActivityIndicatorView(style: .medium)
            spinner.color = .white
            spinner.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 60)
            spinner.startAnimating()
            tableView.tableFooterView = spinner
        } else {
            tableView.tableFooterView = nil
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard !isRendering, indexPath.row >= viewModel.characters.count - 5 else { return }
        viewModel.loadNextPage()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !isRendering, scrollView.isDragging || scrollView.isDecelerating,
              scrollView.contentOffset.y + scrollView.bounds.height >= scrollView.contentSize.height - 300 else { return }
        viewModel.loadNextPage()
    }

    @objc private func retryRequest() {
        viewModel.retry()
    }

    // Informa a quantidade de personagens exibidos.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.characters.count
    }

    // Configura e devolve a célula do personagem na linha solicitada.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: CharacterCell.identifier, for: indexPath
        ) as? CharacterCell else { return UITableViewCell() }
        cell.configure(with: viewModel.characters[indexPath.row])
        return cell
    }

    // Abre os detalhes do personagem selecionado.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let detailViewController = CharacterDetailViewController(character: viewModel.characters[indexPath.row])
        navigationController?.pushViewController(detailViewController, animated: true)
    }
}

