//
//  SideMenuTableViewController.swift
//  SrilaPrabhupada
//
//  Created by IE06 on 21/08/22.
//

import UIKit
import IQListKit

// Protocol
protocol SideMenuControllerDelegate: AnyObject {

    func sideMenuController(_ controller: SideMenuTableViewController, didSelected menu: SideMenuItem)
}

class SideMenuTableViewController: UITableViewController {

    @IBOutlet weak var sideMenuTableView: UITableView!

    typealias Model = SideMenuItem
    typealias Cell = SideMenuCell

    private let models: [SideMenuItem] = SideMenuItem.allCases
    private lazy var list = IQList(listView: sideMenuTableView, delegateDataSource: self)

    // delegate property
    weak var delegate: SideMenuControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        do {
            list.registerCell(type: Cell.self, registerType: .nib)
            refreshUI(animated: false)
        }
    }
}

extension SideMenuTableViewController: IQListViewDelegateDataSource {

    private func refreshUI(animated: Bool? = nil) {

        let animated: Bool = animated ?? (models.count <= 1000)
        list.performUpdates({

            let section = IQSection(identifier: "Cell", headerSize: CGSize.zero, footerSize: CGSize.zero)
            list.append(section)

            list.append(Cell.self, models: models, section: section)

        }, animatingDifferences: animated, completion: nil)
    }

    func listView(_ listView: IQListView, didSelect item: IQItem, at indexPath: IndexPath) {

        if let model = item.model as? Cell.Model {

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
                self.present(alertController, animated: true, completion: nil)
            default:
                delegate?.sideMenuController(self, didSelected: model)
            }
        }
    }
}
