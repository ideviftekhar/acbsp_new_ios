//
//  LectureViewController.swift
//  SrilaPrabhupada
//
//  Created by IE06 on 08/09/22.
//

import UIKit
import AVKit
import FirebaseFirestore
import IQListKit
import FirebaseDynamicLinks
import StatusAlert
import SKActivityIndicatorView

protocol LectureViewControllerDelegate: AnyObject {
    func lectureController(_ controller: LectureViewController, didSelected lectures: [Lecture])
    func lectureControllerDidCancel(_ controller: LectureViewController)
}

class LectureViewController: SearchViewController {

    @IBOutlet internal var lectureTebleView: UITableView!

    weak var delegate: LectureViewControllerDelegate?

    internal let sortButton: UIBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "arrow.up.arrow.down.circle"), style: .plain, target: nil, action: nil)
    internal var sortMenu: SPMenu!

    internal let moreButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), style: .plain, target: nil, action: nil)
    internal var moreMenu: SPMenu!
    internal var defaultSelectionActions: [SPAction] = []
    internal var defaultNormalActions: [SPAction] = []
    internal var allActions: [LectureOption: SPAction] = [:]

    internal lazy var doneSelectionButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneSelectionAction(_:)))
    internal lazy var cancelSelectionButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelButtonAction(_:)))

    private var isFirstTimeLoaded: Bool = false

    var removeFromPlaylistEnabled: Bool = false
    var isSelectionEnabled: Bool = false
    var selectedModels: [Model] = [] {
        didSet {
            doneSelectionButton.isEnabled = !selectedModels.isEmpty

            if isSelectionEnabled {
                navigationItem.prompt = "\(selectedModels.count) Selected"
            } else {
                navigationItem.prompt = nil
            }

            refreshMoreOption()
        }
    }

    var selectedPlaylist: Playlist?
    var highlightedLectures: [Lecture] = []

    var selectedSortType: LectureSortType {
        guard let selectedSortAction = sortMenu.selectedAction,
              let selectedSortType = LectureSortType(rawValue: selectedSortAction.action.identifier.rawValue) else {
            return LectureSortType.default
        }
        return selectedSortType
    }

    typealias Model = Lecture
    typealias Cell = LectureCell

    private(set) var models: [Model] = []
    private(set) lazy var list = IQList(listView: lectureTebleView, delegateDataSource: self)
    private lazy var serialListKitQueue = DispatchQueue(label: "ListKitQueue_\(Self.self)", qos: .userInteractive)

    var noItemTitle: String?
    var noItemMessage: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        var rightButtons = self.navigationItem.rightBarButtonItems ?? []

        rightButtons.insert(moreButton, at: 0)
        rightButtons.append(sortButton)
        if isSelectionEnabled {
            selectedModels = []
            rightButtons.insert(doneSelectionButton, at: 0)
            self.navigationItem.leftBarButtonItem = cancelSelectionButton
            searchController.searchBar.text = nil
        }

        self.navigationItem.rightBarButtonItems = rightButtons

        do {
            if let playlistLectureViewController = self as? PlaylistLecturesViewController,
               FirestoreManager.shared.currentUser != nil,
               let email = FirestoreManager.shared.currentUserEmail,
               playlistLectureViewController.playlist.authorEmail.elementsEqual(email) {
                removeFromPlaylistEnabled = true
            } else {
                removeFromPlaylistEnabled = false
            }
        }

        do {
            self.list.loadingMessage = "Loading..."
            list.registerCell(type: Cell.self, registerType: .nib)
            lectureTebleView.tableFooterView = UIView()
            lectureTebleView.separatorStyle = .singleLine
            refreshUI(animated: false, showNoItems: false)
        }

        configureSortButton()
        configureSelectionButton()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(lectureUpdateNotification(_:)), name: DefaultLectureViewModel.Notification.lectureUpdated, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: DefaultLectureViewModel.Notification.lectureUpdated, object: nil)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.lectureTebleView.reloadData()
    }

    @objc func lectureUpdateNotification(_ notification: Notification) {
        guard isFirstTimeLoaded else {
            return
        }
        if let lectures: [Lecture] = notification.object as? [Lecture] {

            serialListKitQueue.async { [self] in
                var newModels = self.models

                let lectureIDHashTable: [Int: Int] = newModels.enumerated().reduce(into: [Int: Int]()) { result, lecture in
                    result[lecture.element.id] = lecture.offset
                }

                var removedIDs: [Int] = []
                var addedLectures: [Lecture] = []

                for lecture in lectures {

                    if self is DownloadViewController { // If download controller, then we also need to remove or add it in UI
                        if lecture.downloadState == .notDownloaded {
                            removedIDs.append(lecture.id)
                        } else {
                            if let index = lectureIDHashTable[lecture.id] {
                                newModels[index] = lecture
                            } else {
                                addedLectures.append(lecture)
                            }
                        }
                    } else if self is FavoriteViewController {    // If favorites controller, then we also need to remove or add it in UI
                        if lecture.isFavorite {
                            if let index = lectureIDHashTable[lecture.id] {
                                newModels[index] = lecture
                            } else {
                                addedLectures.append(lecture)
                            }
                        } else {
                            removedIDs.append(lecture.id)
                        }
                    } else {
                        if let index = lectureIDHashTable[lecture.id] {
                            newModels[index] = lecture
                        }
                    }
                }

                var removedIndexes: [Int] = []
                for removedID in removedIDs {
                    if let index = lectureIDHashTable[removedID] {
                        removedIndexes.append(index)
                    }
                }

                if !removedIndexes.isEmpty {
                    let indices: IndexSet = IndexSet(removedIndexes)

                    newModels.remove(atOffsets: indices)
                }

                newModels.insert(contentsOf: addedLectures, at: 0)

                DispatchQueue.main.async {
                    self.models = newModels
                    self.refreshUI(animated: nil, showNoItems: true)
                }
            }
        }
    }

    @objc internal func keyboardWillShow(_ notification: Notification?) {

        let keyboardFrame: CGRect
        //  Getting UIKeyboardSize.
        if let kbFrame = notification?.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            keyboardFrame = kbFrame
        } else {
            keyboardFrame = .zero
        }

        var kbSize = keyboardFrame.size

        do {
            let intersectRect = keyboardFrame.intersection(self.lectureTebleView.frame)

            if intersectRect.isNull {
                kbSize = CGSize(width: keyboardFrame.size.width, height: 0)
            } else {
                kbSize = intersectRect.size
            }
        }

        var oldInset = self.lectureTebleView.contentInset
        oldInset.bottom = kbSize.height - self.view.layoutMargins.bottom
        self.lectureTebleView.contentInset = oldInset
        self.lectureTebleView.verticalScrollIndicatorInsets = oldInset
    }

    @objc internal func keyboardWillHide(_ notification: Notification?) {
        var oldInset = self.lectureTebleView.contentInset
        oldInset.bottom = 0
        self.lectureTebleView.contentInset = oldInset
        self.lectureTebleView.verticalScrollIndicatorInsets = oldInset
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    func syncStarted() {
    }

    func syncEnded() {
    }

    func lecturesLoadingFinished() {

    }

    override func refresh(source: FirestoreSource, animated: Bool?) {
        refresh(source: source, existing: nil, animated: animated)
    }

    func refresh(source: FirestoreSource, existing: [Model]?, animated: Bool?) {

        self.list.noItemImage = nil
        self.list.noItemTitle = nil
        self.list.noItemMessage = nil

        if let existing = existing {
            self.models = existing
            refreshUI(animated: animated, showNoItems: false)
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
                self.isFirstTimeLoaded = true
                refreshUI(animated: animated, showNoItems: true)
            case .failure(let error):
                Haptic.error()
                self.list.setIsLoading(false, animated: true)
                self.showAlert(error: error)
            }
        })
    }

    func refreshAsynchronous(source: FirestoreSource, completion: @escaping (_ result: Swift.Result<[Model], Error>) -> Void) {
        completion(.success(self.models))
    }
}


extension LectureViewController: LectureCellDelegate {
    func lectureCell(_ cell: LectureCell, didSelected option: LectureOption, with lecture: Lecture) {

        switch option {
        case .addToQueue:
            Haptic.softImpact()
            if let playerController = self as? PlayerViewController {
                playerController.addToQueue(lectureIDs: [lecture.id])
            } else if let tabController = self.tabBarController as? TabBarController {
                tabController.addToQueue(lectureIDs: [lecture.id])
            }
        case .removeFromQueue:
            Haptic.softImpact()
            if let playerController = self as? PlayerViewController {
                playerController.removeFromQueue(lectureIDs: [lecture.id])
            } else if let tabController = self.tabBarController as? TabBarController {
                tabController.removeFromQueue(lectureIDs: [lecture.id])
            }
        case .addToPlayNext:
            Haptic.softImpact()
            if let playerController = self as? PlayerViewController {
                playerController.addToPlayNext(lectureIDs: [lecture.id])
            } else if let tabController = self.tabBarController as? TabBarController {
                tabController.addToPlayNext(lectureIDs: [lecture.id])
            }
        case .download, .resumeDownload:
            Haptic.softImpact()
            Persistant.shared.save(lectures: [lecture], completion: { _ in })
            DefaultLectureViewModel.defaultModel.updateLectureInfo(lectures: [lecture], isCompleted: nil, isDownloaded: true, isFavorite: nil, lastPlayedPoint: nil, postUpdate: false, completion: {_ in })
        case .pauseDownload:
            Haptic.softImpact()
            Persistant.shared.pauseDownloads(lectures: [lecture])
        case .deleteFromDownloads:
            Haptic.warning()
            askToDeleteFromDownloads(lectures: [lecture], sourceView: cell)
        case .markAsFavorite:
            Haptic.softImpact()
            markAsFavorite(lectures: [lecture], sourceView: cell)
        case .removeFromFavorite:
            Haptic.warning()
            askToRemoveFromFavorite(lectures: [lecture], sourceView: cell)
        case .addToPlaylist:
            Haptic.softImpact()

            let navigationController = UIStoryboard.playlists.instantiate(UINavigationController.self, identifier: "PlaylistNavigationController")
            guard let playlistController = navigationController.viewControllers.first as? PlaylistViewController else {
                return
            }
            playlistController.lecturesToAdd = [lecture]
            playlistController.popoverPresentationController?.sourceView = cell
            self.present(navigationController, animated: true, completion: nil)

        case .removeFromPlaylist:
            Haptic.warning()
            askToRemoveFromPlaylist(lectures: [lecture], sourceView: cell)
        case .markAsHeard:
            Haptic.softImpact()
            markAsHeard(lectures: [lecture], sourceView: cell)
        case .resetProgress:
            Haptic.softImpact()
            resetProgress(lectures: [lecture], sourceView: cell)
        case .share:

            lecture.generateShareLink(completion: { result in
                switch result {
                case .success(let success):
                    let shareController = UIActivityViewController(activityItems: [success], applicationActivities: nil)
                    shareController.popoverPresentationController?.sourceView = cell
                    self.present(shareController, animated: true)
                case .failure(let failure):
                    self.showAlert(error: failure)
                }
            })
        case .info:
            let controller = UIStoryboard.common.instantiate(LectureInfoViewController.self)
            controller.lecture = lecture

            switch Environment.current.device {
            case .mac, .pad:
                controller.modalPresentationStyle = .formSheet
            default:
                controller.modalPresentationStyle = .automatic
            }

            controller.popoverPresentationController?.sourceView = cell
            self.present(controller, animated: true)
        }
    }
}


extension LectureViewController: IQListViewDelegateDataSource {

    func scrollTo(lectureID: Int) {
        serialListKitQueue.async { [self] in
            if let item = self.list.itemIdentifier(of: LectureCell.self, where: { $0.lecture.id == lectureID }) {
                DispatchQueue.main.async {
                    self.list.scrollTo(item: item, at: .none, animated: true)
                }
            }
        }
    }

    private func refreshUI(animated: Bool?, showNoItems: Bool) {

        serialListKitQueue.async { [self] in

            let animated: Bool = animated ?? (models.count <= 1000)
            list.reloadData({

                DispatchQueue.main.async { [self] in
                    activityIndicatorView.startAnimating()
                }

                let section = IQSection(identifier: "Cell", headerSize: CGSize.zero, footerSize: CGSize.zero)
                list.append([section])

                let selecteIDHashTable: [Int: Int] = selectedModels.enumerated().reduce(into: [Int: Int]()) { result, lecture in
                    if result[lecture.element.id] == nil {
                        result[lecture.element.id] = lecture.offset
                    }
                }

                let isOnPlayingList = self is PlayerViewController
                let newModels: [Cell.Model] = models.map { modelLecture in
                    let isSelected: Bool = selecteIDHashTable[modelLecture.id] != nil

                    var showPlaylistIcon: Bool = false
                    if let selectedPlaylist = selectedPlaylist {
                        showPlaylistIcon = selectedPlaylist.lectureIds.contains(where: { modelLecture.id == $0 })
                    }

                    let isHighlited: Bool = highlightedLectures.contains(where: { modelLecture.id == $0.id })
                    return Cell.Model(lecture: modelLecture, isSelectionEnabled: isSelectionEnabled, isSelected: isSelected, enableRemoveFromPlaylist: removeFromPlaylistEnabled, isOnPlayingList: isOnPlayingList, showPlaylistIcon: showPlaylistIcon, isHighlited: isHighlited)
                }

                list.append(Cell.self, models: newModels, section: section)

            }, animatingDifferences: animated, diffing: false, endLoadingOnCompletion: showNoItems, completion: { [self] in
                if showNoItems {
                    let noItemImage = UIImage(named: "music.mic_60")
                    self.list.noItemImage = noItemImage

                    self.list.noItemTitle = self.noItemTitle

                    var finalMessage = self.noItemMessage ?? ""

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

                activityIndicatorView.stopAnimating()
                self.lecturesLoadingFinished()
            })
        }
    }

    internal func reloadSelectedAll(isSelected: Bool) {
        serialListKitQueue.async { [self] in

            list.reloadData({

                let updatedModels: [Cell.Model] = list.itemIdentifiers.compactMap { item in
                    if var cellModel: Cell.Model = item.model as? Cell.Model {
                        cellModel.isSelected = isSelected
                        cellModel.isSelectionEnabled = isSelectionEnabled
                        return cellModel
                    }
                    return nil
                }

                list.deleteAllItems()

                let section = IQSection(identifier: "Cell", headerSize: CGSize.zero, footerSize: CGSize.zero)
                list.append([section])
                list.append(Cell.self, models: updatedModels)

            }, updateExistingSnapshot: true, animatingDifferences: false)
        }
    }

    private func updateLecture(lecture: Lecture, isSelected: Bool? = nil) {
        serialListKitQueue.async { [self] in
            list.reloadData({

                if let item = list.itemIdentifier(where: { item in
                    if let cellModel: Cell.Model = item.model as? Cell.Model {
                        return cellModel.lecture.id == lecture.id
                    }
                    return false
                }) {
                    if var cellModel: Cell.Model = item.model as? Cell.Model {
                        cellModel.lecture = lecture
                        if let isSelected = isSelected {
                            cellModel.isSelected = isSelected
                        }

                        list.reload(Cell.self, models: [cellModel]) { $0.lecture.id == $1.lecture.id }
                    }
                }
            }, updateExistingSnapshot: true, animatingDifferences: false)
        }
    }

    // This delegate Declared here because some subclasses are overriding it.
    func listView(_ listView: IQListView, modifyCell cell: IQListCell, at indexPath: IndexPath) {
        if let cell = cell as? Cell {
            cell.delegate = self
        }
    }

    func listView(_ listView: IQListView, canEdit item: IQItem, at indexPath: IndexPath) -> Bool {
        return self is PlayerViewController
    }

    func listView(_ listView: IQListView, canMove item: IQItem, at indexPath: IndexPath) -> Bool {
        return self is PlayerViewController
    }

    func listView(_ listView: IQListView, move sourceItem: IQItem, at sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if let playerController = self as? PlayerViewController,
           let model = sourceItem.model as? LectureCell.Model,
           sourceIndexPath != destinationIndexPath {
            playerController.moveQueueLecture(id: model.lecture.id, toIndex: destinationIndexPath.item)
        }
    }

    func listView(_ listView: IQListView, commit item: IQItem, style: UITableViewCell.EditingStyle, at indexPath: IndexPath) {
        if let playerController = self as? PlayerViewController,
           style == .delete, let model = item.model as? LectureCell.Model {
            playerController.removeFromQueue(lectureIDs: [model.lecture.id])
        }
    }

    func tableView(_ tableView: UITableView,
                   shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }

    func listView(_ listView: IQListView, didSelect item: IQItem, at indexPath: IndexPath) {

        if let model = item.model as? Cell.Model {

            Haptic.selection()

            if isSelectionEnabled {
                var isSelected: Bool = false
                if let index = selectedModels.firstIndex(where: { $0.id == model.lecture.id }) {
                    selectedModels.remove(at: index)
                    isSelected = false
                } else {
                    selectedModels.append(model.lecture)
                    isSelected = true
                }

                updateLecture(lecture: model.lecture, isSelected: isSelected)
            } else {

                if model.lecture.resources.audios.first?.audioURL != nil {
                    if let playerController = self as? PlayerViewController, let tabController = playerController.parentTabBarController {
                        tabController.showPlayer(lecture: model.lecture)
                    } else if let tabController = self.tabBarController as? TabBarController {
                        tabController.showPlayer(lecture: model.lecture)
                    }
                } else if let videoURL = model.lecture.resources.videos.first?.videoURL {

                    guard UIApplication.shared.canOpenURL(videoURL) else {
                        self.showAlert(title: "Error", message: "Sorry, we are unable to show this video.")
                        return
                    }
                    UIApplication.shared.open(videoURL, options: [:], completionHandler: nil)
                } else {
                    showAlert(title: "No Lecture found", message: "We did not found any lectures to play for '\(model.lecture.titleDisplay)'")
                }
            }
        }
    }
}

extension LectureViewController {

    @objc override func showLoading() {
        super.showLoading()
    }

    @objc override func hideLoading() {
        super.hideLoading()
    }
}
