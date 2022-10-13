//
//  SPAudioVisualizerView.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 10/13/22.
//

import UIKit

class SPAudioVisualizerView: UIView {

    private var barViews: [UIView] = []
    private var waveForms: [Int] = []
    private var initialBarHeight: CGFloat = .zero
    private let animationDuration: TimeInterval = 0.15
    private let barsCount: Int

    init(frame: CGRect, barsCount: Int) {

        self.barsCount = barsCount
        super.init(frame: frame)
        self.setupEqualizerBars()
    }

    required init?(coder: NSCoder) {
        self.barsCount = 6

        super.init(coder: coder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        setupEqualizerBars()
    }

    func updateWithLevel(level: CGFloat) {

    }

    override func tintColorDidChange() {
        super.tintColorDidChange()

        for view in barViews {
            view.backgroundColor = self.tintColor
         }
    }

    func setupEqualizerBars() {
        let padding: CGFloat = (self.frame.size.width / CGFloat(self.barsCount)) / 3
        let rectHeight: CGFloat = self.frame.size.height-padding
        let rectWidth: CGFloat = (self.frame.size.width-padding*CGFloat(self.barsCount+1))/CGFloat(self.barsCount)

        let peaks: [Int] = [5,10,15,10,5]
        for i in 0..<self.barsCount {

            let rectangle: UIView = UIView()
            let rectFrame: CGRect = CGRect(x: padding+(padding+rectWidth)*CGFloat(i), y: padding+(rectHeight-rectWidth), width: rectWidth, height: rectWidth)
            initialBarHeight = rectWidth

            rectangle.frame = rectFrame
            rectangle.backgroundColor = self.tintColor
            rectangle.layer.cornerRadius = rectWidth / 2

            self.addSubview(rectangle)
            barViews.append(rectangle)

            waveForms.append(peaks[i%peaks.count])
         }
    }

    func animate(level_0: CGFloat, level_1: CGFloat) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: self.animationDuration, delay: 0, options: .beginFromCurrentState, animations: {

                for i in 0..<self.barsCount {

                    let channelValue: Int = (0...1).randomElement() ?? 0
                    let wavePeak: CGFloat = CGFloat((0...self.waveForms[i]).randomElement() ?? 0)

                    let barView: UIView = self.barViews[i]

                    var barFrame: CGRect = barView.frame
                    if channelValue == 0 {
                        barFrame.size.height = self.frame.size.height - (1 / level_0 * 13) + wavePeak
                    } else {
                        barFrame.size.height = self.frame.size.height - (1 / level_1 * 13) + wavePeak
                    }

                    if barFrame.size.height < 4 || barFrame.size.height > self.frame.size.height {
                        barFrame.size.height = self.initialBarHeight + CGFloat(wavePeak)
                    }

                    barFrame.origin.y = self.frame.size.height - barFrame.size.height
                    barView.frame = barFrame
                }
            })
        }
    }

    func stop() {
        DispatchQueue.main.async {

            UIView.animate(withDuration: self.animationDuration, delay: 0, options: .beginFromCurrentState, animations: {

                for i in 0..<self.barsCount {

                    let barView: UIView = self.barViews[i]

                    var barFrame:CGRect = barView.frame
                    barFrame.size.height = self.initialBarHeight
                    barFrame.origin.y = self.frame.size.height - barFrame.size.height
                    barView.frame = barFrame
                }
            })
        }
    }
}
