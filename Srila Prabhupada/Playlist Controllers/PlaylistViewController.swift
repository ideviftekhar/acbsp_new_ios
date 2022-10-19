//
//  PlaylistViewController.swift
//  SrilaPrabhupada
//
//  Created by IE06 on 20/08/22.
//

import UIKit
import IQListKit
import FirebaseFirestore
import ProgressHUD
import FirebaseAuth

class PlaylistViewController: SearchViewController {

    @IBOutlet private var playlistSegmentControl: UISegmentedControl!
    @IBOutlet private var playlistTableView: UITableView!

    private let loadingIndicator: UIActivityIndicatorView = {
        if #available(iOS 13.0, *) {
            return UIActivityIndicatorView(style: .medium)
        } else {
            return UIActivityIndicatorView(style: .gray)
        }
    }()

    private lazy var addPlaylistButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addPlaylistButtonAction(_:)))

    private let sortButton: UIBarButtonItem = UIBarButtonItem(image: UIImage(compatibleSystemName: "arrow.up.arrow.down"), style: .plain, target: nil, action: nil)
    private var sortMenu: SPMenu!

    var selectedSortType: PlaylistSortType {
        guard let selectedSortAction = sortMenu.selectedAction,
              let selectedSortType = PlaylistSortType(rawValue: selectedSortAction.action.identifier.rawValue) else {
            return PlaylistSortType.default
        }
        return selectedSortType
    }

    let playlistViewModel: PlaylistViewModel = DefaultPlaylistViewModel()

    typealias Model = Playlist
    typealias Cell = PlaylistCell

    private var models: [Model] = []
    private lazy var list = IQList(listView: playlistTableView, delegateDataSource: self)
    private lazy var serialListKitQueue = DispatchQueue(label: "ListKitQueue_\(Self.self)", qos: .userInteractive)

    var lecturesToAdd: [Lecture] = []

    override func viewDidLoad() {

        super.viewDidLoad()

        var rightButtons = self.navigationItem.rightBarButtonItems ?? []
        rightButtons.removeAll { $0 == filterButton }
        rightButtons.append(addPlaylistButton)
        rightButtons.append(sortButton)
        self.navigationItem.rightBarButtonItems = rightButtons

        do {
            playlistSegmentControl.removeAllSegments()

            for (index, listType) in PlaylistType.allCases.enumerated() {
                playlistSegmentControl.insertSegment(withTitle: listType.rawValue, at: index, animated: false)
            }

            let userDefaultKey: String = "\(Self.self).\(UISegmentedControl.self)"
            let lastSelectedIndex: Int = UserDefaults.standard.integer(forKey: userDefaultKey)
            if lastSelectedIndex < playlistSegmentControl.numberOfSegments {
                playlistSegmentControl.selectedSegmentIndex = lastSelectedIndex
            } else {
                playlistSegmentControl.selectedSegmentIndex = 0
            }
        }

        do {
            list.registerCell(type: Cell.self, registerType: .nib)
            playlistTableView.tableFooterView = UIView()
            refreshUI(animated: false, showNoItems: false)
        }

        do {
            loadingIndicator.color = UIColor.gray
            self.view.addSubview(loadingIndicator)
            loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
            loadingIndicator.hidesWhenStopped = true
            loadingIndicator.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
            loadingIndicator.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        }

        configureSortButton()

        if !lecturesToAdd.isEmpty {
            let cancelBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(cancelAction(_:)))
            self.navigationItem.leftBarButtonItem  = cancelBarButtonItem
        }
    }

    @objc func cancelAction(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true)
    }

    @objc func addPlaylistButtonAction(_ sender: UIBarButtonItem) {
        let navController = UIStoryboard.playlists.instantiate(UINavigationController.self, identifier: "CreatePlaylistNavigationController")
        if let addPlaylistController = navController.viewControllers.first as? CreatePlaylistViewController {
            addPlaylistController.delegate = self

        }
        present(navController, animated: true, completion: nil)
    }

    @IBAction func segmentChanged(_ sender: UISegmentedControl) {

        do {
            let userDefaultKey: String = "\(Self.self).\(UISegmentedControl.self)"
            UserDefaults.standard.set(sender.selectedSegmentIndex, forKey: userDefaultKey)
            UserDefaults.standard.synchronize()
        }

        refresh(source: .cache, existing: [])
    }

    override func refresh(source: FirestoreSource) {
        refresh(source: source, existing: nil)
    }

    func refresh(source: FirestoreSource, existing: [Playlist]?) {
        if let existing = existing {
            self.models = existing
            refreshUI(showNoItems: false)
        }

        if self.models.isEmpty {
            showLoading()
            self.list.noItemTitle = nil
            self.list.noItemMessage = "Loading..."
        }

        refreshAsynchronous(source: source, completion: { [self] result in
            hideLoading()
            switch result {
            case .success(let success):
                self.models = success
                refreshUI(showNoItems: true)
            case .failure(let error):
                showAlert(title: "Error", message: error.localizedDescription)
            }
        })
    }

    func refreshAsynchronous(source: FirestoreSource, completion: @escaping (Result<[Playlist], Error>) -> Void) {

        guard let selectedPlaylistType = PlaylistType(rawValue: playlistSegmentControl.selectedSegmentIndex) else {
            return
        }

        switch selectedPlaylistType {
        case .private:
            playlistViewModel.getPrivatePlaylist(searchText: searchText, sortType: selectedSortType, completion: completion)
        case .public:

            let userEmail: String?
            if !lecturesToAdd.isEmpty {
                userEmail = Auth.auth().currentUser?.email ?? ""
            } else {
                userEmail = nil
            }

            playlistViewModel.getPublicPlaylist(searchText: searchText, sortType: selectedSortType, userEmail: userEmail, completion: completion)
        }
    }
}

extension PlaylistViewController {

    private func configureSortButton() {
        var actions: [SPAction] = []

        let userDefaultKey: String = "\(Self.self).\(PlaylistSortType.self)"
        let lastType: PlaylistSortType

        if let typeString = UserDefaults.standard.string(forKey: userDefaultKey), let type = PlaylistSortType(rawValue: typeString) {
            lastType = type
        } else {
            lastType = .default
        }

        for sortType in PlaylistSortType.allCases {

            let state: UIAction.State = (lastType == sortType ? .on : .off)

            let action: SPAction = SPAction(title: sortType.rawValue, image: nil, identifier: .init(sortType.rawValue), state: state, handler: { [self] action in
                sortActionSelected(action: action)
            })

            actions.append(action)
        }

        self.sortMenu = SPMenu(title: "", image: nil, identifier: UIMenu.Identifier.init(rawValue: "Sort"), options: UIMenu.Options.displayInline, children: actions, barButton: sortButton, parent: self)

        updateSortButtonUI()
    }

    private func sortActionSelected(action: UIAction) {
        let userDefaultKey: String = "\(Self.self).\(PlaylistSortType.self)"
        let children: [SPAction] = self.sortMenu.children
        UserDefaults.standard.set(action.identifier.rawValue, forKey: userDefaultKey)
        UserDefaults.standard.synchronize()

       for anAction in children {
           if anAction.action.identifier == action.identifier { anAction.action.state = .on  } else {  anAction.action.state = .off }
        }
        self.sortMenu.children = children

        updateSortButtonUI()

        refresh(source: .cache, existing: self.models)
    }

    private func updateSortButtonUI() {
        if selectedSortType == .default {
            sortButton.image = UIImage(compatibleSystemName: "arrow.up.arrow.down.circle")
        } else {
            sortButton.image = UIImage(compatibleSystemName: "arrow.up.arrow.down.circle.fill")
        }
    }
}

extension PlaylistViewController: IQListViewDelegateDataSource {

    private func refreshUI(animated: Bool? = nil, showNoItems: Bool) {

        serialListKitQueue.async { [self] in
            let animated: Bool = animated ?? (models.count <= 1000)
            list.performUpdates({

                let section = IQSection(identifier: "Cell", headerSize: CGSize.zero, footerSize: CGSize.zero)
                list.append(section)

                list.append(Cell.self, models: models, section: section)

            }, animatingDifferences: animated, completion: { [self] in
                if showNoItems, let selectedPlaylistType = PlaylistType(rawValue: playlistSegmentControl.selectedSegmentIndex) {
                    switch selectedPlaylistType {
                    case .private:
                        list.noItemTitle = "No Private Playlist"
                        list.noItemMessage = "No private playlist to display here"
                    case .public:
                        list.noItemTitle = "No Public Playlist"
                        list.noItemMessage = "No public playlist to display here"
                    }
                }
            })
        }
    }

    func listView(_ listView: IQListView, modifyCell cell: IQListCell, at indexPath: IndexPath) {
        if let cell = cell as? Cell {
            cell.delegate = self

            if !lecturesToAdd.isEmpty {
                cell.accessoryType = .none
            } else {
                cell.accessoryType = .disclosureIndicator
            }
        }
    }

    func listView(_ listView: IQListView, didSelect item: IQItem, at indexPath: IndexPath) {

        if let model = item.model as? Cell.Model {

            if !lecturesToAdd.isEmpty {

                let message: String

                if lecturesToAdd.count == 1, let lecture = lecturesToAdd.first {
                    message = "Would you like to add '\(lecture.titleDisplay)' to '\(model.title)' playlist?"
                } else {
                    message = "Would you like to add \(lecturesToAdd.count) lectures to '\(model.title)' playlist?"
                }

                self.showAlert(title: "Add to '\(model.title)'?", message: message, cancel: (title: "Cancel", {
                }), buttons: (title: "Add", {

                    ProgressHUD.show("Adding...", interaction: false)
                    self.playlistViewModel.add(lectures: self.lecturesToAdd, to: model, completion: { result in
                        ProgressHUD.dismiss()

                        switch result {
                        case .success:
                            self.dismiss(animated: true)
                        case .failure(let error):
                            self.showAlert(title: "Error", message: error.localizedDescription)
                        }
                    })
                }))
            } else {
                let controller = UIStoryboard.playlists.instantiate(PlaylistLecturesViewController.self)
                controller.playlist = model
                self.navigationController?.pushViewController(controller, animated: true)
            }
        }
    }
}

extension PlaylistViewController: CreatePlaylistViewControllerDelegate {
    func controller(_ controller: CreatePlaylistViewController, didAdd playlist: Playlist) {

        guard let selectedPlaylistType = PlaylistType(rawValue: playlistSegmentControl.selectedSegmentIndex) else {
            refresh(source: .default)
            return
        }

        if playlist.listType == selectedPlaylistType {
            var models = models
            if let index = models.firstIndex(where: { $0.listID == playlist.listID }) {
                models[index] = playlist
            } else {
                models.insert(playlist, at: 0)
            }
            refresh(source: .default, existing: models)
        } else {
            refresh(source: .default)
        }
    }

    func controller(_ controller: CreatePlaylistViewController, didUpdate playlist: Playlist) {
        guard let selectedPlaylistType = PlaylistType(rawValue: playlistSegmentControl.selectedSegmentIndex) else {
            refresh(source: .default)
            return
        }

        if playlist.listType == selectedPlaylistType {
            var models = models
            if let index = models.firstIndex(where: { $0.listID == playlist.listID }) {
                models[index] = playlist
            } else {
                models.insert(playlist, at: 0)
            }
            refresh(source: .default, existing: models)
        } else {
            refresh(source: .default)
        }
    }
}

extension PlaylistViewController: PlaylistCellDelegate {

    func playlistCell(_ cell: PlaylistCell, didSelected option: PlaylistOption, with playlist: Playlist) {
        switch option {
        case .delete:

            self.showAlert(title: "Delete '\(playlist.title)'?", message: "Would you really like to delete '\(playlist.title)' playlist?",
                           cancel: (title: "Cancel", {}),
                           destructive: (title: "Delete", {

                ProgressHUD.show("Deleting...", interaction: false)
                self.playlistViewModel.delete(playlist: playlist) { result in
                    ProgressHUD.dismiss()

                    switch result {
                    case .success:

                        if let index = self.models.firstIndex(where: { $0.listID == playlist.listID }) {
                            var models = self.models
                            models.remove(at: index)
                            self.refresh(source: .default, existing: models)
                        }

                    case .failure(let error):
                        self.showAlert(title: "Error", message: error.localizedDescription)
                    }
                }
            }))
        case .edit:
            let navController = UIStoryboard.playlists.instantiate(UINavigationController.self, identifier: "CreatePlaylistNavigationController")
            if let addPlaylistController = navController.viewControllers.first as? CreatePlaylistViewController {
                addPlaylistController.playlist = playlist
                addPlaylistController.delegate = self

            }
            present(navController, animated: true, completion: nil)
        }
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
}
