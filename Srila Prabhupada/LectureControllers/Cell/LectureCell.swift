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
    @IBOutlet private var favoriteIconImageView: UIImageView?
    @IBOutlet private var completedIconImageView: UIImageView?
    @IBOutlet private var playlistIconView: UIView?

    @IBOutlet private var firstDotLabel: UILabel?
    @IBOutlet private var secondDotLabel: UILabel?
    @IBOutlet private var thirdDotLabel: UILabel?

    @IBOutlet private var thumbnailImageView: UIImageView?
    @IBOutlet private var titleLabel: UILabel?
    @IBOutlet private var verseLabel: UILabel?
    @IBOutlet private var durationLabel: UILabel?
    @IBOutlet private var locationLabel: UILabel?
    @IBOutlet private var dateLabel: UILabel?
    @IBOutlet private var downloadInfoLabel: UILabel?
    @IBOutlet private var menuButton: UIButton?
    @IBOutlet private var selectedImageView: UIImageView?
    @IBOutlet private var downloadProgressView: MBCircularProgressBarView?
    @IBOutlet private var listenProgressView: IQCircularProgressView?
    @IBOutlet private var labelListenProgress: UILabel?
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
        func hash(into hasher: inout Hasher) {
            hasher.combine(lecture.id)
        }

        static func == (lhs: Self, rhs: Self) -> Bool {
            return lhs.lecture == rhs.lecture &&
            lhs.isSelectionEnabled == rhs.isSelectionEnabled &&
            lhs.isSelected == rhs.isSelected &&
            lhs.enableRemoveFromPlaylist == rhs.enableRemoveFromPlaylist &&
            lhs.showPlaylistIcon == rhs.showPlaylistIcon &&
            lhs.isHighlited == rhs.isHighlited
        }

        var lecture: Lecture
        var isSelectionEnabled: Bool
        var isSelected: Bool
        let enableRemoveFromPlaylist: Bool
        var showPlaylistIcon: Bool
        var isHighlited: Bool
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
            thirdDotLabel?.isHidden = true
            downloadInfoLabel?.text = nil

            let playProgress: CGFloat = model.lecture.playProgress

            labelListenProgress?.text = "\(Int(playProgress * 100))%"
            listenProgressView?.progress = playProgress
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

                    labelListenProgress?.text = "\(Int(playProgress * 100))%"
                    listenProgressView?.progress = playProgress
                    listenProgressView?.isHidden = playProgress >= 1.0
                    completedIconImageView?.isHidden = playProgress < 1.0

                    audioVisualizerView.state = .playing
                case .paused:
                    audioVisualizerView.state = .paused
                }
            })

            thirdDotLabel?.isHidden = true
            downloadInfoLabel?.text = nil

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
                if let downloadError = lecture.downloadError {
                    thirdDotLabel?.isHidden = false
                    downloadInfoLabel?.text = downloadError
                }
            case .pause:
                downloadedIconImageView?.isHidden = false
                downloadedIconImageView?.tintColor = UIColor.F96D00
                downloadedIconImageView?.image = UIImage(compatibleSystemName: "pause.circle.fill")
                downloadProgressView?.isHidden = false
                downloadProgressView?.value = 0
            }

            DownloadManager.shared.registerProgress(observer: self, lectureID: lecture.id, progressHandler: { [self] progress in
                let fractionCompleted: CGFloat = CGFloat(progress.fractionCompleted)

                if fractionCompleted >= 1.0 {
                    downloadedIconImageView?.isHidden = false
                    downloadedIconImageView?.tintColor = UIColor.systemGreen
                    downloadedIconImageView?.image = UIImage(compatibleSystemName: "arrow.down.circle.fill")
                    downloadProgressView?.isHidden = false
                    downloadProgressView?.value = 0
                    thirdDotLabel?.isHidden = true
                    downloadInfoLabel?.text = nil
                } else if fractionCompleted > 0 {
                    downloadedIconImageView?.isHidden = false
                    downloadedIconImageView?.tintColor = UIColor.systemBlue
                    downloadedIconImageView?.image = UIImage(compatibleSystemName: "arrow.down.circle.fill")
                    downloadProgressView?.isHidden = false
                    downloadProgressView?.value = fractionCompleted * 100
                    thirdDotLabel?.isHidden = false

                    let completedUnitCountString: String = BackgroundSession.shared.byteFormatter.string(fromByteCount: progress.completedUnitCount)
                    let totalUnitCountString: String = BackgroundSession.shared.byteFormatter.string(fromByteCount: progress.totalUnitCount)
                    downloadInfoLabel?.text = "\(completedUnitCountString) of \(totalUnitCountString)"
                } else if fractionCompleted == 0 {
                    downloadedIconImageView?.isHidden = true
                    downloadProgressView?.isHidden = true
                    thirdDotLabel?.isHidden = true
                    downloadInfoLabel?.text = nil
                }
            })

            favoriteIconImageView?.isHidden = !lecture.isFavorite
            playlistIconView?.isHidden = !model.showPlaylistIcon

            do {
                var actions: [SPAction] = []

                switch lecture.downloadState {
                case .notDownloaded:
                    if let download = allActions[.download] {
                        actions.append(download)
                    }
                case .downloading:
                    if let pauseDownload = allActions[.pauseDownload] {
                        actions.append(pauseDownload)
                    }
                    if let deleteFromDownloads = allActions[.deleteFromDownloads] {
                        actions.append(deleteFromDownloads)
                    }
                case .downloaded:
                    if let deleteFromDownloads = allActions[.deleteFromDownloads] {
                        actions.append(deleteFromDownloads)
                    }
                case .pause:
                    if let download = allActions[.resumeDownload] {
                        actions.append(download)
                    }
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

                // Is Favorites
                if lecture.isFavorite, let removeFromFavorite = allActions[.removeFromFavorite] {
                    actions.append(removeFromFavorite)
                } else if let markAsFavorite = allActions[.markAsFavorite] {
                    actions.append(markAsFavorite)
                }

                // addToPlaylist
                if let addToPlaylist = allActions[.addToPlaylist] {
                    actions.append(addToPlaylist)
                }

                if model.enableRemoveFromPlaylist, let removeFromPlaylist = allActions[.removeFromPlaylist] {
                    actions.append(removeFromPlaylist)
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

                // share
                if let info = allActions[.info] {
                    actions.append(info)
                }

                self.optionMenu.children = actions
                self.menuButton?.isHidden = actions.isEmpty || model.isSelectionEnabled
                self.selectedImageView?.isHidden = !model.isSelectionEnabled
                if model.isSelectionEnabled {
                    self.selectedImageView?.image = model.isSelected ? UIImage(compatibleSystemName: "checkmark.circle.fill") : UIImage(compatibleSystemName: "circle")
                    self.backgroundColor = model.isSelected ? UIColor.zero_0099CC.withAlphaComponent(0.2) : nil
                } else if model.isHighlited {
                    self.backgroundColor = .systemOrange.withAlphaComponent(0.2)
                } else {
                    self.backgroundColor = nil
                }
            }
        }
    }
}

extension LectureCell {
    func contextMenuConfiguration() -> UIContextMenuConfiguration? {

        guard let model = model else {
            return nil
        }

        return .init(identifier: nil, previewProvider: {

            let controller = UIStoryboard.common.instantiate(LectureInfoViewController.self)
            controller.lecture = model.lecture

            if UIDevice.current.userInterfaceIdiom == .pad {
                controller.modalPresentationStyle = .formSheet
            } else {
                controller.modalPresentationStyle = .automatic
            }
            controller.popoverPresentationController?.sourceView = self

            return controller
        }, actionProvider: { _ in
            return self.optionMenu.menu
        })
    }

    func performPreviewAction(configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        if let previewViewController = animator.previewViewController {
            animator.addAnimations {
                self.parentViewController?.present(previewViewController, animated: true)
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

            switch option {
            case .download, .resumeDownload, .pauseDownload, .markAsFavorite, .addToPlaylist, .markAsHeard, .resetProgress, .share, .info:
                break
            case .deleteFromDownloads, .removeFromPlaylist, .removeFromFavorite:
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
        return CGSize(width: listView.frame.width, height: 64)
    }

    static func size(for model: AnyHashable?, listView: IQListView) -> CGSize {
        return CGSize(width: listView.frame.width, height: 64)
    }
}
