//
//  PlayerViewController.swift
//  Srila Prabhupada
//
//  Created by IE06 on 01/10/22.
//

import AVFoundation
import AVKit
import AlamofireImage
import IQListKit
import FirebaseFirestore

class PlayerViewController: LectureViewController {

    enum State {
        case close
        case minimize
        case expanded
    }

    @IBOutlet private var thumbnailImageView: UIImageView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var verseLabel: UILabel!
    @IBOutlet private var languageLabel: UILabel!
    @IBOutlet private var categoryLabel: UILabel!
    @IBOutlet private var locationLabel: UILabel!
    @IBOutlet private var dateLabel: UILabel!
    @IBOutlet private var firstDotLabel: UILabel?
    @IBOutlet private var secondDotLabel: UILabel?

    @IBOutlet private var currentTimeLabel: UILabel!
    @IBOutlet private var totalTimeLabel: UILabel!
    @IBOutlet private var timeSlider: UISlider!

    @IBOutlet private var playPauseButton: UIButton!
    @IBOutlet private var speedMenuButton: UIButton!

    @IBOutlet private var previousLectureButton: UIButton!
    @IBOutlet private var nextLectureButton: UIButton!

    @IBOutlet private var loopLectureButton: UIButton!
    @IBOutlet private var shuffleLectureButton: UIButton!

    @IBOutlet private var miniPlayerView: MiniPlayerView!
    @IBOutlet private var fullPlayerContainerView: UIView!

    private let playerContainerView: UIView = UIView()

    var itemStatusObserver: NSKeyValueObservation?
    var itemDidPlayToEndObserver: AnyObject?

    private var isSeeking = false
    var player: AVPlayer! {
        willSet {
            if let item = player?.currentItem {
                removePlayerItemNotificationObserver(item: item)
            }
        }
        didSet {
            addPeriodicTimeObserver()
            if let item = player?.currentItem {
                addPlayerItemNotificationObserver(item: item)
            }
        }
    }

    var visibleState: State = .close

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

    var currentLecture: Model? {
        didSet {
            loadViewIfNeeded()

            miniPlayerView.currentLecture = currentLecture

            self.pause()
            if let currentLecture = currentLecture {
                titleLabel.text = currentLecture.titleDisplay
                verseLabel.text = currentLecture.legacyData.verse
                languageLabel.text = currentLecture.language.main
                let categoryString = currentLecture.category.joined(separator: ", ")
                categoryLabel.text = categoryString
                locationLabel.text = currentLecture.location.displayString
                dateLabel.text = currentLecture.dateOfRecording.display_dd_MMM_yyyy
                timeSlider.maximumValue = Float(currentLecture.lengthTime.totalSeconds)
                totalTimeLabel.text = currentLecture.lengthTime.displayString

                if !currentLecture.location.displayString.isEmpty {
                    locationLabel?.text = currentLecture.location.displayString
                } else {
                    locationLabel?.text = currentLecture.place.joined(separator: ", ")
                }

                firstDotLabel?.isHidden = currentLecture.legacyData.verse.isEmpty || categoryString.isEmpty
                secondDotLabel?.isHidden = locationLabel?.text?.isEmpty ?? true

                if let url = currentLecture.thumbnailURL {
                    thumbnailImageView.af.setImage(withURL: url, placeholderImage: UIImage(named: "logo_40"))
                } else {
                    thumbnailImageView.image = UIImage(named: "logo_40")
                }

                if currentLecture.downloadingState == .downloaded,
                   let audioURL = currentLecture.localFileURL {
                    let item = AVPlayerItem(url: audioURL)
                    player = AVPlayer(playerItem: item)
                } else if let firstAudio = currentLecture.resources.audios.first,
                          let audioURL = firstAudio.audioURL {
                    let item = AVPlayerItem(url: audioURL)
                    player = AVPlayer(playerItem: item)
                }

                if let index = playlistLectures.firstIndex(where: { $0.id == currentLecture.id && $0.creationTimestamp == currentLecture.creationTimestamp }) {
                    previousLectureButton.isEnabled = (index != 0)
                    nextLectureButton.isEnabled = (index+1 < playlistLectures.count)
                } else {
                    previousLectureButton.isEnabled = false
                    nextLectureButton.isEnabled = false
                }
                if visibleState == .close {
                    minimize(animated: true)
                }
            } else {
                previousLectureButton.isEnabled = false
                nextLectureButton.isEnabled = false

                titleLabel.text = "--"
                verseLabel.text = "--"
                languageLabel.text = "--"
                categoryLabel.text = "--"
                locationLabel.text = "--"
                dateLabel.text = "--"
                firstDotLabel?.isHidden = false
                secondDotLabel?.isHidden = false
                timeSlider.maximumValue = 0
                close(animated: true)
            }
        }
    }

    var playlistLectures: [Model] = [] {
        didSet {
            loadViewIfNeeded()
            refreshAsynchronous(source: .cache)
        }
    }

    override func viewDidLoad() {

        list.registerCell(type: Cell.self, registerType: .storyboard)

        super.viewDidLoad()

        configurePlayRateMenu()

        do {
            loopLectureButton.isSelected = false
            shuffleLectureButton.isSelected = false
        }

        do {
            miniPlayerView.delegate = self
        }

        timeSlider.setThumbImage(UIImage(compatibleSystemName: "circle.fill"), for: .normal)
        do {
            self.playerContainerView.clipsToBounds = true
        }

        do {
            let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(swipeRecognized(_:)))
            swipeGesture.direction = .down
            self.view.addGestureRecognizer(swipeGesture)
        }
    }

    @objc private func swipeRecognized(_ sender: UISwipeGestureRecognizer) {
        if sender.state == .ended {
            minimize(animated: true)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func refreshAsynchronous(source: FirestoreSource) {
        super.refreshAsynchronous(source: source)

        reloadData(with: self.playlistLectures)
    }

    @IBAction func backButtonTapped(_ sender: UIButton) {
        minimize(animated: true)
    }

    func addToTabBarController(_ tabBarController: UITabBarController) {
        loadViewIfNeeded()

        do {
            tabBarController.addChild(self)
            self.view.frame = tabBarController.view.bounds
            self.view.autoresizingMask = []
            tabBarController.view.addSubview(playerContainerView)
            self.playerContainerView.addSubview(self.view)
            self.didMove(toParent: tabBarController)
        }
        close(animated: false)
    }

    func reposition() {

        switch self.visibleState {
        case .close:
            close(animated: true)
        case .minimize:
            minimize(animated: true)
        case .expanded:
            expand(animated: true)
        }
    }

    func expand(animated: Bool) {

        guard let tabBarController = self.parent as? UITabBarController else {
            return
        }

        tabBarController.view.insertSubview(playerContainerView, aboveSubview: tabBarController.tabBar)

        let middleAnimationBlock = { [self] in
            miniPlayerView.alpha = 0.0
            fullPlayerContainerView.alpha = 1.0
        }

        let animationBlock = { [self] in
            playerContainerView.frame = tabBarController.view.bounds
        }

        visibleState = .expanded
        setNeedsStatusBarAppearanceUpdate()
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [], animations: middleAnimationBlock)
            UIView.animate(withDuration: 0.6, delay: 0.0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.3, options: .curveEaseInOut, animations: animationBlock)
        } else {
            middleAnimationBlock()
            animationBlock()
        }
    }

    func minimize(animated: Bool) {

        guard let tabBarController = self.parent as? UITabBarController else {
            return
        }

        let middleAnimationBlock = { [self] in
            miniPlayerView.alpha = 1.0
            fullPlayerContainerView.alpha = 0.0
        }

        let animationBlock = { [self] in
            let y = tabBarController.tabBar.frame.minY - 60
            let rect = CGRect(x: 0, y: y, width: tabBarController.view.frame.width, height: 60)
            playerContainerView.frame = rect
        }

        let options: UIView.AnimationOptions
        if visibleState == .close {
            options = .curveEaseOut
        } else {
            options = .curveEaseInOut
        }

        visibleState = .minimize
        setNeedsStatusBarAppearanceUpdate()
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [], animations: middleAnimationBlock)
            UIView.animate(withDuration: 0.6, delay: 0.0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.1, options: options, animations: animationBlock)
        } else {
            animationBlock()
        }
    }

    func close(animated: Bool) {

        guard let tabBarController = self.parent as? UITabBarController else {
            return
        }

        tabBarController.view.insertSubview(playerContainerView, belowSubview: tabBarController.tabBar)

        let animationBlock = { [self] in
            let y = tabBarController.tabBar.frame.minY
            let rect = CGRect(x: 0, y: y, width: tabBarController.view.frame.width, height: 60)
            playerContainerView.frame = rect
            miniPlayerView.alpha = 1.0
            fullPlayerContainerView.alpha = 0.0
        }

        visibleState = .close
        setNeedsStatusBarAppearanceUpdate()
        if animated {
            UIView.animate(withDuration: 0.6, delay: 0.0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.1, options: .curveEaseInOut, animations: animationBlock)
        } else {
            animationBlock()
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        switch visibleState {
        case .close:
            return .lightContent
        case .minimize:
            return .lightContent
        case .expanded:
            return .darkContent
        }
    }

    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }
}

extension PlayerViewController {

    var isPaused: Bool {
        player?.rate == 0.0
    }

    func play() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, policy: .longFormAudio)
        try? AVAudioSession.sharedInstance().setActive(true)
        player?.play()
        player?.rate = self.selectedRate.rate
        playPauseButton.setImage(UIImage(compatibleSystemName: "pause.fill"), for: .normal)
        miniPlayerView.isPlaying = true
    }

    func pause() {
        player?.pause()
        playPauseButton.setImage(UIImage(compatibleSystemName: "play.fill"), for: .normal)
        miniPlayerView.isPlaying = false

        try? AVAudioSession.sharedInstance().setCategory(.ambient)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    func seekTo(seconds: Int) {
        let seconds: Int64 = Int64(seconds)
        let targetTime: CMTime = CMTimeMake(value: seconds, timescale: 1)

        isSeeking = true
        player?.seek(to: targetTime, completionHandler: { _ in
            self.isSeeking = false
        })
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

        guard let player = player else { return }

        player.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1, preferredTimescale: 1), queue: DispatchQueue.main) { [self] (time) -> Void in
            if player.currentItem?.status == .readyToPlay {
                let time: Float64 = CMTimeGetSeconds(time)
                if !timeSlider.isTracking && !isSeeking {
                    timeSlider.value = Float(time)
                    miniPlayerView.playedSeconds = timeSlider.value
                }
            }
            currentTimeLabel.text = Int(timeSlider.value).toHHMMSS
        }
    }
}

extension PlayerViewController {

    @IBAction func backwardXSecondsPressed(_ sender: UIButton) {
        guard let player = player else { return }

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
        guard let player = player else { return }

        guard let duration = player.currentItem?.duration else { return }
        let currentTime = CMTimeGetSeconds(player.currentTime())
        let newTime = currentTime + 10.0

        if newTime < (CMTimeGetSeconds(duration) - 10.0) {
            seekTo(seconds: Int(newTime))
        }
    }
}

extension PlayerViewController {

    private func removePlayerItemNotificationObserver(item: AVPlayerItem) {
        self.itemStatusObserver?.invalidate()
        if let itemDidPlayToEndObserver = itemDidPlayToEndObserver {
            NotificationCenter.default.removeObserver(itemDidPlayToEndObserver, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: item)
        }
    }

    private func addPlayerItemNotificationObserver(item: AVPlayerItem) {

        self.itemStatusObserver = item.observe(\.status, options: [.new, .old], changeHandler: { [self] (playerItem, change) in
            if playerItem.status == .readyToPlay {

                if playerItem.duration.isValid {
                    let duration = CMTimeGetSeconds(playerItem.duration)
                    let time = Time(totalSeconds: Int(duration))
                    timeSlider.maximumValue = Float(duration)
                    totalTimeLabel.text = time.displayString
                    miniPlayerView.lectureDuration = time
                }
            }
        })

        itemDidPlayToEndObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: item, queue: nil) { [self] _ in
            if loopLectureButton.isSelected == true {
                player.seek(to: CMTime.zero)
            } else if shuffleLectureButton.isSelected == true {
                if currentLecture != nil {
                    let newLecture = playlistLectures.randomElement()
                    self.currentLecture = newLecture
                }
            } else {
                if let currentLecture = currentLecture,
                   let index = playlistLectures.firstIndex(where: { $0.id == currentLecture.id && $0.creationTimestamp == currentLecture.creationTimestamp }), (index+1) < playlistLectures.count {
                    let newLecture = playlistLectures[index+1]
                    self.currentLecture = newLecture
                }
            }
            play()
        }
    }

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

    @IBAction func loopLectureButtonPressed(_ sender: UIButton) {
        if loopLectureButton.isSelected == true {
            loopLectureButton.isSelected = false
        } else {
            loopLectureButton.isSelected = true
            shuffleLectureButton.isSelected = false
        }
    }

    @IBAction func shuffleLectureButtonPressed(_ sender: UIButton) {
        if shuffleLectureButton.isSelected == true {
            shuffleLectureButton.isSelected = false
        } else {
            loopLectureButton.isSelected = false
            shuffleLectureButton.isSelected = true
        }
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
            player?.rate = playRate.rate
        }
        speedMenuButton.setTitle(playRate.rawValue, for: .normal)
    }
}

extension PlayerViewController: MiniPlayerViewDelegate {
    func miniPlayerViewDidClose(_ playerView: MiniPlayerView) {
        self.currentLecture = nil
        self.playlistLectures = []
    }

    func miniPlayerView(_ playerView: MiniPlayerView, didSeekTo seconds: Int) {
        seekTo(seconds: seconds)
    }

    func miniPlayerView(_ playerView: MiniPlayerView, didChangePlay isPlay: Bool) {
        if isPlay {
            play()
        } else {
            pause()
        }
    }

    func miniPlayerViewDidExpand(_ playerView: MiniPlayerView) {
        expand(animated: true)
    }
}
