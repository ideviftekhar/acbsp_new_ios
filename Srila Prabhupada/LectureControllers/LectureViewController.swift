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

protocol LectureViewControllerDelegate: AnyObject {
    func lectureController(_ controller: LectureViewController, didSelected lectures: [Lecture])
    func lectureControllerDidCancel(_ controller: LectureViewController)
}

class LectureViewController: SearchViewController {

    @IBOutlet private var lectureTebleView: UITableView!
    private let loadingIndicator: UIActivityIndicatorView = {
        if #available(iOS 13.0, *) {
            return UIActivityIndicatorView(style: .medium)
        } else {
            return UIActivityIndicatorView(style: .gray)
        }
    }()

    weak var delegate: LectureViewControllerDelegate?

    private let sortButton: UIBarButtonItem = UIBarButtonItem(image: UIImage(compatibleSystemName: "arrow.up.arrow.down.circle"), style: .plain, target: nil, action: nil)
    private var sortMenu: SPMenu!

    private let moreButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), style: .plain, target: nil, action: nil)
    private var moreMenu: SPMenu!
    private var defaultSelectionActions: [SPAction] = []
    private var defaultNormalActions: [SPAction] = []
    private var allActions: [LectureOption: SPAction] = [:]

    private lazy var doneSelectionButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneSelectionAction(_:)))
    private lazy var cancelSelectionButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelButtonAction(_:)))

    var isSelectionEnabled: Bool = false
    var selectedModels: [Model] = [] {
        didSet {
            doneSelectionButton.isEnabled = !selectedModels.isEmpty
            refreshMoreOption()
        }
    }

    var selectedSortType: LectureSortType {
        guard let selectedSortAction = sortMenu.selectedAction,
              let selectedSortType = LectureSortType(rawValue: selectedSortAction.action.identifier.rawValue) else {
            return LectureSortType.default
        }
        return selectedSortType
    }

    typealias Model = Lecture
    typealias Cell = LectureCell

    private var models: [Model] = []
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
            rightButtons.insert(doneSelectionButton, at: 0)
            self.navigationItem.leftBarButtonItem = cancelSelectionButton
        }

        self.navigationItem.rightBarButtonItems = rightButtons

        do {
            list.registerCell(type: Cell.self, registerType: .nib)
            lectureTebleView.tableFooterView = UIView()
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
        configureSelectionButton()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidShowNotification, object: nil)
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

    override func refresh(source: FirestoreSource) {
        refresh(source: source, existing: nil)
    }

    func refresh(source: FirestoreSource, existing: [Lecture]?) {

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

    func refreshAsynchronous(source: FirestoreSource, completion: @escaping (_ result: Swift.Result<[Lecture], Error>) -> Void) {
        completion(.success(self.models))
    }

    // This delegate Declared here because some subclasses are overriding it.
    func listView(_ listView: IQListView, modifyCell cell: IQListCell, at indexPath: IndexPath) {
        if let cell = cell as? Cell {
            cell.delegate = self
        }
    }
}

extension LectureViewController {

    private func configureSortButton() {
        var actions: [SPAction] = []

        let userDefaultKey: String = "\(Self.self).\(LectureSortType.self)"
        let lastType: LectureSortType

        if let typeString = UserDefaults.standard.string(forKey: userDefaultKey), let type = LectureSortType(rawValue: typeString) {
            lastType = type
        } else {
            lastType = .default
        }

        for sortType in LectureSortType.allCases {

            let state: UIAction.State = (lastType == sortType ? .on : .off)

            let action: SPAction = SPAction(title: sortType.rawValue, image: nil, identifier: .init(sortType.rawValue), state: state, handler: { [self] action in
                sortActionSelected(action: action)
            })

            actions.append(action)
        }

        self.sortMenu = SPMenu(title: "", image: nil, identifier: .init(rawValue: "Sort"), options: .displayInline, children: actions, barButton: sortButton, parent: self)

        updateSortButtonUI()
    }

    private func sortActionSelected(action: UIAction) {
        let userDefaultKey: String = "\(Self.self).\(LectureSortType.self)"
        UserDefaults.standard.set(action.identifier.rawValue, forKey: userDefaultKey)
        UserDefaults.standard.synchronize()

        let children: [SPAction] = self.sortMenu.children
        for anAction in children {
            if anAction.action.identifier == action.identifier { anAction.action.state = .on  } else {  anAction.action.state = .off }
        }
        self.sortMenu.children = children

        updateSortButtonUI()

        refresh(source: .cache)
    }

    private func updateSortButtonUI() {
        if selectedSortType == .default {
            sortButton.image = UIImage(compatibleSystemName: "arrow.up.arrow.down.circle")
        } else {
            sortButton.image = UIImage(compatibleSystemName: "arrow.up.arrow.down.circle.fill")
        }
    }
}

extension LectureViewController {

    @objc private func doneSelectionAction(_ sender: UIBarButtonItem) {
        delegate?.lectureController(self, didSelected: selectedModels)
    }

    private func startSelection() {
        isSelectionEnabled = true
        selectedModels.removeAll()
        refreshUI(animated: false, showNoItems: true)
        navigationItem.leftBarButtonItem = cancelSelectionButton
    }

    private func cancelSelection() {
        isSelectionEnabled = false
        selectedModels.removeAll()
        refreshUI(animated: false, showNoItems: true)
        navigationItem.leftBarButtonItem = hamburgerBarButton
    }

    @objc private func cancelButtonAction(_ sender: UIBarButtonItem) {
        if delegate != nil {
            delegate?.lectureControllerDidCancel(self)
        } else {
            cancelSelection()
        }
    }

    private func configureSelectionButton() {

        let select: SPAction = SPAction(title: "Select", image: nil, handler: { [self] (_) in
            startSelection()
        })

        let cancel: SPAction = SPAction(title: "Cancel", image: nil, handler: { [self] (_) in
            cancelSelection()
        })

        let selectAll: SPAction = SPAction(title: "Select All", image: nil, handler: { [self] (_) in
            selectedModels = models
            refreshUI(animated: false, showNoItems: true)
        })
        let deselectAll: SPAction = SPAction(title: "Deselect All", image: nil, handler: { [self] (_) in
            selectedModels.removeAll()
            refreshUI(animated: false, showNoItems: true)
        })

        for option in LectureOption.allCases {
            let action: SPAction = SPAction(title: option.rawValue, image: nil, identifier: .init(option.rawValue), handler: { [self] _ in

                guard !selectedModels.isEmpty else {
                    return
                }

                switch option {
                case .download:
                    let eligibleDownloadModels: [Model] = selectedModels.filter { $0.downloadingState == .notDownloaded || $0.downloadingState == .error }
                    Persistant.shared.save(lectures: eligibleDownloadModels)

                    DefaultLectureViewModel.defaultModel.updateLectureInfo(lectures: eligibleDownloadModels, isCompleted: nil, isDownloaded: true, isFavourite: nil, lastPlayedPoint: nil, completion: {_ in })

                case .deleteFromDownloads:
                    let eligibleDeleteFromDownloadsModels: [Model] = selectedModels.filter { $0.downloadingState == .downloaded }
                    Persistant.shared.delete(lectures: eligibleDeleteFromDownloadsModels)

                    DefaultLectureViewModel.defaultModel.updateLectureInfo(lectures: eligibleDeleteFromDownloadsModels, isCompleted: nil, isDownloaded: false, isFavourite: nil, lastPlayedPoint: nil, completion: {_ in })
                case .markAsFavourite:
                    let eligibleMarkAsFavouriteModels: [Model] = selectedModels.filter { !$0.isFavourites }

                    DefaultLectureViewModel.defaultModel.updateLectureInfo(lectures: eligibleMarkAsFavouriteModels, isCompleted: nil, isDownloaded: nil, isFavourite: true, lastPlayedPoint: nil, completion: {_ in })
                case .removeFromFavourites:
                    let eligibleRemoveFromFavouritesModels: [Model] = selectedModels.filter { $0.isFavourites }
                    DefaultLectureViewModel.defaultModel.updateLectureInfo(lectures: eligibleRemoveFromFavouritesModels, isCompleted: nil, isDownloaded: nil, isFavourite: false, lastPlayedPoint: nil, completion: {_ in })
                case .addToPlaylist:
                    let navigationController = UIStoryboard.playlists.instantiate(UINavigationController.self, identifier: "PlaylistNavigationController")
                    guard let playlistController = navigationController.viewControllers.first as? PlaylistViewController else {
                        return
                    }
                    playlistController.lecturesToAdd = selectedModels
                    self.present(navigationController, animated: true, completion: nil)
                case .markAsHeard:
                    let eligibleMarkAsHeardModels: [Model] = selectedModels.filter { $0.playProgress < 1.0 }
                    DefaultLectureViewModel.defaultModel.updateLectureInfo(lectures: eligibleMarkAsHeardModels, isCompleted: true, isDownloaded: nil, isFavourite: nil, lastPlayedPoint: -1, completion: {_ in })
                case .resetProgress:
                    let eligibleResetProgressModels: [Model] = selectedModels.filter { $0.playProgress >= 1.0 }
                    DefaultLectureViewModel.defaultModel.updateLectureInfo(lectures: eligibleResetProgressModels, isCompleted: false, isDownloaded: nil, isFavourite: nil, lastPlayedPoint: 0, completion: {_ in })
                case .share, .downloading:
                    break
               }

                cancelSelection()
            })
            allActions[option] = action
        }

        if delegate != nil {
            defaultNormalActions = []
            defaultSelectionActions = [selectAll, deselectAll]
            moreMenu = SPMenu(title: "", image: nil, identifier: UIMenu.Identifier.init("More Menu"), options: [], children: defaultSelectionActions, barButton: moreButton, parent: self)
        } else {
            defaultNormalActions = [select]
            defaultSelectionActions = [cancel, selectAll, deselectAll]
            moreMenu = SPMenu(title: "", image: nil, identifier: UIMenu.Identifier.init("More Menu"), options: [], children: defaultNormalActions, barButton: moreButton, parent: self)
        }
    }

    private func refreshMoreOption() {

        guard delegate == nil else {
            return
        }

        var menuItems: [SPAction] = []

        if isSelectionEnabled {
            menuItems.append(contentsOf: defaultSelectionActions)
        } else {
            menuItems.append(contentsOf: defaultNormalActions)
        }

        if !selectedModels.isEmpty {

            let eligibleDownloadModels: [Model] = selectedModels.filter { $0.downloadingState == .notDownloaded || $0.downloadingState == .error }
            if !eligibleDownloadModels.isEmpty, let download = allActions[.download] {
                download.action.title = LectureOption.download.rawValue + " (\(eligibleDownloadModels.count))"
                menuItems.append(download)
            }

            let eligibleDeleteFromDownloadsModels: [Model] = selectedModels.filter { $0.downloadingState == .downloaded }
            if !eligibleDeleteFromDownloadsModels.isEmpty, let deleteFromDownloads = allActions[.deleteFromDownloads] {
                deleteFromDownloads.action.title = LectureOption.deleteFromDownloads.rawValue + " (\(eligibleDeleteFromDownloadsModels.count))"
                menuItems.append(deleteFromDownloads)
            }

            let eligibleMarkAsFavouriteModels: [Model] = selectedModels.filter { !$0.isFavourites }
            if !eligibleMarkAsFavouriteModels.isEmpty, let markAsFavourite = allActions[.markAsFavourite] {
                markAsFavourite.action.title = LectureOption.markAsFavourite.rawValue + " (\(eligibleMarkAsFavouriteModels.count))"
                menuItems.append(markAsFavourite)
            }

            let eligibleRemoveFromFavouritesModels: [Model] = selectedModels.filter { $0.isFavourites }
            if !eligibleRemoveFromFavouritesModels.isEmpty, let removeFromFavourites = allActions[.removeFromFavourites] {
                removeFromFavourites.action.title = LectureOption.removeFromFavourites.rawValue + " (\(eligibleRemoveFromFavouritesModels.count))"
                menuItems.append(removeFromFavourites)
            }

            if let addToPlaylist = allActions[.addToPlaylist] {
                addToPlaylist.action.title = LectureOption.addToPlaylist.rawValue + " (\(selectedModels.count))"
                menuItems.append(addToPlaylist)
            }

            let eligibleMarkAsHeardModels: [Model] = selectedModels.filter { $0.playProgress < 1.0 }
            if !eligibleMarkAsHeardModels.isEmpty, let markAsHeard = allActions[.markAsHeard] {
                markAsHeard.action.title = LectureOption.markAsHeard.rawValue + " (\(eligibleMarkAsHeardModels.count))"
                menuItems.append(markAsHeard)
            }

            let eligibleResetProgressModels: [Model] = selectedModels.filter { $0.playProgress >= 1.0 }
            if !eligibleResetProgressModels.isEmpty, let resetProgress = allActions[.resetProgress] {
                resetProgress.action.title = LectureOption.resetProgress.rawValue + " (\(eligibleResetProgressModels.count))"
                menuItems.append(resetProgress)
            }
        }

        self.moreMenu.children = menuItems
    }
}

extension LectureViewController: IQListViewDelegateDataSource {

    private func refreshUI(animated: Bool? = nil, showNoItems: Bool) {

        serialListKitQueue.async { [self] in

            let animated: Bool = animated ?? (models.count <= 1000)
            list.performUpdates({

                let section = IQSection(identifier: "Cell", headerSize: CGSize.zero, footerSize: CGSize.zero)
                list.append(section)

                let newModels: [Cell.Model] = models.map { modelLecture in
                    Cell.Model(lecture: modelLecture, isSelectionEnabled: isSelectionEnabled, isSelected: selectedModels.contains(where: { modelLecture.id == $0.id }))
                }

                list.append(Cell.self, models: newModels, section: section)

            }, animatingDifferences: animated, completion: {
                if showNoItems {
                    self.list.noItemTitle = self.noItemTitle
                    self.list.noItemMessage = self.noItemMessage
                }
            })
        }
    }

    func listView(_ listView: IQListView, didSelect item: IQItem, at indexPath: IndexPath) {

        if let model = item.model as? Cell.Model {

            if isSelectionEnabled {
                if let index = selectedModels.firstIndex(where: { $0.id == model.lecture.id }) {
                    selectedModels.remove(at: index)
                } else {
                    selectedModels.append(model.lecture)
                }
                refreshUI(animated: false, showNoItems: true)
            } else {
                if let tabController = self.tabBarController as? TabBarController {
                    tabController.showPlayer(lecture: model.lecture, playlistLectures: self.models)
                }
            }
        }
    }
}

extension LectureViewController: LectureCellDelegate {
    func lectureCell(_ cell: LectureCell, didSelected option: LectureOption, with lecture: Lecture) {

        switch option {
        case .download:
            Persistant.shared.save(lectures: [lecture])
            DefaultLectureViewModel.defaultModel.updateLectureInfo(lectures: [lecture], isCompleted: nil, isDownloaded: true, isFavourite: nil, lastPlayedPoint: nil, completion: {_ in })
        case .deleteFromDownloads:
            Persistant.shared.delete(lectures: [lecture])
            DefaultLectureViewModel.defaultModel.updateLectureInfo(lectures: [lecture], isCompleted: nil, isDownloaded: false, isFavourite: nil, lastPlayedPoint: nil, completion: {_ in })
        case .markAsFavourite:
            DefaultLectureViewModel.defaultModel.updateLectureInfo(lectures: [lecture], isCompleted: nil, isDownloaded: nil, isFavourite: true, lastPlayedPoint: nil, completion: {_ in })
        case .removeFromFavourites:
            DefaultLectureViewModel.defaultModel.updateLectureInfo(lectures: [lecture], isCompleted: nil, isDownloaded: nil, isFavourite: false, lastPlayedPoint: nil, completion: {_ in })
        case .addToPlaylist:

            let navigationController = UIStoryboard.playlists.instantiate(UINavigationController.self, identifier: "PlaylistNavigationController")
            guard let playlistController = navigationController.viewControllers.first as? PlaylistViewController else {
                return
            }
            playlistController.lecturesToAdd = [lecture]
            self.present(navigationController, animated: true, completion: nil)

        case .markAsHeard:
            DefaultLectureViewModel.defaultModel.updateLectureInfo(lectures: [lecture], isCompleted: true, isDownloaded: nil, isFavourite: nil, lastPlayedPoint: -1, completion: {_ in })
        case .resetProgress:
            DefaultLectureViewModel.defaultModel.updateLectureInfo(lectures: [lecture], isCompleted: false, isDownloaded: nil, isFavourite: nil, lastPlayedPoint: 0, completion: {_ in })
        case .share:
            break
        case .downloading:
            break
        }
    }
}

extension LectureViewController {

    @objc func showLoading() {
        loadingIndicator.startAnimating()
    }

    @objc func hideLoading() {
        loadingIndicator.stopAnimating()
    }
}
