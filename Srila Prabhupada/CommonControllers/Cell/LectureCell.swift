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
import IQKeyboardManagerSwift

protocol LectureCellDelegate: AnyObject {
    func lectureCell(_ cell: LectureCell, didSelected option: LectureOption, with lecture: Lecture)
}

class LectureCell: UITableViewCell, IQModelableCell {

    @IBOutlet private var downloadedIconImageView: UIImageView?
    @IBOutlet private var favouritesIconImageView: UIImageView?
    @IBOutlet private var completedIconImageView: UIImageView?

    @IBOutlet private var thumbnailImageView: UIImageView?
    @IBOutlet private var titleLabel: UILabel?
    @IBOutlet private var verseLabel: UILabel?
    @IBOutlet private var durationLabel: UILabel?
    @IBOutlet private var locationLabel: UILabel?
    @IBOutlet private var dateLabel: UILabel?
    @IBOutlet private var menuButton: UIButton?
    @IBOutlet private var downloadProgressView: MBCircularProgressBarView?
    @IBOutlet private var listenProgressView: MBCircularProgressBarView?

    weak var delegate: LectureCellDelegate?

    private var optionMenu: UIMenu!
    var allActions: [LectureOption: UIAction] = [:]

    override func awakeFromNib() {
        super.awakeFromNib()
        configureMenuButton()
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

            titleLabel?.text = model.titleDisplay
            verseLabel?.text = model.legacyData.verse
            durationLabel?.text = model.lengthTime.displayString
            locationLabel?.text = model.location.displayString
            dateLabel?.text = model.dateOfRecording.display_yyyy_mm_dd

            let progress: CGFloat
            if model.length != 0 {
                progress = CGFloat(model.lastPlayedPoint) / CGFloat(model.length)
            } else {
                progress = 0
            }

            listenProgressView?.value = progress * 100

            listenProgressView?.isHidden = progress >= 1.0
            completedIconImageView?.isHidden = progress < 1.0

            if let url = model.thumbnailURL {
                thumbnailImageView?.af.setImage(withURL: url, placeholderImage: UIImage(named: "logo_40"))
            } else {
                thumbnailImageView?.image = UIImage(named: "logo_40")
            }

            switch model.downloadingState {
            case .notDownloaded:
                downloadedIconImageView?.isHidden = true
                downloadProgressView?.isHidden = true
            case .downloading:
                downloadedIconImageView?.isHidden = false
                downloadedIconImageView?.tintColor = UIColor.systemBlue
                downloadedIconImageView?.image = UIImage(compatibleSystemName: "arrow.down.circle.fill")
                downloadProgressView?.isHidden = false

                DownloadManager.shared.registerProgress(observer: self, lectureID: model.id) { [weak self] progress in
                    self?.downloadProgressView?.value = progress * 100
                }
            case .downloaded:
                downloadedIconImageView?.isHidden = false
                downloadedIconImageView?.tintColor = UIColor.systemGreen
                downloadedIconImageView?.image = UIImage(compatibleSystemName: "arrow.down.circle.fill")
                downloadProgressView?.isHidden = false
                downloadProgressView?.value = 0
            case .error:
                downloadedIconImageView?.isHidden = false
                downloadedIconImageView?.tintColor = UIColor.systemRed
                downloadedIconImageView?.image = UIImage(compatibleSystemName: "exclamationmark.circle.fill")
                downloadProgressView?.isHidden = false
                downloadProgressView?.value = 0
            }

            favouritesIconImageView?.isHidden = !model.isFavourites

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
                if progress >= 1.0, let resetProgress = allActions[.resetProgress] {
                    actions.append(resetProgress)
                } else if let markAsHeard = allActions[.markAsHeard] {
                    actions.append(markAsHeard)
                }

                // share
                if let share = allActions[.share] {
                    actions.append(share)
                }

                self.optionMenu = self.optionMenu.replacingChildren(actions)
                self.menuButton?.isHidden = actions.isEmpty

                if #available(iOS 14.0, *) {
                    self.menuButton?.menu = self.optionMenu
                }
            }
        }
    }
}

extension LectureCell {

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

        self.optionMenu = UIMenu(title: "", image: nil, identifier: UIMenu.Identifier.init(rawValue: "Option"), options: UIMenu.Options.displayInline, children: childrens)

        if #available(iOS 14.0, *) {
            menuButton?.showsMenuAsPrimaryAction = true
            menuButton?.menu = optionMenu
        } else {
            menuButton?.addTarget(self, action: #selector(optionMenuActioniOS13(_:)), for: .touchUpInside)
        }
    }

    // Backward compatibility for iOS 13
    @objc private func optionMenuActioniOS13(_ sender: UIButton) {

        var buttons: [UIViewController.ButtonConfig] = []
        let actions: [UIAction] = self.optionMenu.children as? [UIAction] ?? []
        for action in actions {
            buttons.append((title: action.title, handler: { [self] in

                guard let model = model, let option: LectureOption = allActions.first(where: { $0.value == action})?.key else {
                    return
                }

                delegate?.lectureCell(self, didSelected: option, with: model)
            }))
        }

        self.parentViewController?.showAlert(title: "", message: "", preferredStyle: .actionSheet, buttons: buttons)
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
