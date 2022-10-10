//
//  FavouritesViewController.swift
//  SrilaPrabhupada
//
//  Created by IE06 on 20/08/22.
//

import UIKit
import FirebaseFirestore

class FavouritesViewController: LectureViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        do {
            noItemTitle = "No Favourite Lectures"
            noItemMessage = "You can star your favourite lectures from home tab"
        }
    }

    override func refreshAsynchronous(source: FirestoreSource) {
        super.refreshAsynchronous(source: source)

        showLoading()

        Self.lectureViewModel.getUsersLectureInfo(source: source, completion: { [self] result in

            switch result {
            case .success(var success):
                success = success.filter({ $0.isFavourite })
                let lectureIDs: [Int] = success.map({ $0.id })

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
