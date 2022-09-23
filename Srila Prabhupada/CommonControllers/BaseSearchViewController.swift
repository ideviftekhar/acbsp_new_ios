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

    private(set) lazy var filterButton: UIBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "line.3.horizontal.decrease.circle"), style: .plain, target: self, action: #selector(filterAction(_:)))

    var selectedFilters: [Filter: [String]] = [:]

    var searchText: String? {
        if let text = searchController.searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty {
            return text
        } else {
            return nil
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        var rightButtons = self.navigationItem.rightBarButtonItems ?? []
        rightButtons.append(filterButton)
        self.navigationItem.rightBarButtonItems = rightButtons

        do {
            let userDefaultKey: String = "\(Self.self).\(UISearchController.self)"
            let searchText = UserDefaults.standard.string(forKey: userDefaultKey)

            searchController.obscuresBackgroundDuringPresentation = false
            searchController.searchBar.text = searchText
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
        }

        let userDefaultKey: String = "\(Self.self).\(Filter.self)"
        selectedFilters = Filter.get(userDefaultKey: userDefaultKey)
        updateFilterButtonUI()
    }

    var isFirstTime: Bool = true

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if isFirstTime {
            isFirstTime = false
            refreshAsynchronous(source: .default)
        }
    }

    @objc func refreshAsynchronous(source: FirestoreSource) {

    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

extension BaseSearchViewController: FilterViewControllerDelegate {

    private func updateFilterButtonUI() {

        var count = 0
        for filter in selectedFilters {
            count += filter.value.count
        }

        if count == 0 {
            filterButton.image = UIImage(systemName: "line.3.horizontal.decrease.circle")
        } else {
            filterButton.image = UIImage(systemName: "line.3.horizontal.decrease.circle.fill")
        }
    }

    @objc private func filterAction(_ sender: Any) {
        let navController = UIStoryboard.common.instantiate(UINavigationController.self, identifier: "FilterNavigationController")
        guard let viewController = navController.viewControllers.first as? FilterViewController else {
            return
        }

        viewController.delegate = self
        viewController.selectedFilters = self.selectedFilters

        self.present(navController, animated: true)
    }

    func filterController(_ controller: FilterViewController, didSelected filters: [Filter: [String]]) {

        self.selectedFilters = filters

        updateFilterButtonUI()

        let userDefaultKey: String = "\(Self.self).\(Filter.self)"
        Filter.set(filters: filters, userDefaultKey: userDefaultKey)

        refreshAsynchronous(source: .cache)
    }
}

extension BaseSearchViewController: UISearchControllerDelegate, UISearchResultsUpdating {

    func willPresentSearchController(_ searchController: UISearchController) {
        lastSearchText = searchController.searchBar.text ?? ""
    }

    func willDismissSearchController(_ searchController: UISearchController) {

    }

    func updateSearchResults(for searchController: UISearchController) {
        if let text = searchController.searchBar.text, !text.elementsEqual(lastSearchText) {
            Self.cancelPreviousPerformRequests(withTarget: self, selector: #selector(userDidStoppedTyping), object: nil)
            self.perform(#selector(userDidStoppedTyping), with: nil, afterDelay: 1)
            lastSearchText = text
            let userDefaultKey: String = "\(Self.self).\(UISearchController.self)"
            UserDefaults.standard.set(lastSearchText, forKey: userDefaultKey)
        }
    }

    @objc private func userDidStoppedTyping() {
        refreshAsynchronous(source: .cache)
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
