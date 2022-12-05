//
//  StatsViewController.swift
//  SrilaPrabhupada
//
//  Created by IE06 on 22/08/22.
//

import UIKit
import Charts
import FirebaseFirestore
import FirebaseFirestoreSwift

class StatsViewController: UIViewController, ChartViewDelegate {

    @IBOutlet private var totalFileCountLabel: UILabel!
    @IBOutlet private var totalListenedCountLabel: UILabel!
    @IBOutlet private var totalProgressView: UIProgressView!
    @IBOutlet private var totalProgressLabel: UILabel!

    @IBOutlet private var thisWeekChartView: BarChartView!

    @IBOutlet private var lastWeekListenedTimeLabel: UILabel!
    @IBOutlet private var lastWeekProgressView: UIProgressView!
    @IBOutlet private var lastWeekProgressLabel: UILabel!
    @IBOutlet private var lastWeekSBLabel: UILabel!
    @IBOutlet private var lastWeekBGLabel: UILabel!
    @IBOutlet private var lastWeekCCLabel: UILabel!
    @IBOutlet private var lastWeekBhajansLabel: UILabel!

    @IBOutlet private var lastMonthListenedTimeLabel: UILabel!
    @IBOutlet private var lastMonthProgressView: UIProgressView!
    @IBOutlet private var lastMonthProgressLabel: UILabel!
    @IBOutlet private var lastMonthSBLabel: UILabel!
    @IBOutlet private var lastMonthBGLabel: UILabel!
    @IBOutlet private var lastMonthCCLabel: UILabel!
    @IBOutlet private var lastMonthBhajansLabel: UILabel!

    @IBOutlet private var customTimeListenedTimeLabel: UILabel!
    @IBOutlet private var customTimeProgressView: UIProgressView!
    @IBOutlet private var customTimeProgressLabel: UILabel!
    @IBOutlet private var customTimeSBLabel: UILabel!
    @IBOutlet private var customTimeBGLabel: UILabel!
    @IBOutlet private var customTimeCCLabel: UILabel!
    @IBOutlet private var customTimeBhajansLabel: UILabel!
    @IBOutlet private var customTimeButton: UIButton!

    private var customTimeMenu: SPMenu!

    var selectedStatType: StatsType {
        guard let selectedAction = customTimeMenu.selectedAction,
              let selectedType = StatsType(rawValue: selectedAction.action.identifier.rawValue) else {
            return StatsType.all
        }
        return selectedType
    }

    @IBOutlet private var startDatePicker: UIDatePicker!
    @IBOutlet private var endDatePicker: UIDatePicker!

    private var allLectures: [Lecture] = []
    private var allListenInfo: [ListenInfo] = []


    override func viewDidLoad() {
        super.viewDidLoad()

        do {
            totalFileCountLabel.text = "-"
            totalListenedCountLabel.text = "-"
            totalProgressView.progress = 0
            totalProgressLabel.text = nil

            lastMonthSBLabel.text = "SB -"
            lastMonthBGLabel.text = "BG -"
            lastMonthCCLabel.text = "CC -"
            lastMonthBhajansLabel.text = "Bhanjan -"
            lastMonthListenedTimeLabel.text = "-"
            lastMonthProgressView.progress = 0
            lastMonthProgressLabel.text = nil

            lastWeekSBLabel.text = "SB -"
            lastWeekBGLabel.text = "BG -"
            lastWeekCCLabel.text = "CC -"
            lastWeekBhajansLabel.text = "Bhanjan -"
            lastWeekListenedTimeLabel.text = "-"
            lastWeekProgressView.progress = 0
            lastWeekProgressLabel.text = nil

            customTimeSBLabel.text = "SB -"
            customTimeBGLabel.text = "BG -"
            customTimeCCLabel.text = "CC -"
            customTimeBhajansLabel.text = "Bhanjan -"
            customTimeListenedTimeLabel.text = "-"
            customTimeProgressView.progress = 0
            customTimeProgressLabel.text = nil
        }

        configureCustomTimeButton()
        setUpChart()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getAllListenInfo()
        getAllLectures()
    }

    @IBAction func choosStartDate(sender: UIDatePicker) {

        updateCustomTime()
//        startDateLabel.text = DateFormatter.dd_MM_yyyy.string(from: sender.date)
    }

    @IBAction func choosEndDate(sender: UIDatePicker) {
//        endDateLabel.text = DateFormatter.dd_MM_yyyy.string(from: sender.date)
        updateCustomTime()
    }

    func setUpChart() {

        thisWeekChartView.delegate = self

        thisWeekChartView.highlightPerTapEnabled = false
        thisWeekChartView.highlightFullBarEnabled = false
        thisWeekChartView.highlightPerDragEnabled = true

        thisWeekChartView.pinchZoomEnabled = false
        thisWeekChartView.setScaleEnabled(false)
        thisWeekChartView.doubleTapToZoomEnabled = false

        thisWeekChartView.drawBarShadowEnabled = false
        thisWeekChartView.drawGridBackgroundEnabled = false
        thisWeekChartView.drawBordersEnabled = false

        thisWeekChartView.drawBarShadowEnabled = false
        thisWeekChartView.drawGridBackgroundEnabled = false
        thisWeekChartView.drawBordersEnabled = false

        let days: [String] = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

        let xAxis = thisWeekChartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.drawAxisLineEnabled = true
        xAxis.drawGridLinesEnabled = false
        xAxis.granularityEnabled = false
        xAxis.labelRotationAngle = 0
        xAxis.setLabelCount(7, force: true)
        xAxis.valueFormatter = IndexAxisValueFormatter(values: days)
        xAxis.axisMaximum = Double(7)
        xAxis.axisLineColor = UIColor.black
        xAxis.labelTextColor = UIColor.black

        let leftAxis = thisWeekChartView.leftAxis
        leftAxis.axisMinimum = 0
        leftAxis.drawTopYLabelEntryEnabled = true
        leftAxis.drawAxisLineEnabled = true
        leftAxis.drawGridLinesEnabled = true
        leftAxis.granularityEnabled = false
        leftAxis.axisLineColor = UIColor.black
        leftAxis.labelTextColor = UIColor.black

        let rightAxis = thisWeekChartView.rightAxis
        rightAxis.enabled = false
    }
}

// Custom Time
extension StatsViewController {

    private func configureCustomTimeButton() {
        var actions: [SPAction] = []

        let userDefaultKey: String = "\(Self.self).\(StatsType.self)"
        let lastType: StatsType

        if let typeString = UserDefaults.standard.string(forKey: userDefaultKey), let type = StatsType(rawValue: typeString) {
            lastType = type
        } else {
            lastType = .all
        }

        for statsType in StatsType.allCases {

            let state: UIAction.State = (lastType == statsType ? .on : .off)

            let action: SPAction = SPAction(title: statsType.rawValue, image: nil, identifier: .init(statsType.rawValue), state: state, handler: { [self] action in
                customTimeActionSelected(action: action)
            })

            actions.append(action)
        }

        self.customTimeMenu = SPMenu(title: "", image: nil, identifier: .init(rawValue: "Stats Type"), options: .displayInline, children: actions, button: customTimeButton)

        updateCustomTimeButtonUI()
    }

    private func customTimeActionSelected(action: UIAction) {
        let userDefaultKey: String = "\(Self.self).\(StatsType.self)"
        UserDefaults.standard.set(action.identifier.rawValue, forKey: userDefaultKey)
        UserDefaults.standard.synchronize()

        let children: [SPAction] = self.customTimeMenu.children
        for anAction in children {
            if anAction.action.identifier == action.identifier { anAction.action.state = .on  } else {  anAction.action.state = .off }
        }
        self.customTimeMenu.children = children

        updateCustomTimeButtonUI()

        updateCustomTime()
    }

    private func updateCustomTimeButtonUI() {
        customTimeButton.setTitle(selectedStatType.rawValue, for: .normal)

        if let range = selectedStatType.range {
            startDatePicker.date = range.startDate
            endDatePicker.date = range.endDate

            startDatePicker.isEnabled = false
            endDatePicker.isEnabled = false
            startDatePicker.alpha = 0.25
            endDatePicker.alpha = 0.25
        } else {
            startDatePicker.isEnabled = true
            endDatePicker.isEnabled = true
            startDatePicker.alpha = 1.0
            endDatePicker.alpha = 1.0
        }
    }
}

// UI
extension StatsViewController {
    private func updateUI() {
        updateLastMonth()
        updateLastWeek()
        updateThisWeek()
        updateCustomTime()
    }

    private func updateTotalListened() {

        let completedLectures = allLectures.filter { $0.isCompleted }

        totalFileCountLabel.text = "\(allLectures.count)"
        totalListenedCountLabel.text = "\(completedLectures.count)"

        if allLectures.count > 0 {
            let progress: Float = Float(completedLectures.count) / Float(allLectures.count)
            totalProgressView.setProgress(progress, animated: true)
        } else {
            totalProgressView.setProgress(0, animated: true)
        }
        totalProgressLabel.text = "\(Int(totalProgressView.progress*100))%"
    }

    private func updateLastMonth() {

        let filteredRecords: [ListenInfo]
        if let range = StatsType.lastMonth.range {

            let startTimestamp = Int(range.startDate.startOfDay.timeIntervalSince1970 * 1000)
            let endTimestamp = Int(range.endDate.endOfDay.timeIntervalSince1970 * 1000)

            filteredRecords = allListenInfo.filter {  startTimestamp <= $0.creationTimestamp && $0.creationTimestamp <= endTimestamp }
        } else {
            var month: Int = Date().component(.month) - 1
            var year: Int = Date().component(.year)

            if month == 0 {
                month = 12
                year -= 1
            }

            filteredRecords = allListenInfo.filter { $0.dateOfRecord.month == month && $0.dateOfRecord.year == year }
        }

        var totalSB: Int = 0
        var totalBG: Int = 0
        var totalCC: Int = 0
        var totalBhajans: Int = 0
        var totalOthers: Int = 0
        var totalVSN: Int = 0
        var audioListen = 0

        filteredRecords.forEach { listenInfo in
            totalSB += listenInfo.listenDetails.SB
            totalBG += listenInfo.listenDetails.BG
            totalCC += listenInfo.listenDetails.CC
            totalBhajans += listenInfo.listenDetails.others
            totalOthers += listenInfo.listenDetails.Seminars
            totalVSN += listenInfo.listenDetails.VSN
            audioListen += listenInfo.audioListen
        }

        let total: Int = totalSB + totalBG + totalCC + totalBhajans + totalVSN + totalOthers

        let totalSBTime: Time = Time(totalSeconds: totalSB)
        let totalBGTime: Time = Time(totalSeconds: totalBG)
        let totalCCTime: Time = Time(totalSeconds: totalCC)
        let totalBhajanTime: Time = Time(totalSeconds: totalBhajans)
        let totalListenTime: Time = Time(totalSeconds: total)

        lastMonthListenedTimeLabel.text = "\(totalListenTime.displayStringH )"
        lastMonthSBLabel.text = "SB \(totalSBTime.displayTopUnit)"
        lastMonthBGLabel.text = "BG \(totalBGTime.displayTopUnit)"
        lastMonthCCLabel.text = "CC \(totalCCTime.displayTopUnit)"
        lastMonthBhajansLabel.text = "Bhanjan \(totalBhajanTime.displayTopUnit)"

        let finalPoint: Float = Float(filteredRecords.count * 3600 * 24)
        if finalPoint > 0 {
            let progress: Float = Float(audioListen) / finalPoint
            lastMonthProgressView.setProgress(progress, animated: true)
        } else {
            lastMonthProgressView.setProgress(0, animated: true)
        }
        lastMonthProgressLabel.text = "\(Int(lastMonthProgressView.progress*100))%"
    }

    private func updateLastWeek() {

        let filteredRecords: [ListenInfo]
        if let range = StatsType.lastWeek.range {

            let startTimestamp = Int(range.startDate.startOfDay.timeIntervalSince1970 * 1000)
            let endTimestamp = Int(range.endDate.endOfDay.timeIntervalSince1970 * 1000)

            filteredRecords = allListenInfo.filter {  startTimestamp <= $0.creationTimestamp && $0.creationTimestamp <= endTimestamp }
        } else if let lastWeekDate = Calendar(identifier: .iso8601).date(byAdding: .weekOfYear, value: -1, to: Date()),
                   let startDay = lastWeekDate.startOfWeek,
                   let endDay = lastWeekDate.endOfWeek {

            let startTimestamp = Int(startDay.startOfDay.timeIntervalSince1970 * 1000)
            let endTimestamp = Int(endDay.endOfDay.timeIntervalSince1970 * 1000)

            filteredRecords = allListenInfo.filter {  startTimestamp <= $0.creationTimestamp && $0.creationTimestamp <= endTimestamp }
        } else {
            filteredRecords = []
        }

        var totalSB: Int = 0
        var totalBG: Int = 0
        var totalCC: Int = 0
        var totalBhajans: Int = 0
        var totalOthers: Int = 0
        var totalVSN: Int = 0
        var audioListen = 0

        filteredRecords.forEach { listenInfo in
            totalSB += listenInfo.listenDetails.SB
            totalBG += listenInfo.listenDetails.BG
            totalCC += listenInfo.listenDetails.CC
            totalBhajans += listenInfo.listenDetails.others
            totalOthers += listenInfo.listenDetails.Seminars
            totalVSN += listenInfo.listenDetails.VSN
            audioListen += listenInfo.audioListen
        }

        let total: Int = totalSB + totalBG + totalCC + totalBhajans + totalVSN + totalOthers

        let totalSBTime: Time = Time(totalSeconds: totalSB)
        let totalBGTime: Time = Time(totalSeconds: totalBG)
        let totalCCTime: Time = Time(totalSeconds: totalCC)
        let totalBhajanTime: Time = Time(totalSeconds: totalBhajans)
        let totalListenTime: Time = Time(totalSeconds: total)

        lastWeekListenedTimeLabel.text = "\(totalListenTime.displayStringH )"
        lastWeekSBLabel.text = "SB \(totalSBTime.displayTopUnit)"
        lastWeekBGLabel.text = "BG \(totalBGTime.displayTopUnit)"
        lastWeekCCLabel.text = "CC \(totalCCTime.displayTopUnit)"
        lastWeekBhajansLabel.text = "Bhanjan \(totalBhajanTime.displayTopUnit)"

        let finalPoint: Float = Float(filteredRecords.count * 3600 * 24)
        if finalPoint > 0 {
            let progress: Float = Float(audioListen) / finalPoint
            lastWeekProgressView.setProgress(progress, animated: true)
        } else {
            lastWeekProgressView.setProgress(0, animated: true)
        }
        lastWeekProgressLabel.text = "\(Int(lastWeekProgressView.progress*100))%"
    }

    private func updateThisWeek() {

        let thisWeekDate = Date()
        guard let startDay = thisWeekDate.startOfWeek else {
            return
        }

        var barChartEntries: [BarChartDataEntry] = []
        for additionDay in 0..<7 {
            if let date = startDay.adding(.day, value: additionDay) {
                let day = date.component(.day)
                let month = date.component(.month)
                let year = date.component(.year)

                let finalDay = Day(day: day, month: month, year: year)

                if let listenInfo = allListenInfo.first(where: { $0.dateOfRecord == finalDay }) {
                    barChartEntries.append(BarChartDataEntry(x: Double(additionDay), y: Double(listenInfo.audioListen)))
                } else {
                    barChartEntries.append(BarChartDataEntry(x: Double(additionDay), y: 0))
                }
            }
        }

        let dataSet = BarChartDataSet(entries: barChartEntries)
        dataSet.setColor(UIColor.systemOrange)
        dataSet.highlightColor = UIColor.systemFill
        dataSet.highlightAlpha = 1

        let data = BarChartData(dataSet: dataSet)
        data.setDrawValues(true)
        data.setValueTextColor(UIColor.systemPink)
        thisWeekChartView.data = data
    }

    private func updateCustomTime() {

        if  startDatePicker.date > endDatePicker.date {
            let tempDate = startDatePicker.date
            startDatePicker.date = endDatePicker.date
            endDatePicker.date = tempDate
        }

        let startTimestamp = Int(startDatePicker.date.startOfDay.timeIntervalSince1970 * 1000)
        let endTimestamp = Int(endDatePicker.date.endOfDay.timeIntervalSince1970 * 1000)

        let filteredRecords: [ListenInfo] = allListenInfo.filter {  startTimestamp <= $0.creationTimestamp && $0.creationTimestamp <= endTimestamp }

        var totalSB: Int = 0
        var totalBG: Int = 0
        var totalCC: Int = 0
        var totalBhajans: Int = 0
        var totalOthers: Int = 0
        var totalVSN: Int = 0
        var audioListen = 0

        filteredRecords.forEach { listenInfo in
            totalSB += listenInfo.listenDetails.SB
            totalBG += listenInfo.listenDetails.BG
            totalCC += listenInfo.listenDetails.CC
            totalBhajans += listenInfo.listenDetails.others
            totalOthers += listenInfo.listenDetails.Seminars
            totalVSN += listenInfo.listenDetails.VSN
            audioListen += listenInfo.audioListen
        }

        let totalDuration: Int = totalSB + totalBG + totalCC + totalBhajans + totalVSN + totalOthers

        let totalSBTime: Time = Time(totalSeconds: totalSB)
        let totalBGTime: Time = Time(totalSeconds: totalBG)
        let totalCCTime: Time = Time(totalSeconds: totalCC)
        let totalBhajanTime: Time = Time(totalSeconds: totalBhajans)
        let totalDurationListenTime: Time = Time(totalSeconds: totalDuration)

        customTimeListenedTimeLabel.text = "\(totalDurationListenTime.displayStringH )"
        customTimeSBLabel.text = "SB \(totalSBTime.displayTopUnit)"
        customTimeBGLabel.text = "BG \(totalBGTime.displayTopUnit)"
        customTimeCCLabel.text = "CC \(totalCCTime.displayTopUnit)"
        customTimeBhajansLabel.text = "Bhanjan \(totalBhajanTime.displayTopUnit)"

        let finalPoint: Float = Float(filteredRecords.count * 3600 * 24)
        if finalPoint > 0 {
            let progress: Float = Float(audioListen) / finalPoint
            customTimeProgressView.setProgress(progress, animated: true)
        } else {
            customTimeProgressView.setProgress(0, animated: true)
        }
        customTimeProgressLabel.text = "\(Int(customTimeProgressView.progress*100))%"
    }
}

extension StatsViewController {
    private func getAllLectures() {
        DefaultLectureViewModel.defaultModel.getLectures(searchText: nil, sortType: nil, filter: [:], lectureIDs: nil, source: .cache, progress: nil, completion: {  [self] result in

            switch result {
            case .success(let success):
                allLectures = success
                updateTotalListened()
            case .failure(let error):
                Haptic.error()
                showAlert(title: "Error", message: error.localizedDescription)
            }
        })
    }

    private func getAllListenInfo() {
        DefaultLectureViewModel.defaultModel.getUsersListenInfo(source: .default, completion: { [self] result in
            switch result {
            case .success(let success):
                allListenInfo = success
                updateUI()
            case .failure(let error):
                Haptic.error()
                showAlert(title: "Error", message: error.localizedDescription)
            }
        })
    }
}
