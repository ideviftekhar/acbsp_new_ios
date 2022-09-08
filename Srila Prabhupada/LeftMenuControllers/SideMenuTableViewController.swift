//
//  SideMenuTableViewController.swift
//  SrilaPrabhupada
//
//  Created by IE06 on 21/08/22.
//

import UIKit

//Protocol
protocol SideMenuControllerDelegate: AnyObject {

    func sideMenuController(_ controller: SideMenuTableViewController, didSelected menu: SideMenuTableViewController.Menu)
}

class SideMenuTableViewController: UITableViewController{
    
    @IBOutlet weak var sideMenuTableView : UITableView!

    enum Menu: String, CaseIterable {
        case mediaLibrary = "Media library"
        case history = "History"
        case stats = "Stats"
        case popularLectures = "Popular Lectures"
        case about = "About"
        case share = "Share"
        case donate = "Donate"
        case copyright = "Copyright"
        case signOut = "Logout"
    }

    let menus: [Menu] = Menu.allCases

    //delegate property
    weak var delegate : SideMenuControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menus.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SideMenuCell", for: indexPath)
        
        let menu = menus[indexPath.row]
        cell.textLabel?.text = menu.rawValue
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        tableView.deselectRow(at: indexPath, animated: true)

        let menu = menus[indexPath.row]

        switch menu {
        case .signOut:

            let alertController = UIAlertController(title: "Logout", message: "Are you sure you would like to Logout?", preferredStyle: .actionSheet)
            alertController.addAction(UIAlertAction(title: "Logout", style: .destructive, handler: { _ in
                if let window = UIApplication.shared.keyWindow {
                // A mask of options indicating how you want to perform the animations.
                UIView.transition(with: window, duration: 0.5, options: [.transitionFlipFromLeft]) {
                            let storyboard = UIStoryboard(name: "Main", bundle: nil)
                            let initialController = storyboard.instantiateInitialViewController()
                            window.rootViewController = initialController
                        } completion: { _ in
                        }
                    }
            }))

            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        default:
            delegate?.sideMenuController(self, didSelected: menu)
        }
    }

}
