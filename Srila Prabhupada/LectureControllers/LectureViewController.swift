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
import Loaf

protocol LectureViewControllerDelegate: AnyObject {
    func lectureController(_ controller: LectureViewController, didSelected lectures: [Lecture])
    func lectureControllerDidCancel(_ controller: LectureViewController)
}

class LectureViewController: SearchViewController {

    @IBOutlet private var lectureTebleView: UITableView!

    weak var delegate: LectureViewControllerDelegate?

    private let sortButton: UIBarButtonItem = UIBarButtonItem(image: UIImage(compatibleSystemName: "arrow.up.arrow.down.circle"), style: .plain, target: nil, action: nil)
    private var sortMenu: SPMenu!

    private let moreButton = UIBarButtonItem(image: UIImage(compatibleSystemName: "ellipsis.circle"), style: .plain, target: nil, action: nil)
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
            self.list.loadingMessage = "Loading..."
            list.registerCell(type: Cell.self, registerType: .nib)
            lectureTebleView.tableFooterView = UIView()
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

    @objc private func lectureUpdateNotification(_ notification: Notification) {

        if let lectures: [Lecture] = notification.object as? [Lecture] {

            serialListKitQueue.async { [self] in
                var newModels = self.models
                for lecture in lectures {

                    if self is DownloadViewController { // If download controller, then we also need to remove or add it in UI
                        if lecture.downloadState == .notDownloaded {
                            newModels.removeAll(where: { $0.id == lecture.id })
                        } else {
                            let lectureIndexes = newModels.allIndex(where: { $0.id == lecture.id })
                            if !lectureIndexes.isEmpty {
                                for index in lectureIndexes {
                                    newModels[index] = lecture
                                }
                            } else {
                                newModels.insert(lecture, at: 0)
                            }
                        }
                    } else if self is FavouritesViewController {    // If favorites controller, then we also need to remove or add it in UI
                        if lecture.isFavourite {
                            let lectureIndexes = newModels.allIndex(where: { $0.id == lecture.id })
                            if !lectureIndexes.isEmpty {
                                for index in lectureIndexes {
                                    newModels[index] = lecture
                                }
                            } else {
                                newModels.insert(lecture, at: 0)
                            }
                        } else {
                            newModels.removeAll(where: { $0.id == lecture.id })
                        }
                    } else {
                        let lectureIndexes = newModels.allIndex(where: { $0.id == lecture.id })
                        for index in lectureIndexes {
                            newModels[index] = lecture
                        }
                    }
                }

                DispatchQueue.main.async {
                    self.models = newModels
                    self.refreshUI(showNoItems: true)
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

    override func refresh(source: FirestoreSource) {
        refresh(source: source, existing: nil)
    }

    func refresh(source: FirestoreSource, existing: [Lecture]?) {

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
                self.list.setIsLoading(false, animated: true)
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

            let action: SPAction = SPAction(title: sortType.rawValue, image: sortType.image, identifier: .init(sortType.rawValue), state: state, handler: { [self] action in
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
        if let icon = selectedSortType.imageSelected {
            sortButton.image = icon
        } else {
            sortButton.image = UIImage(compatibleSystemName: "arrow.up.arrow.down.circle")
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

        let selectAll: SPAction = SPAction(title: "Select All", image: UIImage(compatibleSystemName: "checkmark.circle.fill"), handler: { [self] (_) in
            selectedModels = models
            refreshUI(animated: false, showNoItems: true)
        })
        let deselectAll: SPAction = SPAction(title: "Deselect All", image: UIImage(compatibleSystemName: "checkmark.circle"), handler: { [self] (_) in
            selectedModels.removeAll()
            refreshUI(animated: false, showNoItems: true)
        })

        for option in LectureOption.allCases {
            let action: SPAction = SPAction(title: option.rawValue, image: option.image, identifier: .init(option.rawValue), handler: { [self] _ in

                guard !selectedModels.isEmpty else {
                    return
                }

                switch option {
                case .download:
                    let eligibleDownloadModels: [Model] = selectedModels.filter { $0.downloadState == .notDownloaded || $0.downloadState == .error }
                    Persistant.shared.save(lectures: eligibleDownloadModels)

                    DefaultLectureViewModel.defaultModel.updateLectureInfo(lectures: eligibleDownloadModels, isCompleted: nil, isDownloaded: true, isFavourite: nil, lastPlayedPoint: nil, completion: { _ in
                    })

                case .deleteFromDownloads:
                    let eligibleDeleteFromDownloadsModels: [Model] = selectedModels.filter { $0.downloadState == .downloaded || $0.downloadState == .error }
                    Persistant.shared.delete(lectures: eligibleDeleteFromDownloadsModels)

                    DefaultLectureViewModel.defaultModel.updateLectureInfo(lectures: eligibleDeleteFromDownloadsModels, isCompleted: nil, isDownloaded: false, isFavourite: nil, lastPlayedPoint: nil, completion: {_ in })
                case .markAsFavourite:
                    let eligibleMarkAsFavouriteModels: [Model] = selectedModels.filter { !$0.isFavourite }

                    DefaultLectureViewModel.defaultModel.updateLectureInfo(lectures: eligibleMarkAsFavouriteModels, isCompleted: nil, isDownloaded: nil, isFavourite: true, lastPlayedPoint: nil, completion: { result in
                        switch result {
                        case .success:
                            if eligibleMarkAsFavouriteModels.count == 1 {
                                Loaf("Favorited", state: .success, sender: self).show(.short)
                            } else {
                                Loaf("Favorited \(eligibleMarkAsFavouriteModels) lecture(s)", state: .success, sender: self).show(.short)
                            }
                        case .failure(let error):
                            Loaf(error.localizedDescription, state: .error, sender: self).show(.short)
                        }

                    })
                case .removeFromFavourites:
                    let eligibleRemoveFromFavouritesModels: [Model] = selectedModels.filter { $0.isFavourite }
                    DefaultLectureViewModel.defaultModel.updateLectureInfo(lectures: eligibleRemoveFromFavouritesModels, isCompleted: nil, isDownloaded: nil, isFavourite: false, lastPlayedPoint: nil, completion: { result in
                        switch result {
                        case .success:
                            if eligibleRemoveFromFavouritesModels.count == 1 {
                                Loaf("Unfavorited", state: .success, sender: self).show(.short)
                            } else {
                                Loaf("Unfavorited \(eligibleRemoveFromFavouritesModels) lecture(s)", state: .success, sender: self).show(.short)
                            }
                        case .failure(let error):
                            Loaf(error.localizedDescription, state: .error, sender: self).show(.short)
                        }

                    })
                case .addToPlaylist:
                    let navigationController = UIStoryboard.playlists.instantiate(UINavigationController.self, identifier: "PlaylistNavigationController")
                    guard let playlistController = navigationController.viewControllers.first as? PlaylistViewController else {
                        return
                    }
                    playlistController.lecturesToAdd = selectedModels
                    self.present(navigationController, animated: true, completion: nil)
                case .markAsHeard:
                    let eligibleMarkAsHeardModels: [Model] = selectedModels.filter { $0.playProgress < 1.0 }
                    DefaultLectureViewModel.defaultModel.updateLectureInfo(lectures: eligibleMarkAsHeardModels, isCompleted: true, isDownloaded: nil, isFavourite: nil, lastPlayedPoint: -1, completion: { result in
                        switch result {
                        case .success:
                            if eligibleMarkAsHeardModels.count == 1 {
                                Loaf("Marked as heard", state: .success, sender: self).show(.short)
                            } else {
                                Loaf("Marked heard \(eligibleMarkAsHeardModels) lecture(s)", state: .success, sender: self).show(.short)
                            }
                        case .failure(let error):
                            Loaf(error.localizedDescription, state: .error, sender: self).show(.short)
                        }

                    })
                case .resetProgress:
                    let eligibleResetProgressModels: [Model] = selectedModels.filter { $0.playProgress >= 1.0 }
                    DefaultLectureViewModel.defaultModel.updateLectureInfo(lectures: eligibleResetProgressModels, isCompleted: false, isDownloaded: nil, isFavourite: nil, lastPlayedPoint: 0, completion: { result in
                        switch result {
                        case .success:
                            if eligibleResetProgressModels.count == 1 {
                                Loaf("Progress reset", state: .success, sender: self).show(.short)
                            } else {
                                Loaf("Progress reset of \(eligibleResetProgressModels) lecture(s)", state: .success, sender: self).show(.short)
                            }

                        case .failure(let error):
                            Loaf(error.localizedDescription, state: .error, sender: self).show(.short)
                        }

                    })
                case .share, .downloading:
                    break
               }

                cancelSelection()
            })

            if option == .deleteFromDownloads {
                action.action.attributes = .destructive
            }

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

            let eligibleDownloadModels: [Model] = selectedModels.filter { $0.downloadState == .notDownloaded || $0.downloadState == .error }
            if !eligibleDownloadModels.isEmpty, let download = allActions[.download] {
                download.action.title = LectureOption.download.rawValue + " (\(eligibleDownloadModels.count))"
                menuItems.append(download)
            }

            let eligibleDeleteFromDownloadsModels: [Model] = selectedModels.filter { $0.downloadState == .downloaded || $0.downloadState == .error }
            if !eligibleDeleteFromDownloadsModels.isEmpty, let deleteFromDownloads = allActions[.deleteFromDownloads] {
                deleteFromDownloads.action.title = LectureOption.deleteFromDownloads.rawValue + " (\(eligibleDeleteFromDownloadsModels.count))"
                menuItems.append(deleteFromDownloads)
            }

            let eligibleMarkAsFavouriteModels: [Model] = selectedModels.filter { !$0.isFavourite }
            if !eligibleMarkAsFavouriteModels.isEmpty, let markAsFavourite = allActions[.markAsFavourite] {
                markAsFavourite.action.title = LectureOption.markAsFavourite.rawValue + " (\(eligibleMarkAsFavouriteModels.count))"
                menuItems.append(markAsFavourite)
            }

            let eligibleRemoveFromFavouritesModels: [Model] = selectedModels.filter { $0.isFavourite }
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

            }, animatingDifferences: animated, endLoadingOnUpdate: showNoItems, completion: { [self] in
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

                guard model.lecture.resources.audios.first?.audioURL != nil else {
                    showAlert(title: "No Lecture found", message: "We did not found any lectures to play for '\(model.lecture.titleDisplay)'")
                    return
                }

                if let playerController = self as? PlayerViewController, let tabController = playerController.parentTabBarController {
                    tabController.showPlayer(lecture: model.lecture, playlistLectures: self.models)
                } else if let tabController = self.tabBarController as? TabBarController {
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
            DefaultLectureViewModel.defaultModel.updateLectureInfo(lectures: [lecture], isCompleted: nil, isDownloaded: nil, isFavourite: true, lastPlayedPoint: nil, completion: { result in
                switch result {
                case .success:
                    Loaf("Favorited", state: .success, sender: self).show(.short)
                case .failure(let error):
                    Loaf(error.localizedDescription, state: .error, sender: self).show(.short)
                }

            })
        case .removeFromFavourites:
            DefaultLectureViewModel.defaultModel.updateLectureInfo(lectures: [lecture], isCompleted: nil, isDownloaded: nil, isFavourite: false, lastPlayedPoint: nil, completion: { result in
                switch result {
                case .success:
                    Loaf("Unfavorited", state: .success, sender: self).show(.short)
                case .failure(let error):
                    Loaf(error.localizedDescription, state: .error, sender: self).show(.short)
                }

            })
        case .addToPlaylist:

            let navigationController = UIStoryboard.playlists.instantiate(UINavigationController.self, identifier: "PlaylistNavigationController")
            guard let playlistController = navigationController.viewControllers.first as? PlaylistViewController else {
                return
            }
            playlistController.lecturesToAdd = [lecture]
            self.present(navigationController, animated: true, completion: nil)

        case .markAsHeard:
            DefaultLectureViewModel.defaultModel.updateLectureInfo(lectures: [lecture], isCompleted: true, isDownloaded: nil, isFavourite: nil, lastPlayedPoint: -1, completion: { result in
                switch result {
                case .success:
                    Loaf("Marked as heard", state: .success, sender: self).show(.short)
                case .failure(let error):
                    Loaf(error.localizedDescription, state: .error, sender: self).show(.short)
                }

            })
        case .resetProgress:
            DefaultLectureViewModel.defaultModel.updateLectureInfo(lectures: [lecture], isCompleted: false, isDownloaded: nil, isFavourite: nil, lastPlayedPoint: 0, completion: { result in
                switch result {
                case .success:
                    Loaf("Progress reset", state: .success, sender: self).show(.short)

                case .failure(let error):
                    Loaf(error.localizedDescription, state: .error, sender: self).show(.short)
                }

            })
        case .share:

            let deepLinkBaseURL = "https://bvks.com?lectureId=\(lecture.id)"
            let domainURIPrefix = "https://prabhupada.page.link"

            var descriptions: [String] = []
            do {
                let durationString = "• Duration: " + lecture.lengthTime.displayString
                descriptions.append(durationString)

                if !lecture.legacyData.verse.isEmpty {
                    let verseString = "• " + lecture.legacyData.verse
                    descriptions.append(verseString)
                }

                let recordingDateString = "• Date of Recording: " + lecture.dateOfRecording.display_dd_MM_yyyy
                descriptions.append(recordingDateString)

                if !lecture.location.displayString.isEmpty {
                    let locationString = "• Location: " + lecture.location.displayString
                    descriptions.append(locationString)
                }
            }

            guard let link = URL(string: deepLinkBaseURL),
                  let linkBuilder = DynamicLinkComponents(link: link, domainURIPrefix: domainURIPrefix) else {
                return
            }

            do {
                let iOSParameters = DynamicLinkIOSParameters(bundleID: "com.bvksdigital.acbsp")
                iOSParameters.appStoreID = "1645287937"
                linkBuilder.iOSParameters = iOSParameters
            }

            do {
                let androidParameters = DynamicLinkAndroidParameters(packageName: "com.iskcon.prabhupada")
                 linkBuilder.androidParameters = androidParameters
            }

            do {
                let socialMediaParameters = DynamicLinkSocialMetaTagParameters()
                socialMediaParameters.title = lecture.titleDisplay
                socialMediaParameters.descriptionText = descriptions.joined(separator: "\n")
                if let thumbnailURL = lecture.thumbnailURL {
                    socialMediaParameters.imageURL = thumbnailURL
                }
                linkBuilder.socialMetaTagParameters = socialMediaParameters
            }

            linkBuilder.shorten() { url, _, _ in
                var appLinks: [Any] = []
                if let url = url {
                    appLinks.append(url)
                } else if let url = linkBuilder.url {
                    appLinks.append(url)
                }

                guard !appLinks.isEmpty else {
                    return
                }

                let shareController = UIActivityViewController(activityItems: appLinks, applicationActivities: nil)
                shareController.popoverPresentationController?.sourceView = cell
                self.present(shareController, animated: true)
            }

        case .downloading:
            break
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
