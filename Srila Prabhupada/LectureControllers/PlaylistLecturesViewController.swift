//
//  PlaylistLecturesViewController.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 9/8/22.
//

import UIKit
import FirebaseFirestore

class PlaylistLecturesViewController: BaseLectureViewController {

    var playlist: Playlist!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func refreshAsynchronous(source: FirestoreSource) {

        showLoading()
        lectureViewModel.getLectures(searchText: searchText, sortType: selectedSortType, filter: selectedFilters, lectureIDs: playlist.lectureIds, source: source, completion: { [self] result in
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
