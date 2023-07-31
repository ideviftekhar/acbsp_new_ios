//
//  MiniPlayerView+Gesture.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 7/6/23.
//

import UIKit

extension MiniPlayerView: UIGestureRecognizerDelegate {

    private func startLondPressTimer() {
        longPressTimer?.invalidate()
        longPressTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true, block: { [self] _ in
            if let index = Self.temporaryRates.firstIndex(of: temporaryRate),
                (index + 1) < Self.temporaryRates.count {
                temporaryRate = Self.temporaryRates[index + 1]
                delegate?.miniPlayerView(self, didTemporaryChangeRate: temporaryRate)
            }
        })
        longPressTimer?.fire()
    }

    private func stopLongPressTimer() {
        longPressTimer?.invalidate()
        longPressTimer = nil
    }

    @objc internal func longPressRecognized(_ sender: UILongPressGestureRecognizer) {
        guard let model = currentLecture, isPlaying else {
            return
        }

        switch sender.state {
        case .began:
            initialRate = dataSource?.miniPlayerViewCurrentRate(self).rate ?? 1
            temporaryRate = initialRate
            startLondPressTimer()
        case .ended, .cancelled, .failed:
            DispatchQueue.main.async {
                (sender.view as? UIAnimatedButton)?.animateUp()
            }
            stopLongPressTimer()
            delegate?.miniPlayerView(self, didTemporaryChangeRate: initialRate)
        default:
            break
        }
    }
    
    @objc internal func panRecognized(_ sender: UIPanGestureRecognizer) {

        guard let model = currentLecture else {
            return
        }

        if lastProposedSeek == 0 {
            lastProposedSeek = Float(playedSeconds)
            let viewLocation = sender.location(in: self)
            let progressViewLocation = progressView.convert(CGPoint(x: progressView.bounds.midX, y: progressView.bounds.midY), to: self)
            initialYDiff = viewLocation.y - progressViewLocation.y
        }

        let translation = sender.translation(in: self)
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
            let velocity = sender.velocity(in: self)

            if abs(velocity.x) >= abs(velocity.y) {
                if velocity.x < 0 {
                    direction = .left
                } else {
                    direction = .right
                }
            } else if abs(velocity.x) < abs(velocity.y) {
                if velocity.y < 0 {
                    direction = .up
                } else {
                    direction = .down
                }

            } else {
                direction = .right
            }

        case .changed:
            switch direction {
            case .left, .right:
                progressView.progress = proposedSeek / totalSeconds
                currentTimeLabel.text = Int(proposedSeek).toHHMMSS
            case .up, .down:
                break
            default:
                break
            }
        case .ended, .cancelled:

            lastPanTranslation = .zero
            lastProposedSeek = 0

            switch direction {
            case .left, .right:
                delegate?.miniPlayerView(self, didSeekTo: Int(proposedSeek))
            case .up, .down:

                let velocity = sender.velocity(in: self)

                if velocity.y < 0 && abs(velocity.y) > 250 {
                    delegate?.miniPlayerViewDidExpand(self)
                } else if velocity.y > 0 && abs(velocity.y) > 250 {
                    delegate?.miniPlayerViewDidClose(self)
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
}
