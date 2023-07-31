//
//  LectureCell.swift
//  Srila Prabhupada
//
//  Created by IE06 on 08/09/22.
//

import UIKit
import IQListKit
import AlamofireImage
import IQKeyboardManagerSwift

protocol LectureCellDelegate: AnyObject {
    func lectureCell(_ cell: LectureCell, didSelected option: LectureOption, with lecture: Lecture)
}

class LectureCell: UITableViewCell, IQModelableCell {

    @IBOutlet private var videoIconImageView: UIImageView?
    @IBOutlet private var downloadedContentView: UIView?
    @IBOutlet private var downloadedIconImageView: UIImageView?
    @IBOutlet private var favoriteIconImageView: UIImageView?
    @IBOutlet private var completedIconImageView: UIImageView?
    @IBOutlet private var playlistIconView: UIView?

    @IBOutlet private var firstDotLabel: UILabel?
    @IBOutlet private var secondDotLabel: UILabel?

    @IBOutlet private var thumbnailImageView: UIImageView?
    @IBOutlet private var titleLabel: UILabel?
    @IBOutlet private var verseLabel: UILabel?
    @IBOutlet private var durationLabel: UILabel?
    @IBOutlet private var locationLabel: UILabel?
    @IBOutlet private var dateLabel: UILabel?
    @IBOutlet private var downloadInfoLabel: UILabel?
    @IBOutlet private var menuSelectionContentView: UIView?
    @IBOutlet private var menuButton: UIButton?
    @IBOutlet private var selectedImageView: UIImageView?
    @IBOutlet private var downloadProgressView: IQCircularProgressView?
    @IBOutlet private var listenProgressView: IQProgressView?
    @IBOutlet private var listenProgressStackView: UIStackView?
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
        let isOnPlayingList: Bool
        var showPlaylistIcon: Bool
        var isHighlited: Bool
    }

    var model: Model? {
        didSet {
            guard let model = model else {
                return
            }

            if model.isOnPlayingList {
                backgroundColor = UIColor.clear
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

            if lecture.resources.videos.first?.videoURL != nil {
                videoIconImageView?.image = UIImage(systemName: "video.fill")
                videoIconImageView?.tintColor = UIColor.F96D00
                videoIconImageView?.isHidden = false
            } else if lecture.resources.audios.first?.audioURL != nil {
                videoIconImageView?.image = UIImage(systemName: "music.note.list")
                videoIconImageView?.tintColor = UIColor(named: "ProgressColor")
                videoIconImageView?.isHidden = false
            } else {
                videoIconImageView?.isHidden = true
            }

            durationLabel?.text = lecture.lengthTime.displayString
            dateLabel?.text = lecture.dateOfRecording.display_dd_MMM_yyyy

            firstDotLabel?.isHidden = verseLabel?.text?.isEmpty ?? true
            downloadInfoLabel?.text = nil

            let playProgress: CGFloat = model.lecture.playProgress

            listenProgressStackView?.isHidden = playProgress >= 1.0 || playProgress <= 0
            completedIconImageView?.isHidden = playProgress < 1.0
            labelListenProgress?.text = "\(Int(playProgress * 100))%"
            listenProgressView?.progress = playProgress

            if let url = lecture.thumbnailURL {
                thumbnailImageView?.af.setImage(withURL: url, placeholderImage: UIImage(named: "logo_40"))
            } else {
                thumbnailImageView?.image = UIImage(named: "logo_40")
            }

            PlayerViewController.register(observer: self, lectureID: lecture.id, playStateHandler: { [self] state in
                switch state {
                case .stopped:
                    audioVisualizerView.state = .stopped
                    listenProgressView?.tintColor = UIColor.zero_0099CC
                case .playing(let playProgress):

                    listenProgressStackView?.isHidden = playProgress >= 1.0
                    labelListenProgress?.text = "\(Int(playProgress * 100))%"
                    listenProgressView?.progress = playProgress
                    completedIconImageView?.isHidden = playProgress < 1.0

                    audioVisualizerView.state = .playing
                    listenProgressView?.tintColor = UIColor(named: "ProgressColor")
                case .paused:
                    audioVisualizerView.state = .paused
                    listenProgressView?.tintColor = UIColor.zero_0099CC
                }
            })

            downloadInfoLabel?.text = nil

            switch lecture.downloadState {
            case .notDownloaded:
                downloadedContentView?.isHidden = true
            case .downloading:
                downloadedContentView?.isHidden = false
                downloadedIconImageView?.isHidden = false
                downloadProgressView?.isHidden = false

                downloadedIconImageView?.tintColor = UIColor.systemBlue
                downloadedIconImageView?.image = UIImage(systemName: "arrow.down.circle.fill")
            case .downloaded:
                downloadedContentView?.isHidden = false
                downloadedIconImageView?.isHidden = false
                downloadProgressView?.isHidden = true

                downloadedIconImageView?.tintColor = UIColor.systemGreen
                downloadedIconImageView?.image = UIImage(systemName: "arrow.down.circle.fill")
            case .error:
                downloadedContentView?.isHidden = false
                downloadedIconImageView?.isHidden = false
                downloadProgressView?.isHidden = true

                downloadedIconImageView?.tintColor = UIColor.systemRed
                downloadedIconImageView?.image = UIImage(systemName: "exclamationmark.circle.fill")
                if let downloadError = lecture.downloadError {
                    downloadInfoLabel?.text = downloadError
                }
            case .pause:
                downloadedContentView?.isHidden = false
                downloadedIconImageView?.isHidden = false
                downloadProgressView?.isHidden = false
                downloadProgressView?.progress = 0.0

                downloadedIconImageView?.tintColor = UIColor.F96D00
                downloadedIconImageView?.image = UIImage(systemName: "pause.circle.fill")
            }

            DownloadManager.shared.registerProgress(observer: self, lectureID: lecture.id, progressHandler: { [self] progress in
                let fractionCompleted: CGFloat = CGFloat(progress.fractionCompleted)

                if fractionCompleted >= 1.0 {
                    downloadedContentView?.isHidden = false
                    downloadedIconImageView?.isHidden = false
                    downloadProgressView?.isHidden = true

                    downloadedIconImageView?.tintColor = UIColor.systemGreen
                    downloadedIconImageView?.image = UIImage(systemName: "arrow.down.circle.fill")
                    downloadInfoLabel?.text = nil
                } else if fractionCompleted > 0 {
                    downloadedContentView?.isHidden = false
                    downloadedIconImageView?.isHidden = false
                    downloadProgressView?.isHidden = false

                    downloadedIconImageView?.tintColor = UIColor.systemBlue
                    downloadedIconImageView?.image = UIImage(systemName: "arrow.down.circle.fill")
                    downloadProgressView?.progress = fractionCompleted

                    let completedUnitCountString: String = BackgroundSession.shared.byteFormatter.string(fromByteCount: progress.completedUnitCount)
                    let totalUnitCountString: String = BackgroundSession.shared.byteFormatter.string(fromByteCount: progress.totalUnitCount)
                    downloadInfoLabel?.text = "\(completedUnitCountString) of \(totalUnitCountString)"
                } else if fractionCompleted == 0 {
                    downloadedContentView?.isHidden = true
                    downloadedIconImageView?.isHidden = true
                    downloadProgressView?.isHidden = true

                    downloadInfoLabel?.text = nil
                }
            })

            secondDotLabel?.isHidden = (locationLabel?.text?.isEmpty ?? true) || (downloadInfoLabel?.text?.isEmpty ?? true)

            favoriteIconImageView?.isHidden = !lecture.isFavorite
            playlistIconView?.isHidden = !model.showPlaylistIcon

            do {
                var actions: [SPAction] = []

                // addToQueue, removeFromQueue
                if model.isOnPlayingList, let removeFromQueue = allActions[.removeFromQueue] {
                    actions.append(removeFromQueue)
                } else {
                    if let addToPlayNext = allActions[.addToPlayNext] {
                        actions.append(addToPlayNext)
                    }

                    if let addToQueue = allActions[.addToQueue] {
                        actions.append(addToQueue)
                    }
                }

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
                    self.selectedImageView?.image = model.isSelected ? UIImage(systemName: "checkmark.circle.fill") : UIImage(systemName: "circle")
                    self.backgroundColor = model.isSelected ? UIColor.zero_0099CC.withAlphaComponent(0.2) : nil
                } else if model.isHighlited {
                    self.backgroundColor = .systemOrange.withAlphaComponent(0.2)
                } else {
                    self.backgroundColor = nil
                }
            }
        }
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)

        menuSelectionContentView?.isHidden = editing
    }
}

extension LectureCell {
    func contextMenuConfiguration() -> UIContextMenuConfiguration? {

        guard let model = model, !model.isSelectionEnabled else {
            return nil
        }

        return .init(identifier: nil, previewProvider: {

            let controller = UIStoryboard.common.instantiate(LectureInfoViewController.self)
            controller.lecture = model.lecture

            switch Environment.current.device {
            case .mac, .pad:
                controller.modalPresentationStyle = .formSheet
            default:
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
            case .addToQueue, .addToPlayNext, .download, .resumeDownload, .pauseDownload, .markAsFavorite, .addToPlaylist, .markAsHeard, .resetProgress, .share, .info:
                break
            case .deleteFromDownloads, .removeFromPlaylist, .removeFromFavorite, .removeFromQueue:
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
        switch Environment.current.device {
        case .mac, .pad:
            return CGSize(width: listView.frame.width, height: 97)
        default:
            return CGSize(width: listView.frame.width, height: 71)
        }
    }

    static func size(for model: AnyHashable?, listView: IQListView) -> CGSize {
        return CGSize(width: listView.frame.width, height: UITableView.automaticDimension)
    }
}
