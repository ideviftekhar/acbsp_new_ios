//
//  TopLectureViewController.swift
//  SrilaPrabhupada
//
//  Created by IE06 on 21/08/22.
//

import UIKit
import FirebaseFirestore

class TopLectureViewController: BaseLectureViewController {

    @IBOutlet weak var topLecturesSegmentControl: UISegmentedControl!

    override func viewDidLoad() {
        super.viewDidLoad()

        do {
            list.noItemTitle = "No Top Lectures"
            list.noItemMessage = "Top lectures will display here"
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

        switch topLecturesSegmentControl.selectedSegmentIndex {
        case 0:
            showLoading()

            Self.lectureViewModel.getWeekLecturesIds(weekDays: currentWeekDates, completion: { [self] result in

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
        case 1:
            showLoading()

            let calendar = Calendar.current
            let currentMonth = calendar.component(.month, from: Date())
            let currentYear = calendar.component(.year, from: Date())

            Self.lectureViewModel.getMonthLecturesIds(month: currentMonth, year: currentYear, completion: { [self] result in

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
        default:
            break
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

    var currentWeekDates: [String] {

        guard let endOfWeek = Date().endOfWeek else {
            return []
        }

        var startOfWeek = Date().startOfWeek

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        var weekDates: [String] = []

        while let day = startOfWeek, day < endOfWeek {
            let dateString = dateFormatter.string(from: day)
            weekDates.append(dateString)
            startOfWeek = Date.gregorianCalenar.date(byAdding: .day, value: 1, to: day)
        }
        return weekDates
    }
}
