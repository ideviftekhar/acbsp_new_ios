//
//  MiniPlayerView+Gesture.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 7/6/23.
//

import UIKit

extension MiniPlayerView: UIGestureRecognizerDelegate {

    @objc internal func panRecognized(_ sender: UIPanGestureRecognizer) {

        guard let model = currentLecture else {
            return
        }
        let translation = sender.translation(in: self)
        let totalSeconds: Float = Float(lectureDuration.totalSeconds)
        let progressViewWidth = progressView.bounds.width
//        let multiplier = (progressViewWidth - abs(translation.y)) / progressViewWidth
//        let distanceMultiplier = CGFloat.maximum(0.1, multiplier)
//        let translationInX = translation.x * distanceMultiplier
        let translationInX = translation.x

        let seekProgress: Float = Float(translationInX / progressViewWidth)
        let maxSeekSeconds: Float = totalSeconds // 10*60 // 10 minutes
        let changedSeconds: Float = maxSeekSeconds*seekProgress
        var proposedSeek: Float = playedSeconds + changedSeconds
        proposedSeek = Float.maximum(proposedSeek, 0)
        proposedSeek = Float.minimum(proposedSeek, totalSeconds-1.0)    // 1 seconds to not reach at the end instantly

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
