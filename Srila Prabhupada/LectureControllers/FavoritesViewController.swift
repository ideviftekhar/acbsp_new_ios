//
//  FavoritesViewController.swift
//  SrilaPrabhupada
//
//  Created by IE06 on 20/08/22.
//

import UIKit
import FirebaseFirestore

class FavoritesViewController: BaseLectureViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        do {
            list.noItemTitle = "No Favorite Lectures"
            list.noItemMessage = "You can star your favorite lectures from home tab"
        }
    }

    override func refreshAsynchronous(source: FirestoreSource) {

        showLoading()

        Self.lectureViewModel.getFavoriteLectureIds(completion: { [self] result in

            switch result {
            case .success(let lectureIDs):

                Self.lectureViewModel.getLectures(searchText: searchText, sortType: selectedSortType, filter: selectedFilters, lectureIDs: lectureIDs, source: source, completion: { [self] result in
                    hideLoading()

                    switch result {
                    case .success(let lectures):
                        reloadData(with: lectures)
                    case .failure(let error):
                        showAlert(title: "Error", message: error.localizedDescription)
                    }
                })

            case .failure(let error):
                hideLoading()
                showAlert(title: "Error", message: error.localizedDescription)
            }
        })
    }
}
