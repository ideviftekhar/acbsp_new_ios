//
//  IQProgressView.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 7/18/23.
//

import UIKit

class IQProgressView: UIView {

    private let progressLayer = CALayer()

    private var _progress: CGFloat = 0.0
    var progress: CGFloat {
        get {
            _progress
        }
        set {
            _progress = CGFloat.minimum(1.0, newValue)
            _progress = CGFloat.maximum(0.0, _progress)
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            updateProgress()
            CATransaction.commit()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.layer.addSublayer(progressLayer)
        progressLayer.backgroundColor = tintColor?.cgColor
    }

    override var tintColor: UIColor? {
        didSet {
            progressLayer.backgroundColor = tintColor?.cgColor
        }
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()
        progressLayer.backgroundColor = tintColor?.cgColor
    }

    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        if layer == self.layer {
            updateProgress()
        }
    }

    private func updateProgress() {
        var bounds = self.layer.bounds
        bounds.size.width = bounds.width * progress
        self.progressLayer.frame = bounds
    }

    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.height = 4
        return size
    }
}
