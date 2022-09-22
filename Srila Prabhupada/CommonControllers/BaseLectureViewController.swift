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

    let lectureViewModel: LectureViewModel = DefaultLectureViewModel()

    private(set) var lectures: [Lecture] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        lectureTebleView.register(UINib(nibName: cellIdentifier, bundle: nil), forCellReuseIdentifier: cellIdentifier)

        do {
            loadingIndicator.color = UIColor.gray
            self.view.addSubview(loadingIndicator)
            loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
            loadingIndicator.hidesWhenStopped = true
            loadingIndicator.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
            loadingIndicator.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        }

        refreshAsynchronous()
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
