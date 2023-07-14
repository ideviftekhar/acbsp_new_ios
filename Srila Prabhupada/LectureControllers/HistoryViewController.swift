//
//  HistoryViewController.swift
//  SrilaPrabhupada
//
//  Created by IE06 on 29/08/22.
//

import UIKit
import FirebaseFirestore

class HistoryViewController: LectureViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        do {
            noItemTitle = "No Lectures"
            noItemMessage = "Your past played lectures will display here"
        }
    }

    override func refreshAsynchronous(source: FirestoreSource, completion: @escaping (Result<[LectureViewController.Model], Error>) -> Void) {

        DefaultLectureViewModel.defaultModel.getUsersListenInfo(source: source, completion: { [self] result in

            switch result {
            case .success(let success):

                var lectureIDs: [Int] = success.flatMap({ $0.playedIds })
                let uniqueIds: Set<Int> = Set(lectureIDs)
                lectureIDs = Array(uniqueIds)

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
