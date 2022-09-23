//
//  BaseLectureViewController.swift
//  SrilaPrabhupada
//
//  Created by IE06 on 08/09/22.
//

import UIKit
import AVKit
import FirebaseFirestore

class BaseLectureViewController: BaseSearchViewController {

    @IBOutlet private var lectureTebleView: UITableView!
    private let cellIdentifier =  "LectureCell"
    private let loadingIndicator: UIActivityIndicatorView = UIActivityIndicatorView(style: .medium)
    private let sortButton: UIBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "arrow.up.arrow.down.circle"), style: .plain, target: nil, action: nil)

    let lectureViewModel: LectureViewModel = DefaultLectureViewModel()

    private(set) var lectures: [Lecture] = []

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

        lectureTebleView.register(UINib(nibName: cellIdentifier, bundle: nil), forCellReuseIdentifier: cellIdentifier)

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

extension BaseLectureViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return lectures.count
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! LectureCell

        let aLecture = lectures[indexPath.row]

        cell.model = aLecture

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let aLecture = lectures[indexPath.row]

        guard let firstAudio = aLecture.resources.audios.first,
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

extension BaseLectureViewController {

    @objc func showLoading() {
        loadingIndicator.startAnimating()
    }

    @objc func hideLoading() {
        loadingIndicator.stopAnimating()
    }

    func reloadData(with lectures: [Lecture]) {
        self.lectures = lectures
        self.lectureTebleView.reloadData()
    }
}
