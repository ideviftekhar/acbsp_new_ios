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
    private var sortMenu: UIMenu!

    private lazy var doneSelectionButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneSelectionAction(_:)))
    var isSelectionEnabled: Bool = false
    var selectedModels: [Model] = []

    static let lectureViewModel: LectureViewModel = DefaultLectureViewModel()

    var selectedSortType: LectureSortType {
        if #available(iOS 15.0, *) {
            guard let selectedSortAction = sortMenu.selectedElements.first as? UIAction,
                  let selectedSortType = LectureSortType(rawValue: selectedSortAction.identifier.rawValue) else {
                return LectureSortType.default
            }
            return selectedSortType
        } else {
            guard let children: [UIAction] = sortMenu.children as? [UIAction],
                  let selectedSortAction = children.first(where: { $0.state == .on }),
                    let selectedSortType = LectureSortType(rawValue: selectedSortAction.identifier.rawValue) else {
                return LectureSortType.default
            }
            return selectedSortType
        }
    }

    typealias Model = Lecture
    typealias Cell = LectureCell

    private var models: [Model] = []
    private(set) lazy var list = IQList(listView: lectureTebleView, delegateDataSource: self)

    var noItemTitle: String?
    var noItemMessage: String?

    override func viewDidLoad() {
       super.viewDidLoad()

        var rightButtons = self.navigationItem.rightBarButtonItems ?? []
        rightButtons.append(sortButton)
        if isSelectionEnabled {
            rightButtons.insert(doneSelectionButton, at: 0)
        }
        self.navigationItem.rightBarButtonItems = rightButtons

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
    }

    @objc private func doneSelectionAction(_ sender: UIBarButtonItem) {
        delegate?.lectureController(self, didSelected: selectedModels)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func refreshAsynchronous(source: FirestoreSource) {
        super.refreshAsynchronous(source: source)
    }
}

extension LectureViewController {

    private func configureSortButton() {
        var actions: [UIAction] = []

        let userDefaultKey: String = "\(Self.self).\(LectureSortType.self)"
        let lastType: LectureSortType

        if let typeString = UserDefaults.standard.string(forKey: userDefaultKey), let type = LectureSortType(rawValue: typeString) {
            lastType = type
        } else {
            lastType = .default
        }

        for sortType in LectureSortType.allCases {

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
        let userDefaultKey: String = "\(Self.self).\(LectureSortType.self)"
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

extension LectureViewController: IQListViewDelegateDataSource {

    private func refreshUI(animated: Bool? = nil) {

        DispatchQueue.global().async { [self] in
            
            let animated: Bool = animated ?? (models.count <= 1000)
            list.performUpdates({
                
                let section = IQSection(identifier: "Cell", headerSize: CGSize.zero, footerSize: CGSize.zero)
                list.append(section)
                
                let newModels: [Cell.Model] = models.map { modelLecture in
                    Cell.Model(lecture: modelLecture, isSelectionEnabled: isSelectionEnabled, isSelected: selectedModels.contains(where: { modelLecture.id == $0.id }))
                }
                
                list.append(Cell.self, models: newModels, section: section)
                
            }, animatingDifferences: animated, completion: {
                self.list.noItemTitle = self.noItemTitle
                self.list.noItemMessage = self.noItemMessage
            })
        }
    }

    func listView(_ listView: IQListView, modifyCell cell: IQListCell, at indexPath: IndexPath) {
        if let cell = cell as? Cell {
            cell.delegate = self
        }
    }

    func listView(_ listView: IQListView, didSelect item: IQItem, at indexPath: IndexPath) {

        if let model = item.model as? Cell.Model {

            if isSelectionEnabled {
                if let index = selectedModels.firstIndex(of: model.lecture) {
                    selectedModels.remove(at: index)
                } else {
                    selectedModels.append(model.lecture)
                }
                refreshUI(animated: false)
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
            Persistant.shared.save(lecture: lecture)
        case .deleteFromDownloads:
            Persistant.shared.delete(lecture: lecture)
        case .markAsFavourite:
            Self.lectureViewModel.favourite(lecture: lecture, isFavourite: true, completion: {_ in })
        case .removeFromFavourites:
            Self.lectureViewModel.favourite(lecture: lecture, isFavourite: false, completion: {_ in })
        case .addToPlaylist:

            let navigationController = UIStoryboard.playlists.instantiate(UINavigationController.self, identifier: "PlaylistNavigationController")
            guard let playlistController = navigationController.viewControllers.first as? PlaylistViewController else {
                return
            }
            playlistController.lectureToAdd = lecture
            self.present(navigationController, animated: true, completion: nil)

        case .markAsHeard:
            break
        case .resetProgress:
            break
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
        self.list.noItemTitle = nil
        self.list.noItemMessage = nil
    }

    @objc func hideLoading() {
        loadingIndicator.stopAnimating()
    }

    func reloadData(with lectures: [Model]) {
        self.models = lectures
        refreshUI()
    }
}
