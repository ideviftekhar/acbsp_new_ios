//
//  ESTMusicIndicatorContentView.swift
//  ESTMusicIndicator
//
//  Created by Aufree on 12/6/15.
//  Copyright © 2015 The EST Group. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import UIKit

final class ESTMusicIndicatorContentView: UIView {

    private let kBarCount = 6
    private let kBarHeighRatio: [CGFloat] = [0.25, 0.4, 0.55, 0.7, 0.85, 1.0]
    private let kBarWidth: CGFloat = 2.0
    private let kHorizontalBarSpacing: CGFloat = 1.5
    private let kBarMaxPeakHeight: CGFloat = 12.0

    private var barLayers = [UIView]()
    private var hasInstalledConstraints: Bool = false

    private(set) var isOscillating: Bool = false

    public var audioLevel: CGFloat = 0.0

    private var oscilationTimer: Timer?
    private let preferredTimerInterval: TimeInterval = 15.0/100.0

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false

        prepareBarLayers()
        tintColorDidChange()
        setNeedsUpdateConstraints()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        prepareBarLayers()
        tintColorDidChange()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    private func prepareBarLayers() {
        var xOffset: CGFloat = 0.0

        for _ in 1...kBarCount {
            let newLayer = createBarLayerWithXOffset(xOffset)
            barLayers.append(newLayer)
            self.addSubview(newLayer)
            xOffset = newLayer.frame.maxX + kHorizontalBarSpacing
        }
    }

    private var lastSize: CGSize = .zero
    override func layoutSubviews() {
        super.layoutSubviews()

        if !lastSize.equalTo(bounds.size) {
            lastSize = bounds.size

            UIView.animate(withDuration: 0.15, delay: 0, options: .beginFromCurrentState, animations: { [self] in
                for layer in barLayers {
                    var frame = layer.frame
                    frame.origin.y = (self.bounds.height - kBarWidth)/2
                    frame.size.height = kBarWidth
                    layer.frame = frame
                }
            })
        }
    }

    private func createBarLayerWithXOffset(_ xOffset: CGFloat) -> UIView {
        let layer: UIView = UIView()
        let yOffset = (self.bounds.height - kBarWidth)/2
        layer.frame = CGRect(x: xOffset, y: yOffset, width: kBarWidth, height: kBarWidth)
        layer.layer.cornerRadius = kBarWidth / 2
        layer.layer.masksToBounds = true
        return layer
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()
        for layer in barLayers {
            layer.backgroundColor = tintColor.withAlphaComponent(0.8)
        }
    }

    override var intrinsicContentSize: CGSize {
        var unionFrame: CGRect = CGRect.zero

        for layer in barLayers {
            unionFrame = unionFrame.union(layer.frame)
        }

        unionFrame.size.height = CGFloat.maximum(unionFrame.size.height, kBarMaxPeakHeight)

        return unionFrame.size
    }

    override func updateConstraints() {
        if !hasInstalledConstraints {
            let size = intrinsicContentSize
            addConstraint(NSLayoutConstraint(item: self,
                                        attribute: .width,
                                        relatedBy: .equal,
                                            toItem: nil,
                                        attribute: .notAnAttribute,
                                        multiplier: 0.0,
                                        constant: size.width))

            addConstraint(NSLayoutConstraint(item: self,
                                        attribute: .height,
                                        relatedBy: .equal,
                                        toItem: nil,
                                        attribute: .notAnAttribute,
                                        multiplier: 0.0,
                                        constant: size.height))
            hasInstalledConstraints = true
        }
        super.updateConstraints()
    }

    public func startOscillation() {

        guard !isOscillating else {
            return
        }

        isOscillating = true
        updateOscillatingBarLayer()

        oscilationTimer?.invalidate()
        oscilationTimer = Timer.scheduledTimer(withTimeInterval: preferredTimerInterval, repeats: true, block: { [self] _ in
            updateOscillatingBarLayer()
        })
        oscilationTimer?.fire()
        if let oscilationTimer = oscilationTimer {
            RunLoop.main.add(oscilationTimer, forMode: .common)
        }
    }

    public func stopOscillation() {

        guard isOscillating else {
            return
        }

        oscilationTimer?.invalidate()
        oscilationTimer = nil

        UIView.animate(withDuration: 0.15, delay: 0, options: .beginFromCurrentState, animations: { [self] in
            for layer in barLayers {
                var frame = layer.frame
                frame.origin.y = (self.bounds.height - kBarWidth)/2
                frame.size.height = kBarWidth
                layer.frame = frame
            }
        })

        isOscillating = false
    }

    @objc private func updateOscillatingBarLayer() {

        let channelValue = self.audioLevel
        let applicableValue = channelValue * 13
        let valueRange = kBarMaxPeakHeight - kBarWidth + 1

        let barHeightRatio = kBarHeighRatio.shuffled()

        UIView.animate(withDuration: 0.15, delay: 0, options: .beginFromCurrentState, animations: { [self] in
            for (index, layer) in barLayers.enumerated() {
                let peakHeight: CGFloat = CGFloat.minimum(kBarWidth + valueRange * applicableValue, kBarMaxPeakHeight)
                let modifiedHeight = CGFloat.maximum(peakHeight * barHeightRatio[index], kBarWidth)

                let y: CGFloat = (self.bounds.height - modifiedHeight)/2

                var frame = layer.frame
                frame.origin.y = y
                frame.size.height = modifiedHeight
                layer.frame = frame
            }
        })
    }
}
