//
//  SideMenuTableViewController.swift
//  SrilaPrabhupada
//
//  Created by IE06 on 21/08/22.
//

import UIKit

// Protocol
protocol SideMenuControllerDelegate: AnyObject {

    func sideMenuController(_ controller: SideMenuTableViewController, didSelected menu: SideMenuItem)
}

class SideMenuTableViewController: UITableViewController {

    @IBOutlet weak var sideMenuTableView: UITableView!

    let menus: [SideMenuItem] = SideMenuItem.allCases

    // delegate property
    weak var delegate: SideMenuControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

extension SideMenuTableViewController {

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menus.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SideMenuCell", for: indexPath)

        let menu = menus[indexPath.row]
        cell.textLabel?.text = menu.rawValue

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let menu = menus[indexPath.row]

        switch menu {
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
            delegate?.sideMenuController(self, didSelected: menu)
        }
    }
}
