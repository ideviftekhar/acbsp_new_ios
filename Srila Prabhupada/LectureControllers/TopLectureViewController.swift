//
//  TopLectureViewController.swift
//  SrilaPrabhupada
//
//  Created by IE06 on 21/08/22.
//

import UIKit
import FirebaseFirestore

class TopLectureViewController: LectureViewController {

    @IBOutlet private var topLecturesSegmentControl: UISegmentedControl!

    override func viewDidLoad() {
        super.viewDidLoad()

        do {
            noItemTitle = "No Top Lectures"
            noItemMessage = "Top lectures will display here"
        }

        do {
            topLecturesSegmentControl.removeAllSegments()

            for (index, listType) in TopLectureType.allCases.enumerated() {
                topLecturesSegmentControl.insertSegment(withTitle: listType.rawValue, at: index, animated: false)
            }

            let userDefaultKey: String = "\(Self.self).\(UISegmentedControl.self)"
            let lastSelectedIndex: Int = UserDefaults.standard.integer(forKey: userDefaultKey)
            if lastSelectedIndex < topLecturesSegmentControl.numberOfSegments {
                topLecturesSegmentControl.selectedSegmentIndex = lastSelectedIndex
            } else {
                topLecturesSegmentControl.selectedSegmentIndex = 0
            }
        }

        do {
            let userDefaultKey: String = "\(Self.self).\(UISegmentedControl.self)"
            let lastSelectedIndex: Int = UserDefaults.standard.integer(forKey: userDefaultKey)
            topLecturesSegmentControl.selectedSegmentIndex = lastSelectedIndex
        }
    }

    @IBAction func segmentAction(_ sender: UISegmentedControl) {

        do {
            let userDefaultKey: String = "\(Self.self).\(UISegmentedControl.self)"
            UserDefaults.standard.set(sender.selectedSegmentIndex, forKey: userDefaultKey)
            UserDefaults.standard.synchronize()
        }

        Haptic.selection()
        refresh(source: .cache, existing: [], animated: nil)
    }

    override func refreshAsynchronous(source: FirestoreSource, completion: @escaping (Result<[LectureViewController.Model], Error>) -> Void) {

        guard let selectedLectureType = TopLectureType(rawValue: topLecturesSegmentControl.selectedSegmentIndex) else {
            return
        }

        let sortType: LectureSortType? = selectedSortType == .default ? nil : selectedSortType  // We don't want default behaviour here

        switch selectedLectureType {
        case .thisWeek:

            DefaultLectureViewModel.defaultModel.getWeekLecturesIds(weekDays: Date.currentWeekDates, completion: { [self] result in

                switch result {
                case .success(let success):
                    let lectureIDs: [Int] = success.map({ $0.key })
                    DefaultLectureViewModel.defaultModel.getLectures(searchText: searchText, sortType: sortType, filter: selectedFilters, lectureIDs: lectureIDs, source: source, progress: nil, completion: completion)
                case .failure(let error):
                    completion(.failure(error))
                }
            })
        case .thisMonth:

            let calendar = Calendar.current
            let currentMonth = calendar.component(.month, from: Date())
            let currentYear = calendar.component(.year, from: Date())

            DefaultLectureViewModel.defaultModel.getMonthLecturesIds(month: currentMonth, year: currentYear, completion: { [self] result in

                switch result {
                case .success(let success):
                    let lectureIDs: [Int] = success.map({ $0.key })
                    DefaultLectureViewModel.defaultModel.getLectures(searchText: searchText, sortType: sortType, filter: selectedFilters, lectureIDs: lectureIDs, source: source, progress: nil, completion: completion)
                case .failure(let error):
                    completion(.failure(error))
                }
            })
        case .lastWeek:

            DefaultLectureViewModel.defaultModel.getWeekLecturesIds(weekDays: Date.lastWeekDates, completion: { [self] result in

                switch result {
                case .success(let success):
                    let lectureIDs: [Int] = success.map({ $0.key })
                    DefaultLectureViewModel.defaultModel.getLectures(searchText: searchText, sortType: sortType, filter: selectedFilters, lectureIDs: lectureIDs, source: source, progress: nil, completion: completion)
                case .failure(let error):
                    completion(.failure(error))
                }
            })
        case .lastMonth:

            let calendar = Calendar.current
            let currentMonth = calendar.component(.month, from: Date())
            var previousMonth = currentMonth - 1
            var currentYear = calendar.component(.year, from: Date())
            let lastYear = currentYear - 1
            if previousMonth == 0 {
                previousMonth = 12
                currentYear = lastYear
            }

            DefaultLectureViewModel.defaultModel.getMonthLecturesIds(month: previousMonth, year: currentYear, completion: { [self] result in

                switch result {
                case .success(let success):
                    let lectureIDs: [Int] = success.map({ $0.key })
                    DefaultLectureViewModel.defaultModel.getLectures(searchText: searchText, sortType: sortType, filter: selectedFilters, lectureIDs: lectureIDs, source: source, progress: nil, completion: completion)
                case .failure(let error):
                    completion(.failure(error))
                }
            })
        case .allTime:
            DefaultLectureViewModel.defaultModel.getPopularLectureIds(completion: { [self] result in

                switch result {
                case .success(let success):
                    let lectureIDs: [Int] = success.map({ $0.key })
                    DefaultLectureViewModel.defaultModel.getLectures(searchText: searchText, sortType: sortType, filter: selectedFilters, lectureIDs: lectureIDs, source: source, progress: nil, completion: completion)
                case .failure(let error):
                    completion(.failure(error))
                }
            })
        }
    }
}

extension TopLectureViewController {
    override func showLoading() {
        super.showLoading()
        topLecturesSegmentControl.isEnabled = false
    }

    override func hideLoading() {
        super.hideLoading()
        topLecturesSegmentControl.isEnabled = true
    }
}
