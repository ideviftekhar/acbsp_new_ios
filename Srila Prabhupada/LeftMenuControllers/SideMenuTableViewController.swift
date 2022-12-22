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

                let placeholderImage = userImageView.placeholderImage(text: FirestoreManager.shared.currentUserDisplayName)
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
            sideMenuTableView.tableFooterView = UIView()
            refreshUI(animated: false)
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
            case .signOut:

                self.showAlert(title: "Logout", message: "Are you sure you would like to Logout?", preferredStyle: .actionSheet, sourceView: cell, cancel: ("Cancel", nil), destructive: ("Logout", {

                    FirestoreManager.shared.signOut(completion: { result in
                        switch result {
                        case .success:

                            if let keyWindow = self.view.window {
                                UIView.transition(with: keyWindow, duration: 0.5, options: .transitionFlipFromLeft, animations: {
                                    let loginNavigationController = UIStoryboard.main.instantiate(UINavigationController.self, identifier: "LoginNavigationController")
                                    keyWindow.rootViewController = loginNavigationController
                                })
                            }
                        case .failure(let error):
                            Haptic.error()
                            self.showAlert(title: "Error!", message: error.localizedDescription)
                        }
                    })
                }))
            default:
                delegate?.sideMenuController(self, didSelected: model, cell: cell)
            }
        }
    }
}
