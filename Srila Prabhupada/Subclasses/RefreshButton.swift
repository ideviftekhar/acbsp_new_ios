//
//  RefreshButton.swift
//  Day Interpreting
//
//  Created by Iftekhar on 06/03/19.
//  Copyright © 2019 Ben Fawcett. All rights reserved.
//

import UIKit

final class RefreshButton: UIButton {

    var animating = false
    
    func startSpinning() {
        
        if (animating) {
            return;
        }
        animating = true
        let angle: CGFloat = CGFloat.pi * 2
        self.rotateWithDuration(1, angle: angle)
    }
    
    func stopSpinning() {
        animating = false
    }
    
    //  https://stackoverflow.com/a/24061266
    private func rotateWithDuration(_ duration : CFTimeInterval, angle: CGFloat) {
    
        CATransaction.begin()
        
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotationAnimation.byValue = angle
        rotationAnimation.duration = duration
        rotationAnimation.isRemovedOnCompletion = true
        CATransaction.setCompletionBlock {
            if self.animating {
                self.rotateWithDuration(duration, angle: angle)
            }
        }
        
        self.layer.add(rotationAnimation, forKey: "rotationAnimation")
        CATransaction.commit()
    }
}
