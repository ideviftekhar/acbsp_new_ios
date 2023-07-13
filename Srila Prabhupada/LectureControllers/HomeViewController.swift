//
//  Home.swift
//  SrilaPrabhupada
//
//  Created by IE06 on 19/08/22.
//

import UIKit
import FirebaseFirestore

class HomeViewController: LectureViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        do {
            noItemTitle = "No Lectures"
            noItemMessage = "No lectures to display here"
        }

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshTriggered(_:)), for: .valueChanged)
        lectureTebleView.refreshControl = refreshControl
    }

    @objc private func refreshTriggered(_ sender: UIRefreshControl) {
        if let tabBarController = self.tabBarController as? TabBarController {
            tabBarController.startSyncing(force: false)
        }
    }

    override func syncStarted() {
        lectureTebleView.refreshControl?.beginRefreshing()
    }

    override func syncEnded() {
        lectureTebleView.refreshControl?.endRefreshing()
    }

    override func viewWillAppear(_ animated: Bool) {

        super.viewWillAppear(animated)
    }

    override func refreshAsynchronous(source: FirestoreSource, completion: @escaping (Result<[Model], Error>) -> Void) {

        DefaultLectureViewModel.defaultModel.getLectures(searchText: searchText, sortType: selectedSortType, filter: selectedFilters, lectureIDs: nil, source: source, progress: nil, completion: { result in

            switch result {
            case .success(let lectures):
                completion(.success(lectures))
            case .failure(let error):
                completion(.failure(error))
            }
        })
    }
}
