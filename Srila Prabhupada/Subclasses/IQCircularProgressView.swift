//
//  IQCircularProgressView.swift
//  Response Angel
//
//  Created by Iftekhar on 5/27/23.
//  Copyright © 2023 mac. All rights reserved.
//

import UIKit

class IQCircularProgressView : UIView {

    private let progressAnimationKey: String = "progressAnimationKey"
    private let indeterminantAnimationKey: String = "indeterminantAnimationKey"

    private let progressLayer: CAShapeLayer = CAShapeLayer()

    var indeterminateProgress: CGFloat = 0.25 {
        didSet {
            if let progress = _progress, progress < 0 {
                progressLayer.strokeEnd = indeterminateProgress
            }
        }
    }

    private var _progress: CGFloat? = nil
    var progress: CGFloat? {
        get {
            _progress
        }
        set {
            self.setProgress(newValue, animated: false)
        }
    }

    override init(frame:CGRect) {
        super.init(frame:frame)
        self.setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.setup()
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()

        let tintColor:UIColor = tintColor ?? UIColor(red:0, green:122/255.0, blue:1.0, alpha:1)

        progressLayer.strokeColor = tintColor.cgColor
        progressLayer.borderColor = tintColor.withAlphaComponent(0.5).cgColor
    }

    private func setup() {
        self.isHidden = true
        self.isUserInteractionEnabled = false

        progressLayer.contentsScale = UIScreen.main.scale
        progressLayer.fillColor = nil
        progressLayer.lineCap = CAShapeLayerLineCap.square
        progressLayer.lineWidth = 2.0
        self.layer.addSublayer(progressLayer)

        let animation: CABasicAnimation = CABasicAnimation(keyPath: "strokeEnd")
        animation.duration = 0.25
        progressLayer.add(animation, forKey: progressAnimationKey)

        let tintColor:UIColor = tintColor ?? UIColor(red:0, green:122/255.0, blue:1.0, alpha:1)
        progressLayer.strokeColor = tintColor.cgColor
        progressLayer.borderColor = tintColor.withAlphaComponent(0.5).cgColor
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        if size.width == -1 && size.height == -1 {
            return CGSize(width: 40, height: 40)
        }
        return size
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let size = super.sizeThatFits(size)
        return size
    }

    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        if layer == self.layer {

            CATransaction.begin()
            CATransaction.setValue(true, forKey:kCATransactionDisableActions)
            progressLayer.frame = self.layer.bounds
            progressLayer.cornerRadius = progressLayer.frame.size.width/2.0
            progressLayer.path = self.progressPath().cgPath
            CATransaction.commit()
        }
    }

    private func progressPath() -> UIBezierPath! {
        let TWO_M_PI:Double = 2.0 * Double.pi
        let startAngle:Double = 0.75 * TWO_M_PI
        let endAngle:Double = startAngle + TWO_M_PI

        let width:CGFloat = self.frame.size.width
        let lineWidth:CGFloat = progressLayer.lineWidth
        let point = CGPointMake(width/2.0, width/2.0)
        let radius = width/2.0 - lineWidth/2.0
        return UIBezierPath(arcCenter: point,
                            radius:radius,
                            startAngle:startAngle,
                            endAngle:endAngle,
                            clockwise:true)
    }

    func setProgress(_ progress: CGFloat?, animated: Bool) {

        guard _progress != progress else {
            return
        }

        guard var progress = progress else {
            self.isHidden = true
            _progress = nil
            return
        }

        _progress = progress

        if progress >= 0 && progress <= 1 {
            progressLayer.removeAllAnimations()
            self.isHidden = false

            if animated {
                progressLayer.strokeEnd = progress
            } else {
                CATransaction.begin()
                CATransaction.setValue(true, forKey: kCATransactionDisableActions)
                progressLayer.strokeEnd = progress
                CATransaction.commit()
            }

            progressLayer.borderWidth = 1.0
        } else {
            self.isHidden = false
            progressLayer.strokeEnd = indeterminateProgress
            progressLayer.borderWidth = 0.0

            let spinAnimation: CABasicAnimation = CABasicAnimation(keyPath: "transform.rotation")
            spinAnimation.toValue        = 2*Double.pi
            spinAnimation.timingFunction = CAMediaTimingFunction(name: .linear)
            spinAnimation.duration       = 1.0
            spinAnimation.repeatCount    = .infinity
            progressLayer.add(spinAnimation, forKey: indeterminantAnimationKey)
        }
    }
}
