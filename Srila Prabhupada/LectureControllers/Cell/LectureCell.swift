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

    private var optionMenu: SPMenu!
    var allActions: [LectureOption: SPAction] = [:]

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

            let playProgress: CGFloat = model.lecture.playProgress

            listenProgressView?.value = playProgress * 100
            listenProgressView?.isHidden = playProgress >= 1.0
            completedIconImageView?.isHidden = playProgress < 1.0

            if let url = lecture.thumbnailURL {
                thumbnailImageView?.af.setImage(withURL: url, placeholderImage: UIImage(named: "logo_40"))
            } else {
                thumbnailImageView?.image = UIImage(named: "logo_40")
            }

            PlayerViewController.register(observer: self, lectureID: lecture.id, playStateHandler: { [self] state in
                switch state {
                case .stopped:
                    audioVisualizerView.state = .stopped
                case .playing(let playProgress):

                    listenProgressView?.value = playProgress * 100
                    listenProgressView?.isHidden = playProgress >= 1.0
                    completedIconImageView?.isHidden = playProgress < 1.0

                    audioVisualizerView.state = .playing
                case .paused:
                    audioVisualizerView.state = .paused
                }
            })

            switch lecture.downloadState {
            case .notDownloaded:
                downloadedIconImageView?.isHidden = true
                downloadProgressView?.isHidden = true
            case .downloading:
                downloadedIconImageView?.isHidden = false
                downloadedIconImageView?.tintColor = UIColor.systemBlue
                downloadedIconImageView?.image = UIImage(compatibleSystemName: "arrow.down.circle.fill")
                downloadProgressView?.isHidden = false
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

            DownloadManager.shared.registerProgress(observer: self, lectureID: lecture.id, progressHandler: { [self] downloadProgress in
                if downloadProgress >= 1.0 {
                    downloadedIconImageView?.isHidden = false
                    downloadedIconImageView?.tintColor = UIColor.systemGreen
                    downloadedIconImageView?.image = UIImage(compatibleSystemName: "arrow.down.circle.fill")
                    downloadProgressView?.isHidden = false
                    downloadProgressView?.value = 0
                } else if downloadProgress > 0 {
                    downloadedIconImageView?.isHidden = false
                    downloadedIconImageView?.tintColor = UIColor.systemBlue
                    downloadedIconImageView?.image = UIImage(compatibleSystemName: "arrow.down.circle.fill")
                    downloadProgressView?.isHidden = false
                    downloadProgressView?.value = downloadProgress * 100
                } else if downloadProgress == 0 {
                    downloadedIconImageView?.isHidden = true
                    downloadProgressView?.isHidden = true
                }
            })

            favouritesIconImageView?.isHidden = !lecture.isFavourite

            do {
                var actions: [SPAction] = []

                switch lecture.downloadState {
                case .notDownloaded:
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
                case .error:
                    if let download = allActions[.download] {
                        actions.append(download)
                    }
                    if let deleteFromDownloads = allActions[.deleteFromDownloads] {
                        actions.append(deleteFromDownloads)
                    }
                }

                // Is Favourites
                if lecture.isFavourite, let removeFromFavourites = allActions[.removeFromFavourites] {
                    actions.append(removeFromFavourites)
                } else if let markAsFavourite = allActions[.markAsFavourite] {
                    actions.append(markAsFavourite)
                }

                // addToPlaylist
                if let addToPlaylist = allActions[.addToPlaylist] {
                    actions.append(addToPlaylist)
                }

                // Is Heard
                if playProgress >= 1.0, let resetProgress = allActions[.resetProgress] {
                    actions.append(resetProgress)
                } else if let markAsHeard = allActions[.markAsHeard] {
                    actions.append(markAsHeard)
                }

                // share
                if let share = allActions[.share] {
                    actions.append(share)
                }

                let isSelected = model.isSelectionEnabled && model.isSelected

                self.optionMenu.children = actions
                self.menuButton?.isHidden = actions.isEmpty || model.isSelectionEnabled
                self.selectedImageView?.isHidden = !isSelected
                self.backgroundColor = isSelected ? UIColor.systemGray3 : nil
            }
        }
    }
}

extension LectureCell {

    private func configureMenuButton() {

        for option in LectureOption.allCases {
            let action: SPAction = SPAction(title: option.rawValue, image: option.image, identifier: .init(option.rawValue), handler: { [self] _ in

                guard let model = model else {
                    return
                }

                delegate?.lectureCell(self, didSelected: option, with: model.lecture)
            })

            if option == .downloading {
                action.action.attributes = .disabled
            } else if option == .deleteFromDownloads {
                action.action.attributes = .destructive
            }

            allActions[option] = action
        }

        let childrens: [SPAction] = allActions.compactMap({ (key: LectureOption, _: SPAction) in
            return allActions[key]
        })

        if let menuButton = menuButton {
            self.optionMenu = SPMenu(title: "", image: nil, identifier: .init(rawValue: "Option"), options: .displayInline, children: childrens, button: menuButton)
        }
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
