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
        let height: CGFloat
        if #available(iOS 14.0, *), #available(macCatalyst 14.0, *), UIDevice.current.userInterfaceIdiom == .mac {
            height = 90
        } else {
            height = 60
        }
        return height
    }()
    
    @IBOutlet private var thumbnailImageView: UIImageView!
    @IBOutlet private var titleLabel: MarqueeLabel!
    @IBOutlet private var verseLabel: UILabel!
    @IBOutlet private var durationLabel: UILabel!
    @IBOutlet private var locationLabel: UILabel!
    @IBOutlet private var dateLabel: UILabel!
    @IBOutlet private var expandButton: UIButton!
    @IBOutlet private var playButton: UIButton!
    @IBOutlet internal var timeSlider: UISlider!
    @IBOutlet private var firstDotLabel: UILabel?
    @IBOutlet private var secondDotLabel: UILabel?

    @IBOutlet internal var currentTimeLabel: UILabel!
    @IBOutlet private var heightConstraint: NSLayoutConstraint!

    internal lazy var seekGesture = UIPanGestureRecognizer(target: self, action: #selector(panRecognized(_:)))
    var direction: UISwipeGestureRecognizer.Direction = .down

    weak var delegate: MiniPlayerViewDelegate?

    var playFillImage = UIImage(compatibleSystemName: "play.fill")
    var pauseFillImage = UIImage(compatibleSystemName: "pause.fill")
    
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

        if #available(iOS 14.0, *), #available(macCatalyst 14.0, *), UIDevice.current.userInterfaceIdiom == .mac {
            playFillImage = UIImage(named: "playFill")
            pauseFillImage = UIImage(named: "pauseFill")
            let newImage: UIImage? = isPlaying ? pauseFillImage :  playFillImage
            playButton.setImage(newImage, for: .normal)
        }

        if #available(iOS 14.0, *) {
            if UIDevice.current.userInterfaceIdiom != .mac {
                timeSlider.setThumbImage(UIImage(), for: .normal)
            }
        } else {
            timeSlider.setThumbImage(UIImage(), for: .normal)
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

                timeSlider.value = 0
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
                timeSlider.value = 0
            }
        }
    }

    var lectureDuration: Time = Time(totalSeconds: 0) {
        didSet {
            durationLabel.text = lectureDuration.displayString
            timeSlider.isHidden = lectureDuration.totalSeconds == 0
            timeSlider.maximumValue = Float(lectureDuration.totalSeconds)
        }
    }

    var playedSeconds: Float = 0 {
        didSet {
            let totalSeconds: Int = lectureDuration.totalSeconds
            if totalSeconds > 0 {

                if seekGesture.state != .changed {

                    currentTimeLabel.text = Int(playedSeconds).toHHMMSS

                    timeSlider.value = playedSeconds
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

