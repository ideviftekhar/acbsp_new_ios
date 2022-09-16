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

    let firestore: Firestore = {
        let firestore = Firestore.firestore()
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        firestore.settings = settings

        return firestore
    }()

    @IBOutlet weak var hamburgerBarButton: UIBarButtonItem!
    let searchController = UISearchController(searchResultsController: nil)
    private var lastSearchText: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()

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
    }

    @objc func refreshAsynchronous() {

    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
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

    @IBAction func humburgerBarButtonTapped(_ sender : UIBarButtonItem){
        let sideMenuNavigationController = UIStoryboard.sideMenu.instantiate(SideMenuNavigationController.self)
        sideMenuNavigationController.settings.presentationStyle = .menuSlideIn
        sideMenuNavigationController .settings.presentationStyle.presentingEndAlpha = 0.7
        sideMenuNavigationController.settings.presentationStyle.onTopShadowOpacity = 0.3

        if let sideMenuNavigationController = sideMenuNavigationController.viewControllers.first as? SideMenuTableViewController {
            sideMenuNavigationController.delegate = self
        }

        present(sideMenuNavigationController, animated: true, completion: nil)
    }

    func sideMenuController(_ controller: SideMenuTableViewController, didSelected menu: SideMenuTableViewController.Menu) {
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
            controller.present(shareController,animated: true)
        case .donate:
            if let donateWebsite = URL (string: "https://bvks.com/donate/"){
                let config = SFSafariViewController.Configuration()
                config.entersReaderIfAvailable = true
                let safariController = SFSafariViewController(url: donateWebsite, configuration:config)
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
