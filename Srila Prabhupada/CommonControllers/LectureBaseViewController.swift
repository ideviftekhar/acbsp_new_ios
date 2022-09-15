//
//  BaseLectureViewController.swift
//  SrilaPrabhupada
//
//  Created by IE06 on 08/09/22.
//

import UIKit
import FirebaseFirestore

class BaseLectureViewController: BaseSearchViewController {

    @IBOutlet weak var lectureTebleView : UITableView!
    private let cellIdentifier =  "LectureCell"

    var lectures: [Lecture] = []

    let sortButton: UIBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "arrow.up.arrow.down"), style: .plain, target: nil, action: nil)

    private lazy var filterButton: UIBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "line.3.horizontal.decrease"), style: .plain, target: self, action: #selector(filterAction(_:)))
    var selectedFilters: [Filter : [String]] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()

        lectureTebleView.register(UINib(nibName: cellIdentifier, bundle: nil), forCellReuseIdentifier: cellIdentifier)

        var rightButtons = self.navigationItem.rightBarButtonItems ?? []
        rightButtons.append(sortButton)
        rightButtons.append(filterButton)
        self.navigationItem.rightBarButtonItems = rightButtons

        configureSortButton()
        refreshAsynchronous()
    }

    func configureSortButton() {
        var actions: [UIAction] = []

        for (index, sortType) in SortType.allCases.enumerated() {

            let action: UIAction = UIAction(title: sortType.rawValue, image: nil, identifier: UIAction.Identifier(sortType.rawValue), state: (index == 0 ? .on : .off), handler: { [self] action in

                for anAction in actions {
                    if anAction.identifier == action.identifier { anAction.state = .on  }
                    else {  anAction.state = .off }
                }

                self.sortButton.menu = self.sortButton.menu?.replacingChildren(actions)

                refreshAsynchronous()
            })

            actions.append(action)
        }

        let menu = UIMenu(title: "Sort", image: nil, identifier: UIMenu.Identifier.init(rawValue: "Sort"), options: UIMenu.Options.displayInline, children: actions)
        sortButton.menu = menu
    }

    @IBAction func filterAction(_ sender: Any) {
        let viewController = UIStoryboard.common.instantiate(FilterViewController.self)
        viewController.delegate = self
        viewController.selectedFilters = self.selectedFilters
        self.navigationController?.pushViewController(viewController, animated: true)
    }

    func refreshAsynchronous() {

        guard let selectedSortAction = sortButton.menu?.selectedElements.first as? UIAction, let selectedSortType = SortType(rawValue: selectedSortAction.identifier.rawValue) else {
            return
        }

        do {
            var query: Query = firestore.collection("Lectures")

            for (filter, subtypes) in selectedFilters {
                query = filter.applyOn(query: query, selectedSubtypes: subtypes)
            }

            query = selectedSortType.applyOn(query: query)

            query.getDocuments { [self] snapshot, error in

                if let error = error {
                    showAlert(title: "Error", message: error.localizedDescription)
               } else if let documents: [QueryDocumentSnapshot] = snapshot?.documents {

                   self.lectures = documents.map({ Lecture($0.data()) })

                    self.lectureTebleView.reloadData()
                }
            }
        } catch {
            showAlert(title: "Error", message: error.localizedDescription)
        }
    }
}

extension BaseLectureViewController : UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return lectures.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! LectureCell
        
        let aLecture = lectures[indexPath.row]

        cell.model = aLecture

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension BaseLectureViewController: FilterViewControllerDelegate {
    func filterController(_ controller: FilterViewController, didSelected filters: [Filter : [String]]) {

        self.selectedFilters = filters
        refreshAsynchronous()
    }
}
