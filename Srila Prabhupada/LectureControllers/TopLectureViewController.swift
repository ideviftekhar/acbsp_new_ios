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

        reloadData(with: [])
        refreshAsynchronous(source: .cache)
    }

    override func refreshAsynchronous(source: FirestoreSource) {
        super.refreshAsynchronous(source: source)

        guard let selectedLectureType = TopLectureType(rawValue: topLecturesSegmentControl.selectedSegmentIndex) else {
            return
        }

        switch selectedLectureType {
        case .thisWeek:
            showLoading()

            DefaultLectureViewModel.defaultModel.getWeekLecturesIds(weekDays: currentWeekDates, completion: { [self] result in

                switch result {
                case .success(let lectureIDs):

                    DefaultLectureViewModel.defaultModel.getLectures(searchText: searchText, sortType: selectedSortType, filter: selectedFilters, lectureIDs: lectureIDs, source: source, completion: { [self] result in
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
        case .thisMonth:
            showLoading()

            let calendar = Calendar.current
            let currentMonth = calendar.component(.month, from: Date())
            let currentYear = calendar.component(.year, from: Date())

            DefaultLectureViewModel.defaultModel.getMonthLecturesIds(month: currentMonth, year: currentYear, completion: { [self] result in

                switch result {
                case .success(let lectureIDs):

                    DefaultLectureViewModel.defaultModel.getLectures(searchText: searchText, sortType: selectedSortType, filter: selectedFilters, lectureIDs: lectureIDs, source: source, completion: { [self] result in
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
        case .lastWeek:
            showLoading()

            DefaultLectureViewModel.defaultModel.getWeekLecturesIds(weekDays: lastWeekDates, completion: { [self] result in

                switch result {
                case .success(let lectureIDs):

                    DefaultLectureViewModel.defaultModel.getLectures(searchText: searchText, sortType: selectedSortType, filter: selectedFilters, lectureIDs: lectureIDs, source: source, completion: { [self] result in
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
        case .lastMonth:
            showLoading()

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

                    DefaultLectureViewModel.defaultModel.getLectures(searchText: searchText, sortType: selectedSortType, filter: selectedFilters, lectureIDs: lectureIDs, source: source, completion: { [self] result in
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
}

extension TopLectureViewController {
    override func showLoading() {
        topLecturesSegmentControl.isEnabled = false
        super.showLoading()
    }

    override func hideLoading() {
        topLecturesSegmentControl.isEnabled = true
        super.hideLoading()
    }
}

extension TopLectureViewController {

    var lastWeekDates: [String] {

        guard let endOfWeek = Date().startOfWeek else {
            return []
        }
        var startOfWeek = Date().startOfWeek
        startOfWeek = Date.gregorianCalenar.date(byAdding: .day, value: -7, to: startOfWeek!)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d-M-yyyy"
        var weekDates: [String] = []

        while let day = startOfWeek, day < endOfWeek {
            let dateString = dateFormatter.string(from: day)
            weekDates.append(dateString)
            startOfWeek = Date.gregorianCalenar.date(byAdding: .day, value: 1, to: day)
        }
        return weekDates

    }

    var currentWeekDates: [String] {

        guard let endOfWeek = Date().endOfWeek else {
            return []
        }

        var startOfWeek = Date().startOfWeek

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d-M-yyyy"
        var weekDates: [String] = []

        while let day = startOfWeek, day <= endOfWeek {
            let dateString = dateFormatter.string(from: day)
            weekDates.append(dateString)
            startOfWeek = Date.gregorianCalenar.date(byAdding: .day, value: 1, to: day)
        }
        return weekDates
    }
}
