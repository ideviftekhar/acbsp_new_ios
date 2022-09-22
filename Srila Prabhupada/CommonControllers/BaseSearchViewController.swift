//
//  BaseSearchViewController.swift
//  Srila Prabhupada
//
//  Created by IE06 on 08/09/22.
//

import UIKit
import SideMenu
import SafariServices
import FirebaseFirestore

class BaseSearchViewController: UIViewController {

    @IBOutlet weak var hamburgerBarButton: UIBarButtonItem!
    private let searchController = UISearchController(searchResultsController: nil)
    private var lastSearchText: String = ""

    private let sortButton: UIBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "arrow.up.arrow.down"), style: .plain, target: nil, action: nil)
    private lazy var filterButton: UIBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "line.3.horizontal.decrease"), style: .plain, target: self, action: #selector(filterAction(_:)))

    var selectedFilters: [Filter: [String]] = [:]

    var searchText: String? {
        if let text = searchController.searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty {
            return text
        } else {
            return nil
        }
    }

    var selectedSortType: SortType {
        guard let selectedSortAction = sortButton.menu?.selectedElements.first as? UIAction, let selectedSortType = SortType(rawValue: selectedSortAction.identifier.rawValue) else {
            return SortType.default
        }
        return selectedSortType
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        var rightButtons = self.navigationItem.rightBarButtonItems ?? []
        rightButtons.append(sortButton)
        rightButtons.append(filterButton)
        self.navigationItem.rightBarButtonItems = rightButtons

        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search..."
        searchController.searchBar.searchTextField.leftView?.tintColor = UIColor.systemGray4
        searchController.searchBar.searchTextField.rightView?.tintColor = UIColor.systemGray4
        searchController.searchBar.barStyle = .black
        searchController.searchBar.searchTextField.defaultTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        searchController.searchBar.searchTextField.attributedPlaceholder = NSAttributedString(string: "Search...", attributes: [NSAttributedString.Key.foregroundColor: UIColor.systemGray4])
        searchController.delegate = self
        searchController.searchResultsUpdater = self
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true

        configureSortButton()
    }

    func configureSortButton() {
        var actions: [UIAction] = []

        for (index, sortType) in SortType.allCases.enumerated() {

            let action: UIAction = UIAction(title: sortType.rawValue, image: nil, identifier: UIAction.Identifier(sortType.rawValue), state: (index == 0 ? .on : .off), handler: { [self] action in

                for anAction in actions {
                    if anAction.identifier == action.identifier { anAction.state = .on  } else {  anAction.state = .off }
                }

                self.sortButton.menu = self.sortButton.menu?.replacingChildren(actions)

                refreshAsynchronous()
            })

            actions.append(action)
        }

        let menu = UIMenu(title: "Sort", image: nil, identifier: UIMenu.Identifier.init(rawValue: "Sort"), options: UIMenu.Options.displayInline, children: actions)
        sortButton.menu = menu
    }

    @objc func refreshAsynchronous() {

    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

extension BaseSearchViewController: FilterViewControllerDelegate {

    @objc private func filterAction(_ sender: Any) {
        let viewController = UIStoryboard.common.instantiate(FilterViewController.self)
        viewController.delegate = self
        viewController.selectedFilters = self.selectedFilters
        self.navigationController?.pushViewController(viewController, animated: true)
    }

    func filterController(_ controller: FilterViewController, didSelected filters: [Filter: [String]]) {

        self.selectedFilters = filters
        refreshAsynchronous()
    }
}

extension BaseSearchViewController: UISearchControllerDelegate, UISearchResultsUpdating {

    func willPresentSearchController(_ searchController: UISearchController) {
        lastSearchText = searchController.searchBar.text ?? ""
    }

    func willDismissSearchController(_ searchController: UISearchController) {

    }

    func updateSearchResults(for searchController: UISearchController) {
        Self.cancelPreviousPerformRequests(withTarget: self, selector: #selector(refreshAsynchronous), object: nil)
        if let text = searchController.searchBar.text, !text.elementsEqual(lastSearchText) {
            self.perform(#selector(refreshAsynchronous), with: nil, afterDelay: 1)
            lastSearchText = text
        }
    }
}

extension BaseSearchViewController: SideMenuControllerDelegate {

    @IBAction func humburgerBarButtonTapped(_ sender: UIBarButtonItem) {
        let sideMenuNavigationController = UIStoryboard.sideMenu.instantiate(SideMenuNavigationController.self)
        sideMenuNavigationController.settings.presentationStyle = .menuSlideIn
        sideMenuNavigationController .settings.presentationStyle.presentingEndAlpha = 0.7
        sideMenuNavigationController.settings.presentationStyle.onTopShadowOpacity = 0.3

        if let sideMenuNavigationController = sideMenuNavigationController.viewControllers.first as? SideMenuTableViewController {
            sideMenuNavigationController.delegate = self
        }

        present(sideMenuNavigationController, animated: true, completion: nil)
    }

    func sideMenuController(_ controller: SideMenuTableViewController, didSelected menu: SideMenuItem) {
        switch menu {
        case .mediaLibrary:
            self.tabBarController?.selectedIndex = 0
            controller.dismiss(animated: true, completion: nil)
        case .history:
            let historyController = UIStoryboard.history.instantiate(HistoryViewController.self)
            controller.navigationController?.pushViewController(historyController, animated: true)
        case .stats:
            let statsController = UIStoryboard.stats.instantiate(StatsViewController.self)
            controller.navigationController?.pushViewController(statsController, animated: true)
        case .popularLectures:
            let popularLectureController = UIStoryboard.popularLecture.instantiate(PopularLectureViewController.self)
            controller.navigationController?.pushViewController(popularLectureController, animated: true)
        case .about:
            let aboutController = UIStoryboard.sideMenu.instantiate(AboutViewController.self)
            controller.present(aboutController, animated: true, completion: nil)
        case .share:
            let appLink = [URL(string: "https://play.google.com/store/apps/details?id=com.iskcon.prabhupada")!]
            let shareController = UIActivityViewController(activityItems: appLink, applicationActivities: nil)
            controller.present(shareController, animated: true)
        case .donate:
            if let donateWebsite = URL(string: "https://bvks.com/donate/") {
                let config = SFSafariViewController.Configuration()
                config.entersReaderIfAvailable = true
                let safariController = SFSafariViewController(url: donateWebsite, configuration: config)
                controller.present(safariController, animated: true, completion: nil)
            }
        case .copyright:
            let copyrightController = UIStoryboard.sideMenu.instantiate(CopyrightViewController.self)
            controller.present(copyrightController, animated: true, completion: nil)
        case .signOut:
            break
        }
    }
}
