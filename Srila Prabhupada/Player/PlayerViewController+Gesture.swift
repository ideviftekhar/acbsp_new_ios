//
//  PlayerViewController+Gesture.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 7/6/23.
//

import UIKit

extension PlayerViewController: UIGestureRecognizerDelegate {

    @objc internal func panRecognized(_ sender: UIPanGestureRecognizer) {
        
        guard let model = currentLecture else {
            return
        }

//        if seekGesture.state != .changed {
//            currentTimeLabel.text = Int(playedSeconds).toHHMMSS
//            timeSlider.value = playedSeconds
//        }

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
            let velocity = seekGesture.velocity(in: self.view)
            
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
                timeSlider.value = proposedSeek
                currentTimeLabel.text = Int(proposedSeek).toHHMMSS
                miniPlayerView.playedSeconds = proposedSeek
            case .up, .down:
                break
            default:
                break
            }
        case .ended, .cancelled:
            
            switch direction {
            case .left, .right:
                seekTo(seconds: Int(proposedSeek))
            case .up, .down:
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
}
