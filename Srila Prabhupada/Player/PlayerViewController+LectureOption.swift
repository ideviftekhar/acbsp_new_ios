//
//  PlayerViewController+More.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 10/03/23.
//

import Foundation
import UIKit

extension PlayerViewController {

    func updateMenuOption() {
        var actions: [SPAction] = []

        guard let currentLecture = currentLecture else {
            self.optionMenu.children = actions
            self.menuButton?.isHidden = actions.isEmpty
            return
        }

        switch currentLecture.downloadState {
        case .notDownloaded:
            if let download = allCurrentLectureActions[.download] {
                actions.append(download)
            }
        case .downloading:
            if let pauseDownload = allCurrentLectureActions[.pauseDownload] {
                actions.append(pauseDownload)
            }
            if let deleteFromDownloads = allCurrentLectureActions[.deleteFromDownloads] {
                actions.append(deleteFromDownloads)
            }
        case .downloaded:
            if let deleteFromDownloads = allCurrentLectureActions[.deleteFromDownloads] {
                actions.append(deleteFromDownloads)
            }
        case .pause:
            if let download = allCurrentLectureActions[.resumeDownload] {
                actions.append(download)
            }
            if let deleteFromDownloads = allCurrentLectureActions[.deleteFromDownloads] {
                actions.append(deleteFromDownloads)
            }
        case .error:
            if let download = allCurrentLectureActions[.download] {
                actions.append(download)
            }
            if let deleteFromDownloads = allCurrentLectureActions[.deleteFromDownloads] {
                actions.append(deleteFromDownloads)
            }
        }

        // isFavorite
        if currentLecture.isFavorite, let removeFromFavorite = allCurrentLectureActions[.removeFromFavorite] {
            actions.append(removeFromFavorite)
        } else if let markAsFavorite = allCurrentLectureActions[.markAsFavorite] {
            actions.append(markAsFavorite)
        }

        // addToPlaylist
        if let addToPlaylist = allCurrentLectureActions[.addToPlaylist] {
            actions.append(addToPlaylist)
        }

        if let share = allCurrentLectureActions[.share] {
            actions.append(share)
        }
        if let info = allCurrentLectureActions[.info] {
            actions.append(info)
        }
        self.optionMenu.children = actions
        self.menuButton?.isHidden = actions.isEmpty
    }

    func configureMenuButton() {

        for option in LectureOption.allCases {
            let action: SPAction = SPAction(title: option.rawValue, image: option.image, identifier: .init(option.rawValue), groupIdentifier: option.groupIdentifier, handler: { [self] _ in

                guard let model = currentLecture else {
                    return
                }
                menuButtonActions(controller: self, option: option, lecture: model)

            })

            switch option {
            case .addToQueue, .addToPlayNext, .download, .resumeDownload, .pauseDownload, .markAsFavorite, .addToPlaylist, .markAsHeard, .resetProgress, .share, .info:
                break
            case .deleteFromDownloads, .removeFromPlaylist, .removeFromFavorite, .removeFromQueue:
                action.action.attributes = .destructive
            }

            allCurrentLectureActions[option] = action
        }

        let childrens: [SPAction] = allCurrentLectureActions.compactMap({ (key: LectureOption, _: SPAction) in
            return allCurrentLectureActions[key]
        })

        if let menuButton = menuButton {
            self.optionMenu = SPMenu(title: "", image: nil, identifier: .init(rawValue: "Option"), options: .displayInline, children: childrens, button: menuButton)
        }
    }

    func menuButtonActions(controller: PlayerViewController, option: LectureOption, lecture: Lecture) {

        switch option {
        case .download, .resumeDownload:
            Haptic.softImpact()
            Persistant.shared.save(lectures: [lecture], completion: { _ in })
            DefaultLectureViewModel.defaultModel.updateLectureInfo(lectures: [lecture], isCompleted: nil, isDownloaded: true, isFavorite: nil, lastPlayedPoint: nil, postUpdate: false, completion: {_ in })

        case .deleteFromDownloads:
            Haptic.warning()
            let eligibleDeleteFromDownloadsModels: [Model] = selectedModels.filter { $0.downloadState != .notDownloaded }
            askToDeleteFromDownloads(lectures: eligibleDeleteFromDownloadsModels, sourceView: self)

        case .markAsFavorite:
            Haptic.softImpact()
            markAsFavorite(lectures: [lecture], sourceView: self)

        case .removeFromFavorite:
            Haptic.warning()
            askToRemoveFromFavorite(lectures: [lecture], sourceView: self)
        case .addToPlaylist:
            Haptic.softImpact()
            let navigationController = UIStoryboard.playlists.instantiate(UINavigationController.self, identifier: "PlaylistNavigationController")
            guard let playlistController = navigationController.viewControllers.first as? PlaylistViewController else {
                return
            }
            playlistController.lecturesToAdd = [lecture]
            playlistController.popoverPresentationController?.sourceView = self.menuButton
            self.present(navigationController, animated: true, completion: nil)

        case .removeFromPlaylist, .markAsHeard, .resetProgress, .pauseDownload, .addToQueue, .addToPlayNext:
            break
        case .removeFromQueue:
            Haptic.softImpact()
            self.removeFromQueue(lectureIDs: [lecture.id])
        case .share:

            lecture.generateShareLink(completion: { result in
                switch result {
                case .success(let success):
                    let shareController = UIActivityViewController(activityItems: [success], applicationActivities: nil)
                    shareController.popoverPresentationController?.sourceView = self.menuButton
                    self.present(shareController, animated: true)
                case .failure(let failure):
                    self.showAlert(error: failure)
                }
            })
        case .info:
            let controller = UIStoryboard.common.instantiate(LectureInfoViewController.self)
            controller.lecture = lecture

            switch Environment.current.device {
            case .mac, .pad:
                controller.modalPresentationStyle = .formSheet
            default:
                controller.modalPresentationStyle = .automatic
            }
            controller.popoverPresentationController?.sourceView = self.menuButton
            self.present(controller, animated: true)
        }
    }
}
