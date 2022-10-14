//
//  MiniPlayerView.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 10/7/22.
//

import UIKit
import AlamofireImage

protocol MiniPlayerViewDelegate: AnyObject {
    func miniPlayerViewDidExpand(_ playerView: MiniPlayerView)
    func miniPlayerViewDidClose(_ playerView: MiniPlayerView)
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
    @IBOutlet private var firstDotLabel: UILabel?
    @IBOutlet private var secondDotLabel: UILabel?

    @IBOutlet private var currentTimeLabel: UILabel!

    private lazy var seekGesture = UIPanGestureRecognizer(target: self, action: #selector(panRecognized(_:)))

    var direction: UISwipeGestureRecognizer.Direction = .down

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
                lectureDuration = model.lengthTime
                dateLabel.text = model.dateOfRecording.display_dd_MMM_yyyy
                currentTimeLabel.text = 0.toHHMMSS

                if !model.legacyData.verse.isEmpty {
                    verseLabel?.text = model.legacyData.verse
                } else {
                    verseLabel?.text = model.category.joined(separator: ", ")
                }

                if !model.location.displayString.isEmpty {
                    locationLabel?.text = model.location.displayString
                } else {
                    locationLabel?.text = model.place.joined(separator: ", ")
                }

                firstDotLabel?.isHidden = verseLabel?.text?.isEmpty ?? true
                secondDotLabel?.isHidden = locationLabel?.text?.isEmpty ?? true

                if let url = model.thumbnailURL {
                    thumbnailImageView.af.setImage(withURL: url, placeholderImage: UIImage(named: "logo_40"))
                } else {
                    thumbnailImageView.image = UIImage(named: "logo_40")
                }

                progressView.progress = 0
            } else {
                lectureDuration = Time(totalSeconds: 0)
                titleLabel.text = "--"
                verseLabel.text = "--"
                durationLabel.text = "--"
                locationLabel.text = "--"
                dateLabel.text = "--"
                currentTimeLabel.text = "--"

                firstDotLabel?.isHidden = false
                secondDotLabel?.isHidden = false
                thumbnailImageView.image = UIImage(named: "logo_40")
                progressView.progress = 0
            }
        }
    }

    var lectureDuration: Time = Time(totalSeconds: 0) {
        didSet {
            durationLabel.text = lectureDuration.displayString
            progressView.isHidden = lectureDuration.totalSeconds == 0
            progressView.progress = 0
        }
    }

    var playedSeconds: Float = 0 {
        didSet {
            let totalSeconds: Int = lectureDuration.totalSeconds
            if totalSeconds > 0 {
                let progress = playedSeconds / Float(totalSeconds)
                if seekGesture.state != .changed {

                    currentTimeLabel.text = Int(playedSeconds).toHHMMSS

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
        let totalSeconds: Float = Float(lectureDuration.totalSeconds)
        let seekProgress: Float = Float(translation.x / self.bounds.width)
        let maxSeekSeconds: Float = totalSeconds // 10*60 // 10 minutes
        let changedSeconds: Float = maxSeekSeconds*seekProgress
        var proposedSeek: Float = playedSeconds + changedSeconds
        proposedSeek = Float.maximum(proposedSeek, 0)
        proposedSeek = Float.minimum(proposedSeek, totalSeconds-1.0)    // 1 seconds to not reach at the end instantly

        switch sender.state {
        case .began:
            let velocity = seekGesture.velocity(in: self)

            if abs(velocity.x) >= abs(velocity.y) {
                if velocity.x < 0 {
                    direction = .left
                } else {
                    direction = .right
                }
            } else if abs(velocity.x) < abs(velocity.y) {
                if velocity.y < 0 {
                    direction = .up
                } else {
                    direction = .down
                }

            } else {
                direction = .right
            }

        case .changed:
            switch direction {
            case .left, .right:
                progressView.progress =  proposedSeek / totalSeconds
                currentTimeLabel.text = Int(proposedSeek).toHHMMSS
            case .up, .down:
                break
            default:
                break
            }
        case .ended, .cancelled:

            switch direction {
            case .left, .right:
                delegate?.miniPlayerView(self, didSeekTo: Int(proposedSeek))
            case .up, .down:

                let velocity = seekGesture.velocity(in: self)

                if velocity.y < 0 && abs(velocity.y) > 250 {
                    delegate?.miniPlayerViewDidExpand(self)
                } else if velocity.y > 0 && abs(velocity.y) > 250 {
                    delegate?.miniPlayerViewDidClose(self)
                }

            default:
                break
            }

        case .possible, .failed:
            break
        @unknown default:
            break
        }
    }
}
