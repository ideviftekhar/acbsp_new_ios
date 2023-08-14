//
//  PlaylistHeaderView.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 8/10/23.
//

import Foundation
import IQListKit

protocol PlaylistHeaderViewDelegate: AnyObject {
    func playlistHeaderView(_ view: PlaylistHeaderView, didSelected option: PlaylistOption, with playlist: Playlist)
}

class PlaylistHeaderView: UICollectionReusableView, IQModelableSupplementaryView {

    @IBOutlet private var thumbnailImageView: UIImageView!
    @IBOutlet private var titleLabel: UILabel?
    @IBOutlet private var categoryLabel: UILabel!
    @IBOutlet private var dateLabel: UILabel!
    @IBOutlet private var lectureCountLabel: UILabel!
    @IBOutlet private var emailLabel: UILabel!
    @IBOutlet private var menuButton: UIButton!

    weak var delegate: PlaylistHeaderViewDelegate?

    private var optionMenu: SPMenu!
    var allActions: [PlaylistOption: SPAction] = [:]

    override func awakeFromNib() {
        super.awakeFromNib()
        configureMenuButton()
    }

    struct Model: Hashable {

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.identifier == rhs.identifier &&
            lhs.playlist == rhs.playlist
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(identifier)
        }

        let identifier: AnyHashable
        let playlist: Playlist
    }

    var model: Model? {
        didSet {
            guard let model = model else {
                return
            }

            titleLabel?.text = model.playlist.title
            categoryLabel.text = model.playlist.lecturesCategory
            let dateString = DateFormatter.dd_MMM_yyyy.string(from: model.playlist.creationTime)
            dateLabel.text = dateString

            lectureCountLabel.text = "Lecture: \(model.playlist.lectureIds.count)"
            emailLabel.text = model.playlist.authorEmail

            if let url = model.playlist.thumbnailURL {
                thumbnailImageView.af.setImage(withURL: url, placeholderImage: UIImage(named: "logo_40"))
            } else {
                thumbnailImageView.image = UIImage(named: "logo_40")
            }

            do {
                var actions: [SPAction] = []

                if !model.playlist.lectureIds.isEmpty, let addToPlayNext = allActions[.addToPlayNext] {
                    actions.append(addToPlayNext)
                }

                if !model.playlist.lectureIds.isEmpty, let addToQueue = allActions[.addToQueue] {
                    actions.append(addToQueue)
                }

                if FirestoreManager.shared.currentUser != nil,
                   let email = FirestoreManager.shared.currentUserEmail,
                   model.playlist.authorEmail.elementsEqual(email) {

                    if let editPlaylist = allActions[.edit] {
                        actions.append(editPlaylist)
                    }

                    if let deletePlaylist = allActions[.delete] {
                        actions.append(deletePlaylist)
                    }
                }

                self.optionMenu.children = actions
                self.menuButton.isHidden = actions.isEmpty
            }
        }
    }

    static func estimatedSize(for model: AnyHashable?, listView: IQListView) -> CGSize {
        switch Environment.current.device {
        case .mac, .pad:
            return CGSize(width: listView.frame.width, height: 242)
        default:
            return CGSize(width: listView.frame.width, height: 242)
        }
    }

    static func size(for model: AnyHashable?, listView: IQListView) -> CGSize {
        return CGSize(width: listView.frame.width, height: UITableView.automaticDimension)
    }
}

extension PlaylistHeaderView {

    private func configureMenuButton() {

        for option in PlaylistOption.allCases {

            let action: SPAction = SPAction(title: option.rawValue, image: option.image, identifier: .init(option.rawValue), groupIdentifier: option.groupIdentifier, handler: { [self] _ in

                guard let model = model else {
                    return
                }

                delegate?.playlistHeaderView(self, didSelected: option, with: model.playlist)
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
