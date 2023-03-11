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


        // Is Favourites
        if currentLecture.isFavourite, let removeFromFavourites = allActions[.removeFromFavourites] {
            actions.append(removeFromFavourites)
        } else if let markAsFavourite = allActions[.markAsFavourite] {
            actions.append(markAsFavourite)
        }

        // addToPlaylist
        if let addToPlaylist = allActions[.addToPlaylist] {
            actions.append(addToPlaylist)
        }

        self.optionMenu.children = actions
        self.menuButton?.isHidden = actions.isEmpty
    }

    func configureMenuButton() {

        for option in LectureOption.allCases {
            let action: SPAction = SPAction(title: option.rawValue, image: option.image, identifier: .init(option.rawValue), handler: { [self] _ in

                guard let model = currentLecture else {
                    return
                }
                menuButtonActions(controller: self, option: option, lecture: model)

            })

            switch option {
            case .download, .resumeDownload, .pauseDownload, .markAsFavourite, .addToPlaylist, .markAsHeard, .resetProgress, .share:
                break
            case .deleteFromDownloads, .removeFromPlaylist, .removeFromFavourites:
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

    func menuButtonActions(controller: PlayerViewController, option: LectureOption, lecture: Lecture) {

        switch option {

        case .download, .resumeDownload:
            Haptic.softImpact()
            Persistant.shared.save(lectures: [lecture], completion: { _ in })
            DefaultLectureViewModel.defaultModel.updateLectureInfo(lectures: [lecture], isCompleted: nil, isDownloaded: true, isFavourite: nil, lastPlayedPoint: nil, postUpdate: false, completion: {_ in })

        case .deleteFromDownloads:
            Haptic.warning()
            let eligibleDeleteFromDownloadsModels: [Model] = selectedModels.filter { $0.downloadState != .notDownloaded }
            askToDeleteFromDownloads(lectures: eligibleDeleteFromDownloadsModels, sourceView: self)

        case .markAsFavourite:
            Haptic.softImpact()
            markAsFavourites(lectures: [lecture], sourceView: self)

        case .removeFromFavourites:
            Haptic.warning()
            askToRemoveFromFavourites(lectures: [lecture], sourceView: self)
        case .addToPlaylist:
            Haptic.softImpact()
            let navigationController = UIStoryboard.playlists.instantiate(UINavigationController.self, identifier: "PlaylistNavigationController")
            guard let playlistController = navigationController.viewControllers.first as? PlaylistViewController else {
                return
            }
            playlistController.lecturesToAdd = [lecture]
            self.present(navigationController, animated: true, completion: nil)

        case .removeFromPlaylist, .markAsHeard, .resetProgress, .pauseDownload, .share:
            break
        }
    }
}
