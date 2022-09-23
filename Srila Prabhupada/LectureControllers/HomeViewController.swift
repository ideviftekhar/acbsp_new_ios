//
//  Home.swift
//  SrilaPrabhupada
//
//  Created by IE06 on 19/08/22.
//

import UIKit
import FirebaseFirestore

class HomeViewController: BaseLectureViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func refreshAsynchronous(source: FirestoreSource) {

        showLoading()
        lectureViewModel.getLectures(searchText: searchText, sortType: selectedSortType, filter: selectedFilters, lectureIDs: nil, source: source, completion: { [self] result in
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
