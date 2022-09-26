//
//  PlaylistViewController.swift
//  SrilaPrabhupada
//
//  Created by IE06 on 20/08/22.
//

import UIKit
import FirebaseFirestore

class PlaylistViewController: BaseSearchViewController {

    @IBOutlet weak var playlistSegmentControl: UISegmentedControl!

    @IBOutlet weak var playlistTableView: UITableView!

    private let cellIdentifier = "PlaylistCell"
    private let loadingIndicator: UIActivityIndicatorView = UIActivityIndicatorView(style: .medium)
    private let sortButton: UIBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "arrow.up.arrow.down"), style: .plain, target: nil, action: nil)

    let playlistViewModel: PlaylistViewModel = DefaultPlaylistViewModel()
    var playlists: [Playlist] = []

    var selectedSortType: PlaylistSortType {
        guard let selectedSortAction = sortButton.menu?.selectedElements.first as? UIAction, let selectedSortType = PlaylistSortType(rawValue: selectedSortAction.identifier.rawValue) else {
            return PlaylistSortType.default
        }
        return selectedSortType
    }

    override func viewDidLoad() {

        super.viewDidLoad()

        var rightButtons = self.navigationItem.rightBarButtonItems ?? []
        rightButtons.removeAll { $0 == filterButton }
        rightButtons.append(sortButton)
        self.navigationItem.rightBarButtonItems = rightButtons

        playlistTableView.register(UINib(nibName: cellIdentifier, bundle: nil), forCellReuseIdentifier: cellIdentifier)

        do {
            loadingIndicator.color = UIColor.gray
            self.view.addSubview(loadingIndicator)
            loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
            loadingIndicator.hidesWhenStopped = true
            loadingIndicator.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
            loadingIndicator.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        }

        do {
            let userDefaultKey: String = "\(Self.self).\(UISegmentedControl.self)"
            let lastSelectedIndex: Int = UserDefaults.standard.integer(forKey: userDefaultKey)
            playlistSegmentControl.selectedSegmentIndex = lastSelectedIndex
        }

        configureSortButton()
    }

    func configureSortButton() {
        var actions: [UIAction] = []

        let userDefaultKey: String = "\(Self.self).\(PlaylistSortType.self)"
        let lastType: PlaylistSortType

        if let typeString = UserDefaults.standard.string(forKey: userDefaultKey), let type = PlaylistSortType(rawValue: typeString) {
            lastType = type
        } else {
            lastType = .default
        }

        for sortType in PlaylistSortType.allCases {

            let state: UIAction.State = (lastType == sortType ? .on : .off)

            let action: UIAction = UIAction(title: sortType.rawValue, image: nil, identifier: UIAction.Identifier(sortType.rawValue), state: state, handler: { [self] action in

                for anAction in actions {
                    if anAction.identifier == action.identifier { anAction.state = .on  } else {  anAction.state = .off }
                }

                self.sortButton.menu = self.sortButton.menu?.replacingChildren(actions)

                UserDefaults.standard.set(action.identifier.rawValue, forKey: userDefaultKey)
                UserDefaults.standard.synchronize()

                updateSortButtonUI()

                refreshAsynchronous(source: .cache)
            })

            actions.append(action)
        }

        let menu = UIMenu(title: "", image: nil, identifier: UIMenu.Identifier.init(rawValue: "Sort"), options: UIMenu.Options.displayInline, children: actions)
        sortButton.menu = menu
        updateSortButtonUI()
    }

    private func updateSortButtonUI() {
        if selectedSortType == .default {
            sortButton.image = UIImage(systemName: "arrow.up.arrow.down.circle")
        } else {
            sortButton.image = UIImage(systemName: "arrow.up.arrow.down.circle.fill")
        }
    }

    @IBAction func segmentChanged(_ sender: UISegmentedControl) {

        do {
            let userDefaultKey: String = "\(Self.self).\(UISegmentedControl.self)"
            UserDefaults.standard.set(sender.selectedSegmentIndex, forKey: userDefaultKey)
            UserDefaults.standard.synchronize()
        }

        reloadData(with: [])
        refreshAsynchronous(source: .cache)
    }

    override func refreshAsynchronous(source: FirestoreSource) {

        switch playlistSegmentControl.selectedSegmentIndex {
        case 0:

            showLoading()
            playlistViewModel.getPrivatePlaylist(searchText: searchText, sortType: selectedSortType, completion: { [self] result in
                hideLoading()

                switch result {
                case .success(let playlists):
                    reloadData(with: playlists)
                case .failure(let error):
                    showAlert(title: "Error", message: error.localizedDescription)
                }
            })
        case 1:

            showLoading()
            playlistViewModel.getPublicPlaylist(searchText: searchText, sortType: selectedSortType, completion: { [self] result in
                hideLoading()

                switch result {
                case .success(let playlists):
                    reloadData(with: playlists)
                case .failure(let error):
                    showAlert(title: "Error", message: error.localizedDescription)
                }
            })
        default:
            break
        }

    }
}

extension PlaylistViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return playlists.count
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! PlaylistCell

        let playlist = playlists[indexPath.row]

        cell.model = playlist

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let playlist = playlists[indexPath.row]

        let controller = UIStoryboard.playlists.instantiate(PlaylistLecturesViewController.self)
        controller.playlist = playlist
        self.navigationController?.pushViewController(controller, animated: true)
    }
}

extension PlaylistViewController {

    func showLoading() {
        loadingIndicator.startAnimating()
        playlistSegmentControl.isEnabled = false
    }

    func hideLoading() {
        loadingIndicator.stopAnimating()
        playlistSegmentControl.isEnabled = true
   }

    func reloadData(with playlists: [Playlist]) {
        self.playlists = playlists
        self.playlistTableView.reloadData()
    }
}
