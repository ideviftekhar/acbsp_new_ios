//
//  PlayerViewController+More.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 10/03/23.
//

import Foundation
import UIKit
import FirebaseDynamicLinks

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

        // isFavorite
        if currentLecture.isFavorite, let removeFromFavorite = allActions[.removeFromFavorite] {
            actions.append(removeFromFavorite)
        } else if let markAsFavorite = allActions[.markAsFavorite] {
            actions.append(markAsFavorite)
        }

        // addToPlaylist
        if let addToPlaylist = allActions[.addToPlaylist] {
            actions.append(addToPlaylist)
        }

        if let share = allActions[.share] {
            actions.append(share)
        }
        if let info = allActions[.info] {
            actions.append(info)
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

        case .removeFromPlaylist, .markAsHeard, .resetProgress, .pauseDownload:
            break
        case .share:

            let deepLinkBaseURL = "https://bvks.com?lectureId=\(lecture.id)"
            let domainURIPrefix = "https://prabhupada.page.link"

            guard let link = URL(string: deepLinkBaseURL),
                  let linkBuilder = DynamicLinkComponents(link: link, domainURIPrefix: domainURIPrefix) else {
                return
            }

            do {
                let iOSParameters = DynamicLinkIOSParameters(bundleID: "com.bvksdigital.acbsp")
                iOSParameters.appStoreID = "1645287937"
                linkBuilder.iOSParameters = iOSParameters
            }

            do {
                let androidParameters = DynamicLinkAndroidParameters(packageName: "com.iskcon.prabhupada")
                 linkBuilder.androidParameters = androidParameters
            }

            var descriptions: [String] = []
            do {
                let durationString = "• Duration: " + lecture.lengthTime.displayString
                descriptions.append(durationString)

                if !lecture.legacyData.verse.isEmpty {
                    let verseString = "• " + lecture.legacyData.verse
                    descriptions.append(verseString)
                }

                let recordingDateString = "• Date of Recording: " + lecture.dateOfRecording.display_dd_MM_yyyy
                descriptions.append(recordingDateString)

                if !lecture.location.displayString.isEmpty {
                    let locationString = "• Location: " + lecture.location.displayString
                    descriptions.append(locationString)
                }
            }

            do {
                let socialMediaParameters = DynamicLinkSocialMetaTagParameters()
                socialMediaParameters.title = lecture.titleDisplay
                socialMediaParameters.descriptionText = descriptions.joined(separator: "\n")
                if let thumbnailURL = lecture.thumbnailURL {
                    socialMediaParameters.imageURL = thumbnailURL
                }
                linkBuilder.socialMetaTagParameters = socialMediaParameters
            }

            linkBuilder.shorten(completion: { url, _, _ in
                var appLinks: [Any] = []
                if let url = url {
                    appLinks.append(url)
                } else if let url = linkBuilder.url {
                    appLinks.append(url)
                }

                guard !appLinks.isEmpty else {
                    return
                }

                let shareController = UIActivityViewController(activityItems: appLinks, applicationActivities: nil)
                shareController.popoverPresentationController?.sourceView = self.menuButton
                self.present(shareController, animated: true)
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
