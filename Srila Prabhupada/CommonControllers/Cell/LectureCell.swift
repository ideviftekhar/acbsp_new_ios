//
//  LectureCell.swift
//  Srila Prabhupada
//
//  Created by IE06 on 08/09/22.
//

import UIKit
import IQListKit
import MBCircularProgressBar
import AlamofireImage

class LectureCell: UITableViewCell, IQModelableCell {

    @IBOutlet private var downloadedIconImageView: UIImageView!
    @IBOutlet private var favoritesIconImageView: UIImageView!
    @IBOutlet private var completedIconImageView: UIImageView!

    @IBOutlet private var thumbnailImageView: UIImageView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var verseLabel: UILabel!
    @IBOutlet private var durationLabel: UILabel!
    @IBOutlet private var locationLabel: UILabel!
    @IBOutlet private var dateLabel: UILabel!
    @IBOutlet private var menuButton: UIButton!
    @IBOutlet private var progressView: MBCircularProgressBarView!

    var allActions: [LectureOption: UIAction] = [:]

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

    typealias Model = Lecture

    var model: Model? {
        didSet {
            guard let model = model else {
                return
            }

            titleLabel.text = model.titleDisplay
//            verseLabel.text = model.language["main"] as? String
            verseLabel.text = model.legacyData.verse
            durationLabel.text = model.lengthTime.displayString
            locationLabel.text = model.location.displayString
            dateLabel.text = "\(model.dateOfRecording.year)/\(model.dateOfRecording.month)/\(model.dateOfRecording.day)/"
            progressView.value = CGFloat(model.playProgress)

            progressView.isHidden = model.playProgress == 100
            completedIconImageView.isHidden = model.playProgress != 100

            if let url = model.thumbnailURL {
                thumbnailImageView.af.setImage(withURL: url, placeholderImage: UIImage(named: "logo_40"))
            } else {
                thumbnailImageView.image = UIImage(named: "logo_40")
            }

            switch model.downloadingState {
            case .notDownloaded:
                downloadedIconImageView.isHidden = true
            case .downloading:
                downloadedIconImageView.isHidden = false
                downloadedIconImageView.tintColor = UIColor.systemGray
            case .downloaded:
                downloadedIconImageView.isHidden = false
                downloadedIconImageView.tintColor = UIColor.systemGreen
            }

            favoritesIconImageView.isHidden = !model.isFavorites

            do {
                var actions: [UIAction] = []

                if model.downloadingState != .notDownloaded, let deleteDownload = allActions[.deleteFromDownloads] {
                    actions.append(deleteDownload)
                } else if let download = allActions[.download] {
                    actions.append(download)
                }

                // Is Favorites
                if model.isFavorites, let removeFromFavorites = allActions[.removeFromFavorites] {
                    actions.append(removeFromFavorites)
                } else if let markAsFavorite = allActions[.markAsFavorite] {
                    actions.append(markAsFavorite)
                }

                // addToPlaylist
                if let addToPlaylist = allActions[.addToPlaylist] {
                    actions.append(addToPlaylist)
                }

                // Is Heard
                if model.playProgress == 100, let resetProgress = allActions[.resetProgress] {
                    actions.append(resetProgress)
                } else if let markAsHeard = allActions[.markAsHeard] {
                    actions.append(markAsHeard)
                }

                // share
                if let share = allActions[.share] {
                    actions.append(share)
                }

                self.menuButton.menu = self.menuButton.menu?.replacingChildren(actions)
            }
        }
    }

    private func configureMenuButton() {

        for option in LectureOption.allCases {
            let action: UIAction = UIAction(title: option.rawValue, image: nil, identifier: UIAction.Identifier(option.rawValue), handler: { [self] _ in

                guard let model = model else {
                    return
                }

                switch option {
                case .download:
                    Persistant.shared.save(lecture: model)
                case .deleteFromDownloads:
                    Persistant.shared.delete(lecture: model)
                case .markAsFavorite:
                    break
                case .removeFromFavorites:
                    break
                case .addToPlaylist:
                    break
                case .markAsHeard:
                    break
                case .resetProgress:
                    break
                case .share:
                    break
                }
            })

            allActions[option] = action
        }

        let childrens: [UIAction] = allActions.compactMap({ (key: LectureOption, _: UIAction) in
            return allActions[key]
        })

        menuButton.showsMenuAsPrimaryAction = true
        menuButton.menu = UIMenu(title: "", image: nil, identifier: UIMenu.Identifier.init(rawValue: "Option"), options: UIMenu.Options.displayInline, children: childrens)
    }
}

extension LectureCell {

    static func estimatedSize(for model: AnyHashable?, listView: IQListView) -> CGSize {
        size(for: model, listView: listView)
    }

    static func size(for model: AnyHashable?, listView: IQListView) -> CGSize {
        return CGSize(width: listView.frame.width, height: 60)
    }
}
