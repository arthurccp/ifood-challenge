//
//  ViewController.swift
//  ifood-challenge
//
//  Created by Arthur Silva on 14/10/26.
//

import UIKit

final class ViewController: UIViewController, UITableViewDataSource {

    private let tableView = UITableView()
    private var characters: [Result] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        setupRequest()

    }
    
    func setupTableView() {
        view.backgroundColor = .black
        tableView.backgroundColor = .black
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 160
        tableView.register(CharacterCell.self, forCellReuseIdentifier: CharacterCell.identifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
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
}

