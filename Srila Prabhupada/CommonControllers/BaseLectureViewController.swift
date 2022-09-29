//
//  BaseLectureViewController.swift
//  SrilaPrabhupada
//
//  Created by IE06 on 08/09/22.
//

import UIKit
import AVKit
import FirebaseFirestore
import IQListKit

class BaseLectureViewController: BaseSearchViewController {

    @IBOutlet private var lectureTebleView: UITableView!
    private let loadingIndicator: UIActivityIndicatorView = UIActivityIndicatorView(style: .medium)
    private let sortButton: UIBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "arrow.up.arrow.down.circle"), style: .plain, target: nil, action: nil)

    static let lectureViewModel: LectureViewModel = DefaultLectureViewModel()

    typealias Model = Lecture
    typealias Cell = LectureCell

    private(set) var lectures: [Model] = []
    private(set) lazy var list = IQList(listView: lectureTebleView, delegateDataSource: self)

    var selectedSortType: LectureSortType {
        guard let selectedSortAction = sortButton.menu?.selectedElements.first as? UIAction, let selectedSortType = LectureSortType(rawValue: selectedSortAction.identifier.rawValue) else {
            return LectureSortType.default
        }
        return selectedSortType
    }

    override func viewDidLoad() {
       super.viewDidLoad()

        var rightButtons = self.navigationItem.rightBarButtonItems ?? []
        rightButtons.append(sortButton)
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

    func configureSortButton() {
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

                for anAction in actions {
                    if anAction.identifier == action.identifier { anAction.state = .on  } else {  anAction.state = .off }
                }

                updateSortButtonUI()

                UserDefaults.standard.set(action.identifier.rawValue, forKey: userDefaultKey)
                UserDefaults.standard.synchronize()

                self.sortButton.menu = self.sortButton.menu?.replacingChildren(actions)

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
}

extension BaseLectureViewController: IQListViewDelegateDataSource {

    private func refreshUI(animated: Bool? = nil) {

        let animated: Bool = animated ?? (lectures.count <= 1000)
        list.performUpdates({

            let section = IQSection(identifier: "lectures", headerSize: CGSize.zero, footerSize: CGSize.zero)
            list.append(section)

            list.append(Cell.self, models: lectures, section: section)

        }, animatingDifferences: animated, completion: nil)
    }

    func listView(_ listView: IQListView, modifyCell cell: IQListCell, at indexPath: IndexPath) {
        if let cell = cell as? Cell {
            cell.delegate = self
        }
    }

    func listView(_ listView: IQListView, didSelect item: IQItem, at indexPath: IndexPath) {

        if let model = item.model as? Cell.Model {

            if model.downloadingState == .downloaded, let audioURL = model.localFileURL {

                let playerController = AVPlayerViewController()
                playerController.player = AVPlayer(url: audioURL)
                self.present(playerController, animated: true) {
                    playerController.player?.play()
                }
            } else {
                guard let firstAudio = model.resources.audios.first,
                      let audioURL = firstAudio.audioURL else {
                    return
                }

                let playerController = AVPlayerViewController()
                playerController.player = AVPlayer(url: audioURL)
                self.present(playerController, animated: true) {
                    playerController.player?.play()
                }
            }
        }
    }
}

extension BaseLectureViewController: LectureCellDelegate {
    func lectureCell(_ cell: LectureCell, didSelected option: LectureOption, with lecture: Lecture) {

        switch option {
        case .download:
            Persistant.shared.save(lecture: lecture)
        case .deleteFromDownloads:
            Persistant.shared.delete(lecture: lecture)
        case .markAsFavourite:
            Self.lectureViewModel.favourite(lectureId: lecture.id, isFavourite: true, completion: {_ in })
        case .removeFromFavourites:
            Self.lectureViewModel.favourite(lectureId: lecture.id, isFavourite: false, completion: {_ in })
        case .addToPlaylist:
            break
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

extension BaseLectureViewController {

    @objc func showLoading() {
        loadingIndicator.startAnimating()
    }

    @objc func hideLoading() {
        loadingIndicator.stopAnimating()
    }

    func reloadData(with lectures: [Model]) {
        self.lectures = lectures
        refreshUI()
    }
}
