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
            sideMenuTableView.tableFooterView = UIView()
            sideMenuTableView.separatorStyle = .singleLine
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(stackViewTapped))
        userProfileStackView.addGestureRecognizer(tapGesture)
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

extension SideMenuViewController: IQListViewDelegateDataSource {

    private func refreshUI(animated: Bool? = nil) {

        let footer = NSMutableAttributedString()
        if let lastTimestamp: Date = UserDefaults.standard.object(forKey: CommonConstants.keyTimestamp) as? Date {
            footer.append(.init(string: "\n\tLectures Updated On:", attributes: [.font: UIFont(name: "AvenirNextCondensed-Medium", size: 12)!, .foregroundColor: UIColor.gray]))

            

            let dateString = "\n\t" + DateFormatter.localizedString(from: lastTimestamp, dateStyle: .medium, timeStyle: .short)
            footer.append(.init(string: dateString, attributes: [.font: UIFont(name: "AvenirNextCondensed-Regular", size: 12)!, .foregroundColor: UIColor.lightGray]))
        }
        let label = UILabel()
        label.numberOfLines = 0
        label.attributedText = footer
        label.sizeToFit()

        serialListKitQueue.async { [self] in
            let animated: Bool = animated ?? (models.count <= 1000)
            list.reloadData({

                let section = IQSection(identifier: "Cell", headerSize: CGSize.zero, footerView: label)
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
