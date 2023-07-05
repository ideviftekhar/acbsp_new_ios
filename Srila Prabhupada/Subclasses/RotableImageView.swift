//
//  RotableImageView.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 7/5/23.
//

import UIKit

class RotableImageView: UIImageView {

    var isSpinning = false

    func startSpinning() {

        if (isSpinning) {
            return;
        }
        isSpinning = true
        let angle: CGFloat = CGFloat.pi * 2
        self.rotateWithDuration(1, angle: angle)
    }

    func stopSpinning() {
        isSpinning = false
    }

    //  https://stackoverflow.com/a/24061266
    private func rotateWithDuration(_ duration : CFTimeInterval, angle: CGFloat) {

        CATransaction.begin()

        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotationAnimation.byValue = angle
        rotationAnimation.duration = duration
        rotationAnimation.isRemovedOnCompletion = true
        CATransaction.setCompletionBlock {
            if self.isSpinning {
                self.rotateWithDuration(duration, angle: angle)
            }
        }

        self.layer.add(rotationAnimation, forKey: "rotationAnimation")
        CATransaction.commit()
    }
}
