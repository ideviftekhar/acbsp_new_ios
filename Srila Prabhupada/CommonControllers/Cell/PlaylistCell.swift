//
//  PlaylistCell.swift
//  Srila Prabhupada
//
//  Created by IE on 9/22/22.
//

import UIKit
import IQListKit

class PlaylistCell: UITableViewCell, IQModelableCell {

    @IBOutlet private var thumbnailImageView: UIImageView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var categoryLabel: UILabel!
    @IBOutlet private var dateLabel: UILabel!
    @IBOutlet private var lectureCountLabel: UILabel!
    @IBOutlet private var emailLabel: UILabel!
    @IBOutlet private var menuButton: UIButton!

    var menu: UIMenu!

    var allActions: [PlaylistOption: UIAction] = [:]

    override func awakeFromNib() {
        super.awakeFromNib()
        configureMenuButton()
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    typealias Model = Playlist

    var model: Model? {
        didSet {
            guard let model = model else {
                return
            }

            titleLabel.text = model.title
            categoryLabel.text = "TODO"
            dateLabel.text = "TODO"
//            dateLabel.text = "\(model.dateOfRecording.year)/\(model.dateOfRecording.month)/\(model.dateOfRecording.day)/"
            lectureCountLabel.text = "Lecture: \(model.lectureIds.count)"
            emailLabel.text = "TODO"

//            if let url = model.thumbnail {
//                thumbnailImageView.af.setImage(withURL: url, placeholderImage: UIImage(named: "logo_40"))
//            } else {
                thumbnailImageView.image = UIImage(named: "logo_40")
//            }

            do {
                var actions: [UIAction] = []

                // Is Private
                if Bool.random(), let deletePlaylist = allActions[.deletePlaylist] {
                    actions.append(deletePlaylist)
                }

                menu.replacingChildren(actions)
            }
        }
    }

    private func configureMenuButton() {

        for option in PlaylistOption.allCases {
            let action: UIAction = UIAction(title: option.rawValue, image: nil, identifier: UIAction.Identifier(option.rawValue), handler: { [self] _ in

                switch option {
                case .deletePlaylist:
                    break
                }

            })

            allActions[option] = action
        }

        let childrens: [UIAction] = allActions.compactMap({ (key: PlaylistOption, _: UIAction) in
            return allActions[key]
        })

        menu = UIMenu(title: "", image: nil, identifier: UIMenu.Identifier.init(rawValue: "Option"), options: UIMenu.Options.displayInline, children: childrens)

        menuButton.showsMenuAsPrimaryAction = true
        menuButton.menu = menu
    }
}
