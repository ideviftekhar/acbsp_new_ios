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

    override func refreshAsynchronous() {

        showLoading()
        lectureViewModel.getLectures(searchText: searchText, sortyType: selectedSortType, filter: selectedFilters, lectureIDs: nil, completion: { [self] result in
            hideLoading()

            switch result {
            case .success(let lectures):
                reloadData(with: lectures)
            case .failure(let error):
                showAlert(title: "Error", message: error.localizedDescription)
            }
        })
    }
}
