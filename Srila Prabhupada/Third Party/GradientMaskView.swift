//
//  GradientMaskView.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 8/2/23.
//

import UIKit

class IQGradientMaskView : UIView {
    @IBInspectable var topGradientHeight: CGFloat = 0 {
        didSet {
            update()
        }
    }

    @IBInspectable var bottomGradientHeight: CGFloat = 0 {
        didSet {
            update()
        }
    }

    private let maskLayer: CAGradientLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    var lastSize: CGSize = .zero
    override func layoutSubviews() {
        super.layoutSubviews()
        if lastSize != self.bounds.size {
            lastSize = self.bounds.size
            update()
        }
    }

    private func commonInit() {
        self.maskLayer.bounds = self.layer.bounds
        self.maskLayer.colors = [UIColor.clear.cgColor,
                                 UIColor.black.cgColor,
                                 UIColor.black.cgColor,
                                 UIColor.clear.cgColor]
        self.maskLayer.anchorPoint = .zero
        self.maskLayer.bounds = self.layer.bounds
        self.layer.mask = self.maskLayer
    }

    private func update() {
        let topPosition = CGFloat.minimum(1, topGradientHeight/self.bounds.height)
        let bottomPosition = 1 - CGFloat.minimum(1, bottomGradientHeight/self.bounds.height)

        self.maskLayer.locations = [0, topPosition, bottomPosition, 1] as [NSNumber]
        self.maskLayer.bounds = self.layer.bounds
        self.layer.mask = self.maskLayer
    }
}
