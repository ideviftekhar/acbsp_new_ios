//
//  PlaylistViewController.swift
//  SrilaPrabhupada
//
//  Created by IE06 on 20/08/22.
//

import UIKit
import IQListKit
import FirebaseFirestore
import SKActivityIndicatorView
import FirebaseAuth
import StatusAlert

class PlaylistViewController: SearchViewController {

    @IBOutlet private var playlistSegmentControl: UISegmentedControl!
    @IBOutlet private var playlistTableView: UITableView!

    private lazy var addPlaylistButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addPlaylistButtonAction(_:)))

    private let sortButton: UIBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "arrow.up.arrow.down"), style: .plain, target: nil, action: nil)
    private var sortMenu: SPMenu!

    var selectedSortType: PlaylistSortType {
        guard let selectedSortAction = sortMenu.selectedAction,
              let selectedSortType = PlaylistSortType(rawValue: selectedSortAction.action.identifier.rawValue) else {
            return PlaylistSortType.default
        }
        return selectedSortType
    }

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

            for (index, listType) in PlaylistType.allCases.enumerated() where listType != .unknown {
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
            self.list.loadingMessage = "Loading..."
            list.registerCell(type: Cell.self, registerType: .nib)
            playlistTableView.tableFooterView = UIView()
            playlistTableView.separatorStyle = .singleLine
            refreshUI(animated: false, showNoItems: false)
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

        Haptic.selection()
        refresh(source: .cache, existing: [], animated: nil)
    }

    override func refresh(source: FirestoreSource, animated: Bool?) {
        refresh(source: source, existing: nil, animated: animated)
    }

    func refresh(source: FirestoreSource, existing: [Playlist]?, animated: Bool?) {
        self.list.noItemImage = nil
        self.list.noItemTitle = nil
        self.list.noItemMessage = nil

        if let existing = existing {
            self.models = existing
            refreshUI(showNoItems: false)
        }

        serialListKitQueue.async {
            DispatchQueue.main.async { [self] in
                showLoading()
                list.setIsLoading(true, animated: true)
            }
        }

        refreshAsynchronous(source: source, completion: { [self] result in
            hideLoading()
            switch result {
            case .success(let success):
                self.models = success
                refreshUI(showNoItems: true)
            case .failure(let error):
                Haptic.error()
                self.list.setIsLoading(false, animated: true)
                self.showAlert(error: error)
            }
        })
    }

    func refreshAsynchronous(source: FirestoreSource, completion: @escaping (Result<[Playlist], Error>) -> Void) {

        guard let selectedPlaylistType = PlaylistType(rawValue: playlistSegmentControl.selectedSegmentIndex) else {
            return
        }

        switch selectedPlaylistType {
        case .private:
            DefaultPlaylistViewModel.defaultModel.getPrivatePlaylist(searchText: searchText, sortType: selectedSortType, completion: completion)
        case .public:

            let userEmail: String?
            if !lecturesToAdd.isEmpty {
                userEmail = FirestoreManager.shared.currentUserEmail ?? nil
            } else {
                userEmail = nil
            }

            DefaultPlaylistViewModel.defaultModel.getPublicPlaylist(searchText: searchText, sortType: selectedSortType, userEmail: userEmail, completion: completion)
        case .unknown:
            break
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

        for option in PlaylistSortType.allCases {

            let state: UIAction.State = (lastType == option ? .on : .off)

            let action: SPAction = SPAction(title: option.rawValue, image: option.image, identifier: .init(option.rawValue), state: state, groupIdentifier: option.groupIdentifier, handler: { [self] action in
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

        Haptic.selection()

        refresh(source: .cache, existing: self.models, animated: nil)
    }

    private func updateSortButtonUI() {

        if let icon = selectedSortType.imageSelected {
            sortButton.image = icon
        } else {
            sortButton.image = UIImage(systemName: "arrow.up.arrow.down.circle")
        }
    }
}

extension PlaylistViewController: IQListViewDelegateDataSource {

    private func refreshUI(animated: Bool? = nil, showNoItems: Bool) {

        serialListKitQueue.async { [self] in
            let animated: Bool = animated ?? (models.count <= 1000)
            list.reloadData({

                let section = IQSection(identifier: "Cell", headerSize: CGSize.zero, footerSize: CGSize.zero)
                list.append([section])

                let isSelectionEnabled = !lecturesToAdd.isEmpty
                let models: [Cell.Model] = models.map { .init(playlist: $0, isSelectionEnabled: isSelectionEnabled)
                }
                list.append(Cell.self, models: models, section: section)

            }, animatingDifferences: animated, endLoadingOnCompletion: showNoItems, completion: { [self] in
                if showNoItems, let selectedPlaylistType = PlaylistType(rawValue: playlistSegmentControl.selectedSegmentIndex) {
                    let noItemImage = UIImage(named: "music.note.list_60")
                    self.list.noItemImage = noItemImage

                    var finalMessage: String

                    switch selectedPlaylistType {
                    case .private:
                        list.noItemTitle = "No Private Playlist"
                        finalMessage = "No private playlist to display here"
                    case .public:
                        list.noItemTitle = "No Public Playlist"
                        finalMessage = "No public playlist to display here"
                    case .unknown:
                        list.noItemTitle = ""
                        finalMessage = ""
                    }

                    if let searchText = searchText {
                        finalMessage += "\nSearched for '\(searchText)'"
                    }

                    let allValues: [String] = selectedFilters.flatMap { $0.value }
                    if !allValues.isEmpty {
                        if allValues.count == 1 {
                            finalMessage += "\n\(allValues.count) filter applied"
                        } else {
                            finalMessage += "\n\(allValues.count) filters applied"
                        }
                    }

                    self.list.noItemMessage = finalMessage
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

                Haptic.selection()

                let message: String

                if lecturesToAdd.count == 1, let lecture = lecturesToAdd.first {
                    message = "Would you like to add '\(lecture.titleDisplay)' to '\(model.playlist.title)' Playlist?"
                } else {
                    message = "Would you like to add \(lecturesToAdd.count) lecture(s) to '\(model.playlist.title)' Playlist?"
                }

                self.showAlert(title: "Add to '\(model.playlist.title)'?", message: message, cancel: (title: "Cancel", {
                }), buttons: (title: "Add", {

                    SKActivityIndicator.statusTextColor(.textDarkGray)
                    SKActivityIndicator.spinnerColor(.textDarkGray)
                    SKActivityIndicator.show("Adding to '\(model.playlist.title)' ...")

                    DefaultPlaylistViewModel.defaultModel.add(lectures: self.lecturesToAdd, to: model.playlist, completion: { result in
                        SKActivityIndicator.dismiss()

                        switch result {
                        case .success:
                            Haptic.success()
                            let presenting = self.presentingViewController
                            self.dismiss(animated: true, completion: {
                                if let presenting = presenting {

                                    let message: String?
                                    if self.lecturesToAdd.count > 1 {
                                        message = "Added \(self.lecturesToAdd.count) lecture(s)"
                                    } else {
                                        message = nil
                                    }

                                    let playlistIcon = UIImage(systemName: "music.note.list")
                                    StatusAlert.show(image: playlistIcon, title: "Added to '\(model.playlist.title)'", message: message, in: presenting.view)
                                }
                            })
                        case .failure(let error):
                            Haptic.error()
                            self.showAlert(error: error)
                        }
                    })
                }))
            } else {
                let controller = UIStoryboard.playlists.instantiate(PlaylistLecturesViewController.self)
                controller.playlist = model.playlist
                self.navigationController?.pushViewController(controller, animated: true)
            }
        }
    }
}

extension PlaylistViewController: CreatePlaylistViewControllerDelegate {
    func controller(_ controller: CreatePlaylistViewController, didAdd playlist: Playlist) {

        guard let selectedPlaylistType = PlaylistType(rawValue: playlistSegmentControl.selectedSegmentIndex) else {
            refresh(source: .default, animated: nil)
            return
        }

        if playlist.listType == selectedPlaylistType {
            var models = models
            if let index = models.firstIndex(where: { $0.listID == playlist.listID }) {
                models[index] = playlist
            } else {
                models.insert(playlist, at: 0)
            }
            refresh(source: .default, existing: models, animated: nil)
        } else {
            refresh(source: .default, animated: nil)
        }

        let message: String = "'\(playlist.title)' playlist created!"

        let playlistIcon = UIImage(systemName: "music.note.list")
        StatusAlert.show(image: playlistIcon, title: "Playlist Created", message: message, in: self.view)

        if lecturesToAdd.isEmpty {
            let controller = UIStoryboard.playlists.instantiate(PlaylistLecturesViewController.self)
            controller.playlist = playlist
            self.navigationController?.pushViewController(controller, animated: true)
        }

    }

    func controller(_ controller: CreatePlaylistViewController, didUpdate playlist: Playlist) {
        guard let selectedPlaylistType = PlaylistType(rawValue: playlistSegmentControl.selectedSegmentIndex) else {
            refresh(source: .default, animated: nil)
            return
        }

        if playlist.listType == selectedPlaylistType {
            var models = models
            if let index = models.firstIndex(where: { $0.listID == playlist.listID }) {
                models[index] = playlist
            } else {
                models.insert(playlist, at: 0)
            }
            refresh(source: .default, existing: models, animated: nil)
        } else {
            refresh(source: .default, animated: nil)
        }

        let message: String = "'\(playlist.title)' playlist updated!"

        let playlistIcon = UIImage(systemName: "music.note.list")
        StatusAlert.show(image: playlistIcon, title: "Playlist Updated", message: message, in: self.view)
    }
}

extension PlaylistViewController: PlaylistCellDelegate {

    func playlistCell(_ cell: PlaylistCell, didSelected option: PlaylistOption, with playlist: Playlist) {
        switch option {
        case .delete:
            Haptic.warning()
            self.showAlert(title: "Delete '\(playlist.title)'?", message: "Would you really like to delete '\(playlist.title)' playlist?",
                           cancel: (title: "Cancel", {}),
                           destructive: (title: "Delete", {
                
                SKActivityIndicator.statusTextColor(.textDarkGray)
                SKActivityIndicator.spinnerColor(.textDarkGray)
                SKActivityIndicator.show("Deleting...")
                DefaultPlaylistViewModel.defaultModel.delete(playlist: playlist) { result in
                    SKActivityIndicator.dismiss()

                    switch result {
                    case .success:

                        Haptic.success()
                        if let index = self.models.firstIndex(where: { $0.listID == playlist.listID }) {
                            var models = self.models
                            models.remove(at: index)
                            self.refresh(source: .default, existing: models, animated: nil)
                        }

                    case .failure(let error):
                        Haptic.error()
                        self.showAlert(error: error)
                    }
                }
            }))
        case .edit:
            Haptic.softImpact()
            let navController = UIStoryboard.playlists.instantiate(UINavigationController.self, identifier: "CreatePlaylistNavigationController")
            if let addPlaylistController = navController.viewControllers.first as? CreatePlaylistViewController {
                addPlaylistController.playlist = playlist
                addPlaylistController.delegate = self

            }
            present(navController, animated: true, completion: nil)
        case .addToQueue:
            Haptic.softImpact()
            if let tabBarController = self.tabBarController as? TabBarController {
                tabBarController.addToQueue(lectureIDs: playlist.lectureIds)
            }
        case .addToPlayNext:
            Haptic.softImpact()
            if let tabBarController = self.tabBarController as? TabBarController {
                tabBarController.addToPlayNext(lectureIDs: playlist.lectureIds)
            }
        }
    }
}

extension PlaylistViewController {

    override func showLoading() {
        super.showLoading()
        playlistSegmentControl.isEnabled = false
    }

    override func hideLoading() {
        super.hideLoading()
        playlistSegmentControl.isEnabled = true
   }
}
