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

protocol LectureCellDelegate: AnyObject {
    func lectureCell(_ cell: LectureCell, didSelected option: LectureOption, with lecture: Lecture)
}

class LectureCell: UITableViewCell, IQModelableCell {

    @IBOutlet private var downloadedIconImageView: UIImageView!
    @IBOutlet private var favouritesIconImageView: UIImageView!
    @IBOutlet private var completedIconImageView: UIImageView!

    @IBOutlet private var thumbnailImageView: UIImageView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var verseLabel: UILabel!
    @IBOutlet private var durationLabel: UILabel!
    @IBOutlet private var locationLabel: UILabel!
    @IBOutlet private var dateLabel: UILabel!
    @IBOutlet private var menuButton: UIButton!
    @IBOutlet private var downloadProgressView: MBCircularProgressBarView!
    @IBOutlet private var listenProgressView: MBCircularProgressBarView!

    weak var delegate: LectureCellDelegate?

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

    override func prepareForReuse() {
        super.prepareForReuse()

        guard let model = model else {
            return
        }

        DownloadManager.shared.unregisterProgress(observer: self, lectureID: model.id)
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
            listenProgressView.value = CGFloat(model.playProgress)

            listenProgressView.isHidden = model.playProgress == 100
            completedIconImageView.isHidden = model.playProgress != 100

            if let url = model.thumbnailURL {
                thumbnailImageView.af.setImage(withURL: url, placeholderImage: UIImage(named: "logo_40"))
            } else {
                thumbnailImageView.image = UIImage(named: "logo_40")
            }

            switch model.downloadingState {
            case .notDownloaded:
                downloadedIconImageView.isHidden = true
                downloadProgressView.isHidden = true
            case .downloading:
                downloadedIconImageView.isHidden = false
                downloadedIconImageView.tintColor = UIColor.systemBlue
                downloadedIconImageView.image = UIImage(systemName: "arrow.down.circle.fill")
                downloadProgressView.isHidden = false

                DownloadManager.shared.registerProgress(observer: self, lectureID: model.id) { [weak self] progress in
                    self?.downloadProgressView.value = progress * 100
                }
            case .downloaded:
                downloadedIconImageView.isHidden = false
                downloadedIconImageView.tintColor = UIColor.systemGreen
                downloadedIconImageView.image = UIImage(systemName: "arrow.down.circle.fill")
                downloadProgressView.isHidden = false
                downloadProgressView.value = 0
            case .error:
                downloadedIconImageView.isHidden = false
                downloadedIconImageView.tintColor = UIColor.systemRed
                downloadedIconImageView.image = UIImage(systemName: "exclamationmark.circle.fill")
                downloadProgressView.isHidden = false
                downloadProgressView.value = 0
            }

            favouritesIconImageView.isHidden = !model.isFavourites

            do {
                var actions: [UIAction] = []

                switch model.downloadingState {
                case .notDownloaded, .error:
                    if let download = allActions[.download] {
                        actions.append(download)
                    }
                case .downloading:
                    if let downloading = allActions[.downloading] {
                        actions.append(downloading)
                    }
                case .downloaded:
                    if let deleteFromDownloads = allActions[.deleteFromDownloads] {
                        actions.append(deleteFromDownloads)
                    }
                }

                // Is Favourites
                if model.isFavourites, let removeFromFavourites = allActions[.removeFromFavourites] {
                    actions.append(removeFromFavourites)
                } else if let markAsFavourite = allActions[.markAsFavourite] {
                    actions.append(markAsFavourite)
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

                delegate?.lectureCell(self, didSelected: option, with: model)
            })

            if option == .downloading {
                action.attributes = .disabled
            }

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
