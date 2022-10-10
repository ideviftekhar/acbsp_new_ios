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

    @IBOutlet weak var playlistSegmentControl: UISegmentedControl!
    @IBOutlet weak var playlistTableView: UITableView!

    private let loadingIndicator: UIActivityIndicatorView = {
        if #available(iOS 13.0, *) {
            return UIActivityIndicatorView(style: .medium)
        } else {
            return UIActivityIndicatorView(style: .gray)
        }
    }()

    private let sortButton: UIBarButtonItem = UIBarButtonItem(image: UIImage(compatibleSystemName: "arrow.up.arrow.down"), style: .plain, target: nil, action: nil)
    private var sortMenu: UIMenu!

    var selectedSortType: PlaylistSortType {

        if #available(iOS 15.0, *) {
            guard let selectedSortAction = sortMenu.selectedElements.first as? UIAction,
                  let selectedSortType = PlaylistSortType(rawValue: selectedSortAction.identifier.rawValue) else {
                return PlaylistSortType.default
            }
            return selectedSortType
        } else {
            guard let children: [UIAction] = sortMenu.children as? [UIAction],
                  let selectedSortAction = children.first(where: { $0.state == .on }),
                    let selectedSortType = PlaylistSortType(rawValue: selectedSortAction.identifier.rawValue) else {
                return PlaylistSortType.default
            }
            return selectedSortType
        }
    }

    let playlistViewModel: PlaylistViewModel = DefaultPlaylistViewModel()

    typealias Model = Playlist
    typealias Cell = PlaylistCell

    private var models: [Model] = []
    private lazy var list = IQList(listView: playlistTableView, delegateDataSource: self)

    var lectureToAdd: Lecture?

    override func viewDidLoad() {

        super.viewDidLoad()

        var rightButtons = self.navigationItem.rightBarButtonItems ?? []
        rightButtons.removeAll { $0 == filterButton }
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

            updateEmptyPlaylistMessage()
        }

        do {
            list.registerCell(type: Cell.self, registerType: .nib)
            refreshUI(animated: false)
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

        if lectureToAdd != nil {
            let cancelBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(cancelAction(_:)))
            self.navigationItem.leftBarButtonItem  = cancelBarButtonItem
        }
    }

    @objc func cancelAction(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true)
    }

    @IBAction func segmentChanged(_ sender: UISegmentedControl) {

        do {
            let userDefaultKey: String = "\(Self.self).\(UISegmentedControl.self)"
            UserDefaults.standard.set(sender.selectedSegmentIndex, forKey: userDefaultKey)
            UserDefaults.standard.synchronize()
        }

        updateEmptyPlaylistMessage()

        reloadData(with: [])
        refreshAsynchronous(source: .cache)
    }

    private func updateEmptyPlaylistMessage() {
        if let selectedPlaylistType = PlaylistType(rawValue: playlistSegmentControl.selectedSegmentIndex) {
            switch selectedPlaylistType {
            case .private:
                list.noItemTitle = "No Private Playlist"
                list.noItemMessage = "No private playlist to display here"
            case .public:
                list.noItemTitle = "No Public Playlist"
                list.noItemMessage = "No public playlist to display here"
            }
        }
    }

    override func refreshAsynchronous(source: FirestoreSource) {
        super.refreshAsynchronous(source: source)

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

            let userEmail: String?
            if lectureToAdd != nil {
                userEmail = Auth.auth().currentUser?.email ?? ""
            } else {
                userEmail = nil
            }

            playlistViewModel.getPublicPlaylist(searchText: searchText, sortType: selectedSortType, userEmail: userEmail, completion: { [self] result in
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

extension PlaylistViewController {

    private func configureSortButton() {
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
                sortActionSelected(action: action)
            })

            actions.append(action)
        }

        self.sortMenu = UIMenu(title: "", image: nil, identifier: UIMenu.Identifier.init(rawValue: "Sort"), options: UIMenu.Options.displayInline, children: actions)

        if #available(iOS 14.0, *) {
            sortButton.menu = self.sortMenu
        } else {
            sortButton.target = self
            sortButton.action = #selector(sortActioniOS13(_:))
        }
        updateSortButtonUI()
    }

    // Backward compatibility for iOS 13
    @objc private func sortActioniOS13(_ sender: UIBarButtonItem) {

        var buttons: [UIViewController.ButtonConfig] = []
        let actions: [UIAction] = self.sortMenu.children as? [UIAction] ?? []
        for action in actions {
            buttons.append((title: action.title, handler: { [self] in
                sortActionSelected(action: action)
            }))
        }

        self.showAlert(title: "Sort", message: "", preferredStyle: .actionSheet, buttons: buttons)
    }

    private func sortActionSelected(action: UIAction) {
        let userDefaultKey: String = "\(Self.self).\(PlaylistSortType.self)"
        let actions: [UIAction] = self.sortMenu.children as? [UIAction] ?? []
       for anAction in actions {
            if anAction.identifier == action.identifier { anAction.state = .on  } else {  anAction.state = .off }
        }

        updateSortButtonUI()

        UserDefaults.standard.set(action.identifier.rawValue, forKey: userDefaultKey)
        UserDefaults.standard.synchronize()

        self.sortMenu = self.sortMenu.replacingChildren(actions)

        if #available(iOS 14.0, *) {
            self.sortButton.menu = self.sortMenu
        }

        refreshAsynchronous(source: .cache)
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

    private func refreshUI(animated: Bool? = nil) {

        let animated: Bool = animated ?? (models.count <= 1000)
        list.performUpdates({

            let section = IQSection(identifier: "Cell", headerSize: CGSize.zero, footerSize: CGSize.zero)
            list.append(section)

            list.append(Cell.self, models: models, section: section)

        }, animatingDifferences: animated, completion: nil)
    }

    func listView(_ listView: IQListView, modifyCell cell: IQListCell, at indexPath: IndexPath) {
        if let cell = cell as? Cell {
            cell.delegate = self

            if lectureToAdd != nil {
                cell.accessoryType = .none
            } else {
                cell.accessoryType = .disclosureIndicator
            }
        }
    }

    func listView(_ listView: IQListView, didSelect item: IQItem, at indexPath: IndexPath) {

        if let model = item.model as? Cell.Model {

            if let lectureToAdd = lectureToAdd {
                self.showAlert(title: "Add to '\(model.title)'?", message: "Would you like to add '\(lectureToAdd.titleDisplay)' to '\(model.title)' playlist?", cancel: (title: "Cancel", {
                }), buttons: (title: "Add", {

                    ProgressHUD.show("Adding...", interaction: false)
                    self.playlistViewModel.add(lecture: lectureToAdd, to: model) { result in
                        ProgressHUD.dismiss()

                        switch result {
                        case .success:
                            self.dismiss(animated: true)
                        case .failure(let error):
                            self.showAlert(title: "Error", message: error.localizedDescription)
                        }
                    }
                }))
            } else {
                let controller = UIStoryboard.playlists.instantiate(PlaylistLecturesViewController.self)
                controller.playlist = model
                self.navigationController?.pushViewController(controller, animated: true)
            }
        }
    }
}

extension PlaylistViewController: PlaylistCellDelegate {

    func playlistCell(_ cell: PlaylistCell, didSelected option: PlaylistOption, with playlist: Playlist) {
        switch option {
        case .deletePlaylist:

            self.showAlert(title: "Delete '\(playlist.title)'?",message: "Would you really like to delete '\(playlist.title)' playlist?",
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
                            self.reloadData(with: models)
                        }

                    case .failure(let error):
                        self.showAlert(title: "Error", message: error.localizedDescription)
                    }
                }
            }))
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

    func reloadData(with playlists: [Playlist]) {
        self.models = playlists
        refreshUI()
    }
}
