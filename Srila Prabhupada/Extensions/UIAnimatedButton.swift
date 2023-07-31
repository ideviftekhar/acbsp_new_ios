//
//  UIButton+Animation.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 7/18/23.
//

import UIKit

class UIAnimatedButton: UIButton {

    override func awakeFromNib() {
        super.awakeFromNib()
        addTarget(self, action: #selector(animateDown), for: [.touchDown, .touchDragEnter])
        addTarget(self, action: #selector(animateUp), for: [.touchDragExit, .touchCancel, .touchUpInside, .touchUpOutside])
    }

    @objc func animateDown() {
        animate(transform: CGAffineTransform.identity.scaledBy(x: 0.8, y: 0.8))
    }

    @objc func animateUp() {
        animate(transform: .identity)
    }

    private func animate(transform: CGAffineTransform) {
        UIView.animate(withDuration: 0.4,
                       delay: 0,
                       usingSpringWithDamping: 0.5,
                       initialSpringVelocity: 3,
                       options: [.curveEaseInOut, .allowUserInteraction, .beginFromCurrentState],
                       animations: {
            self.transform = transform
            }, completion: nil)
    }
}
