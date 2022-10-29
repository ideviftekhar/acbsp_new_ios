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

    @IBOutlet private var firstDotLabel: UILabel?
    @IBOutlet private var secondDotLabel: UILabel?

    weak var delegate: PlaylistCellDelegate?

    private var optionMenu: SPMenu!
    var allActions: [PlaylistOption: SPAction] = [:]

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
            let dateString = DateFormatter.dd_MMM_yyyy.string(from: model.creationTime)
            dateLabel.text = dateString

            lectureCountLabel.text = "Lecture: \(model.lectureIds.count)"
            emailLabel.text = model.authorEmail

            firstDotLabel?.isHidden = model.lecturesCategory.isEmpty || dateString.isEmpty
            secondDotLabel?.isHidden = model.authorEmail.isEmpty

            if let url = model.thumbnailURL {
                thumbnailImageView.af.setImage(withURL: url, placeholderImage: UIImage(named: "logo_40"))
            } else {
                thumbnailImageView.image = UIImage(named: "logo_40")
            }

            do {
                var actions: [SPAction] = []

                if let user = Auth.auth().currentUser,
                   let email = user.email,
                   model.authorEmail.elementsEqual(email) {

                    if let deletePlaylist = allActions[.delete] {
                        actions.append(deletePlaylist)
                    }

                    if let editPlaylist = allActions[.edit] {
                        actions.append(editPlaylist)
                    }
                }

                self.optionMenu.children = actions
                self.menuButton.isHidden = actions.isEmpty
            }
        }
    }
}

extension PlaylistCell {

    private func configureMenuButton() {

        for option in PlaylistOption.allCases {

            let action: SPAction = SPAction(title: option.rawValue, image: option.image, identifier: .init(option.rawValue), handler: { [self] _ in

                guard let model = model else {
                    return
                }

                delegate?.playlistCell(self, didSelected: option, with: model)
            })

            if option == .delete {
                action.action.attributes = .destructive
            }

            allActions[option] = action
        }

        let childrens: [SPAction] = allActions.compactMap({ (key: PlaylistOption, _: SPAction) in
            return allActions[key]
        })

        self.optionMenu = SPMenu(title: "", image: nil, identifier: UIMenu.Identifier.init(rawValue: "Option"), options: .displayInline, children: childrens, button: menuButton)
    }
}
