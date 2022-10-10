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

        if isFirstTime {
            Self.lectureViewModel.getUsersLectureInfo(source: .default) { _ in }
            Self.lectureViewModel.getUsersListenInfo(source: .default) { _ in }
        }

        super.viewWillAppear(animated)
    }

    override func refreshAsynchronous(source: FirestoreSource) {
        super.refreshAsynchronous(source: source)

        showLoading()
        Self.lectureViewModel.getLectures(searchText: searchText, sortType: selectedSortType, filter: selectedFilters, lectureIDs: nil, source: source, completion: { [self] result in
            hideLoading()

            switch result {
            case .success(let lectures):

                if searchText == nil, selectedSortType == .default, selectedFilters.isEmpty {
                    Filter.updateFilterSubtypes(lectures: lectures)
                }

                reloadData(with: lectures)
            case .failure(let error):
                showAlert(title: "Error", message: error.localizedDescription)
            }
        })
    }
}
