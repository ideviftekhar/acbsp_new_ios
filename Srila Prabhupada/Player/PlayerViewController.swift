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

    class PlayStateObserver {
        let observer: NSObject
        var stateHandler: ((_ state: ESTMusicIndicatorViewState) -> Void)

        init(observer: NSObject, playStateHandler: @escaping ((_ state: ESTMusicIndicatorViewState) -> Void)) {
            self.observer = observer
            self.stateHandler = playStateHandler
        }
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
    var itemRateObserver: NSKeyValueObservation?
    var itemDidPlayToEndObserver: AnyObject?

    static var lecturePlayStateObservers = [Int: [PlayStateObserver]]()
    static var nowPlaying: (lecture: Lecture, state: ESTMusicIndicatorViewState)? {
        didSet {
            if nowPlaying?.lecture.id != oldValue?.lecture.id || nowPlaying?.state != oldValue?.state {

                if let lastPlaying = oldValue, lastPlaying.lecture.id != nowPlaying?.lecture.id, let observers = self.lecturePlayStateObservers[lastPlaying.lecture.id] {
                    for observer in observers {
                        observer.stateHandler(.stopped)
                    }
                }

                if let nowPlaying = nowPlaying, let observers = self.lecturePlayStateObservers[nowPlaying.lecture.id] {
                    for observer in observers {
                        observer.stateHandler(nowPlaying.state)
                    }
                }
            }
        }
    }

    private var isSeeking = false
    private var player: AVPlayer? {
        willSet {
            if let item = player?.currentItem {
                removePlayerItemNotificationObserver(item: item)
            }
        }
        didSet {

            player?.allowsExternalPlayback = true
            addPeriodicTimeObserver()
            if let item = player?.currentItem {
                addPlayerItemNotificationObserver(item: item)
            }
        }
    }

    var visibleState: State = .close

    var playRateMenu: UIMenu!
    var selectedRate: PlayRate {
        get {
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
        set {
            let userDefaultKey: String = "\(Self.self).\(PlayRate.self)"
            let actions: [UIAction] = self.playRateMenu.children as? [UIAction] ?? []
           for anAction in actions {
               if anAction.identifier.rawValue == newValue.rawValue { anAction.state = .on  } else {  anAction.state = .off }
            }

            UserDefaults.standard.set(newValue.rawValue, forKey: userDefaultKey)
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
            SPNowPlayingInfoCenter.shared.update(lecture: currentLecture, player: player, selectedRate: selectedRate)
        }
    }

    var currentLecture: Model? {
        didSet {
            loadViewIfNeeded()

            miniPlayerView.currentLecture = currentLecture

            self.pause()
            if let currentLecture = currentLecture {
                UIApplication.shared.beginReceivingRemoteControlEvents()

                try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try? AVAudioSession.sharedInstance().setActive(true)
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

                do {
                    if loopLectureButton.isSelected == true {
                        currentLectureQueue = [currentLecture]
                    }
                }

                if let index = currentLectureQueue.firstIndex(where: { $0.id == currentLecture.id && $0.creationTimestamp == currentLecture.creationTimestamp }) {
                    previousLectureButton.isEnabled = (index != 0)
                    nextLectureButton.isEnabled = (index+1 < currentLectureQueue.count)
                } else {
                    previousLectureButton.isEnabled = false
                    nextLectureButton.isEnabled = false
                }
                if visibleState == .close {
                    minimize(animated: true)
                }
                Self.nowPlaying = (currentLecture, .paused)
            } else {
                try? AVAudioSession.sharedInstance().setCategory(.ambient)
                try? AVAudioSession.sharedInstance().setActive(true)
                player = nil
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
                Self.nowPlaying = nil

                do {
                    if loopLectureButton.isSelected == true {
                        currentLectureQueue.removeAll()
                    }
                }

                UIApplication.shared.endReceivingRemoteControlEvents()
            }

            SPNowPlayingInfoCenter.shared.update(lecture: currentLecture, player: player, selectedRate: self.selectedRate)
        }
    }

    var playlistLectures: [Model] = [] {
        didSet {
            loadViewIfNeeded()
            if loopLectureButton.isSelected == true {

                if let currentLecture = currentLecture {
                    currentLectureQueue = [currentLecture]
                } else {
                    currentLectureQueue.removeAll()
                }
            } else if shuffleLectureButton.isSelected == true {
                currentLectureQueue = playlistLectures.shuffled()
            } else {
                currentLectureQueue = playlistLectures
            }
        }
    }

    private var currentLectureQueue: [Model] = [] {
        didSet {
            loadViewIfNeeded()
            refreshAsynchronous(source: .cache)
        }
    }

    override func viewDidLoad() {

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

        registerNowPlayingCommands()
        registerAudioSessionObservers()
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

//        reloadData(with: self.currentLectureQueue)

        let lectureIds = self.currentLectureQueue.map { $0.id }
        Self.lectureViewModel.getLectures(searchText: nil, sortType: nil, filter: [:], lectureIDs: lectureIds, source: source, completion: { result in
            switch result {
            case .success(let success):
                self.reloadData(with: success)
            default:
                self.reloadData(with: self.currentLectureQueue)
            }
        })
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

    override func listView(_ listView: IQListView, modifyCell cell: IQListCell, at indexPath: IndexPath) {
        super.listView(listView, modifyCell: cell, at: indexPath)
        cell.backgroundColor = UIColor.clear
    }
}

extension PlayerViewController {

    private func registerNowPlayingCommands() {
        SPNowPlayingInfoCenter.shared.registerNowPlayingInfoCenterCommands { [self] (command, value) in
            switch command {
            case .pause:
                pause()
            case .play:
                play()
            case .stop:
                currentLecture = nil
            case .togglePausePlay:
                if isPaused {
                    play()
                } else {
                    pause()
                }
            case .nextTrack:
                gotoNext(play: !isPaused)
            case .previousTrack:
                gotoPrevious(play: !isPaused)
            case .changeRepeatMode:
                if let value = value as? Bool {
                    change(shuffle: false, loop: value)
                }
            case .changeShuffleMode:
                if let value = value as? Bool {
                    change(shuffle: value, loop: false)
                }
            case .changePlaybackRate:
                if let value = value as? Float, let rate = PlayRate(rawValue: value) {
                    self.selectedRate = rate
                }

            case .skipBackward, .skipForward:
                if let value = value as? TimeInterval {
                    seek(seconds: Int(value))
                }
            case .changePlaybackPosition:
                if let value = value as? TimeInterval {
                    seekTo(seconds: Int(value))
                }
            }
        }
    }

    var isPaused: Bool {
        player?.rate == 0.0
    }

    func play() {
        player?.play()
        player?.rate = self.selectedRate.rate
    }

    func pause() {
        player?.pause()
    }

    func seek(seconds: Int) {

        guard let player = player, let currentItem = player.currentItem else { return }

        if currentItem.duration.isNumeric, player.currentTime().isNumeric {
            let duration = Int(currentItem.duration.seconds)

            let currentTime = Int(player.currentTime().seconds)
            var newTime = currentTime + seconds
            if newTime < 0 {
                newTime = 0
            }

            if newTime > duration {
                newTime = duration
            }

            seekTo(seconds: newTime)
        }
    }

    func seekTo(seconds: Int) {
        let seconds: Int64 = Int64(seconds)
        let targetTime: CMTime = CMTimeMake(value: seconds, timescale: 1)

        isSeeking = true
        player?.seek(to: targetTime, completionHandler: { _ in
            self.isSeeking = false
            SPNowPlayingInfoCenter.shared.update(lecture: self.currentLecture, player: self.player, selectedRate: self.selectedRate)
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
            if !timeSlider.isTracking && !isSeeking {
                if time.isNumeric {
                    let time: Double = time.seconds
                    timeSlider.value = Float(time)
                    miniPlayerView.playedSeconds = timeSlider.value
                }
            }
            currentTimeLabel.text = Int(timeSlider.value).toHHMMSS
        }

        if player.currentTime().isNumeric {
            let time: Double = player.currentTime().seconds
            timeSlider.value = Float(time)
            miniPlayerView.playedSeconds = timeSlider.value
            currentTimeLabel.text = Int(timeSlider.value).toHHMMSS
        }
    }
}

extension PlayerViewController {

    @IBAction func backwardXSecondsPressed(_ sender: UIButton) {
        seek(seconds: -10)
    }

    @IBAction func timeSlider(_ sender: UISlider) {
        seekTo(seconds: Int(sender.value))
    }

    @IBAction func forwardXSecondPressed(_ sender: UIButton) {
        seek(seconds: 10)
    }
}

extension PlayerViewController {

    func gotoNext(play: Bool) {
        if loopLectureButton.isSelected == true {
            seekTo(seconds: 0)
        } else {
            if let currentLecture = currentLecture,
               let index = currentLectureQueue.firstIndex(where: { $0.id == currentLecture.id && $0.creationTimestamp == currentLecture.creationTimestamp }), (index+1) < currentLectureQueue.count {
                let newLecture = currentLectureQueue[index+1]
                self.currentLecture = newLecture
                if play {
                    self.play()
                }
            }
        }
    }

    func gotoPrevious(play: Bool) {
        if loopLectureButton.isSelected == true {
            seekTo(seconds: 0)
        } else {
            if let currentLecture = currentLecture,
               let index = currentLectureQueue.firstIndex(where: { $0.id == currentLecture.id && $0.creationTimestamp == currentLecture.creationTimestamp }), index > 0 {

                let newLecture = currentLectureQueue[index-1]
                self.currentLecture = newLecture
                if play {
                    self.play()
                }
            }
        }
    }
}

extension PlayerViewController {

    private func registerAudioSessionObservers() {
        NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: nil) { [self] notification in

            if let interruptionTypeInt = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
               let interruptionType = AVAudioSession.InterruptionType(rawValue: interruptionTypeInt) {

                switch interruptionType {
                case .began:
                    pause()
                case .ended:
                    if let interruptionOptionInt = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt {
                        let interruptionOption = AVAudioSession.InterruptionOptions(rawValue: interruptionOptionInt)
                        if interruptionOption == .shouldResume {
                            play()
                        }
                    }
                @unknown default:
                    break
                }
            }
        }
    }

    private func removePlayerItemNotificationObserver(item: AVPlayerItem) {
        self.itemStatusObserver?.invalidate()
        self.itemRateObserver?.invalidate()
        if let itemDidPlayToEndObserver = itemDidPlayToEndObserver {
            NotificationCenter.default.removeObserver(itemDidPlayToEndObserver, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: item)
        }
    }

    private func addPlayerItemNotificationObserver(item: AVPlayerItem) {

        self.itemRateObserver = player?.observe(\.rate, options: [.new, .old], changeHandler: { [self] (_, change) in

            if let newValue = change.newValue, newValue != 0.0 {
                playPauseButton.setImage(UIImage(compatibleSystemName: "pause.fill"), for: .normal)
                miniPlayerView.isPlaying = true
                SPNowPlayingInfoCenter.shared.update(lecture: currentLecture, player: player, selectedRate: selectedRate)
                if let currentLecture = currentLecture {
                    Self.nowPlaying = (currentLecture, .playing)
                } else {
                    Self.nowPlaying = nil
                }
            } else {
                playPauseButton.setImage(UIImage(compatibleSystemName: "play.fill"), for: .normal)
                miniPlayerView.isPlaying = false
                SPNowPlayingInfoCenter.shared.update(lecture: currentLecture, player: player, selectedRate: selectedRate)
                if let currentLecture = currentLecture {
                    Self.nowPlaying = (currentLecture, .paused)
                } else {
                    Self.nowPlaying = nil
                }
            }
        })

        self.itemStatusObserver = item.observe(\.status, options: [.new, .old], changeHandler: { [self] (playerItem, change) in

            if playerItem.duration.isNumeric {
                let duration: Double = playerItem.duration.seconds
                let time = Time(totalSeconds: Int(duration))
                timeSlider.maximumValue = Float(duration)
                totalTimeLabel.text = time.displayString
                miniPlayerView.lectureDuration = time
            }
        })

        itemDidPlayToEndObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: item, queue: nil) { [self] _ in
            gotoNext(play: true)
        }
    }

    @IBAction func nextLecturePressed(_ sender: UIButton) {
        gotoNext(play: !isPaused)
    }

    @IBAction func previousLecturePressed(_ sender: UIButton) {
        gotoPrevious(play: !isPaused)
    }
}

extension PlayerViewController {
    private func change(shuffle: Bool, loop: Bool) {

        if shuffle {
            shuffleLectureButton.isSelected = true
            loopLectureButton.isSelected = false
        } else if loop {
            loopLectureButton.isSelected = true
            shuffleLectureButton.isSelected = false
        } else {
            loopLectureButton.isSelected = false
            shuffleLectureButton.isSelected = false
        }

        let allLectures = self.playlistLectures
        self.playlistLectures = allLectures // This is to reload current playlist
    }

    @IBAction func loopLectureButtonPressed(_ sender: UIButton) {
        if loopLectureButton.isSelected == true {
            change(shuffle: false, loop: false)
        } else {
            change(shuffle: false, loop: true)
        }
    }

    @IBAction func shuffleLectureButtonPressed(_ sender: UIButton) {

        if shuffleLectureButton.isSelected == true {
            change(shuffle: false, loop: false)
        } else {
            change(shuffle: true, loop: false)
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

        self.showAlert(title: "Play Rate", message: nil, preferredStyle: .actionSheet, cancel: ("Cancel", nil), buttons: buttons)
    }

    private func playRateActionSelected(action: UIAction) {

        if let newRate = PlayRate(rawValue: action.identifier.rawValue) {
            self.selectedRate = newRate
        }
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
