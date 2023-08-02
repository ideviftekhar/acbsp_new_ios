//
//  PlayerViewController+Gesture.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 7/6/23.
//

import UIKit

extension PlayerViewController {

    private func startLondPressTimer() {
        longPressTimer?.invalidate()
        longPressTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true, block: { [self] _ in
            if let index = Self.temporaryRates.firstIndex(of: temporaryRate),
                (index + 1) < Self.temporaryRates.count {
                temporaryRate = Self.temporaryRates[index + 1]
                if isNegativeRate {
                    player?.rate = -temporaryRate
                } else {
                    player?.rate = temporaryRate
                }
            }
        })
        longPressTimer?.fire()
    }

    private func stopLongPressTimer() {
        longPressTimer?.invalidate()
        longPressTimer = nil
    }

    @objc internal func prevNextLongPressRecognized(_ sender: UILongPressGestureRecognizer) {
        guard !self.isPaused else {
            return
        }

        switch sender.state {
        case .began:
            Haptic.softImpact()
            initialRate = self.selectedRate.rate
            isNegativeRate = sender.view == previousLectureButton
            temporaryRate = initialRate
            startLondPressTimer()
        case .ended, .cancelled, .failed:
            Haptic.selection()
            DispatchQueue.main.async {
                (sender.view as? UIAnimatedButton)?.animateUp()
            }
            stopLongPressTimer()
            player?.rate = initialRate
        default:
            break
        }
    }

    @objc internal func panRecognized(_ sender: UIPanGestureRecognizer) {

        guard let model = currentLecture else {
            return
        }

        if lastProposedSeek == 0 {
            lastProposedSeek = Float(currentTime)
            let viewLocation = sender.location(in: self.view)
            let progressViewLocation = progressView.convert(CGPoint(x: progressView.bounds.midX, y: progressView.bounds.midY), to: self.view)
            initialYDiff = viewLocation.y - progressViewLocation.y
        }

        let translation = sender.translation(in: self.view)
        let totalSeconds: Float = Float(model.lengthTime.totalSeconds)
        let progressViewWidth = progressView.bounds.width

        let translationDiff: CGFloat = translation.x - lastPanTranslation.x

        let multiplier = (progressViewWidth - abs(translation.y + initialYDiff)) / progressViewWidth
        let distanceMultiplier = CGFloat.maximum(0.1, multiplier)
        let translationDiffInX = translationDiff * distanceMultiplier

        let seekDiff: Float = totalSeconds * Float(translationDiffInX / progressViewWidth)
        var proposedSeek: Float = lastProposedSeek + seekDiff
        proposedSeek = Float.maximum(proposedSeek, 0)
        proposedSeek = Float.minimum(proposedSeek, totalSeconds-1.0)    // 1 seconds to not reach at the end instantly

        lastPanTranslation = translation
        lastProposedSeek = proposedSeek

        switch sender.state {
        case .began:
            let velocity = sender.velocity(in: self.view)

            if abs(velocity.x) >= abs(velocity.y) {
                Haptic.softImpact()
                if velocity.x < 0 {
                    direction = .left
                } else {
                    direction = .right
                }
                UIView.animate(withDuration: 0.2, delay: 0, options: [.beginFromCurrentState, .curveEaseOut], animations: { [self] in
                    progressView.transform = .init(scaleX: 1, y: 2.0)
                    loadingProgressView.transform = progressView.transform
                })
            } else if abs(velocity.x) < abs(velocity.y) {
                if velocity.y < 0 {
                    direction = .up
                } else {
                    direction = .down
                    self.view.cornerRadius = 30
                }

            } else {
                direction = .right
            }

        case .changed:
            switch direction {
            case .left, .right:
                let progress = proposedSeek / totalSeconds
                progressView.progress = progress
                waveformView.progress = progress
                currentTimeLabel.text = Int(proposedSeek).toHHMMSS
                updateTotalTime(seconds: Int(proposedSeek))
                miniPlayerView.playedSeconds = proposedSeek
            case .up:
                break
            case .down:
                var bounds = self.view.bounds

                var move = sender.translation(in: self.view).y
                move = CGFloat.maximum(0, move)
                move = CGFloat.minimum(bounds.height - MiniPlayerView.miniPlayerHeight, move)

                bounds.origin.y += move
                self.view.frame = bounds
            default:
                break
            }
        case .ended, .cancelled:

            lastPanTranslation = .zero
            lastProposedSeek = 0

            switch direction {
            case .left, .right:
                Haptic.selection()
                UIView.animate(withDuration: 0.2, delay: 0, options: [.beginFromCurrentState, .curveEaseOut], animations: { [self] in
                    progressView.transform = .identity
                    loadingProgressView.transform = progressView.transform
                })
                seekTo(seconds: Int(proposedSeek))
            case .up, .down:

                self.view.cornerRadius = 0.0
                let velocity = sender.velocity(in: self.view)
                if velocity.y < 0 {
                    expand(animated: true)
                } else {
                    minimize(animated: true)
                }

            default:
                break
            }
        case .possible, .failed:
            break
        @unknown default:
            break
        }
    }

    @objc internal func panMinimizeRecognized(_ sender: UIPanGestureRecognizer) {

        switch sender.state {
        case .began:
            break
        case .changed:
            var bounds = self.view.bounds
            var move = sender.translation(in: self.view).y
            move = CGFloat.maximum(0, move)
            move = CGFloat.minimum(bounds.height - MiniPlayerView.miniPlayerHeight, move)

            bounds.origin.y += move
            self.view.frame = bounds
            self.view.cornerRadius = 30
        case .ended, .cancelled:

            self.view.cornerRadius = 0.0
            let velocity = sender.velocity(in: self.view)
            if velocity.y < 0 {
                expand(animated: true)
            } else {
                minimize(animated: true)
            }
        case .possible, .failed:
            break
        @unknown default:
            break
        }
    }

    @objc internal func tableViewPanRecognized(_ sender: UIPanGestureRecognizer) {

        switch sender.state {
        case .began:
            break
        case .changed:
            var move = -(lectureTebleView.contentOffset.y + lectureTebleView.contentInset.top)

            if move > 0 {
                lectureTebleView.contentOffset = CGPoint(x: 0, y: -lectureTebleView.contentInset.top)

                var bounds = self.view.frame

                move = CGFloat.maximum(0, move)
                move = CGFloat.minimum(bounds.height - MiniPlayerView.miniPlayerHeight, move)

                bounds.origin.y += move
                self.view.frame = bounds
                self.view.cornerRadius = 30
            } else {
                let needed = self.view.frame.origin.y
                let adjustment = CGFloat.minimum(needed, -move)

                if adjustment != 0 {
                    var offset = lectureTebleView.contentOffset
                    offset.y -= adjustment
                    lectureTebleView.contentOffset = offset

                    var bounds = self.view.frame
                    bounds.origin.y -= adjustment
                    self.view.frame = bounds
                    self.view.cornerRadius = 30
                } else {
                    self.view.cornerRadius = 0.0
                }
            }

        case .ended, .cancelled:

            self.view.cornerRadius = 0.0
            let velocity = sender.velocity(in: self.view)
            if velocity.y < 0 {
                expand(animated: true)
            } else if self.view.frame.origin.y != 0 {
                minimize(animated: true)
            } else {
                expand(animated: true)
            }

        case .possible, .failed:
            break
        @unknown default:
            break
        }
    }
}
