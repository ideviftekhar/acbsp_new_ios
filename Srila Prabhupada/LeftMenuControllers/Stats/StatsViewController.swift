//
//  StatsViewController.swift
//  SrilaPrabhupada
//
//  Created by IE06 on 22/08/22.
//

import UIKit
import DGCharts
import FirebaseFirestore
import FirebaseFirestoreSwift

class StatsViewController: UIViewController, ChartViewDelegate {

    @IBOutlet private var totalFileCountLabel: UILabel!
    @IBOutlet private var totalListenedCountLabel: UILabel!
    @IBOutlet private var totalProgressView: UIProgressView!
    @IBOutlet private var totalProgressLabel: UILabel!

    @IBOutlet private var thisWeekChartView: BarChartView!

    @IBOutlet private var lastWeekListenedTimeLabel: UILabel!
    @IBOutlet private var lastWeekSBLabel: UILabel!
    @IBOutlet private var lastWeekBGLabel: UILabel!
    @IBOutlet private var lastWeekCCLabel: UILabel!
    @IBOutlet private var lastWeekVSLabel: UILabel!
    @IBOutlet private var lastWeekSeminarsLabel: UILabel!
    @IBOutlet private var lastWeekOthersLabel: UILabel!

    @IBOutlet private var lastMonthListenedTimeLabel: UILabel!
    @IBOutlet private var lastMonthSBLabel: UILabel!
    @IBOutlet private var lastMonthBGLabel: UILabel!
    @IBOutlet private var lastMonthCCLabel: UILabel!
    @IBOutlet private var lastMonthVSLabel: UILabel!
    @IBOutlet private var lastMonthSeminarsLabel: UILabel!
    @IBOutlet private var lastMonthOthersLabel: UILabel!

    @IBOutlet private var customTimeListenedTimeLabel: UILabel!
    @IBOutlet private var customTimeProgressView: UIProgressView!
    @IBOutlet private var customTimeProgressLabel: UILabel!
    @IBOutlet private var customTimeSBLabel: UILabel!
    @IBOutlet private var customTimeBGLabel: UILabel!
    @IBOutlet private var customTimeCCLabel: UILabel!
    @IBOutlet private var customTimeVSLabel: UILabel!
    @IBOutlet private var customTimeSeminarsLabel: UILabel!
    @IBOutlet private var customTimeOthersLabel: UILabel!
    @IBOutlet private var customTimeButton: UIButton!
    @IBOutlet private var loadingIndecator: UIActivityIndicatorView!

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
    @IBOutlet private var scrollView: UIScrollView!

    private var allLectures: [Lecture] = []
    private var allListenInfo: [ListenInfo] = []


    override func viewDidLoad() {
        super.viewDidLoad()

        do {
            totalFileCountLabel.text = "-"
            totalListenedCountLabel.text = "-"
            totalProgressView.progress = 0
            totalProgressLabel.text = nil

            lastWeekSBLabel.text = "-"
            lastWeekBGLabel.text = "-"
            lastWeekCCLabel.text = "-"
            lastWeekVSLabel.text = "-"
            lastWeekSeminarsLabel.text = "-"
            lastWeekOthersLabel.text = "-"
            lastWeekListenedTimeLabel.text = "-"

            lastMonthSBLabel.text = "-"
            lastMonthBGLabel.text = "-"
            lastMonthCCLabel.text = "-"
            lastMonthVSLabel.text = "-"
            lastMonthSeminarsLabel.text = "-"
            lastMonthOthersLabel.text = "-"
            lastMonthListenedTimeLabel.text = "-"

            customTimeSBLabel.text = "-"
            customTimeBGLabel.text = "-"
            customTimeCCLabel.text = "-"
            customTimeVSLabel.text = "-"
            customTimeSeminarsLabel.text = "-"
            customTimeOthersLabel.text = "-"
            customTimeListenedTimeLabel.text = "-"
            customTimeProgressView.progress = 0
            customTimeProgressLabel.text = nil
        }

        configureCustomTimeButton()
        setUpChart()

        let image = UIImage(systemName: "square.and.arrow.up")
        let barButton = UIBarButtonItem(image: image, style: UIBarButtonItem.Style.plain, target: self, action: #selector(shareAction(_:)))
        self.navigationItem.rightBarButtonItem = barButton
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getAllListenInfo()
        getAllLectures()
    }

    @objc func shareAction(_ barButtonItem: UIBarButtonItem) {

        let pdf = SimplePDF(
            pageSize: self.scrollView.contentSize,
            pageMarginLeft: 2.0,
            pageMarginTop: 10.0,
            pageMarginBottom: 0.0,
            pageMarginRight: 2.0
        )

        let actualConstraints = self.view.relatedConstraints()
        let image = self.getImageOfScrollView()
        NSLayoutConstraint.activate(actualConstraints)

        pdf.addImage(image)

        let pdfData = pdf.generatePDFdata()
        self.openShareActivityControler(data: pdfData, barButtonItem: barButtonItem)
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

        switch UIDevice.current.userInterfaceIdiom {
        case .mac, .pad:
            thisWeekChartView.noDataFont = UIFont(name: "AvenirNextCondensed-Regular", size: 22)!
        default:
            thisWeekChartView.noDataFont = UIFont(name: "AvenirNextCondensed-Regular", size: 16)!
        }

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

        for option in StatsType.allCases {

            let state: UIAction.State = (lastType == option ? .on : .off)

            let action: SPAction = SPAction(title: option.rawValue, image: nil, identifier: .init(option.rawValue), state: state, groupIdentifier: option.groupIdentifier, handler: { [self] action in
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
        var totalVSN: Int = 0
        var totalSeminars: Int = 0
        var totalOthers: Int = 0
        var audioListen = 0

        filteredRecords.forEach { listenInfo in
            totalSB += listenInfo.listenDetails.SB
            totalBG += listenInfo.listenDetails.BG
            totalCC += listenInfo.listenDetails.CC
            totalVSN += listenInfo.listenDetails.VSN
            totalSeminars += listenInfo.listenDetails.Seminars
            totalOthers += listenInfo.listenDetails.others
            audioListen += listenInfo.audioListen
        }

        let total: Int = totalSB + totalBG + totalCC + totalVSN + totalSeminars + totalOthers

        let totalSBTime: Time = Time(totalSeconds: totalSB)
        let totalBGTime: Time = Time(totalSeconds: totalBG)
        let totalCCTime: Time = Time(totalSeconds: totalCC)
        let totalVSTime: Time = Time(totalSeconds: totalVSN)
        let totalSeminarTime: Time = Time(totalSeconds: totalSeminars)
        let totalOthersTime: Time = Time(totalSeconds: totalOthers)
        let totalListenTime: Time = Time(totalSeconds: total)

        lastMonthListenedTimeLabel.text = "\(totalListenTime.displayString2Unit )"
        lastMonthSBLabel.text = "\(totalSBTime.displayString2Unit)"
        lastMonthBGLabel.text = "\(totalBGTime.displayString2Unit)"
        lastMonthCCLabel.text = "\(totalCCTime.displayString2Unit)"
        lastMonthVSLabel.text = "\(totalVSTime.displayString2Unit)"
        lastMonthSeminarsLabel.text = "\(totalSeminarTime.displayString2Unit)"
        lastMonthOthersLabel.text = "\(totalOthersTime.displayString2Unit)"
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
        var totalVSN: Int = 0
        var totalSeminars: Int = 0
        var totalOthers: Int = 0
        var audioListen = 0

        filteredRecords.forEach { listenInfo in
            totalSB += listenInfo.listenDetails.SB
            totalBG += listenInfo.listenDetails.BG
            totalCC += listenInfo.listenDetails.CC
            totalVSN += listenInfo.listenDetails.VSN
            totalSeminars += listenInfo.listenDetails.Seminars
            totalOthers += listenInfo.listenDetails.others
            audioListen += listenInfo.audioListen
        }

        let total: Int = totalSB + totalBG + totalCC + totalVSN + totalSeminars + totalOthers

        let totalSBTime: Time = Time(totalSeconds: totalSB)
        let totalBGTime: Time = Time(totalSeconds: totalBG)
        let totalCCTime: Time = Time(totalSeconds: totalCC)
        let totalVSTime: Time = Time(totalSeconds: totalVSN)
        let totalSeminarTime: Time = Time(totalSeconds: totalSeminars)
        let totalOthersTime: Time = Time(totalSeconds: totalOthers)
        let totalListenTime: Time = Time(totalSeconds: total)

        lastWeekListenedTimeLabel.text = "\(totalListenTime.displayString2Unit)"
        lastWeekSBLabel.text = "\(totalSBTime.displayString2Unit)"
        lastWeekBGLabel.text = "\(totalBGTime.displayString2Unit)"
        lastWeekCCLabel.text = "\(totalCCTime.displayString2Unit)"
        lastWeekVSLabel.text = "\(totalVSTime.displayString2Unit)"
        lastWeekSeminarsLabel.text = "\(totalSeminarTime.displayString2Unit)"
        lastWeekOthersLabel.text = "\(totalOthersTime.displayString2Unit)"
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
        dataSet.setColor(UIColor.F96D00)
        dataSet.highlightColor = UIColor.D64214
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
        var totalVSN: Int = 0
        var totalSeminars: Int = 0
        var totalOthers: Int = 0
        var audioListen = 0

        filteredRecords.forEach { listenInfo in
            totalSB += listenInfo.listenDetails.SB
            totalBG += listenInfo.listenDetails.BG
            totalCC += listenInfo.listenDetails.CC
            totalVSN += listenInfo.listenDetails.VSN
            totalSeminars += listenInfo.listenDetails.Seminars
            totalOthers += listenInfo.listenDetails.others
            audioListen += listenInfo.audioListen
        }

        let total: Int = totalSB + totalBG + totalCC + totalVSN + totalSeminars + totalOthers

        let totalSBTime: Time = Time(totalSeconds: totalSB)
        let totalBGTime: Time = Time(totalSeconds: totalBG)
        let totalCCTime: Time = Time(totalSeconds: totalCC)
        let totalVSTime: Time = Time(totalSeconds: totalVSN)
        let totalSeminarTime: Time = Time(totalSeconds: totalSeminars)
        let totalOthersTime: Time = Time(totalSeconds: totalOthers)
        let totalListenTime: Time = Time(totalSeconds: total)

        customTimeListenedTimeLabel.text = "\(totalListenTime.displayString2Unit )"
        customTimeSBLabel.text = "\(totalSBTime.displayString2Unit)"
        customTimeBGLabel.text = "\(totalBGTime.displayString2Unit)"
        customTimeCCLabel.text = "\(totalCCTime.displayString2Unit)"
        customTimeVSLabel.text = "\(totalVSTime.displayString2Unit)"
        customTimeSeminarsLabel.text = "\(totalSeminarTime.displayString2Unit)"
        customTimeOthersLabel.text = "\(totalOthersTime.displayString2Unit)"

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
                self.showAlert(error: error)
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
                self.showAlert(error: error)
            }
        })
    }

    private func getImageOfScrollView() -> UIImage {
        var image = UIImage()

        UIGraphicsBeginImageContextWithOptions(self.scrollView.contentSize, false, UIScreen.main.scale)

        let savedContentOffset = self.scrollView.contentOffset
        let savedFrame = self.scrollView.frame
        let savedBackgroundColor = self.scrollView.backgroundColor

        self.scrollView.contentOffset = CGPoint.zero
        self.scrollView.frame = CGRect(x: 0, y: 0, width: self.scrollView.contentSize.width, height: self.scrollView.contentSize.height)
        self.scrollView.backgroundColor = UIColor.clear

        let tempView = UIView(frame: CGRect(x: 0, y: 0, width: self.scrollView.contentSize.width, height: self.scrollView.contentSize.height))
        let tempSuperView = self.scrollView.superview
        self.scrollView.removeFromSuperview()
        tempView.addSubview(self.scrollView)

        tempView.layer.render(in: UIGraphicsGetCurrentContext()!)
        image = UIGraphicsGetImageFromCurrentImageContext()!

        tempView.subviews[0].removeFromSuperview()
        tempSuperView?.addSubview(self.scrollView)

        self.scrollView.contentOffset = savedContentOffset
        self.scrollView.frame = savedFrame
        self.scrollView.backgroundColor = savedBackgroundColor

        UIGraphicsEndImageContext()

        return image
    }

    private func openShareActivityControler(data: Data, barButtonItem: UIBarButtonItem) {
        self.loadingIndecator.startAnimating()

        self.getDocName(completion: { docName in

            self.loadingIndecator.stopAnimating()
            let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(docName) as NSURL

            do {
                try data.write(to: url as URL)

                let activitycontroller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                if activitycontroller.responds(to: #selector(getter: activitycontroller.completionWithItemsHandler)) {
                    activitycontroller.completionWithItemsHandler = {(type, isCompleted, items, error) in
                        if let error = error {
                            self.showAlert(title: "Error!", message: error.localizedDescription)
                        } else if isCompleted {
                            print("completed")
                        }
                    }
                }

                activitycontroller.excludedActivityTypes = [UIActivity.ActivityType.airDrop]
                activitycontroller.popoverPresentationController?.barButtonItem = barButtonItem
                self.present(activitycontroller, animated: true, completion: nil)

            } catch let error {
                self.showAlert(title: "Error!", message: error.localizedDescription)
            }
        })

//        DispatchQueue.main.async{
//            let activityViewController = UIActivityViewController(activityItems: userContent as [Any], applicationActivities: nil)
//
//            activityViewController.popoverPresentationController?.sourceView = self.view
//            activityViewController.excludedActivityTypes = [ UIActivity.ActivityType.airDrop, UIActivity.ActivityType.postToFacebook ]
//
//            switch UIDevice.current.userInterfaceIdiom {
//            case .phone:
//                // It's an iPhone
//                break
//            case .pad:
//                // It's an iPad (or macOS Catalyst)
//              //  alert.popoverPresentationController?.sourceView = VC.view
//                if let popoverPresentationController = activityViewController.popoverPresentationController {
//                      popoverPresentationController.sourceView = self.view
//                      popoverPresentationController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
//                      popoverPresentationController.permittedArrowDirections = []
//                    }
//                break
//
//            @unknown default:
//                // Uh, oh! What could it be?
//                break
//            }
//
//            self.present(activityViewController, animated: true, completion: nil)
//        }
    }

    private func getDocName(completion: @escaping (String) -> Void) {

        var text = "PdfStats"

        if let name = FirestoreManager.shared.currentUserDisplayName {
            text = name + "_"
        } else if let email = FirestoreManager.shared.currentUserEmail {
            text = email + "_"
        }

        let currentDate = Date()
        let dateFormatter = DateFormatter()

        dateFormatter.dateFormat = "ddMMyyyy_hhmmss"
        let convertedDate: String = dateFormatter.string(from: currentDate)

        text.append(convertedDate)
        text.append(".pdf")

        completion(text)
    }
}
