//
//  LectureViewController+Actions.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 8/4/23.
//

import UIKit

extension LectureViewController {

    @objc internal func doneSelectionAction(_ sender: UIBarButtonItem) {
        delegate?.lectureController(self, didSelected: selectedModels)
    }

    private func startSelection() {
        isSelectionEnabled = true
        selectedModels.removeAll()
        reloadSelectedAll(isSelected: false)
        navigationItem.leftBarButtonItem = cancelSelectionButton
    }

    private func cancelSelection() {
        isSelectionEnabled = false
        selectedModels.removeAll()
        reloadSelectedAll(isSelected: false)
        var leftItems: [UIBarButtonItem] = []

        if let hamburgerBarButton = hamburgerBarButton {
            leftItems.append(hamburgerBarButton)
        }

        leftItems.append(activityBarButton)
        navigationItem.leftBarButtonItems = leftItems
    }

    @objc internal func cancelButtonAction(_ sender: UIBarButtonItem) {
        if delegate != nil {
            delegate?.lectureControllerDidCancel(self)
        } else {
            cancelSelection()
        }
    }

    internal func refreshMoreOption() {

        guard delegate == nil else {
            return
        }

        var menuItems: [SPAction] = []

        if isSelectionEnabled {
            menuItems.append(contentsOf: defaultSelectionActions)
        } else {
            menuItems.append(contentsOf: defaultNormalActions)
        }

        if !selectedModels.isEmpty {

            if !selectedModels.isEmpty, let addToQueue = allActions[.addToQueue] {
                addToQueue.action.title = LectureOption.addToQueue.rawValue + " (\(selectedModels.count))"
                menuItems.append(addToQueue)
            }

            if !selectedModels.isEmpty, let addToPlayNext = allActions[.addToPlayNext] {
                addToPlayNext.action.title = LectureOption.addToPlayNext.rawValue + " (\(selectedModels.count))"
                menuItems.append(addToPlayNext)
            }

            let eligibleDownloadModels: [Model] = selectedModels.filter { $0.downloadState == .notDownloaded || $0.downloadState == .error || $0.downloadState == .pause}
            if !eligibleDownloadModels.isEmpty, let download = allActions[.download] {
                download.action.title = LectureOption.download.rawValue + " (\(eligibleDownloadModels.count))"
                menuItems.append(download)
            }

            let eligiblePauseDownloadModels: [Model] = selectedModels.filter { $0.downloadState == .downloading }
            if !eligiblePauseDownloadModels.isEmpty, let pauseDownload = allActions[.pauseDownload] {
                pauseDownload.action.title = LectureOption.pauseDownload.rawValue + " (\(eligiblePauseDownloadModels.count))"
                menuItems.append(pauseDownload)
            }

            let eligibleDeleteFromDownloadsModels: [Model] = selectedModels.filter { $0.downloadState != .notDownloaded }
            if !eligibleDeleteFromDownloadsModels.isEmpty, let deleteFromDownloads = allActions[.deleteFromDownloads] {
                deleteFromDownloads.action.title = LectureOption.deleteFromDownloads.rawValue + " (\(eligibleDeleteFromDownloadsModels.count))"
                menuItems.append(deleteFromDownloads)
            }

            let eligibleMarkAsFavoriteModels: [Model] = selectedModels.filter { !$0.isFavorite }
            if !eligibleMarkAsFavoriteModels.isEmpty, let markAsFavorite = allActions[.markAsFavorite] {
                markAsFavorite.action.title = LectureOption.markAsFavorite.rawValue + " (\(eligibleMarkAsFavoriteModels.count))"
                menuItems.append(markAsFavorite)
            }

            let eligibleRemoveFromFavoriteModels: [Model] = selectedModels.filter { $0.isFavorite }
            if !eligibleRemoveFromFavoriteModels.isEmpty, let removeFromFavorite = allActions[.removeFromFavorite] {
                removeFromFavorite.action.title = LectureOption.removeFromFavorite.rawValue + " (\(eligibleRemoveFromFavoriteModels.count))"
                menuItems.append(removeFromFavorite)
            }

            if let addToPlaylist = allActions[.addToPlaylist] {
                addToPlaylist.action.title = LectureOption.addToPlaylist.rawValue + " (\(selectedModels.count))"
                menuItems.append(addToPlaylist)
            }

            if removeFromPlaylistEnabled {
                if let removeFromPlaylist = allActions[.removeFromPlaylist] {
                    removeFromPlaylist.action.title = LectureOption.removeFromPlaylist.rawValue + " (\(selectedModels.count))"
                    menuItems.append(removeFromPlaylist)
                }
            }

            let eligibleMarkAsHeardModels: [Model] = selectedModels.filter { $0.playProgress < 1.0 }
            if !eligibleMarkAsHeardModels.isEmpty, let markAsHeard = allActions[.markAsHeard] {
                markAsHeard.action.title = LectureOption.markAsHeard.rawValue + " (\(eligibleMarkAsHeardModels.count))"
                menuItems.append(markAsHeard)
            }

            let eligibleResetProgressModels: [Model] = selectedModels.filter { $0.playProgress > 0.0 }
            if !eligibleResetProgressModels.isEmpty, let resetProgress = allActions[.resetProgress] {
                resetProgress.action.title = LectureOption.resetProgress.rawValue + " (\(eligibleResetProgressModels.count))"
                menuItems.append(resetProgress)
            }
        }

        self.moreMenu.children = menuItems
    }

    internal func configureSelectionButton() {

        let select: SPAction = SPAction(title: "Select", image: nil, groupIdentifier: 10001, handler: { [self] (_) in
            startSelection()
        })

        let cancel: SPAction = SPAction(title: "Cancel", image: nil, groupIdentifier: 1001, handler: { [self] (_) in
            cancelSelection()
        })

        let selectAll: SPAction = SPAction(title: "Select All", image: UIImage(systemName: "checkmark.circle"), groupIdentifier: 1002, handler: { [self] (_) in
            selectedModels = self.models
            reloadSelectedAll(isSelected: true)
            Haptic.selection()
        })
        let deselectAll: SPAction = SPAction(title: "Deselect All", image: UIImage(systemName: "circle"), groupIdentifier: 1002, handler: { [self] (_) in
            selectedModels.removeAll()
            reloadSelectedAll(isSelected: false)
            Haptic.selection()
        })

        for option in LectureOption.allCases {
            let action: SPAction = SPAction(title: option.rawValue, image: option.image, identifier: .init(option.rawValue), groupIdentifier: option.groupIdentifier, handler: { [self] _ in

                guard !selectedModels.isEmpty else {
                    return
                }

                switch option {
                case .addToQueue:
                    let lectureIDs = selectedModels.map({ $0.id })
                    if let playerController = self as? PlayerViewController {
                        playerController.addToQueue(lectureIDs: lectureIDs)
                    } else if let tabController = self.tabBarController as? TabBarController {
                        tabController.addToQueue(lectureIDs: lectureIDs)
                    }
                case .removeFromQueue:
                    let lectureIDs = selectedModels.map({ $0.id })

                    if let playerController = self as? PlayerViewController {
                        playerController.removeFromQueue(lectureIDs: lectureIDs)
                    } else if let tabController = self.tabBarController as? TabBarController {
                        tabController.removeFromQueue(lectureIDs: lectureIDs)
                    }
                case .addToPlayNext:
                    let lectureIDs = selectedModels.map({ $0.id })
                    if let playerController = self as? PlayerViewController {
                        playerController.addToPlayNext(lectureIDs: lectureIDs)
                    } else if let tabController = self.tabBarController as? TabBarController {
                        tabController.addToPlayNext(lectureIDs: lectureIDs)
                    }
                case .download, .resumeDownload:
                    Haptic.softImpact()
                    let eligibleDownloadModels: [Model] = selectedModels.filter { $0.downloadState == .notDownloaded || $0.downloadState == .error || $0.downloadState == .pause }
                    Persistant.shared.save(lectures: eligibleDownloadModels, completion: { _ in })

                    DefaultLectureViewModel.defaultModel.updateLectureInfo(lectures: eligibleDownloadModels, isCompleted: nil, isDownloaded: true, isFavorite: nil, lastPlayedPoint: nil, postUpdate: false, completion: { _ in
                    })
                case .pauseDownload:
                    Haptic.warning()
                    let eligiblePauseDownloadModels: [Model] = selectedModels.filter { $0.downloadState == .downloading }
                    Persistant.shared.pauseDownloads(lectures: eligiblePauseDownloadModels)
                case .deleteFromDownloads:
                    Haptic.warning()
                    let eligibleDeleteFromDownloadsModels: [Model] = selectedModels.filter { $0.downloadState != .notDownloaded }
                    askToDeleteFromDownloads(lectures: eligibleDeleteFromDownloadsModels, sourceView: moreButton)

                case .markAsFavorite:
                    Haptic.softImpact()
                    let eligibleMarkAsFavoriteModels: [Model] = selectedModels.filter { !$0.isFavorite }
                    markAsFavorite(lectures: eligibleMarkAsFavoriteModels, sourceView: moreButton)

                case .removeFromFavorite:
                    Haptic.warning()
                    let eligibleRemoveFromFavoriteModels: [Model] = selectedModels.filter { $0.isFavorite }
                    askToRemoveFromFavorite(lectures: eligibleRemoveFromFavoriteModels, sourceView: moreButton)

                case .addToPlaylist:
                    Haptic.softImpact()
                    let navigationController = UIStoryboard.playlists.instantiate(UINavigationController.self, identifier: "PlaylistNavigationController")
                    guard let playlistController = navigationController.viewControllers.first as? PlaylistViewController else {
                        return
                    }
                    playlistController.lecturesToAdd = selectedModels
                    self.present(navigationController, animated: true, completion: nil)
                case .removeFromPlaylist:
                    Haptic.warning()
                    askToRemoveFromPlaylist(lectures: selectedModels, sourceView: moreButton)
                case .markAsHeard:
                    Haptic.softImpact()
                    let eligibleMarkAsHeardModels: [Model] = selectedModels.filter { $0.playProgress < 1.0 }
                    markAsHeard(lectures: eligibleMarkAsHeardModels, sourceView: moreButton)
                case .resetProgress:
                    Haptic.softImpact()
                    let eligibleResetProgressModels: [Model] = selectedModels.filter { $0.playProgress >= 1.0 }
                    resetProgress(lectures: eligibleResetProgressModels, sourceView: moreButton)
                case .share, .info:
                    break
               }

                cancelSelection()
            })

            switch option {
            case .addToQueue, .addToPlayNext, .download, .resumeDownload, .pauseDownload, .markAsFavorite, .addToPlaylist, .markAsHeard, .resetProgress, .share, .info:
                break
            case .deleteFromDownloads, .removeFromPlaylist, .removeFromFavorite, .removeFromQueue:
                action.action.attributes = .destructive
            }

            allActions[option] = action
        }

        if delegate != nil {
            defaultNormalActions = []
            defaultSelectionActions = [selectAll, deselectAll]
            moreMenu = SPMenu(title: "", image: nil, identifier: UIMenu.Identifier.init("More Menu"), options: [], children: defaultSelectionActions, barButton: moreButton, parent: self)
        } else {
            defaultNormalActions = [select]
            defaultSelectionActions = [cancel, selectAll, deselectAll]
            moreMenu = SPMenu(title: "", image: nil, identifier: UIMenu.Identifier.init("More Menu"), options: [], children: defaultNormalActions, barButton: moreButton, parent: self)
        }
    }
}
