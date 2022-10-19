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

    override func refreshAsynchronous(source: FirestoreSource, completion: @escaping (Result<[Lecture], Error>) -> Void) {

        var lectures = [Model]()
        for dbLecture in Persistant.shared.dbLectures {
            lectures.append(Lecture(from: dbLecture))
        }

        let searchText = self.searchText
        let selectedSortType = self.selectedSortType
        let selectedFilters = self.selectedFilters
        DispatchQueue.global().async {
            let lectures = DefaultLectureViewModel.filter(lectures: lectures, searchText: searchText, sortType: selectedSortType, filter: selectedFilters, lectureIDs: nil)
            DispatchQueue.main.async {
                completion(.success(lectures))
            }
        }
    }
}
