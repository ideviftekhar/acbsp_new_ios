//
//  PlayerViewController+Gesture.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 7/6/23.
//

import UIKit

extension PlayerViewController {

    @objc internal func panRecognized(_ sender: UIPanGestureRecognizer) {

        guard let model = currentLecture else {
            return
        }

        let translation = sender.translation(in: self.view)
        let totalSeconds: Float = Float(model.lengthTime.totalSeconds)
        let seekProgress: Float = Float(translation.x / self.view.bounds.width)
        let maxSeekSeconds: Float = totalSeconds // 10*60 // 10 minutes
        let changedSeconds: Float = maxSeekSeconds*seekProgress
        var proposedSeek: Float = Float(currentTime) + changedSeconds
        proposedSeek = Float.maximum(proposedSeek, 0)
        proposedSeek = Float.minimum(proposedSeek, totalSeconds-1.0)    // 1 seconds to not reach at the end instantly

        switch sender.state {
        case .began:
            let velocity = sender.velocity(in: self.view)

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
                    self.view.cornerRadius = 30
                }

            } else {
                direction = .right
            }

        case .changed:
            switch direction {
            case .left, .right:
                timeSlider.value = proposedSeek
                currentTimeLabel.text = Int(proposedSeek).toHHMMSS
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

            switch direction {
            case .left, .right:
                seekTo(seconds: Int(proposedSeek))
            case .up, .down:

                self.view.cornerRadius = 0.0
                let velocity = sender.velocity(in: self.view)
                if velocity.y < 0 {
                    expand(animated: true)
                } else {
                    minimize(animated: true)
                }

                break
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

        guard let model = currentLecture else {
            return
        }

        let translation = sender.translation(in: self.view)

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

        guard let model = currentLecture else {
            return
        }

        switch sender.state {
        case .began:
            break
        case .changed:
            var move = -lectureTebleView.contentOffset.y

            if move > 0 {
                lectureTebleView.contentOffset = CGPoint.zero

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
