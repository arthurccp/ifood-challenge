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
    private var characters: [Result] = []

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
        setupRequest()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    private func setupHeader() {
        let titleLabel = UILabel()
        titleLabel.text = "Personagens"
        titleLabel.font = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: .systemFont(ofSize: 34, weight: .bold))
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.75
        titleLabel.textColor = .white

        let filterButton = UIButton(type: .system)
        filterButton.setImage(UIImage(systemName: "slider.horizontal.3"), for: .normal)
        filterButton.tintColor = .white
        filterButton.backgroundColor = UIColor(red: 0.065, green: 0.075, blue: 0.095, alpha: 1)
        filterButton.layer.cornerRadius = 22
        filterButton.accessibilityLabel = "Filtros"
        filterButton.accessibilityHint = "Indisponível nesta versão"
        filterButton.isUserInteractionEnabled = false
        heading.addArrangedSubview(titleLabel)
        heading.addArrangedSubview(filterButton)
        heading.alignment = .center
        heading.spacing = 12

        searchField.placeholder = "Pesquisar personagens..."
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

    func setupRequest() {
        Parser().parse { [weak self] characters in
            DispatchQueue.main.async {
                self?.characters = characters
                self?.tableView.reloadData()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        characters.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: CharacterCell.identifier, for: indexPath
        ) as? CharacterCell else { return UITableViewCell() }
        cell.configure(with: characters[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let detailViewController = CharacterDetailViewController(character: characters[indexPath.row])
        navigationController?.pushViewController(detailViewController, animated: true)
    }
}

