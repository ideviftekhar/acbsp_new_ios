//
//  DownloadViewController.swift
//  SrilaPrabhupada
//
//  Created by IE06 on 20/08/22.
//

import UIKit
import FirebaseFirestore

class DownloadViewController: LectureViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        do {
            noItemTitle = "No Downloaded Lectures"
            noItemMessage = "Your downloaded lectures will display here.\nYou can download the lectures from home tab"
        }
    }

    override func refreshAsynchronous(source: FirestoreSource, completion: @escaping (Result<[Model], Error>) -> Void) {

        var lectureIDs: [Int] = []

        for dbLecture in Persistant.shared.getAllDBLectures() {
            lectureIDs.append(dbLecture.id)
        }

        DefaultLectureViewModel.defaultModel.getLectures(searchText: searchText, sortType: selectedSortType, filter: selectedFilters, lectureIDs: lectureIDs, source: source, progress: nil, completion: completion)
    }
}
