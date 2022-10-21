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

        do {
            if let currentUser = Auth.auth().currentUser {
                userNameLabel.text = currentUser.displayName
                userEmailLabel.text = currentUser.email

                let placeholderImage = userImageView.placeholderImage(text: currentUser.displayName)
                if let photoURL = currentUser.photoURL {
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
            list.performUpdates({

                let section = IQSection(identifier: "Cell", headerSize: CGSize.zero, footerSize: CGSize.zero)
                list.append(section)

                list.append(Cell.self, models: models, section: section)

            }, animatingDifferences: animated, completion: nil)
        }
    }

    func listView(_ listView: IQListView, didSelect item: IQItem, at indexPath: IndexPath) {

        if let model = item.model as? Cell.Model {

            guard let cell = sideMenuTableView.cellForRow(at: indexPath) else { return }

            switch model {
            case .signOut:

                let alertController = UIAlertController(title: "Logout", message: "Are you sure you would like to Logout?", preferredStyle: .actionSheet)
                alertController.addAction(UIAlertAction(title: "Logout", style: .destructive, handler: { _ in

                    FirestoreManager.shared.signOut(completion: { result in
                        switch result {
                        case .success:
                            let keyWindow: UIWindow?
                            if #available(iOS 13, *) {
                                keyWindow = UIApplication.shared.connectedScenes
                                    .compactMap { $0 as? UIWindowScene }
                                    .flatMap { $0.windows }
                                    .first(where: { $0.isKeyWindow })
                            } else {
                                keyWindow = UIApplication.shared.keyWindow
                            }

                            if let keyWindow = keyWindow {
                                DefaultLectureViewModel.defaultModel.clearCache()
                                // A mask of options indicating how you want to perform the animations.
                                UIView.transition(with: keyWindow, duration: 0.5, options: [.transitionFlipFromLeft]) {
                                    let initialController = UIStoryboard.main.instantiateInitialViewController()
                                    keyWindow.rootViewController = initialController
                                } completion: { _ in
                                }
                            }
                        case .failure(let error):
                            let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                            alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                            self.present(alertController, animated: true, completion: nil)
                        }

                    })
                }))

                alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                alertController.popoverPresentationController?.sourceView = cell
                self.present(alertController, animated: true, completion: nil)
            default:
                delegate?.sideMenuController(self, didSelected: model, cell: cell)
            }
        }
    }
}
