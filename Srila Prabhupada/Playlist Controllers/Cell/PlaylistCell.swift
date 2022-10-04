//
//  PlaylistCell.swift
//  Srila Prabhupada
//
//  Created by IE on 9/22/22.
//

import UIKit
import IQListKit
import FirebaseAuth

protocol PlaylistCellDelegate: AnyObject {
    func playlistCell(_ cell: PlaylistCell, didSelected option: PlaylistOption, with playlist: Playlist)
}

class PlaylistCell: UITableViewCell, IQModelableCell {

    @IBOutlet private var thumbnailImageView: UIImageView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var categoryLabel: UILabel!
    @IBOutlet private var dateLabel: UILabel!
    @IBOutlet private var lectureCountLabel: UILabel!
    @IBOutlet private var emailLabel: UILabel!
    @IBOutlet private var menuButton: UIButton!

    weak var delegate: PlaylistCellDelegate?

    private var optionMenu: UIMenu!
    var allActions: [PlaylistOption: UIAction] = [:]

    override func awakeFromNib() {
        super.awakeFromNib()
        configureMenuButton()
    }

    typealias Model = Playlist

    var model: Model? {
        didSet {
            guard let model = model else {
                return
            }

            titleLabel.text = model.title
            categoryLabel.text = model.lecturesCategory
            dateLabel.text = DateFormatter.dd_MMM_yyyy.string(from: model.creationTime)

            lectureCountLabel.text = "Lecture: \(model.lectureIds.count)"
            emailLabel.text = model.authorEmail

            if let url = model.thumbnailURL {
                thumbnailImageView.af.setImage(withURL: url, placeholderImage: UIImage(named: "logo_40"))
            } else {
                thumbnailImageView.image = UIImage(named: "logo_40")
            }

            do {
                var actions: [UIAction] = []

                if let user = Auth.auth().currentUser,
                   let email = user.email,
                   model.authorEmail.elementsEqual(email), let deletePlaylist = allActions[.deletePlaylist] {
                    actions.append(deletePlaylist)
                }

                self.optionMenu = self.optionMenu.replacingChildren(actions)
                self.menuButton.isHidden = actions.isEmpty

                if #available(iOS 14.0, *) {
                    self.menuButton.menu = self.optionMenu
                }
            }
        }
    }
}

extension PlaylistCell {

    private func configureMenuButton() {

        for option in PlaylistOption.allCases {
            let action: UIAction = UIAction(title: option.rawValue, image: nil, identifier: UIAction.Identifier(option.rawValue), handler: { [self] _ in

                guard let model = model else {
                    return
                }

                delegate?.playlistCell(self, didSelected: option, with: model)
            })

            allActions[option] = action
        }

        let childrens: [UIAction] = allActions.compactMap({ (key: PlaylistOption, _: UIAction) in
            return allActions[key]
        })

        self.optionMenu = UIMenu(title: "", image: nil, identifier: UIMenu.Identifier.init(rawValue: "Option"), options: UIMenu.Options.displayInline, children: childrens)

        if #available(iOS 14.0, *) {
            menuButton.showsMenuAsPrimaryAction = true
            menuButton.menu = optionMenu
        } else {
            menuButton.addTarget(self, action: #selector(optionMenuActioniOS13(_:)), for: .touchUpInside)
        }
    }

    // Backward compatibility for iOS 13
    @objc private func optionMenuActioniOS13(_ sender: UIButton) {

        var buttons: [UIViewController.ButtonConfig] = []
        let actions: [UIAction] = self.optionMenu.children as? [UIAction] ?? []
        for action in actions {
            buttons.append((title: action.title, handler: { [self] in

                guard let model = model, let option: PlaylistOption = allActions.first(where: { $0.value == action})?.key else {
                    return
                }

                delegate?.playlistCell(self, didSelected: option, with: model)
            }))
        }

        self.parentViewController?.showAlert(title: "", message: "", preferredStyle: .actionSheet, buttons: buttons)
    }
}
