//
//  LectureListViewController.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 8/5/23.
//

import Foundation
import FirebaseFirestore

class LectureListViewController: LectureViewController {

    var lectureIDs: [Dictionary<Int, Int>.Element] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        do {
            noItemTitle = "No Lectures"
        }
    }

    override func refreshAsynchronous(source: FirestoreSource, completion: @escaping (Result<[Model], Error>) -> Void) {

        let sortType: LectureSortType? = selectedSortType == .default ? nil : selectedSortType  // We don't want default behaviour here
        let allIDs = self.lectureIDs.map({ $0.key })

        DefaultLectureViewModel.defaultModel.getLectures(searchText: searchText, sortType: sortType, filter: selectedFilters, lectureIDs: allIDs, source: source, progress: nil, completion: completion)
    }
}
