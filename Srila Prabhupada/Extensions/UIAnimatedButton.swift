//
//  UIButton+Animation.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 7/18/23.
//

import UIKit

class UIAnimatedButton: UIButton {

    private let rippleLayer = CAShapeLayer()
    private var initalSizeFactor: CGFloat = 1.0
    private var initialAlpha: Double = 0.3
    private var rippleColor: UIColor = UIColor.white
    private var sizeFactor: CGFloat = 0.8
    private var duration: Double = 0.4

    override func awakeFromNib() {
        super.awakeFromNib()
        addTarget(self, action: #selector(animateDown(_:)), for: [.touchDown, .touchDragEnter])
        addTarget(self, action: #selector(animateUp(_:)), for: [.touchDragExit, .touchCancel, .touchUpInside, .touchUpOutside])
    }

    @objc private func animateDown(_ sender: UIButton) {
        let activeGestures: [UIGestureRecognizer] = gestureRecognizers?.filter({ $0.state == .began }) ?? []
        if activeGestures.isEmpty {
            animateDown()
        }
    }

    @objc private func animateUp(_ sender: UIButton) {
        let activeGestures: [UIGestureRecognizer] = gestureRecognizers?.filter({ $0.state == .began }) ?? []
        if activeGestures.isEmpty {
            animateUp()
        }
    }

    @objc func animateDown() {
        animate(transform: CGAffineTransform.identity.scaledBy(x: 0.8, y: 0.8))
        animateRippleShow()
    }

    @objc func animateUp() {
        animate(transform: .identity)
        animateRippleHide()
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

    var lastSize: CGSize = .zero
    override func layoutSubviews() {
        super.layoutSubviews()
        if lastSize != self.bounds.size {
            lastSize = self.bounds.size

            let center = CGPoint(x: bounds.midX, y: bounds.midY)
            let diagnolLength = sqrt(bounds.width*bounds.width + bounds.height*bounds.height)
            let endAngle: CGFloat = CGFloat.pi * 2
            let radius: CGFloat = 0.5 * diagnolLength * initalSizeFactor
            let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0.0, endAngle: endAngle, clockwise: true)
            rippleLayer.path = path.cgPath
            rippleLayer.opacity = 0
            rippleLayer.fillColor = rippleColor.cgColor
            rippleLayer.strokeColor = rippleColor.cgColor
            rippleLayer.lineCap = CAShapeLayerLineCap.round
            rippleLayer.frame = bounds
            layer.addSublayer(rippleLayer)
        }
    }

    @objc private func animateRippleShow() {

        let circleEnlargeAnimation = CABasicAnimation(keyPath: "transform.scale")
        circleEnlargeAnimation.fromValue = 1.0
        circleEnlargeAnimation.toValue = sizeFactor/initalSizeFactor
        circleEnlargeAnimation.duration = duration
        circleEnlargeAnimation.fillMode = CAMediaTimingFillMode.forwards
        circleEnlargeAnimation.isRemovedOnCompletion = false
        circleEnlargeAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)

        let fadingOutAnimation = CABasicAnimation(keyPath: "opacity")
        fadingOutAnimation.fromValue = rippleLayer.opacity
        fadingOutAnimation.toValue = initialAlpha
        fadingOutAnimation.duration = duration
        fadingOutAnimation.fillMode = CAMediaTimingFillMode.forwards
        fadingOutAnimation.isRemovedOnCompletion = false
        fadingOutAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
        CATransaction.begin()
        rippleLayer.add(circleEnlargeAnimation, forKey: nil)
        rippleLayer.add(fadingOutAnimation, forKey: nil)
        CATransaction.commit()
    }

    @objc private func animateRippleHide() {
        let fadingOutAnimation = CABasicAnimation(keyPath: "opacity")
        fadingOutAnimation.fromValue = initialAlpha
        fadingOutAnimation.toValue = 0.0
        fadingOutAnimation.duration = duration
        fadingOutAnimation.fillMode = CAMediaTimingFillMode.forwards
        fadingOutAnimation.isRemovedOnCompletion = false
        fadingOutAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
        CATransaction.begin()
        rippleLayer.add(fadingOutAnimation, forKey: nil)
        CATransaction.commit()
    }
}
