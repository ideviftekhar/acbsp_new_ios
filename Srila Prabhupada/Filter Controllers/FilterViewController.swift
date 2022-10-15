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

    typealias TypeCell = FilterTypeTableViewCell
    typealias DetailsCell = FilterDetailTableViewCell

    private(set) lazy var typeList = IQList(listView: filterTypeTableView, delegateDataSource: self)
    private(set) lazy var detailsList = IQList(listView: filterDetailTableView, delegateDataSource: self)

    override func viewDidLoad() {
        super.viewDidLoad()

        do {
            typeList.registerCell(type: TypeCell.self, registerType: .storyboard)
            detailsList.registerCell(type: DetailsCell.self, registerType: .storyboard)
            refreshUI(animated: false)
            filterTypeTableView.tableFooterView = UIView()
            filterDetailTableView.tableFooterView = UIView()
        }

        do {
            let initialSelectedIndex: Int

            if let selectedFilter = selectedFilters.first?.key, let index = filters.firstIndex(of: selectedFilter) {
                initialSelectedIndex = index
            } else {
                initialSelectedIndex = 0
            }
            activeFilter = filters[initialSelectedIndex]
        }
    }

    @IBAction private func clearBarButtonPressed(_: UIBarButtonItem) {
        self.selectedFilters = [:]
        self.refreshUI(animated: false)
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
}

extension FilterViewController: IQListViewDelegateDataSource {

    private func refreshUI(animated: Bool? = nil) {

        DispatchQueue.global().async { [self] in
            let animated: Bool = animated ?? true
            typeList.performUpdates({

                let section = IQSection(identifier: "Cell", headerSize: CGSize.zero, footerSize: CGSize.zero)
                typeList.append(section)

                let models: [TypeCell.Model] = filters.map { filter -> TypeCell.Model in

                    let selectionCount: Int
                    if let selectedSubtypes = selectedFilters[filter] {
                        selectionCount = selectedSubtypes.count
                    } else {
                        selectionCount = 0
                    }

                    return TypeCell.Model(filter: filter, selectionCount: selectionCount)
                }

                typeList.append(TypeCell.self, models: models, section: section)

            }, animatingDifferences: animated, completion: {

                if let activeFilterIndex = filters.firstIndex(of: activeFilter) {
                    self.filterTypeTableView.selectRow(at: IndexPath(row: activeFilterIndex, section: 0), animated: false, scrollPosition: .none)
                }
            })

            detailsList.performUpdates({

                let section = IQSection(identifier: "Cell", headerSize: CGSize.zero, footerSize: CGSize.zero)
                detailsList.append(section)

                let models: [DetailsCell.Model] = activeFilter.subtypes.map { subtype -> DetailsCell.Model in

                    let isSelected: Bool

                    if let selectedSubtypes = selectedFilters[activeFilter], selectedSubtypes.contains(subtype) {
                        isSelected = true
                    } else {
                        isSelected = false
                    }

                    return DetailsCell.Model(details: subtype, isSelected: isSelected)
                }

                detailsList.append(DetailsCell.self, models: models, section: section)

            }, animatingDifferences: animated, completion: nil)
        }
    }

    func listView(_ listView: IQListView, didSelect item: IQItem, at indexPath: IndexPath) {

        if let model = item.model as? TypeCell.Model {

            activeFilter = model.filter

            self.refreshUI(animated: true)
        } else if let model = item.model as? DetailsCell.Model {

            if let selectedSubtypes = selectedFilters[activeFilter], selectedSubtypes.contains(model.details) {

                var existingSubtypes = selectedFilters[activeFilter] ?? []
                existingSubtypes.removeAll(where: { $0 == model.details })
                if existingSubtypes.isEmpty {
                    selectedFilters[activeFilter] = nil
                } else {
                    selectedFilters[activeFilter] = existingSubtypes
                }
            } else {

                var existingSubtypes = selectedFilters[activeFilter] ?? []
                existingSubtypes.append(model.details)
                selectedFilters[activeFilter] = existingSubtypes
            }
            self.refreshUI(animated: false)
        }
    }
}
