//
//  BaseSearchViewController.swift
//  Srila Prabhupada
//
//  Created by IE06 on 08/09/22.
//

import UIKit
import SideMenu
import SafariServices

class BaseSearchViewController: UIViewController {

    @IBOutlet weak var hamburgerBarButton: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

extension BaseSearchViewController: SideMenuControllerDelegate {

    @IBAction func humburgerBarButtonTapped(_ sender : UIBarButtonItem){
        let storyboard = UIStoryboard(name: "SideMenu", bundle: nil)
        let sideMenuNavigationController = storyboard.instantiateViewController(withIdentifier: "SideMenuViewController") as! SideMenuNavigationController
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
            let storyboard = UIStoryboard(name: "History", bundle: nil)
            let history = storyboard.instantiateViewController(withIdentifier: "HistoryViewController") as! HistoryViewController
            controller.navigationController?.pushViewController(history, animated: true)
        case .stats:
            let storyboard = UIStoryboard(name: "Stats", bundle: nil)
            let stats = storyboard.instantiateViewController(withIdentifier: "StatsViewController") as! StatsViewController
            controller.navigationController?.pushViewController(stats, animated: true)
        case .popularLectures:
            let storyboard = UIStoryboard(name: "PopularLecture", bundle: nil)
            let popularLecture = storyboard.instantiateViewController(withIdentifier: "PopularLectureViewController") as! PopularLectureViewController
            controller.navigationController?.pushViewController(popularLecture, animated: true)
        case .about:
            let storyboard = UIStoryboard(name: "SideMenu", bundle: nil)
            let about = storyboard.instantiateViewController(withIdentifier: "AboutViewController") as! AboutViewController
            controller.present(about, animated: true, completion: nil)
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
            let storyboard = UIStoryboard(name: "SideMenu", bundle: nil)
            let copyright = storyboard.instantiateViewController(withIdentifier: "CopyrightViewController") as! CopyrightViewController
            controller.present(copyright, animated: true, completion: nil)
        case .signOut:
            break
        }
    }
}
