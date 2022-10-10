//
//  PlayerViewController.swift
//  Srila Prabhupada
//
//  Created by IE06 on 01/10/22.
//

import AVFoundation
import AVKit

class PlayerViewController: UIViewController {

    @IBOutlet weak var lectureTitleLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var totalTimeLabel: UILabel!

    @IBOutlet weak var timeSlider: UISlider!

    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var speedMenuButton: UIButton!

    @IBOutlet weak var previousLectureButton: UIButton!
    @IBOutlet weak var nextLectureButton: UIButton!

    var player: AVPlayer! {
        didSet {
            addPeriodicTimeObserver()
        }
    }

    var miniPlayerView: MiniPlayerView = MiniPlayerView.loadFromXIB()

    var playRateMenu: UIMenu!
    var selectedRate: PlayRate {
        if #available(iOS 15.0, *) {
            guard let selectedSortAction = playRateMenu.selectedElements.first as? UIAction,
                  let selectedPlayRate = PlayRate(rawValue: selectedSortAction.identifier.rawValue) else {
                return PlayRate.one
            }
            return selectedPlayRate
        } else {
            guard let children: [UIAction] = playRateMenu.children as? [UIAction],
                  let selectedSortAction = children.first(where: { $0.state == .on }),
                    let selectedPlayRate = PlayRate(rawValue: selectedSortAction.identifier.rawValue) else {
                return PlayRate.one
            }
            return selectedPlayRate
        }
    }

    var currentLecture: Lecture? {
        didSet {
            loadViewIfNeeded()

            miniPlayerView.currentLecture = currentLecture

            if let currentLecture = currentLecture {
                lectureTitleLabel.text = currentLecture.titleDisplay
                totalTimeLabel.text = currentLecture.lengthTime.displayString
                timeSlider.maximumValue = Float(currentLecture.lengthTime.totalSeconds)

                if currentLecture.downloadingState == .downloaded,
                   let audioURL = currentLecture.localFileURL {
                    player = AVPlayer(url: audioURL)
                } else if let firstAudio = currentLecture.resources.audios.first,
                          let audioURL = firstAudio.audioURL {
                    player = AVPlayer(url: audioURL)
                } else {
                    pause()
                }

                if let index = playlistLectures.firstIndex(where: { $0.id == currentLecture.id && $0.creationTimestamp == currentLecture.creationTimestamp }) {
                    previousLectureButton.isEnabled = (index != 0)
                    nextLectureButton.isEnabled = (index+1 < playlistLectures.count)
                } else {
                    previousLectureButton.isEnabled = false
                    nextLectureButton.isEnabled = false
                }
            } else {
                previousLectureButton.isEnabled = false
                nextLectureButton.isEnabled = false

                lectureTitleLabel.text = "--"
                totalTimeLabel.text = "--"
                timeSlider.maximumValue = 0
            }
        }
    }

    var playlistLectures: [Lecture] = []

    override func viewDidLoad() {

        super.viewDidLoad()

        configurePlayRateMenu()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    @IBAction func backButtonTapped(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension PlayerViewController {

    var isPaused: Bool {
        player.rate == 0.0
    }

    func play() {
        player.play()
        player.rate = self.selectedRate.rate
        playPauseButton.setImage(UIImage(compatibleSystemName: "pause.fill"), for: .normal)
        miniPlayerView.isPlaying = true
    }

    func pause() {
        player.pause()
        playPauseButton.setImage(UIImage(compatibleSystemName: "play.fill"), for: .normal)
        miniPlayerView.isPlaying = false
    }

    func seekTo(seconds: Int) {
        let seconds: Int64 = Int64(seconds)
        let targetTime: CMTime = CMTimeMake(value: seconds, timescale: 1)

        player.seek(to: targetTime)
    }
}

extension PlayerViewController {

    @IBAction func playPauseButtonTapped(_ sender: UIButton) {
        if isPaused {
            play()
        } else {
            pause()
        }
    }

    private func addPeriodicTimeObserver() {

        player.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1, preferredTimescale: 1), queue: DispatchQueue.main) { [self] (time) -> Void in
            if player.currentItem?.status == .readyToPlay {
                let time: Float64 = CMTimeGetSeconds(time)
                if !timeSlider.isTracking {
                    timeSlider.value = Float(time)
                    miniPlayerView.playedSeconds = timeSlider.value
                }
            }
            let timeDisplay = timeDisplay(totalSecond: Int(timeSlider.value))
            timeLabel.text = timeDisplay
        }
    }
}

extension PlayerViewController {

    @IBAction func backwardXSecondsPressed(_ sender: UIButton) {
        let currentTime = CMTimeGetSeconds(player.currentTime())
        var newTime = currentTime - 10.0
        if newTime < 0 {
            newTime = 0
        }

        seekTo(seconds: Int(newTime))
    }

    @IBAction func timeSlider(_ sender: UISlider) {
        seekTo(seconds: Int(sender.value))
    }

    @IBAction func forwardXSecondPressed(_ sender: UIButton) {
        guard let duration = player.currentItem?.duration else { return }
        let currentTime = CMTimeGetSeconds(player.currentTime())
        let newTime = currentTime + 10.0

        if newTime < (CMTimeGetSeconds(duration) - 10.0) {
            seekTo(seconds: Int(newTime))
        }
    }
}

extension PlayerViewController {

    @IBAction func nextLecturePressed(_ sender: UIButton) {

        if let currentLecture = currentLecture,
           let index = playlistLectures.firstIndex(where: { $0.id == currentLecture.id && $0.creationTimestamp == currentLecture.creationTimestamp }), (index+1) < playlistLectures.count {

            let newLecture = playlistLectures[index+1]
            self.currentLecture = newLecture
            play()
        }
    }

    @IBAction func previousLecturePressed(_ sender: UIButton) {

        if let currentLecture = currentLecture,
           let index = playlistLectures.firstIndex(where: { $0.id == currentLecture.id && $0.creationTimestamp == currentLecture.creationTimestamp }), index > 0 {

            let newLecture = playlistLectures[index-1]
            self.currentLecture = newLecture
            play()
        }
    }
}

extension PlayerViewController {

    private func timeDisplay(totalSecond: Int) -> String {
        var hour = Int()
        var minute = Int()
        var second = totalSecond

        if second >=  60 {
            minute = second/60
            second = second%60
            if minute >= 60 {
                hour = minute/60
                minute = minute%60
            }
        }
        var time: String {
            if hour <= 0 {
                return String(format: "%02i:%02i", minute, second)
            } else {
                return String(format: "%02i:%02i:%02i", hour, minute, second)
            }
        }
        return time
    }
}

extension PlayerViewController {

    private func configurePlayRateMenu() {
        var actions: [UIAction] = []

        let userDefaultKey: String = "\(Self.self).\(PlayRate.self)"
        let lastRate: PlayRate

        if let rateString = UserDefaults.standard.string(forKey: userDefaultKey), let type = PlayRate(rawValue: rateString) {
            lastRate = type
        } else {
            lastRate = .one
        }

        for playRate in PlayRate.allCases {

            let state: UIAction.State = (lastRate == playRate ? .on : .off)

            let action: UIAction = UIAction(title: playRate.rawValue, image: nil, identifier: UIAction.Identifier(playRate.rawValue), state: state, handler: { [self] action in
                playRateActionSelected(action: action)
            })

            actions.append(action)
        }

        self.playRateMenu = UIMenu(title: "", image: nil, identifier: UIMenu.Identifier.init(rawValue: "PlayRate"), options: UIMenu.Options.displayInline, children: actions)

        if #available(iOS 14.0, *) {
            speedMenuButton.menu = self.playRateMenu
            speedMenuButton.showsMenuAsPrimaryAction = true
        } else {
            speedMenuButton.addTarget(self, action: #selector(playRateActioniOS13(_:)), for: .touchUpInside)
        }

        let playRate = self.selectedRate
        speedMenuButton.setTitle(playRate.rawValue, for: .normal)
    }

    // Backward compatibility for iOS 13
    @objc private func playRateActioniOS13(_ sender: UIBarButtonItem) {

        var buttons: [UIViewController.ButtonConfig] = []
        let actions: [UIAction] = self.playRateMenu.children as? [UIAction] ?? []
        for action in actions {
            buttons.append((title: action.title, handler: { [self] in
                playRateActionSelected(action: action)
            }))
        }

        self.showAlert(title: "Play Rate", message: "", preferredStyle: .actionSheet, buttons: buttons)
    }

    private func playRateActionSelected(action: UIAction) {
        let userDefaultKey: String = "\(Self.self).\(PlayRate.self)"
        let actions: [UIAction] = self.playRateMenu.children as? [UIAction] ?? []
       for anAction in actions {
            if anAction.identifier == action.identifier { anAction.state = .on  } else {  anAction.state = .off }
        }

        UserDefaults.standard.set(action.identifier.rawValue, forKey: userDefaultKey)
        UserDefaults.standard.synchronize()

        self.playRateMenu = self.playRateMenu.replacingChildren(actions)

        if #available(iOS 14.0, *) {
            self.speedMenuButton.menu = self.playRateMenu
        }

        let playRate = self.selectedRate
        if !isPaused {
            player.rate = playRate.rate
        }
        speedMenuButton.setTitle(playRate.rawValue, for: .normal)
    }
}
