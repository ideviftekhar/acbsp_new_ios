//
//  SideMenuViewController.swift
//  SrilaPrabhupada
//
//  Created by IE06 on 21/08/22.
//

import UIKit
import IQListKit
import FirebaseAuth
import AlamofireImage

// Protocol
protocol SideMenuControllerDelegate: AnyObject {

    func sideMenuController(_ controller: SideMenuViewController, didSelected menu: SideMenuItem, cell: UITableViewCell)
}

class SideMenuViewController: UIViewController {

    @IBOutlet private var sideMenuTableView: UITableView!
    @IBOutlet private var userImageView: UIImageView!
    @IBOutlet private var userNameLabel: UILabel!
    @IBOutlet private var userEmailLabel: UILabel!
    @IBOutlet private var userProfileStackView: UIStackView!

    @IBOutlet private var syncButton: RefreshButton!
    @IBOutlet private var lastLecturePublishedStaticLabel: UILabel!
    @IBOutlet private var lastLectureDateLabel: UILabel!

    typealias Model = SideMenuItem
    typealias Cell = SideMenuCell

    private let models: [SideMenuItem] = SideMenuItem.allCases
    private lazy var list = IQList(listView: sideMenuTableView, delegateDataSource: self)
    private lazy var serialListKitQueue = DispatchQueue(label: "ListKitQueue_\(Self.self)", qos: .userInteractive)

    // delegate property
    weak var delegate: SideMenuControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 13.0, *) {
            let navigationBarAppearance = UINavigationBarAppearance()
            navigationBarAppearance.backgroundColor = UIColor.themeColor
            navigationBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            navigationBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

            navigationController?.navigationBar.standardAppearance = navigationBarAppearance
            navigationController?.navigationBar.compactAppearance = navigationBarAppearance
            navigationController?.navigationBar.scrollEdgeAppearance = navigationBarAppearance
            if #available(iOS 15.0, *) {
                navigationController?.navigationBar.compactScrollEdgeAppearance = navigationBarAppearance
            }
        }

        do {
            if FirestoreManager.shared.currentUser != nil {
                userNameLabel.text = FirestoreManager.shared.currentUserDisplayName
                userEmailLabel.text = FirestoreManager.shared.currentUserEmail

                var text = ""
                
                if let name = FirestoreManager.shared.currentUserDisplayName {
                    text = name
                } else if let email = FirestoreManager.shared.currentUserEmail {
                    text = email
                }
                
                let placeholderImage = userImageView.placeholderImage(text: text)
                
                if let photoURL = FirestoreManager.shared.currentUserPhotoURL {
                    userImageView.af.setImage(withURL: photoURL, placeholderImage: placeholderImage)
                } else {
                    userImageView.image = placeholderImage
                }
            } else {
                userNameLabel.text = nil
                userEmailLabel.text = nil
                userImageView.image = userImageView.placeholderImage(text: nil)
            }
        }

        do {
            list.registerCell(type: Cell.self, registerType: .nib)
            sideMenuTableView.separatorStyle = .singleLine
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(stackViewTapped))
        userProfileStackView.addGestureRecognizer(tapGesture)

        addSyncStatusListener()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshUI(animated: false)
    }

    @objc func stackViewTapped() {
        let userProfileController = UIStoryboard.sideMenu.instantiate(UINavigationController.self, identifier: "UserProfileNavigationController")
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            userProfileController.modalPresentationStyle = .fullScreen
        }

        self.present(userProfileController, animated: true)
    }
}

extension SideMenuViewController {
    var appTabBarController: TabBarController? {
        var controller: UIViewController = self

        while let presenting = controller.presentingViewController {
            controller = presenting
            if let controller = controller as? TabBarController {
                return controller
            }
        }
        return nil
    }

    private func addSyncStatusListener() {
        guard let tabBarController = self.appTabBarController else {
            return
        }

        switch tabBarController.lectureSyncManager.syncStatus {
        case .none:
            syncButton.stopSpinning()
        case .syncing:
            syncButton.startSpinning()
        }
        updateLastSyncTime()

        tabBarController.lectureSyncManager.syncStatusHandler = { [self] status in
            switch status {
            case .none:
                syncButton.stopSpinning()
            case .syncing:
                syncButton.startSpinning()
            }
            updateLastSyncTime()
        }
    }

    private func updateLastSyncTime() {
        guard let tabBarController = self.appTabBarController else {
            return
        }

        switch tabBarController.lectureSyncManager.syncStatus {
        case .none:
            lastLecturePublishedStaticLabel.text = "Last Lecture Published On:"
        case .syncing:
            lastLecturePublishedStaticLabel.text = "Syncing..."
        }

        if let lastTimestamp: Date = UserDefaults.standard.object(forKey: CommonConstants.keyTimestamp) as? Date {
            lastLectureDateLabel.text = DateFormatter.localizedString(from: lastTimestamp, dateStyle: .medium, timeStyle: .short)
        } else {
            lastLectureDateLabel.text = nil
        }
    }

    @IBAction func syncAction(_ sender: UIButton) {

        guard let tabBarController = self.appTabBarController else {
            return
        }

        switch tabBarController.lectureSyncManager.syncStatus {
        case .none:
            tabBarController.startSyncing()
        case .syncing:
            break
        }
    }
}

extension SideMenuViewController: IQListViewDelegateDataSource {

    private func refreshUI(animated: Bool? = nil) {

        serialListKitQueue.async { [self] in
            let animated: Bool = animated ?? (models.count <= 1000)
            list.reloadData({

                let section = IQSection(identifier: "Cell", headerSize: CGSize.zero, footerSize: CGSize.zero)
                list.append([section])

                list.append(Cell.self, models: models, section: section)

            }, animatingDifferences: animated, completion: nil)
        }
    }

    func listView(_ listView: IQListView, didSelect item: IQItem, at indexPath: IndexPath) {

        if let model = item.model as? Cell.Model {

            guard let cell = sideMenuTableView.cellForRow(at: indexPath) else { return }

            Haptic.selection()

            switch model {
            default:
                delegate?.sideMenuController(self, didSelected: model, cell: cell)
            }
        }
    }
}
