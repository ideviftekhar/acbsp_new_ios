//
//  MiniPlayerView.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 10/7/22.
//

import UIKit
import AlamofireImage
import MarqueeLabel

protocol MiniPlayerViewDelegate: AnyObject {
    func miniPlayerViewDidExpand(_ playerView: MiniPlayerView)
    func miniPlayerViewDidClose(_ playerView: MiniPlayerView)
    func miniPlayerView(_ playerView: MiniPlayerView, didChangePlay isPlay: Bool)
    func miniPlayerView(_ playerView: MiniPlayerView, didSeekTo seconds: Int)
}

class MiniPlayerView: UIView {

    static let miniPlayerHeight: CGFloat = {

        switch Environment.current.device {
        case .mac, .pad:
            return 90
        default:
            return 64
        }
    }()
    
    @IBOutlet private var thumbnailImageView: UIImageView!
    @IBOutlet private var titleLabel: MarqueeLabel!
    @IBOutlet private var verseLabel: UILabel!
    @IBOutlet private var durationLabel: UILabel!
    @IBOutlet private var locationLabel: UILabel!
    @IBOutlet private var dateLabel: UILabel!
    @IBOutlet private var expandButton: UIButton!
    @IBOutlet private var playButton: UIButton!
    @IBOutlet internal var progressView: UIProgressView!
    @IBOutlet private var firstDotLabel: UILabel?
    @IBOutlet private var secondDotLabel: UILabel?

    @IBOutlet internal var currentTimeLabel: UILabel!
    @IBOutlet private var heightConstraint: NSLayoutConstraint!

    internal lazy var seekGesture = UIPanGestureRecognizer(target: self, action: #selector(panRecognized(_:)))
    var direction: UISwipeGestureRecognizer.Direction = .down

    weak var delegate: MiniPlayerViewDelegate?

    var playFillImage = UIImage(systemName: "play.fill")
    var pauseFillImage = UIImage(systemName: "pause.fill")
    
    static func loadFromXIB() -> MiniPlayerView {
        let playerView = Bundle.main.loadNibNamed("MiniPlayerView", owner: nil)?.first as! MiniPlayerView
        return playerView
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.type = .continuous
        titleLabel.speed = .duration(10)
        titleLabel.fadeLength = 10.0
        titleLabel.trailingBuffer = 30.0
        seekGesture.delegate = self
        expandButton.addGestureRecognizer(seekGesture)

        switch Environment.current.device {
        case .mac:
            playFillImage = UIImage(named: "play.fill")
            pauseFillImage = UIImage(named: "pause.fill")
            let newImage: UIImage? = isPlaying ? pauseFillImage :  playFillImage
            playButton.setImage(newImage, for: .normal)
        default:
            break
        }
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
        }
    }

    var playedSeconds: Float = 0 {
        didSet {
            let totalSeconds: Int = lectureDuration.totalSeconds
            if totalSeconds > 0 {

                if seekGesture.state != .changed {

                    currentTimeLabel.text = Int(playedSeconds).toHHMMSS

                    progressView.progress = playedSeconds / Float(totalSeconds)
                }
            }
        }
    }

    var isPlaying: Bool = false {
        didSet {
            let newImage: UIImage? = isPlaying ? pauseFillImage :  playFillImage
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

