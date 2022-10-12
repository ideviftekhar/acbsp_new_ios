//
//  StatsViewController.swift
//  SrilaPrabhupada
//
//  Created by IE06 on 22/08/22.
//

import UIKit
import Charts

class StatsViewController: UIViewController, ChartViewDelegate {

    @IBOutlet private var totalFileCountLabel: UILabel!
    @IBOutlet private var totalListenedCountLabel: UILabel!

    @IBOutlet private var lastMonthListenedTimeLabel: UILabel!
    @IBOutlet private var lastWeekListenedTimeLabel: UILabel!

    @IBOutlet private var lastMonthSBLabel: UILabel!
    @IBOutlet private var lastMonthBGLabel: UILabel!
    @IBOutlet private var lastMonthCCLabel: UILabel!
    @IBOutlet private var lastMonthBhajansLabel: UILabel!

    @IBOutlet private var lastWeekSBLabel: UILabel!
    @IBOutlet private var lastWeekBGLabel: UILabel!
    @IBOutlet private var lastWeekCCLabel: UILabel!
    @IBOutlet private var lastWeekBhajansLabel: UILabel!

    @IBOutlet private var startDateLabel: UILabel!
    @IBOutlet private var endDateLabel: UILabel!

    @IBOutlet private var monthProgressView: UIProgressView!
    @IBOutlet private var weekProgressView: UIProgressView!

    @IBOutlet private var startDatePicker: UIDatePicker!
    @IBOutlet private var EndDatePicker: UIDatePicker!

    @IBOutlet private var allTimeButton: UIButton!

    @IBOutlet private var totalListenedTimeLabel: UILabel!

    @IBOutlet private var chartView: BarChartView!

    var items = [audioItem]()

    let datapicker = UIDatePicker()
    let dateformet = DateFormatter()

    override func viewDidLoad() {
        super.viewDidLoad()

        totalFileCountLabel.text = "100"
        totalListenedCountLabel.text = "10"
        lastWeekBGLabel.text = "8"
        lastMonthListenedTimeLabel.text = "0h 0m 0s"
        lastWeekListenedTimeLabel.text = "0h 0m 0s"

        startDateLabel.text = "Start-Date"
        endDateLabel.text = "End-Date"

        totalListenedTimeLabel.text = "0h 24m"

        items = getFormattedItemValue()
        setUpData()
        setUpChart()
    }

    @IBAction func choosStartDate(sender: UIDatePicker) {

        dateformet.dateFormat = "dd-MM-yyyy"
        startDateLabel.text = dateformet.string(from: sender.date)

    }

    @IBAction func choosEndDate(sender: UIDatePicker) {

        dateformet.dateFormat = "dd-MM-yyyy"
        endDateLabel.text = dateformet.string(from: sender.date)
    }

    @IBAction func allButtonTapped(sender: UIButton) {
        startDateLabel.text = "Start-Date"
        endDateLabel.text = "End-Date"
    }
    func setUpData() {
        let dataEntries = items.map { $0.transformToBarChartDataEntry() }

        let set1 = BarChartDataSet(entries: dataEntries)
        set1.setColor(UIColor.systemOrange)
        set1.highlightColor = UIColor.systemFill
        set1.highlightAlpha = 1

        let data = BarChartData(dataSet: set1)
        data.setDrawValues(true)
        data.setValueTextColor(UIColor.systemPink)
//        let barValueFormatter = BarValueFormatter()
//        data.setValueFormatter(barValueFormatter)
        chartView.data = data
    }

    func setUpChart() {

        chartView.delegate = self

        chartView.highlightPerTapEnabled = false
        chartView.highlightFullBarEnabled = false
        chartView.highlightPerDragEnabled = true

        chartView.pinchZoomEnabled = false
        chartView.setScaleEnabled(false)
        chartView.doubleTapToZoomEnabled = false

        chartView.drawBarShadowEnabled = false
        chartView.drawGridBackgroundEnabled = false
        chartView.drawBordersEnabled = false
        chartView.borderColor = UIColor.red

        chartView.drawBarShadowEnabled = false
        chartView.drawGridBackgroundEnabled = false
        chartView.drawBordersEnabled = false

//        chartView.animate(yAxisDuration: 1.5 , easingOption: .easeOutBounce)

        let xAxis = chartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.drawAxisLineEnabled = true
        xAxis.drawGridLinesEnabled = false
        xAxis.granularityEnabled = false
        xAxis.labelRotationAngle = 0
        xAxis.setLabelCount(7, force: false)
        xAxis.valueFormatter = IndexAxisValueFormatter(values: items.map { $0.days })
        xAxis.axisMaximum = Double(7)
        xAxis.axisLineColor = UIColor.black
        xAxis.labelTextColor = UIColor.black

        let leftAxis = chartView.leftAxis
        leftAxis.drawTopYLabelEntryEnabled = true
        leftAxis.drawAxisLineEnabled = true
        leftAxis.drawGridLinesEnabled = true
        leftAxis.granularityEnabled = false
        leftAxis.axisLineColor = UIColor.black
        leftAxis.labelTextColor = UIColor.black

        let rightAxis = chartView.rightAxis
        rightAxis.enabled = false

    }

    func getFormattedItemValue() -> [audioItem] {

        var items: [audioItem] = []
        items.append(audioItem(index: 0, days: "Mon", minutes: 5))
        items.append(audioItem(index: 1, days: "Tue", minutes: 7))
        items.append(audioItem(index: 2, days: "Wed", minutes: 2))
        items.append(audioItem(index: 3, days: "Thu", minutes: 1))
        items.append(audioItem(index: 4, days: "Fri", minutes: 10))
        items.append(audioItem(index: 5, days: "Sat", minutes: 5))
        items.append(audioItem(index: 6, days: "Sun", minutes: 2))

        return items
    }
}
struct audioItem {
    let index: Int
    let days: String
    let minutes: Double

    func transformToBarChartDataEntry() -> BarChartDataEntry {
        let entry = BarChartDataEntry(x: Double(index), y: minutes)
        return entry
    }
}
