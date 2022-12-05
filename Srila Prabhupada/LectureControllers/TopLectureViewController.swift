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
        refresh(source: .cache, existing: [])
    }

    override func refreshAsynchronous(source: FirestoreSource, completion: @escaping (Result<[LectureViewController.Model], Error>) -> Void) {

        guard let selectedLectureType = TopLectureType(rawValue: topLecturesSegmentControl.selectedSegmentIndex) else {
            return
        }

        switch selectedLectureType {
        case .thisWeek:

            DefaultLectureViewModel.defaultModel.getWeekLecturesIds(weekDays: currentWeekDates, completion: { [self] result in

                switch result {
                case .success(let lectureIDs):
                    DefaultLectureViewModel.defaultModel.getLectures(searchText: searchText, sortType: selectedSortType, filter: selectedFilters, lectureIDs: lectureIDs, source: source, progress: nil, completion: completion)
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
                case .success(let lectureIDs):
                    DefaultLectureViewModel.defaultModel.getLectures(searchText: searchText, sortType: selectedSortType, filter: selectedFilters, lectureIDs: lectureIDs, source: source, progress: nil, completion: completion)
                case .failure(let error):
                    completion(.failure(error))
                }
            })
        case .lastWeek:

            DefaultLectureViewModel.defaultModel.getWeekLecturesIds(weekDays: lastWeekDates, completion: { [self] result in

                switch result {
                case .success(let lectureIDs):
                    DefaultLectureViewModel.defaultModel.getLectures(searchText: searchText, sortType: selectedSortType, filter: selectedFilters, lectureIDs: lectureIDs, source: source, progress: nil, completion: completion)
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
                case .success(let lectureIDs):
                    DefaultLectureViewModel.defaultModel.getLectures(searchText: searchText, sortType: selectedSortType, filter: selectedFilters, lectureIDs: lectureIDs, source: source, progress: nil, completion: completion)
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

extension TopLectureViewController {

    var lastWeekDates: [String] {

        guard let endOfWeek = Date().startOfWeek else {
            return []
        }
        var startOfWeek = Date().startOfWeek
        startOfWeek = Date.gregorianCalendar.date(byAdding: .day, value: -7, to: startOfWeek!)
        var weekDates: [String] = []

        while let day = startOfWeek, day < endOfWeek {
            let dateString = DateFormatter.d_M_yyyy.string(from: day)
            weekDates.append(dateString)
            startOfWeek = Date.gregorianCalendar.date(byAdding: .day, value: 1, to: day)
        }
        return weekDates

    }

    var currentWeekDates: [String] {

        guard let endOfWeek = Date().endOfWeek else {
            return []
        }

        var startOfWeek = Date().startOfWeek

        var weekDates: [String] = []

        while let day = startOfWeek, day <= endOfWeek {
            let dateString = DateFormatter.d_M_yyyy.string(from: day)
            weekDates.append(dateString)
            startOfWeek = Date.gregorianCalendar.date(byAdding: .day, value: 1, to: day)
        }
        return weekDates
    }
}
