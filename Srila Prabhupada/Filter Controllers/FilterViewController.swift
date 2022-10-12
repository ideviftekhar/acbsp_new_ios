//
//  FilterViewController.swift
//  Srila Prabhupada
//
//  Created by IE03 on 13/09/22.
//

import UIKit
import IQListKit
import BEMCheckBox

protocol FilterViewControllerDelegate: AnyObject {
    func filterController(_ controller: FilterViewController, didSelected filters: [Filter: [String]])
}

class FilterViewController: UIViewController {

    @IBOutlet private var filterTypeTableView: UITableView!
    @IBOutlet private var filterDetailTableView: UITableView!
    weak var delegate: FilterViewControllerDelegate?

    var filters: [Filter] = Filter.allCases

    lazy var activeFilter: Filter = filters[0]

    var selectedFilters: [Filter: [String]] = [:]

//    typealias TypeModel = Filter
//    typealias TypeCell = FilterTypeTableViewCell
//    typealias DetailsModel = String
//    typealias DetailsCell = FilterDetailTableViewCell
//
//    private var typeModels: [TypeModel] = []
//    private var detailsModels: [DetailsModel] = []
//    private(set) lazy var typeList = IQList(listView: filterTypeTableView, delegateDataSource: self)
//    private(set) lazy var detailsList = IQList(listView: filterDetailTableView, delegateDataSource: self)

    override func viewDidLoad() {
        super.viewDidLoad()

//        do {
//            typeList.registerCell(type: TypeCell.self, registerType: .storyboard)
//            detailsList.registerCell(type: DetailsCell.self, registerType: .storyboard)
//            refreshUI(animated: false)
//        }

        do {
            let initialSelectedIndex: Int

            if let selectedFilter = selectedFilters.first?.key, let index = filters.firstIndex(of: selectedFilter) {
                initialSelectedIndex = index
            } else {
                initialSelectedIndex = 0
            }
            activeFilter = filters[initialSelectedIndex]
            filterTypeTableView.selectRow(at: IndexPath(row: initialSelectedIndex, section: 0), animated: false, scrollPosition: .middle)
        }
    }

    @IBAction private func clearBarButtonPressed(_: UIBarButtonItem) {
        self.selectedFilters = [:]
        self.reloadData()
    }

    private func goBack() {
        if self.navigationController?.viewControllers.first == self {
            self.dismiss(animated: true, completion: nil)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }

    @IBAction private func cancelButtonPressed(_: UIBarButtonItem) {
        goBack()
    }

    @IBAction func applyFilterAction(_ sender: Any) {

        self.delegate?.filterController(self, didSelected: self.selectedFilters)
        goBack()
    }

    private func reloadData() {

        let selectedIndexPath = filterTypeTableView.indexPathForSelectedRow

        self.filterTypeTableView.reloadData()
        self.filterDetailTableView.reloadData()

        self.filterTypeTableView.selectRow(at: selectedIndexPath, animated: false, scrollPosition: .none)
    }
}

extension FilterViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == filterTypeTableView {
            return self.filters.count
        } else if tableView == filterDetailTableView {
            return activeFilter.subtypes.count
        }
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if tableView == filterTypeTableView { //
            let filter = filters[indexPath.row]

            let cell = tableView.dequeueReusableCell(withIdentifier: "FilterTypeTableViewCell") as! FilterTypeTableViewCell
            cell.filterTypeLabel.text = filter.rawValue

            if let selectedSubtypes = selectedFilters[filter], !selectedSubtypes.isEmpty {
                cell.filterCountLabel.text = "\(selectedSubtypes.count)"
                cell.filterCountLabel.isHidden = false
            } else {
                cell.filterCountLabel.isHidden = true
            }

            return cell

        } else if tableView == filterDetailTableView {
            let subtype = activeFilter.subtypes[indexPath.row]

            let cell = tableView.dequeueReusableCell(withIdentifier: "FilterDetailTableViewCell") as! FilterDetailTableViewCell //
            cell.detailTypeLabel.text = subtype

            if let selectedSubtypes = selectedFilters[activeFilter], selectedSubtypes.contains(subtype) {
                cell.checkView.setOn(true, animated: false)
            } else {
                cell.checkView.setOn(false, animated: false)
            }

            return cell
        } else {
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        if tableView == filterTypeTableView { //
            let filter = filters[indexPath.row]
            activeFilter = filter

            self.reloadData()

        } else {
            tableView.deselectRow(at: indexPath, animated: true)

            let subtype = activeFilter.subtypes[indexPath.row]

            if let selectedSubtypes = selectedFilters[activeFilter], selectedSubtypes.contains(subtype) {

                var existingSubtypes = selectedFilters[activeFilter] ?? []
                existingSubtypes.removeAll(where: { $0 == subtype })
                if existingSubtypes.isEmpty {
                    selectedFilters[activeFilter] = nil
                } else {
                    selectedFilters[activeFilter] = existingSubtypes
                }
            } else {

                var existingSubtypes = selectedFilters[activeFilter] ?? []
                existingSubtypes.append(subtype)
                selectedFilters[activeFilter] = existingSubtypes
            }

            self.reloadData()
        }
    }
}
