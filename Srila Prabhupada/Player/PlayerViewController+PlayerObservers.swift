//
//  PlayerViewController+PlayerObservers.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 7/31/23.
//

import UIKit
import AVFoundation
import CoreMedia

extension PlayerViewController {

    internal func addPeriodicTimeObserver() {

        guard let player = player else { return }

        player.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1, preferredTimescale: 1), queue: DispatchQueue.main, using: { [self] (time) -> Void in

            if time.isNumeric {
                let time: Double = time.seconds
                updatePlayProgressUI(to: time)

                let timeInt = Int(time)
                if timeInt.isMultiple(of: 10) {    // Updating every 10 seconds
                    guard let currentLecture = currentLecture else { return }
                    updateLectureProgress()
                    DefaultLectureViewModel.defaultModel.updateListenInfo(date: Date(), addListenSeconds: 10, lecture: currentLecture, completion: { _ in })
                }
            }
        })

        if seekGesture.state != .changed, let currentLecture = currentLecture {

            let totalSeconds = Float(currentLecture.lengthTime.totalSeconds)
            let playedSeconds = Float(currentTime)
            let progress = playedSeconds / Float(totalSeconds)
            progressView.progress = progress
            waveformView.progress = progress

            miniPlayerView.playedSeconds = playedSeconds
            currentTimeLabel.text = currentTime.toHHMMSS
            updateTotalTime(seconds: currentTime)
        }
    }

    internal func registerAudioSessionObservers() {
        NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: nil, using: { [self] notification in

            if let interruptionTypeInt = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
               let interruptionType = AVAudioSession.InterruptionType(rawValue: interruptionTypeInt) {

                switch interruptionType {
                case .began:
                    pause()
                case .ended:
                    if let interruptionOptionInt = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt {
                        let interruptionOption = AVAudioSession.InterruptionOptions(rawValue: interruptionOptionInt)
                        if interruptionOption == .shouldResume {
                            play()
                        }
                    }
                @unknown default:
                    break
                }
            }
        })
    }

    internal func removePlayerItemNotificationObserver(item: AVPlayerItem) {
        loadingProgressView.progress = 0
        miniPlayerView.loadingProgress = 0
        self.timeControlStatusObserver?.invalidate()
        self.itemStatusObserver?.invalidate()
        self.itemRateObserver?.invalidate()
        self.itemTracksObserver?.invalidate()
        self.playerItemTracksPowerMeterPublisher?.cancel()
        self.playerItemLoadedTimeRangesPublisher?.cancel()
        if let itemDidPlayToEndObserver = itemDidPlayToEndObserver {
            NotificationCenter.default.removeObserver(itemDidPlayToEndObserver, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: item)
        }
    }

    internal func addPlayerItemNotificationObserver(item: AVPlayerItem) {

        self.itemRateObserver = player?.observe(\.rate, options: [.new, .old], changeHandler: { [self] (_, change) in

            if let newValue = change.newValue, newValue != 0.0 {
                playPauseButton.setImage(pauseFillImage, for: .normal)
                miniPlayerView.isPlaying = true

                SPNowPlayingInfoCenter.shared.update(lecture: currentLecture, player: player, selectedRate: selectedRate)
                if let currentLecture = currentLecture {
                    Self.nowPlaying = (currentLecture, .playing(progress: self.currentProgress, audioPower: self.lastAudioPower))
                    audioVisualizerView.state = .playing
                } else {
                    Self.nowPlaying = nil
                    audioVisualizerView.state = .stopped
                }
            } else {
                playPauseButton.setImage(playFillImage, for: .normal)
                miniPlayerView.isPlaying = false
                SPNowPlayingInfoCenter.shared.update(lecture: currentLecture, player: player, selectedRate: selectedRate)
                updateLectureProgress()
                if let currentLecture = currentLecture {
                    Self.nowPlaying = (currentLecture, .paused)
                    audioVisualizerView.state = .paused
                } else {
                    Self.nowPlaying = nil
                    audioVisualizerView.state = .stopped
                }
            }

            previousLongPressGesture.isEnabled = miniPlayerView.isPlaying
            nextLongPressGesture.isEnabled = miniPlayerView.isPlaying
        })

        self.timeControlStatusObserver = player?.observe(\.timeControlStatus, options: [.new, .old], changeHandler: { [self] (player, _) in

            let totalDuration: Int = self.totalDuration
            miniPlayerView.lectureDuration = Time(totalSeconds: totalDuration)
            updateTotalTime(seconds: self.currentTime)

            switch player.timeControlStatus {
            case .paused, .playing:
                bufferingActivityIndicator.stopAnimating()
            case .waitingToPlayAtSpecifiedRate:
                bufferingActivityIndicator.startAnimating()
            @unknown default:
                bufferingActivityIndicator.stopAnimating()
            }
        })

        self.itemStatusObserver = item.observe(\.status, options: [.new, .old], changeHandler: { [self] (_, change) in

            let totalDuration: Int = self.totalDuration
            miniPlayerView.lectureDuration = Time(totalSeconds: totalDuration)
            updateTotalTime(seconds: self.currentTime)

            if let newValue = change.newValue {
                switch newValue {
                case .unknown, .readyToPlay:
                    break
                case .failed:
                    pause()
                    if let error = player?.error {
                        showAlert(title: "Unable to play", message: error.localizedDescription)
                    }
                @unknown default:
                    break
                }
            }
        })

        self.itemTracksObserver = item.observe(\.tracks, options: [.new, .old], changeHandler: { [self] (_, change) in

            if let newValue = change.newValue?.first(where: { $0.assetTrack?.mediaType == .audio }) {

                let audioMix = newValue.newAudioMixWithTap()
                player?.currentItem?.audioMix = audioMix

                addTrackObservers(track: newValue)
            }
        })

        playerItemLoadedTimeRangesPublisher?.cancel()
        playerItemLoadedTimeRangesPublisher = item.publisher(for: \.loadedTimeRanges).sink { [weak self] newValue in
            guard let self = self else { return }
            guard let loadedDuration = newValue.last?.timeRangeValue.end.seconds.rounded(.up), self.totalDuration > 0 else {
                loadingProgressView.progress = 0
                miniPlayerView.loadingProgress = 0
                return
            }
            let progress = Float(loadedDuration / Double(self.totalDuration))
            loadingProgressView.progress = progress
            miniPlayerView.loadingProgress = progress
        }

        itemDidPlayToEndObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: item, queue: nil, using: { [self] _ in
            updateLectureProgress()
            gotoNext(play: true)
        })
    }

    private func addTrackObservers(track: AVPlayerItemTrack) {

        playerItemTracksPowerMeterPublisher?.cancel()
        playerItemTracksPowerMeterPublisher = track.publisher(for: \.audioLevel)
            .map({
                let newValue =  round($0 * 1000.0) / 1000.0
                return newValue
        })
        .removeDuplicates()
        .receive(on: DispatchQueue.main)
        .sink(receiveValue: { [weak self] value in
            guard let self = self else { return }

            let power: CGFloat = CGFloat(value)

            self.lastAudioPower = power

            self.audioVisualizerView.audioLevel = power

            if var nowPlaying = Self.nowPlaying {
                switch nowPlaying.state {
                case .paused, .stopped:
                    break
                case .playing:
                    nowPlaying.state = .playing(progress: self.currentProgress, audioPower: power)
                    Self.nowPlaying = nowPlaying
                }
            }
        })
    }
}
