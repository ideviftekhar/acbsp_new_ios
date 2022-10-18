//
//  NowPlayingInfoCenter.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 10/12/22.
//

import Foundation
import MediaPlayer
import AlamofireImage

final class SPNowPlayingInfoCenter {

    static let shared: SPNowPlayingInfoCenter = SPNowPlayingInfoCenter()

    private let infoCenter = MPNowPlayingInfoCenter.default()

    private init() {
    }

    func registerNowPlayingInfoCenterCommands(_ handler: @escaping (SPNowPlayableCommand, Any?) -> Void) {
        for command in SPNowPlayableCommand.allCases {
            command.addHandler { (command, event) in
                switch command {
                case .pause, .play, .stop, .togglePausePlay, .nextTrack, .previousTrack:
                    handler(command, nil)
                case .changeRepeatMode:
                    guard let event = event as? MPChangeRepeatModeCommandEvent else { return .commandFailed }

                    switch event.repeatType {
                    case .off, .all:
                        handler(command, false)
                    case .one:
                        handler(command, true)
                    @unknown default:
                        handler(command, false)
                    }

                case .changeShuffleMode:
                    guard let event = event as? MPChangeShuffleModeCommandEvent else { return .commandFailed }

                    switch event.shuffleType {
                    case .off:
                        handler(command, false)
                    case .collections ,.items:
                        handler(command, true)
                    @unknown default:
                        handler(command, false)
                    }

                case .changePlaybackRate:
                    guard let event = event as? MPChangePlaybackRateCommandEvent else { return .commandFailed }
                    handler(command, event.playbackRate)

                case .skipBackward:
                    guard let event = event as? MPSkipIntervalCommandEvent else { return .commandFailed }
                    handler(command, event.interval)

                case .skipForward:
                    guard let event = event as? MPSkipIntervalCommandEvent else { return .commandFailed }
                    handler(command, event.interval)
                case .changePlaybackPosition:
                    guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
                    handler(command, event.positionTime)
                }

                return .success
            }
        }
    }

    func update(lecture: Lecture?, player: AVPlayer?, selectedRate: PlayRate) {
        guard let lecture = lecture, let player = player else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }

        var nowPlayingInfo: [String: Any] = [:]

        nowPlayingInfo[MPMediaItemPropertyTitle] = lecture.titleDisplay
        if !lecture.legacyData.verse.isEmpty {
            nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = lecture.legacyData.verse
        } else {
            nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = lecture.category.joined(separator: ", ")
        }

        let imageCache = AutoPurgingImageCache()

        if let url = lecture.thumbnailURL, let image = imageCache.image(for: URLRequest(url: url)) {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: CGSize(width: 40, height: 40), requestHandler: { _ in image })
        } else if let image = UIImage(named: "logo_167") {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: CGSize(width: 40, height: 40), requestHandler: { _ in image })
        }
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = NSNumber(value: lecture.length)

        if player.currentTime().isNumeric {
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(value: player.currentTime().seconds)
        } else {
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(value: 0)
        }

        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = NSNumber(value: 1.0)
        nowPlayingInfo[MPNowPlayingInfoPropertyDefaultPlaybackRate] = NSNumber(value: selectedRate.rate)

        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackQueueIndex] = NSNumber(value: 0)
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackQueueCount] = NSNumber(value: 1)
//        nowPlayingInfo[MPNowPlayingInfoPropertyChapterNumber] = 1
//        nowPlayingInfo[MPNowPlayingInfoPropertyChapterCount] = 1
        nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = NSNumber(value: false)
        //        nowPlayingInfo[MPNowPlayingInfoPropertyAvailableLanguageOptions] =
        //        nowPlayingInfo[MPNowPlayingInfoPropertyCurrentLanguageOptions] =
        //        nowPlayingInfo[MPNowPlayingInfoCollectionIdentifier] =
        //        nowPlayingInfo[MPNowPlayingInfoPropertyExternalContentIdentifier] =
        //        nowPlayingInfo[MPNowPlayingInfoPropertyExternalUserProfileIdentifier] =
        //        nowPlayingInfo[MPNowPlayingInfoPropertyServiceIdentifier] =

        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackProgress] = NSNumber(value: lecture.playProgress)
        nowPlayingInfo[MPNowPlayingInfoPropertyMediaType] = NSNumber(value: MPNowPlayingInfoMediaType.audio.rawValue)
        if let asset = player.currentItem?.asset as? AVURLAsset {
            nowPlayingInfo[MPNowPlayingInfoPropertyAssetURL] = asset.url
        }
        if #available(iOS 14.0, *), let currentDate = player.currentItem?.currentDate() {
            nowPlayingInfo[MPNowPlayingInfoPropertyCurrentPlaybackDate] = currentDate as NSDate
        }

        // MPMediaItemPropertyAlbumTrackCount
        // MPMediaItemPropertyAlbumTrackNumber
        // MPMediaItemPropertyArtist
        //
        // MPMediaItemPropertyComposer
        // MPMediaItemPropertyDiscCount
        // MPMediaItemPropertyDiscNumber
        // MPMediaItemPropertyGenre
        // MPMediaItemPropertyPersistentID
        //

        //            let category: [String]
        //            let creationTimestamp: String
        //            let dateOfRecording: Day
        //            let description: [String]
        //            let id: Int
        //            let language: Language
        //            let legacyData: LegacyData
        //            let length: Int
        //            let lengthType: [String]
        //            let location: Location
        //            let place: [String]
        //            let tags: [String]

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
}
