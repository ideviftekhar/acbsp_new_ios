//
//  PlaylistLecturesViewController.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 9/8/22.
//

import UIKit

class PlaylistLecturesViewController: BaseLectureViewController {

    var playlist: Playlist!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func refreshAsynchronous() {
        showLoading()
        lectureViewModel.getLectures(searchText: searchText, sortyType: selectedSortType, filter: selectedFilters, lectureIDs: playlist.lectureIds, completion: { [self] result in
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
