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

protocol PlayerViewControllerDelegate: AnyObject {
    func playerController(_ controller: PlayerViewController, didChangeVisibleState state: PlayerViewController.ViewState)
}

class PlayerViewController: LectureViewController {

    enum ViewState {
        case close
        case minimize
        case expanded
    }

    enum PlayState: Equatable {

        case stopped
        case playing(progress: CGFloat)
        case paused
    }

    class PlayStateObserver {
        let observer: NSObject
        var stateHandler: ((_ state: PlayState) -> Void)

        init(observer: NSObject, playStateHandler: @escaping ((_ state: PlayState) -> Void)) {
            self.observer = observer
            self.stateHandler = playStateHandler
        }
    }

    weak var playerDelegate: PlayerViewControllerDelegate?

    @IBOutlet var thumbnailImageView: UIImageView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var verseLabel: UILabel!
    @IBOutlet private var languageLabel: UILabel!
    @IBOutlet private var categoryLabel: UILabel!
    @IBOutlet private var locationLabel: UILabel!
    @IBOutlet private var dateLabel: UILabel!
    @IBOutlet private var firstDotLabel: UILabel?
    @IBOutlet private var secondDotLabel: UILabel?

    @IBOutlet private var bufferingActivityIndicator: UIActivityIndicatorView!
    @IBOutlet private var currentTimeLabel: UILabel!
    @IBOutlet private var totalTimeLabel: UILabel!
    @IBOutlet private var timeSlider: UISlider!

    @IBOutlet internal var menuButton: UIButton!
    @IBOutlet internal var playlistButton: UIButton!
    @IBOutlet private var playPauseButton: UIButton!
    @IBOutlet private var speedMenuButton: UIButton!

    @IBOutlet private var previousLectureButton: UIButton!
    @IBOutlet private var nextLectureButton: UIButton!

    @IBOutlet private var loopLectureButton: UIButton!
    @IBOutlet private var shuffleLectureButton: UIButton!

    @IBOutlet private var forwardTenSecondsButton: UIButton!
    @IBOutlet private var backwardTenSecondsButton: UIButton!

    @IBOutlet var miniPlayerView: MiniPlayerView!
    @IBOutlet var fullPlayerContainerView: UIView!

    let playerContainerView: UIView = UIView()

    var timeControlStatusObserver: NSKeyValueObservation?
    var itemStatusObserver: NSKeyValueObservation?
    var itemRateObserver: NSKeyValueObservation?
    var itemDidPlayToEndObserver: AnyObject?

    @IBOutlet var tableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var playingInfoStackView: UIStackView!
    @IBOutlet var playingInfoImageViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet var playingInfoTitleStackView: UIStackView!

    var optionMenu: SPMenu!
    var allActions: [LectureOption: SPAction] = [:]
    
    var playFillImage = UIImage(compatibleSystemName: "play.fill")
    var pauseFillImage = UIImage(compatibleSystemName: "pause.fill")

    static var lecturePlayStateObservers = [Int: [PlayStateObserver]]()
    static var nowPlaying: (lecture: Lecture, state: PlayState)? {
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

            player?.automaticallyWaitsToMinimizeStalling = false
            player?.allowsExternalPlayback = true
            addPeriodicTimeObserver()
            if let item = player?.currentItem {
                addPlayerItemNotificationObserver(item: item)
            }
        }
    }

    var visibleState: ViewState = .close

    var playRateMenu: SPMenu!
    var selectedRate: PlayRate {
        get {
            guard let selectedRateAction = playRateMenu.selectedAction,
                  let selectedPlayRate = PlayRate(rawValue: selectedRateAction.action.identifier.rawValue) else {
                return PlayRate.one
            }
            return selectedPlayRate
        }
        set {
            let userDefaultKey: String = "\(Self.self).\(PlayRate.self)"
            UserDefaults.standard.set(newValue.rawValue, forKey: userDefaultKey)
            UserDefaults.standard.synchronize()

            let actions: [SPAction] = self.playRateMenu.children
           for anAction in actions {
               if anAction.action.identifier.rawValue == newValue.rawValue { anAction.action.state = .on  } else {  anAction.action.state = .off }
            }

            self.playRateMenu.children = actions

            let playRate = self.selectedRate
            if !isPaused {
                player?.rate = playRate.rate
            }
            speedMenuButton.setTitle(playRate.rawValue, for: .normal)
            SPNowPlayingInfoCenter.shared.update(lecture: currentLecture, player: player, selectedRate: selectedRate)
        }
    }

    var _privateCurrentLecture: Model?
    var currentLecture: Model? {
        get {
            _privateCurrentLecture
        }

        set {
            updateLectureProgress()

            _privateCurrentLecture = newValue

            loadViewIfNeeded()

            miniPlayerView.currentLecture = newValue

            let userDefaultKey: String = "\(Self.self).\(Lecture.self)"
            UserDefaults.standard.set(newValue?.id, forKey: userDefaultKey)
            UserDefaults.standard.synchronize()
            updateMenuOption()

            self.pause()
            updateMetadata()
            if let currentLecture = newValue {
                UIApplication.shared.beginReceivingRemoteControlEvents()

                try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try? AVAudioSession.sharedInstance().setActive(true)

                if currentLecture.downloadState == .downloaded,
                   let audioURL = DownloadManager.shared.localFileURL(for: currentLecture) {
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

                if visibleState == .close {
                    minimize(animated: true)
                }
                Self.nowPlaying = (currentLecture, .paused)

                if currentLecture.playProgress < 1.0 {
                    seekTo(seconds: currentLecture.lastPlayedPoint)
                }

                DefaultLectureViewModel.defaultModel.addToRecentlyPlayed(lecture: currentLecture, completion: { _ in })
                DefaultLectureViewModel.defaultModel.updateTopLecture(date: Date(), lectureID: currentLecture.id, completion: { _ in })
            } else {
                try? AVAudioSession.sharedInstance().setCategory(.ambient)
                try? AVAudioSession.sharedInstance().setActive(true)
                player = nil

                close(animated: true)
                Self.nowPlaying = nil

                do {
                    if loopLectureButton.isSelected == true {
                        currentLectureQueue.removeAll()
                    }
                }

                UIApplication.shared.endReceivingRemoteControlEvents()
            }

            updatePreviousNextButtonUI()
            SPNowPlayingInfoCenter.shared.update(lecture: newValue, player: player, selectedRate: self.selectedRate)
        }
    }

    var playlistLectures: [Model] = [] {
        didSet {
            loadViewIfNeeded()

            let userDefaultKey: String = "\(Self.self).playlistLectures"
            let lectureIDs = self.playlistLectures.map { $0.id }
            UserDefaults.standard.set(lectureIDs, forKey: userDefaultKey)
            UserDefaults.standard.synchronize()

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
            refresh(source: .cache, existing: currentLectureQueue)
            updatePreviousNextButtonUI()
        }
    }

    override func viewDidLoad() {

        super.viewDidLoad()

        configurePlayRateMenu()
        configureMenuButton()
        
        do {
            loopLectureButton.isSelected = false
            shuffleLectureButton.isSelected = false
        }

        do {
            miniPlayerView.delegate = self
        }

        if #available(iOS 14.0, *) {
            if UIDevice.current.userInterfaceIdiom != .mac {
                timeSlider.setThumbImage(UIImage(), for: .normal)
            }
        } else {
            timeSlider.setThumbImage(UIImage(), for: .normal)
        }

        do {
            self.playerContainerView.clipsToBounds = true
        }

        do {
            let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(swipeRecognized(_:)))
            swipeGesture.direction = .down
            self.view.addGestureRecognizer(swipeGesture)
        }
        setupPlayerIcons()
        registerNowPlayingCommands()
        registerAudioSessionObservers()
    }

    func updateMetadata() {
        updateMenuOption()
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
                thumbnailImageView.af.setImage(withURL: url, placeholderImage: UIImage(named: "playerViewLogo"))
            } else {
                thumbnailImageView.image = UIImage(named: "playerViewLogo")
            }
        } else {
            titleLabel.text = "--"
            verseLabel.text = "--"
            languageLabel.text = "--"
            categoryLabel.text = "--"
            locationLabel.text = "--"
            dateLabel.text = "--"
            timeSlider.maximumValue = 0
            totalTimeLabel.text = "--"
            locationLabel.text = "--"
            firstDotLabel?.isHidden = false
            secondDotLabel?.isHidden = false
            thumbnailImageView.image = UIImage(named: "playerViewLogo")
        }
    }
    private func setupPlayerIcons() {

        if #available(iOS 14.0, *), #available(macCatalyst 14.0, *), UIDevice.current.userInterfaceIdiom == .mac {
            playFillImage = UIImage(named: "playFill")
            pauseFillImage = UIImage(named: "pauseFill")

            menuButton.setImage(UIImage(named: "ellipsisCircle"), for: .normal)
            playlistButton.setImage(UIImage(named: "musicNoteList"), for: .normal)

            if miniPlayerView.isPlaying {
                playPauseButton.setImage(pauseFillImage, for: .normal)
            } else if miniPlayerView.isPlaying == false {
                playPauseButton.setImage(playFillImage, for: .normal)
            }

            previousLectureButton.setImage(UIImage(named: "backwardEndFill"), for: .normal)
            nextLectureButton.setImage(UIImage(named: "forwardEndFill"), for: .normal)

            loopLectureButton.setImage(UIImage(named: "repeat"), for: .normal)
            shuffleLectureButton.setImage(UIImage(named: "shuffle"), for: .normal)
            forwardTenSecondsButton.setImage(UIImage(named: "goForward10"), for: .normal)
            backwardTenSecondsButton.setImage(UIImage(named: "goBackward10"), for: .normal)
        }
    }

    @objc override func lectureUpdateNotification(_ notification: Notification) {
        super.lectureUpdateNotification(notification)

        if let currentLecture = currentLecture,
           let lectures: [Model] = notification.object as? [Model] {

            if let updatedLecture = lectures.first(where: { $0.id == currentLecture.id }) {
                self.loadViewIfNeeded()
                _privateCurrentLecture = updatedLecture
                updateMetadata()
            }
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

    override func refreshAsynchronous(source: FirestoreSource, completion: @escaping (Result<[LectureViewController.Model], Error>) -> Void) {

        let lectureIDs = self.currentLectureQueue.map { $0.id }

        DefaultLectureViewModel.defaultModel.getLectures(searchText: nil, sortType: nil, filter: [:], lectureIDs: lectureIDs, source: source, progress: nil, completion: { result in
            switch result {
            case .success(let success):
                completion(.success(success))
            default:
                completion(.success(self.currentLectureQueue))
            }
        })
    }

    @IBAction func backButtonTapped(_ sender: UIButton) {
        minimize(animated: true)
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

//    var wasShowingPlaylist: Bool = false

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if UIDevice.current.userInterfaceIdiom == .phone {
            if traitCollection.verticalSizeClass == .compact {
//                wasShowingPlaylist = playlistButton.isSelected
                hidePlaylist(animated: true)
            } else {
                hidePlaylist(animated: true)
//                if wasShowingPlaylist {
//                    showPlaylist(animated: true)
//                }
            }
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

            case .skipForward:
                if let value = value as? TimeInterval {
                    seek(seconds: Int(value))
                }
            case .skipBackward:
                if let value = value as? TimeInterval {
                    seek(seconds: Int(-value))
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

    var currentTime: Int {
        guard let player = player,
              let currentItem = player.currentItem,
              currentItem.currentTime().isNumeric else {
            return currentLecture?.lastPlayedPoint ?? 0
        }

        let currentTime = Int(currentItem.currentTime().seconds.rounded(.up))

        return currentTime
    }

    var totalDuration: Int {
        guard let player = player,
              let currentItem = player.currentItem,
              currentItem.duration.isNumeric else {
            return currentLecture?.length ?? 0
        }

        let currentTime = Int(currentItem.duration.seconds)

        return currentTime
    }

    var currentProgress: CGFloat {
        let totalDuration = totalDuration
        let currentTime = currentTime
        guard totalDuration > 0 else {
            return 0
        }
        return CGFloat(currentTime) / CGFloat(totalDuration)
    }

    func updateLectureProgress() {
        guard let currentLecture = currentLecture else {
            return
        }

        let currentTime = currentTime
        DefaultLectureViewModel.defaultModel.updateLectureInfo(lectures: [currentLecture], isCompleted: nil, isDownloaded: nil, isFavorite: nil, lastPlayedPoint: currentTime, postUpdate: false, completion: { result in
            switch result {
            case .success(let success):
                print("Update lecture \"\(currentLecture.titleDisplay)\" current time: \(currentTime) / \(currentLecture.length)")
            case .failure(let error):
                print("Update lecture failed: \(error.localizedDescription)")
            }
        })
    }

    func seek(seconds: Int) {

        let currentTime = currentTime
        var newTime = currentTime + seconds
        if newTime < 0 {
            newTime = 0
        }

        let totalDuration = totalDuration
        if newTime > totalDuration {
            newTime = totalDuration
        }

        seekTo(seconds: newTime)
    }

    func seekTo(seconds: Int) {
        let seconds: Int64 = Int64(seconds)
        let targetTime: CMTime = CMTimeMake(value: seconds, timescale: 1)

        isSeeking = true
        player?.seek(to: targetTime, completionHandler: { [self] _ in
            self.isSeeking = false
            SPNowPlayingInfoCenter.shared.update(lecture: self.currentLecture, player: self.player, selectedRate: self.selectedRate)
            self.updateLectureProgress()
            updatePlayProgressUI(to: Double(seconds))
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

        player.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1, preferredTimescale: 1), queue: DispatchQueue.main, using: { [self] (time) -> Void in

            if time.isNumeric {
                let time: Double = time.seconds
                updatePlayProgressUI(to: time)

                let timeInt = Int(time)
                if timeInt.isMultiple(of: 10) {    // Updating every 10 seconds
                    guard let currentLecture = currentLecture else { return }
                    updateLectureProgress()
                    DefaultLectureViewModel.defaultModel.updateListenInfo(date: Date(), addListenSeconds: 10, lecture: currentLecture, completion: { _ in })
                }
            }
        })

        timeSlider.value = Float(currentTime)
        miniPlayerView.playedSeconds = timeSlider.value
        currentTimeLabel.text = Int(timeSlider.value).toHHMMSS
    }

    private func updatePlayProgressUI(to seconds: Double) {
        if !timeSlider.isTracking && !isSeeking {
            timeSlider.value = Float(seconds)
            miniPlayerView.playedSeconds = timeSlider.value
        }

        let seconds: Int = Int(timeSlider.value.rounded(.up))
        if seconds % 60 == 0, let currentLecture = currentLecture {
            DefaultLectureViewModel.defaultModel.offlineUpdateLectureProgress(lecture: currentLecture, lastPlayedPoint: seconds)
        }
        currentTimeLabel.text = seconds.toHHMMSS
        if !isPaused, let currentLecture = currentLecture {
            Self.nowPlaying = (currentLecture, .playing(progress: self.currentProgress))
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
            self.play()
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
            self.play()
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
        NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: nil, using: { [self] notification in

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
        })
    }

    private func removePlayerItemNotificationObserver(item: AVPlayerItem) {
        self.timeControlStatusObserver?.invalidate()
        self.itemStatusObserver?.invalidate()
        self.itemRateObserver?.invalidate()
        if let itemDidPlayToEndObserver = itemDidPlayToEndObserver {
            NotificationCenter.default.removeObserver(itemDidPlayToEndObserver, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: item)
        }
    }

    private func addPlayerItemNotificationObserver(item: AVPlayerItem) {

        self.itemRateObserver = player?.observe(\.rate, options: [.new, .old], changeHandler: { [self] (_, change) in

            if let newValue = change.newValue, newValue != 0.0 {
                playPauseButton.setImage(pauseFillImage, for: .normal)
                miniPlayerView.isPlaying = true
                SPNowPlayingInfoCenter.shared.update(lecture: currentLecture, player: player, selectedRate: selectedRate)
                if let currentLecture = currentLecture {
                    Self.nowPlaying = (currentLecture, .playing(progress: self.currentProgress))
                } else {
                    Self.nowPlaying = nil
                }
            } else {
                playPauseButton.setImage(playFillImage, for: .normal)
                miniPlayerView.isPlaying = false
                SPNowPlayingInfoCenter.shared.update(lecture: currentLecture, player: player, selectedRate: selectedRate)
                updateLectureProgress()
                if let currentLecture = currentLecture {
                    Self.nowPlaying = (currentLecture, .paused)
                } else {
                    Self.nowPlaying = nil
                }
            }
        })

        self.timeControlStatusObserver = player?.observe(\.timeControlStatus, options: [.new, .old], changeHandler: { [self] (player, _) in

            let totalDuration: Int = self.totalDuration
            timeSlider.maximumValue = Float(totalDuration)
            let time = Time(totalSeconds: totalDuration)
            totalTimeLabel.text = time.displayString
            miniPlayerView.lectureDuration = time

            switch player.timeControlStatus {
            case .paused, .playing:
                bufferingActivityIndicator.stopAnimating()
            case .waitingToPlayAtSpecifiedRate:
                bufferingActivityIndicator.startAnimating()
            @unknown default:
                bufferingActivityIndicator.stopAnimating()
            }
        })

        self.itemStatusObserver = item.observe(\.status, options: [.new, .old], changeHandler: { [self] (_, change) in

            let totalDuration: Int = self.totalDuration
            timeSlider.maximumValue = Float(totalDuration)
            let time = Time(totalSeconds: totalDuration)
            totalTimeLabel.text = time.displayString
            miniPlayerView.lectureDuration = time

            if let newValue = change.newValue {
                switch newValue {
                case .unknown, .readyToPlay:
                    break
                case .failed:
                    pause()
                    if let error = player?.error {
                        showAlert(title: "Unable to play", message: error.localizedDescription)
                    }
                @unknown default:
                    break
                }
            }
        })

        itemDidPlayToEndObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: item, queue: nil, using: { [self] _ in
            updateLectureProgress()
            gotoNext(play: true)
        })
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

    private func updatePreviousNextButtonUI() {

        if let currentLecture = currentLecture {
            if let index = currentLectureQueue.firstIndex(where: { $0.id == currentLecture.id && $0.creationTimestamp == currentLecture.creationTimestamp }) {
                previousLectureButton.isEnabled = (index != 0)
                nextLectureButton.isEnabled = (index+1 < currentLectureQueue.count)
            } else {
                previousLectureButton.isEnabled = false
                nextLectureButton.isEnabled = false
            }
        } else {
            previousLectureButton.isEnabled = false
            nextLectureButton.isEnabled = false
        }
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
        var actions: [SPAction] = []

        let userDefaultKey: String = "\(Self.self).\(PlayRate.self)"
        let lastRate: PlayRate

        if let rateString = UserDefaults.standard.string(forKey: userDefaultKey), let type = PlayRate(rawValue: rateString) {
            lastRate = type
        } else {
            lastRate = .one
        }

        for playRate in PlayRate.allCases {

            let state: UIAction.State = (lastRate == playRate ? .on : .off)

            let action: SPAction = SPAction(title: playRate.rawValue, image: nil, identifier: .init(playRate.rawValue), state: state, handler: { [self] action in
                playRateActionSelected(action: action)
            })

            actions.append(action)
        }

        self.playRateMenu = SPMenu(title: "", image: nil, identifier: .init(rawValue: "PlayRate"), options: .displayInline, children: actions, button: speedMenuButton)

        let playRate = self.selectedRate
        speedMenuButton.setTitle(playRate.rawValue, for: .normal)
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
