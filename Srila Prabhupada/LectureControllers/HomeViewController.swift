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
    }

    override func viewWillAppear(_ animated: Bool) {

        super.viewWillAppear(animated)
    }

    override func refreshAsynchronous(source: FirestoreSource, completion: @escaping (Result<[Model], Error>) -> Void) {

        DefaultLectureViewModel.defaultModel.getLectures(searchText: searchText, sortType: selectedSortType, filter: selectedFilters, lectureIDs: nil, source: source, progress: nil, completion: { [self] result in

            switch result {
            case .success(let lectures):

                if searchText == nil, selectedSortType == .default, selectedFilters.isEmpty {
                    Filter.updateFilterSubtypes(lectures: lectures)
                }

                completion(.success(lectures))
            case .failure(let error):
                completion(.failure(error))
            }
        })
    }
}
