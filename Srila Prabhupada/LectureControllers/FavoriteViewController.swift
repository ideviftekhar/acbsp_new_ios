//
//  FavoriteViewController.swift
//  SrilaPrabhupada
//
//  Created by IE06 on 20/08/22.
//

import UIKit
import FirebaseFirestore

class FavoriteViewController: LectureViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        do {
            noItemTitle = "No Favorite Lectures"
            noItemMessage = "You can star your favorite lectures from home tab"
        }
    }

    @objc private func refreshTriggered(_ sender: UIRefreshControl) {
        if let tabBarController = self.tabBarController as? TabBarController {
            tabBarController.startSyncing(force: false)
        }
    }

    override func syncStarted() {
        searchController.searchBar.placeholder = "Loading..."
    }

    override func syncEnded() {
        searchController.searchBar.placeholder = "Search..."
    }

    override func refreshAsynchronous(source: FirestoreSource, completion: @escaping (Result<[LectureViewController.Model], Error>) -> Void) {

        DefaultLectureViewModel.defaultModel.getUsersLectureInfo(source: source, progress: nil, completion: { [self] result in
            switch result {
            case .success(var success):
                success = success.filter({ $0.isFavorite })
                var lectureIDs: [Int] = success.map({ $0.id })

                let uniqueIds: NSOrderedSet = NSOrderedSet(array: lectureIDs)
                lectureIDs = (uniqueIds.array as? [Int]) ?? lectureIDs

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
