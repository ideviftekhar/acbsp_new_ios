//
//  SearchViewController.swift
//  Srila Prabhupada
//
//  Created by IE06 on 08/09/22.
//

import UIKit
import SideMenu
import SafariServices
import FirebaseFirestore
import StoreKit

class SearchViewController: UIViewController {

    @IBOutlet var hamburgerBarButton: UIBarButtonItem?
    let searchController = UISearchController(searchResultsController: nil)
    private var lastSearchText: String = ""

    internal let activityIndicatorView = UIActivityIndicatorView(style: .medium)
    internal lazy var activityBarButton = UIBarButtonItem(customView: activityIndicatorView)

    private(set) lazy var filterButton: UIBarButtonItem = UIBarButtonItem(image: UIImage(named: "line.3.horizontal.decrease.circle"), style: .plain, target: self, action: #selector(filterAction(_:)))

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

        self.navigationItem.leftItemsSupplementBackButton = true
        var rightButtons = self.navigationItem.rightBarButtonItems ?? []
        rightButtons.append(filterButton)
        self.navigationItem.rightBarButtonItems = rightButtons

        activityIndicatorView.color = UIColor.white
        var leftButtons = self.navigationItem.leftBarButtonItems ?? []
        leftButtons.append(activityBarButton)
        self.navigationItem.leftBarButtonItems = leftButtons

        do {
            let userDefaultKey: String = "\(Self.self).\(UISearchController.self)"
            let searchText = UserDefaults.standard.string(forKey: userDefaultKey)
            lastSearchText = searchText ?? ""

            searchController.delegate = self
            searchController.searchResultsUpdater = self
            searchController.obscuresBackgroundDuringPresentation = false
            searchController.hidesNavigationBarDuringPresentation = false

            do {
                searchController.searchBar.text = searchText
                searchController.searchBar.placeholder = "Search..."
                searchController.searchBar.barStyle = .black
                if Environment.current.device == .mac {
                    searchController.searchBar.barStyle = .default
                }
                searchController.searchBar.enablesReturnKeyAutomatically = false
            }

            do {
                searchController.automaticallyShowsCancelButton = false
                searchController.searchBar.searchTextField.font = UIFont(name: "AvenirNextCondensed-Regular", size: 17)
                searchController.searchBar.searchTextField.leftView?.tintColor = UIColor.D5D5D5
                searchController.searchBar.searchTextField.rightView?.tintColor = UIColor.D5D5D5
                searchController.searchBar.searchTextField.defaultTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
                searchController.searchBar.searchTextField.attributedPlaceholder = NSAttributedString(string: "Search...", attributes: [NSAttributedString.Key.foregroundColor: UIColor.D5D5D5])
            }

            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = false
        }

        let userDefaultKey: String = "\(Self.self).\(Filter.self)"
        selectedFilters = Filter.get(userDefaultKey: userDefaultKey)
        updateFilterButtonUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        refresh(source: .cache)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    @objc func refresh(source: FirestoreSource) {
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

extension SearchViewController: FilterViewControllerDelegate {

    private func updateFilterButtonUI() {

        var count = 0
        for filter in selectedFilters {
            count += filter.value.count
        }

        if count == 0 {
            filterButton.image = UIImage(named: "line.3.horizontal.decrease.circle")
        } else {
            filterButton.image = UIImage(named: "line.3.horizontal.decrease.circle.fill")
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

        refresh(source: .cache)
    }
}

extension SearchViewController: UISearchControllerDelegate, UISearchResultsUpdating {

    func willPresentSearchController(_ searchController: UISearchController) {
        lastSearchText = searchController.searchBar.text ?? ""
    }

    func willDismissSearchController(_ searchController: UISearchController) {
    }

    func updateSearchResults(for searchController: UISearchController) {
        if let text = searchController.searchBar.text, !text.elementsEqual(lastSearchText) {
            Self.cancelPreviousPerformRequests(withTarget: self, selector: #selector(userDidStoppedTyping), object: nil)
            self.perform(#selector(userDidStoppedTyping), with: nil, afterDelay: 0.1)
            lastSearchText = text
            let userDefaultKey: String = "\(Self.self).\(UISearchController.self)"
            UserDefaults.standard.set(lastSearchText, forKey: userDefaultKey)
        }
    }

    @objc private func userDidStoppedTyping() {
        refresh(source: .cache)
    }
}

extension SearchViewController: SideMenuControllerDelegate {

    @IBAction func humburgerBarButtonTapped(_ sender: UIBarButtonItem) {
        let sideMenuNavigationController = UIStoryboard.sideMenu.instantiate(SideMenuNavigationController.self)
        sideMenuNavigationController.settings.presentationStyle = .menuSlideIn
        sideMenuNavigationController.settings.presentationStyle.presentingEndAlpha = 0.7
        sideMenuNavigationController.settings.presentationStyle.onTopShadowOpacity = 0.3

        if let sideMenuNavigationController = sideMenuNavigationController.viewControllers.first as? SideMenuViewController {
            sideMenuNavigationController.delegate = self
        }

        present(sideMenuNavigationController, animated: true, completion: nil)
    }

    func sideMenuController(_ controller: SideMenuViewController, didSelected menu: SideMenuItem, cell: UITableViewCell) {
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
            let aboutController = UIStoryboard.sideMenu.instantiate(UINavigationController.self, identifier: "AboutNavigationController")
            aboutController.popoverPresentationController?.sourceView = cell
            controller.present(aboutController, animated: true, completion: nil)
        case .share:

            let appLink: [Any] = [URL(string: Constants.appStoreURLString)!, URL(string: Constants.playStoreURLString)!]
            let shareController = UIActivityViewController(activityItems: appLink, applicationActivities: nil)
            shareController.popoverPresentationController?.sourceView = cell
            controller.present(shareController, animated: true)
        case .donate:
            if let donateWebsite = URL(string: Constants.donateURLString) {
                let config = SFSafariViewController.Configuration()
                config.entersReaderIfAvailable = true
                let safariController = SFSafariViewController(url: donateWebsite, configuration: config)
                safariController.popoverPresentationController?.sourceView = cell
                controller.present(safariController, animated: true, completion: nil)
            }
#if SP
        case .copyright:
            let copyrightController = UIStoryboard.sideMenu.instantiate(UINavigationController.self, identifier: "CopyrightNavigationController")
            copyrightController.popoverPresentationController?.sourceView = cell
            controller.present(copyrightController, animated: true, completion: nil)
#endif
        case .rateUs:
            controller.dismiss(animated: true, completion: nil)

            let storeViewController = SKStoreProductViewController()
            storeViewController.delegate = self

            let parameters = [SKStoreProductParameterITunesItemIdentifier: NSNumber(value: Constants.appStoreIdentifier)]
            storeViewController.loadProduct(withParameters: parameters, completionBlock: { [weak self] (loaded, error) -> Void in
                if loaded {
                } else if let error = error {
                    storeViewController.dismiss(animated: true)
                    self?.showAlert(error: error)
                }
            })
            storeViewController.popoverPresentationController?.sourceView = cell
            // Parent class of self is UIViewContorller
            self.present(storeViewController, animated: true, completion: nil)
        case .contactUs:
            let aboutController = UIStoryboard.sideMenu.instantiate(UINavigationController.self, identifier: "ContactUsNavigationController")
            aboutController.popoverPresentationController?.sourceView = cell
            controller.present(aboutController, animated: true, completion: nil)
        }
    }
}

extension SearchViewController: SKStoreProductViewControllerDelegate {
    func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
}

extension SearchViewController {

    @objc func showLoading() {
        activityIndicatorView.startAnimating()
    }

    @objc func hideLoading() {
        activityIndicatorView.stopAnimating()
    }
}
