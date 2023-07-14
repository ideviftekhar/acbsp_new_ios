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

    struct Model: Hashable {
        func hash(into hasher: inout Hasher) {
            hasher.combine(playlist)
        }

        var playlist: Playlist
        var isSelectionEnabled: Bool
    }

    var model: Model? {
        didSet {
            guard let model = model else {
                return
            }

            titleLabel.text = model.playlist.title
            categoryLabel.text = model.playlist.lecturesCategory
            let dateString = DateFormatter.dd_MMM_yyyy.string(from: model.playlist.creationTime)
            dateLabel.text = dateString

            lectureCountLabel.text = "Lecture: \(model.playlist.lectureIds.count)"
            emailLabel.text = model.playlist.authorEmail

            firstDotLabel?.isHidden = model.playlist.lecturesCategory.isEmpty || dateString.isEmpty
            secondDotLabel?.isHidden = model.playlist.authorEmail.isEmpty

            if let url = model.playlist.thumbnailURL {
                thumbnailImageView.af.setImage(withURL: url, placeholderImage: UIImage(named: "logo_40"))
            } else {
                thumbnailImageView.image = UIImage(named: "logo_40")
            }

            do {
                var actions: [SPAction] = []

                if FirestoreManager.shared.currentUser != nil,
                   let email = FirestoreManager.shared.currentUserEmail,
                   model.playlist.authorEmail.elementsEqual(email) {

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

    static func size(for model: AnyHashable?, listView: IQListView) -> CGSize {
        switch Environment.current.device {
        case .mac, .pad:
            return CGSize(width: listView.frame.width, height: 75)
        default:
            return CGSize(width: listView.frame.width, height: 50)
        }
    }
}

extension PlaylistCell {
    func contextMenuConfiguration() -> UIContextMenuConfiguration? {

        guard let model = model, !model.isSelectionEnabled else {
            return nil
        }

        return .init(identifier: nil, previewProvider: {

            let controller = UIStoryboard.playlists.instantiate(PlaylistLecturesViewController.self)
            controller.playlist = model.playlist
            controller.popoverPresentationController?.sourceView = self

            return controller
        }, actionProvider: { _ in
            return self.optionMenu.menu
        })
    }

    func performPreviewAction(configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        if let previewViewController = animator.previewViewController {
            animator.addAnimations {
                self.parentViewController?.navigationController?.pushViewController(previewViewController, animated: true)
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

                delegate?.playlistCell(self, didSelected: option, with: model.playlist)
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
