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
    }

    override func refreshAsynchronous(source: FirestoreSource, completion: @escaping (Result<[Lecture], Error>) -> Void) {

        DefaultLectureViewModel.defaultModel.getPopularLectureIds(completion: { [self] result in

            switch result {
            case .success(let lectureIDs):

                DefaultLectureViewModel.defaultModel.getLectures(searchText: searchText, sortType: selectedSortType, filter: selectedFilters, lectureIDs: lectureIDs, source: source, progress: nil, completion: completion)

            case .failure(let error):
                completion(.failure(error))
            }
        })
    }
}
