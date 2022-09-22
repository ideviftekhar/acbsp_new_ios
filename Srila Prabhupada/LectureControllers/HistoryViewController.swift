//
//  HistoryViewController.swift
//  SrilaPrabhupada
//
//  Created by IE06 on 29/08/22.
//

import UIKit

class HistoryViewController: BaseLectureViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func refreshAsynchronous() {

        showLoading()

        lectureViewModel.getListenedLectureIds(completion: { [self] result in

            switch result {
            case .success(let lectureIDs):

                lectureViewModel.getLectures(searchText: searchText, sortyType: selectedSortType, filter: selectedFilters, lectureIDs: lectureIDs, completion: { [self] result in
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
