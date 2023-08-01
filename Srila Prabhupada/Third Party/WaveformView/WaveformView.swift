//
//  WaveformView.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 8/1/23.
//

import UIKit

final class WaveformView: UIView {

    @IBOutlet private var backgroundImageView: UIImageView!
    @IBOutlet private var foregroundImageView: UIImageView!

    private let waveformImageDrawer = WaveformImageDrawer()

    var audioURL: URL? {
        didSet {
            waveformImageDrawer.analyzer?.cancelLoading()

            backgroundImageView.image = nil
            foregroundImageView.image = nil
            progress = 0
            if let audioURL = audioURL {
                self.isHidden = false
                updateWaveformImages(audioURL: audioURL)
            } else {
                self.isHidden = true
            }
        }
    }

    var progress: Float = 0 {
        didSet {
            let fullRect = foregroundImageView.bounds
            let newWidth = fullRect.size.width * CGFloat(progress)

            let maskLayer = CAShapeLayer()
            let maskRect = CGRect(x: 0.0, y: 0.0, width: newWidth, height: fullRect.height)

            let path = CGPath(rect: maskRect, transform: nil)
            maskLayer.path = path

            foregroundImageView.layer.mask = maskLayer
        }
    }

    private func updateWaveformImages(audioURL: URL) {

        let waveformConfiguration = Waveform.Configuration(
            size: foregroundImageView.bounds.size,
            style: .striped(.init(color: self.tintColor, width: 3, spacing: 2))
        )

        waveformImageDrawer.waveformImage(fromAudioAt: audioURL,
                                          with: waveformConfiguration,
                                          renderer: LinearWaveformRenderer(),
                                          completionHandler: { image in
            DispatchQueue.main.async {
                self.backgroundImageView.image = image?.withRenderingMode(.alwaysTemplate)
                self.foregroundImageView.image = image?.withRenderingMode(.alwaysTemplate)
            }
        })
    }

}
