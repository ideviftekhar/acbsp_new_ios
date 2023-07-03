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

    override func refreshAsynchronous(source: FirestoreSource, completion: @escaping (Result<[LectureViewController.Model], Error>) -> Void) {

        DefaultLectureViewModel.defaultModel.getUsersLectureInfo(source: source, progress: nil, completion: { [self] result in

            switch result {
            case .success(var success):
                success = success.filter({ $0.isFavorite })
                var lectureIDs: [Int] = success.map({ $0.id })

                let uniqueIds: NSOrderedSet = NSOrderedSet(array: lectureIDs)
                lectureIDs = (uniqueIds.array as? [Int]) ?? lectureIDs

                DefaultLectureViewModel.defaultModel.getLectures(searchText: searchText, sortType: selectedSortType, filter: selectedFilters, lectureIDs: lectureIDs, source: source, progress: nil, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        })
    }
}
