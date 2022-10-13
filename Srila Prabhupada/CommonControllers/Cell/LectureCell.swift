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

    @IBOutlet private var firstDotLabel: UILabel?
    @IBOutlet private var secondDotLabel: UILabel?

    @IBOutlet private var thumbnailImageView: UIImageView?
    @IBOutlet private var titleLabel: UILabel?
    @IBOutlet private var verseLabel: UILabel?
    @IBOutlet private var durationLabel: UILabel?
    @IBOutlet private var locationLabel: UILabel?
    @IBOutlet private var dateLabel: UILabel?
    @IBOutlet private var menuButton: UIButton?
    @IBOutlet private var selectedImageView: UIImageView?
    @IBOutlet private var downloadProgressView: MBCircularProgressBarView?
    @IBOutlet private var listenProgressView: MBCircularProgressBarView?
    @IBOutlet private var audioVisualizerView: ESTMusicIndicatorView!

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

        PlayerViewController.unregister(observer: self, lectureID: model.lecture.id)
        DownloadManager.shared.unregisterProgress(observer: self, lectureID: model.lecture.id)
    }

    struct Model: Hashable {
        let lecture: Lecture
        let isSelectionEnabled: Bool
        let isSelected: Bool
    }

    var model: Model? {
        didSet {
            guard let model = model else {
                return
            }

            let lecture = model.lecture

            titleLabel?.text = lecture.titleDisplay
            if !lecture.legacyData.verse.isEmpty {
                verseLabel?.text = lecture.legacyData.verse
            } else {
                verseLabel?.text = lecture.category.joined(separator: ", ")
            }

            if !lecture.location.displayString.isEmpty {
                locationLabel?.text = lecture.location.displayString
            } else {
                locationLabel?.text = lecture.place.joined(separator: ", ")
            }

            durationLabel?.text = lecture.lengthTime.displayString
            dateLabel?.text = lecture.dateOfRecording.display_dd_MMM_yyyy

            firstDotLabel?.isHidden = verseLabel?.text?.isEmpty ?? true
            secondDotLabel?.isHidden = locationLabel?.text?.isEmpty ?? true

            let progress: CGFloat
            if model.lecture.length != 0 {
                progress = CGFloat(lecture.lastPlayedPoint) / CGFloat(lecture.length)
            } else {
                progress = 0
            }

            listenProgressView?.value = progress * 100

            listenProgressView?.isHidden = progress >= 1.0
            completedIconImageView?.isHidden = progress < 1.0

            if let url = lecture.thumbnailURL {
                thumbnailImageView?.af.setImage(withURL: url, placeholderImage: UIImage(named: "logo_40"))
            } else {
                thumbnailImageView?.image = UIImage(named: "logo_40")
            }

            PlayerViewController.register(observer: self, lectureID: lecture.id) { state in
                self.audioVisualizerView.state = state
            }

            switch lecture.downloadingState {
            case .notDownloaded:
                downloadedIconImageView?.isHidden = true
                downloadProgressView?.isHidden = true
            case .downloading:
                downloadedIconImageView?.isHidden = false
                downloadedIconImageView?.tintColor = UIColor.systemBlue
                downloadedIconImageView?.image = UIImage(compatibleSystemName: "arrow.down.circle.fill")
                downloadProgressView?.isHidden = false

                DownloadManager.shared.registerProgress(observer: self, lectureID: lecture.id) { [weak self] progress in
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

            favouritesIconImageView?.isHidden = !lecture.isFavourites

            do {
                var actions: [UIAction] = []

                switch lecture.downloadingState {
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
                if lecture.isFavourites, let removeFromFavourites = allActions[.removeFromFavourites] {
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

                let isSelected = model.isSelectionEnabled && model.isSelected

                self.optionMenu = self.optionMenu.replacingChildren(actions)
                self.menuButton?.isHidden = actions.isEmpty || model.isSelectionEnabled
                self.selectedImageView?.isHidden = !isSelected
                self.backgroundColor = isSelected ? UIColor.systemGray3 : nil

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

                delegate?.lectureCell(self, didSelected: option, with: model.lecture)
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

                delegate?.lectureCell(self, didSelected: option, with: model.lecture)
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
