//
//  PoppularLectureViewController.swift
//  SrilaPrabhupada
//
//  Created by IE06 on 29/08/22.
//

import UIKit
import FirebaseFirestore

class PopularLectureViewController: LectureViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        do {
            noItemTitle = "No Popular Lectures"
            noItemMessage = "Popular lectures will display here"
        }

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshTriggered(_:)), for: .valueChanged)
        lectureTebleView.refreshControl = refreshControl
    }

    @objc private func refreshTriggered(_ sender: UIRefreshControl) {
        refresh(source: .default)
    }

    override func syncStarted() {
    }

    override func syncEnded() {
    }


    override func refreshAsynchronous(source: FirestoreSource, completion: @escaping (Result<[LectureViewController.Model], Error>) -> Void) {

        DefaultLectureViewModel.defaultModel.getPopularLectureIds(completion: { [self] result in
            switch result {
            case .success(let lectureIDs):

                DefaultLectureViewModel.defaultModel.getLectures(searchText: searchText, sortType: selectedSortType, filter: selectedFilters, lectureIDs: lectureIDs, source: source, progress: nil, completion: { result in
                    self.lectureTebleView.refreshControl?.endRefreshing()
                    completion(result)
                })

            case .failure(let error):
                self.lectureTebleView.refreshControl?.endRefreshing()
                completion(.failure(error))
            }
        })
    }
}
