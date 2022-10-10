//
//  MiniPlayerView.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 10/7/22.
//

import UIKit

protocol MiniPlayerViewDelegate: AnyObject {
    func miniPlayerViewDidExpand(_ playerView: MiniPlayerView)
    func miniPlayerView(_ playerView: MiniPlayerView, didChangePlay isPlay: Bool)
    func miniPlayerView(_ playerView: MiniPlayerView, didSeekTo seconds: Int)
}

class MiniPlayerView: UIView {

    @IBOutlet private var thumbnailImageView: UIImageView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var verseLabel: UILabel!
    @IBOutlet private var durationLabel: UILabel!
    @IBOutlet private var locationLabel: UILabel!
    @IBOutlet private var dateLabel: UILabel!
    @IBOutlet private var expandButton: UIButton!
    @IBOutlet private var playButton: UIButton!
    @IBOutlet private var progressView: UIProgressView!

    private lazy var seekGesture = UIPanGestureRecognizer(target: self, action: #selector(panRecognized(_:)))

    weak var delegate: MiniPlayerViewDelegate?

    static func loadFromXIB() -> MiniPlayerView {
        Bundle.main.loadNibNamed("MiniPlayerView", owner: nil)?.first as! MiniPlayerView
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        seekGesture.delegate = self
        expandButton.addGestureRecognizer(seekGesture)
    }

    var currentLecture: Lecture? {
        didSet {
            if let model = currentLecture {
                titleLabel.text = model.titleDisplay
                verseLabel.text = model.legacyData.verse
                durationLabel.text = model.lengthTime.displayString
                locationLabel.text = model.location.displayString
                dateLabel.text = model.dateOfRecording.display_yyyy_mm_dd

                if let url = model.thumbnailURL {
                    thumbnailImageView.af.setImage(withURL: url, placeholderImage: UIImage(named: "logo_40"))
                } else {
                    thumbnailImageView.image = UIImage(named: "logo_40")
                }

                let totalSeconds: Int = model.lengthTime.totalSeconds
                progressView.isHidden = totalSeconds == 0
                progressView.progress = 0
                self.isHidden = false
            } else {
                self.isHidden = true
            }
        }
    }

    var playedSeconds: Float = 0 {
        didSet {
            let totalSeconds: Int = currentLecture?.lengthTime.totalSeconds ?? 0
            if totalSeconds > 0 {
                let progress = playedSeconds / Float(totalSeconds)
                if seekGesture.state != .changed {
                    progressView.progress = progress
                }
            }
        }
    }

    var isPlaying: Bool = false {
        didSet {
            let newImage: UIImage? = isPlaying ? UIImage(compatibleSystemName: "pause.fill") : UIImage(compatibleSystemName: "play.fill")
            playButton.setImage(newImage, for: .normal)
        }
    }

    @IBAction private func playAction(_ sender: UIButton) {
        delegate?.miniPlayerView(self, didChangePlay: !isPlaying)
    }

    @IBAction private func expandAction(_ sender: UIButton) {
        delegate?.miniPlayerViewDidExpand(self)
    }
}

extension MiniPlayerView: UIGestureRecognizerDelegate {

    @objc private func panRecognized(_ sender: UIPanGestureRecognizer) {

        guard let model = currentLecture else {
            return
        }
        let translation = sender.translation(in: self)
        let totalSeconds: Float = Float(model.lengthTime.totalSeconds)
        let seekProgress: Float = Float(translation.x / self.bounds.width)
        let maxSeekSeconds: Float = totalSeconds // 10*60 // 10 minutes
        let changedSeconds: Float = maxSeekSeconds*seekProgress
        var proposedSeek: Float = playedSeconds + changedSeconds

        switch sender.state {
        case .began, .changed:
            progressView.progress =  proposedSeek / totalSeconds
        case .ended, .cancelled:
            proposedSeek = Float.maximum(proposedSeek, 0)
            proposedSeek = Float.minimum(proposedSeek, totalSeconds-1.0)    // 1 seconds to not reach at the end instantly

            delegate?.miniPlayerView(self, didSeekTo: Int(proposedSeek))
            progressView.progress =  proposedSeek / totalSeconds
        case .possible, .failed:
            break
        @unknown default:
            break
        }
    }

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {

        if gestureRecognizer == seekGesture {
            let velocity = seekGesture.velocity(in: self)

            return abs(velocity.x) > abs(velocity.y)
        } else {
            return false
        }
    }
}
