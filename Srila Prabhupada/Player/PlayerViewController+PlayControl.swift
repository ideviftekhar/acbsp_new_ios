//
//  PlayerViewController+PlayControl.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 7/31/23.
//

import UIKit
import CoreMedia

extension PlayerViewController {

    @IBAction func playPauseButtonTapped(_ sender: UIButton) {
        Haptic.softImpact()
        if isPaused {
            play()
        } else {
            pause()
        }
    }

    internal func registerNowPlayingCommands() {
        SPNowPlayingInfoCenter.shared.registerNowPlayingInfoCenterCommands { [self] (command, value) in
            switch command {
            case .pause:
                pause()
            case .play:
                play()
            case .stop:
                currentLecture = nil
            case .togglePausePlay:
                if isPaused {
                    play()
                } else {
                    pause()
                }
            case .nextTrack:
                gotoNext(play: !isPaused)
            case .previousTrack:
                gotoPrevious(play: !isPaused)
            case .changeRepeatMode:
                if let value = value as? Bool {
                    change(shuffle: false, loop: value)
                }
            case .changeShuffleMode:
                if let value = value as? Bool {
                    change(shuffle: value, loop: false)
                }
            case .changePlaybackRate:
                if let value = value as? Float, let rate = PlayRate(rawValue: value) {
                    self.selectedRate = rate
                }

            case .skipForward:
                if let value = value as? TimeInterval {
                    seek(seconds: Int(value))
                }
            case .skipBackward:
                if let value = value as? TimeInterval {
                    seek(seconds: Int(-value))
                }
            case .changePlaybackPosition:
                if let value = value as? TimeInterval {
                    seekTo(seconds: Int(value))
                }
            }
        }
    }

    var isPaused: Bool {
        player?.rate == 0.0
    }

    func play() {
        player?.play()
        player?.rate = self.selectedRate.rate
    }

    func pause() {
        player?.pause()
    }

    var currentTime: Int {
        guard let player = player,
              let currentItem = player.currentItem,
              currentItem.currentTime().isNumeric else {
            return currentLecture?.lastPlayedPoint ?? 0
        }

        let currentTime = Int(currentItem.currentTime().seconds.rounded(.up))

        return currentTime
    }

    var totalDuration: Int {
        guard let player = player,
              let currentItem = player.currentItem,
              currentItem.duration.isNumeric else {
            return currentLecture?.length ?? 0
        }

        let currentTime = Int(currentItem.duration.seconds)

        return currentTime
    }

    var currentProgress: CGFloat {
        let totalDuration = totalDuration
        let currentTime = currentTime
        guard totalDuration > 0 else {
            return 0
        }
        var progress = CGFloat(currentTime) / CGFloat(totalDuration)
        progress = CGFloat.maximum(0.0, progress)
        progress = CGFloat.minimum(1.0, progress)
        return progress
    }

    func updateLectureProgress() {
        guard let currentLecture = currentLecture else {
            return
        }

        let currentTime = currentTime
        DefaultLectureViewModel.defaultModel.updateLectureInfo(lectures: [currentLecture], isCompleted: nil, isDownloaded: nil, isFavorite: nil, lastPlayedPoint: currentTime, postUpdate: false, completion: { result in
            switch result {
            case .success:
//                print("Update lecture \"\(currentLecture.titleDisplay)\" current time: \(currentTime) / \(currentLecture.length)")
                break
            case .failure(let error):
                print("Update lecture failed: \(error.localizedDescription)")
            }
        })
    }

    func seek(seconds: Int) {

        let currentTime = currentTime
        var newTime = currentTime + seconds
        if newTime < 0 {
            newTime = 0
        }

        let totalDuration = totalDuration
        if newTime > totalDuration {
            newTime = totalDuration
        }

        seekTo(seconds: newTime)
    }

    func seekTo(seconds: Int, updateServer: Bool = true) {
        let seconds: Int64 = Int64(seconds)
        let targetTime: CMTime = CMTime(seconds: Double(seconds), preferredTimescale: player?.currentTime().timescale ?? 1)

        isSeeking = true
        player?.seek(to: targetTime, completionHandler: { [self] _ in
            self.isSeeking = false
            SPNowPlayingInfoCenter.shared.update(lecture: self.currentLecture, player: self.player, selectedRate: self.selectedRate)
            if updateServer {
                self.updateLectureProgress()
            }
            updatePlayProgressUI(to: Double(seconds))
        })
    }
}
