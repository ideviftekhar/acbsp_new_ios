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

    @IBOutlet private var thumbnailBackgroundImageView: UIImageView!
    @IBOutlet private var stackViewMain: UIStackView!
    @IBOutlet private var stackViewMinimize: UIStackView!
    @IBOutlet internal var thumbnailImageView: UIImageView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var verseLabel: UILabel!
    @IBOutlet private var languageLabel: UILabel!
    @IBOutlet private var categoryLabel: UILabel!
    @IBOutlet private var locationLabel: UILabel!
    @IBOutlet private var dateLabel: UILabel!
    @IBOutlet private var firstDotLabel: UILabel?
    @IBOutlet private var secondDotLabel: UILabel?

    @IBOutlet private var bufferingActivityIndicator: UIActivityIndicatorView!
    @IBOutlet internal var currentTimeLabel: UILabel!
    @IBOutlet private var totalTimeLabel: UILabel!
    @IBOutlet internal var progressView: UIProgressView!

    @IBOutlet internal var videoButton: UIButton!
    @IBOutlet internal var menuButton: UIButton!
    @IBOutlet internal var playlistButton: UIButton!
    @IBOutlet private var playPauseButton: UIButton!
    @IBOutlet private var speedMenuButton: UIButton!
    @IBOutlet private var stackViewOptions: UIStackView!

    @IBOutlet internal var previousLectureButton: UIButton!
    @IBOutlet internal var nextLectureButton: UIButton!

    internal lazy var previousLongPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(prevNextLongPressRecognized(_:)))
    internal lazy var nextLongPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(prevNextLongPressRecognized(_:)))
    internal var longPressTimer: Timer?
    internal var initialRate: Float = 1
    internal var isNegativeRate: Bool = false
    internal var temporaryRate: Float = 1
    internal static let temporaryRates: [Float] = [1.0, 1.5, 2.0, 3.0, 4.0, 5.0, 10.0]

    @IBOutlet private var playNextOptionStackView: UIStackView!
    @IBOutlet private var loopLectureButton: UIButton!
    @IBOutlet private var shuffleLectureButton: UIButton!
    @IBOutlet private var playNextMenuButton: UIButton!
    @IBOutlet private var playNextMenuDoneButton: UIButton!

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

    internal lazy var seekGesture = UIPanGestureRecognizer(target: self, action: #selector(panRecognized(_:)))
    internal lazy var minimizeGesture = UIPanGestureRecognizer(target: self, action: #selector(panMinimizeRecognized(_:)))
    internal lazy var minimize2Gesture = UIPanGestureRecognizer(target: self, action: #selector(panMinimizeRecognized(_:)))
    internal var direction: UISwipeGestureRecognizer.Direction = .down
    internal var lastPanTranslation: CGPoint = .zero
    internal var lastProposedSeek: Float = 0
    internal var initialYDiff: CGFloat = 0

    var playNextOptionMenu: SPMenu!

    var optionMenu: SPMenu!
    var allActions: [LectureOption: SPAction] = [:]

    var playFillImage = UIImage(systemName: "play.fill")
    var pauseFillImage = UIImage(systemName: "pause.fill")

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
    internal var player: AVPlayer? {
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

    internal func updateCurrentLecture(lecture: Lecture) {
        if lecture.id == _privateCurrentLecture?.id {
            _privateCurrentLecture = lecture
            loadViewIfNeeded()

            updateMenuOption()
            updateMetadata()

            let playedSeconds = miniPlayerView.playedSeconds
            miniPlayerView.currentLecture = lecture
            miniPlayerView.playedSeconds = playedSeconds

            if isPaused {
                seekTo(seconds: lecture.lastPlayedPoint, updateServer: false)
            }
        }
    }

    var currentLecture: Model? {
        get {
            _privateCurrentLecture
        }

        set {
            updateLectureProgress()
            let oldValue = _privateCurrentLecture
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

                do {
                    try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                    try AVAudioSession.sharedInstance().setActive(true)
                } catch {
                    print(error)
                }

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
                        updateCurrentLectureIDsQueue(lectureIDs: [currentLecture.id], animated: nil)
                    } else {
                        let userDefaultKey: String = "\(Self.self).playlistLectures"
                        var updatedLectureIDs: [Int] = []

                        if let data = FileUserDefaults.standard.data(for: userDefaultKey),
                           let mergedLectureIDs = try? JSONDecoder().decode([Int].self, from: data), !mergedLectureIDs.isEmpty {
                            updatedLectureIDs = mergedLectureIDs
                        }

                        if !updatedLectureIDs.contains(currentLecture.id) {
                            if let oldValue = oldValue, let oldValueIndex = updatedLectureIDs.firstIndex(of: oldValue.id) {
                                updatedLectureIDs.insert(currentLecture.id, at: oldValueIndex + 1)
                            } else {
                                updatedLectureIDs.append(currentLecture.id)
                            }
                            let data = try? JSONEncoder().encode(updatedLectureIDs)
                            FileUserDefaults.standard.set(data, for: userDefaultKey)
                            updatePlaylistLectureIDs(ids: updatedLectureIDs, canShuffle: false, animated: nil)
                        }
                    }
                }

                if visibleState == .close {
                    minimize(animated: true)
                }
                Self.nowPlaying = (currentLecture, .paused)

                if currentLecture.playProgress < 1.0 {
                    seekTo(seconds: currentLecture.lastPlayedPoint, updateServer: false)
                }

                DefaultLectureViewModel.defaultModel.addToRecentlyPlayed(lecture: currentLecture, completion: { _ in })
                DefaultLectureViewModel.defaultModel.updateTopLecture(date: Date(), lectureID: currentLecture.id, completion: { _ in })

                DispatchQueue.global().async {
                    self.scrollTo(lectureID: currentLecture.id)
                }

            } else {

                do {
                    try AVAudioSession.sharedInstance().setCategory(.ambient)
                    try AVAudioSession.sharedInstance().setActive(true)
                } catch {
                    print(error)
                }

                player = nil
                videoButton.isHidden = true

                close(animated: true)
                Self.nowPlaying = nil

                do {
                    if loopLectureButton.isSelected == true {
                        currentLectureIDsQueue.removeAll()
                    }
                }

                UIApplication.shared.endReceivingRemoteControlEvents()
            }

            updatePreviousNextButtonUI()
            SPNowPlayingInfoCenter.shared.update(lecture: newValue, player: player, selectedRate: self.selectedRate)
        }
    }

    func moveToLectureID(id: Int, shouldPlay: Bool) {
        if let model = self.models.first(where: { $0.id == id }) {
            currentLecture = model
            if shouldPlay {
                self.play()
            }
        }
    }

    func updatePlaylistLectureIDs(ids: [Int], canShuffle: Bool, lectureIDsQueue: [Int]? = nil, animated: Bool?) {
        self.playlistLectureIDs = ids

        loadViewIfNeeded()

        let updatedLectureIDsQueue: [Int]

        if loopLectureButton.isSelected == true {
            if let currentLecture = currentLecture {
                updatedLectureIDsQueue = [currentLecture.id]
            } else {
                updatedLectureIDsQueue = []
            }
        } else if shuffleLectureButton.isSelected == true {
            if let lectureIDsQueue = lectureIDsQueue {
                updatedLectureIDsQueue = lectureIDsQueue
            } else if canShuffle {
                updatedLectureIDsQueue = playlistLectureIDs.shuffled()
            } else {
                let added = ids.filter { !currentLectureIDsQueue.contains($0) }

                var updatedQueueIDs = currentLectureIDsQueue
                updatedQueueIDs.removeAll { !ids.contains($0) }
                updatedQueueIDs.append(contentsOf: added.shuffled())

                updatedLectureIDsQueue = updatedQueueIDs
            }
        } else {
            updatedLectureIDsQueue = playlistLectureIDs
        }

        updateCurrentLectureIDsQueue(lectureIDs: updatedLectureIDsQueue, animated: animated)
    }

    private func updateCurrentLectureIDsQueue(lectureIDs: [Int], animated: Bool?) {
        self.currentLectureIDsQueue = lectureIDs
        loadViewIfNeeded()
        refresh(source: .cache, animated: animated)
        updatePreviousNextButtonUI()
    }

    private(set) var playlistLectureIDs: [Int] = []
    private(set) var currentLectureIDsQueue: [Int] = []

    override func viewDidLoad() {

        super.viewDidLoad()

        configurePlayRateMenu()
        configureMenuButton()
        configurePlaylistOptionMenu()

        do {
            loopLectureButton.isSelected = false
            shuffleLectureButton.isSelected = false
        }

        do {
            miniPlayerView.delegate = self
            miniPlayerView.dataSource = self
        }

        do {
            self.playerContainerView.clipsToBounds = true
        }

        do {
            nextLectureButton.addGestureRecognizer(nextLongPressGesture)
            previousLectureButton.addGestureRecognizer(previousLongPressGesture)
            stackViewMain.addGestureRecognizer(seekGesture)
            stackViewMinimize.addGestureRecognizer(minimizeGesture)
            playNextOptionStackView.addGestureRecognizer(minimize2Gesture)

            lectureTebleView.panGestureRecognizer.addTarget(self, action: #selector(tableViewPanRecognized(_:)))
        }
        hidePlaylist(animated: false)
        setupPlayerIcons()
        registerNowPlayingCommands()
        registerAudioSessionObservers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    var isFirstTime: Bool = true

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if isFirstTime {
            self.showPlaylist(animated: true)
            isFirstTime = false
        }
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
            totalTimeLabel.text = currentLecture.lengthTime.displayString

            if !currentLecture.location.displayString.isEmpty {
                locationLabel?.text = currentLecture.location.displayString
            } else {
                locationLabel?.text = currentLecture.place.joined(separator: ", ")
            }

            firstDotLabel?.isHidden = currentLecture.legacyData.verse.isEmpty || categoryString.isEmpty
            secondDotLabel?.isHidden = locationLabel?.text?.isEmpty ?? true

            let placeholderImage: UIImage? = UIImage(named: "playerViewLogo")?.withRadius(radius: 10)
            if let url = currentLecture.thumbnailURL {
                thumbnailImageView.af.setImage(withURL: url, placeholderImage: placeholderImage, filter: RoundedCornersFilter(radius: 10))
                thumbnailBackgroundImageView.af.setImage(withURL: url, placeholderImage: placeholderImage, filter: RoundedCornersFilter(radius: 10))
            } else {
                thumbnailImageView.image = placeholderImage
                thumbnailBackgroundImageView.image = placeholderImage
            }
            videoButton.isHidden = currentLecture.resources.videos.first?.videoURL == nil
        } else {
            titleLabel.text = "--"
            verseLabel.text = "--"
            languageLabel.text = "--"
            categoryLabel.text = "--"
            locationLabel.text = "--"
            dateLabel.text = "--"
            totalTimeLabel.text = "--"
            locationLabel.text = "--"
            firstDotLabel?.isHidden = false
            secondDotLabel?.isHidden = false
            let placeholderImage: UIImage? = UIImage(named: "playerViewLogo")?.withRadius(radius: 10)
            thumbnailImageView.image = placeholderImage
            thumbnailBackgroundImageView.image = placeholderImage
            videoButton.isHidden = true
        }
    }
    
    private func setupPlayerIcons() {

        if Environment.current.device == .mac {
            playFillImage = UIImage(named: "play.fill")
            pauseFillImage = UIImage(named: "pause.fill")

            menuButton.setImage(UIImage(named: "ellipsis.circle"), for: .normal)
            playlistButton.setImage(UIImage(named: "list.bullet"), for: .normal)

            if miniPlayerView.isPlaying {
                playPauseButton.setImage(pauseFillImage, for: .normal)
            } else if miniPlayerView.isPlaying == false {
                playPauseButton.setImage(playFillImage, for: .normal)
            }

            previousLectureButton.setImage(UIImage(named: "backward.end.fill"), for: .normal)
            nextLectureButton.setImage(UIImage(named: "forward.end.fill"), for: .normal)

            loopLectureButton.setImage(UIImage(named: "text.badge.xmark"), for: .normal)
            loopLectureButton.setImage(UIImage(named: "repeat"), for: .normal)
            shuffleLectureButton.setImage(UIImage(named: "shuffle"), for: .normal)
            forwardTenSecondsButton.setImage(UIImage(named: "goforward.10"), for: .normal)
            backwardTenSecondsButton.setImage(UIImage(named: "gobackward.10"), for: .normal)
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

    override func refreshAsynchronous(source: FirestoreSource, completion: @escaping (Result<[LectureViewController.Model], Error>) -> Void) {
        DefaultLectureViewModel.defaultModel.getLectures(searchText: nil, sortType: nil, filter: [:], lectureIDs: self.currentLectureIDsQueue, source: source, progress: nil, completion: completion)
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

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if Environment.current.device == .phone {
//            let hasSizeClassChanged = previousTraitCollection?.verticalSizeClass != traitCollection.verticalSizeClass || previousTraitCollection?.horizontalSizeClass != traitCollection.horizontalSizeClass

            if traitCollection.verticalSizeClass == .compact {
                showPlaylist(animated: true)
            } else {
                hidePlaylist(animated: true)
            }
        }
    }

    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }

    override func lecturesLoadingFinished() {
        if currentLecture == nil, let firstLecture = self.models.first {
            self.currentLecture = firstLecture
        }
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
        var progress = CGFloat(currentTime) / CGFloat(totalDuration)
        progress = CGFloat.maximum(0.0, progress)
        progress = CGFloat.minimum(1.0, progress)
        return progress
    }

    func updateLectureProgress() {
        guard let currentLecture = currentLecture else {
            return
        }

        let currentTime = currentTime
        DefaultLectureViewModel.defaultModel.updateLectureInfo(lectures: [currentLecture], isCompleted: nil, isDownloaded: nil, isFavorite: nil, lastPlayedPoint: currentTime, postUpdate: false, completion: { result in
            switch result {
            case .success(let success):
//                print("Update lecture \"\(currentLecture.titleDisplay)\" current time: \(currentTime) / \(currentLecture.length)")
                break
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

    func seekTo(seconds: Int, updateServer: Bool = true) {
        let seconds: Int64 = Int64(seconds)
        let targetTime: CMTime = CMTime(seconds: Double(seconds), preferredTimescale: player?.currentTime().timescale ?? 1)

        isSeeking = true
        player?.seek(to: targetTime, completionHandler: { [self] _ in
            self.isSeeking = false
            SPNowPlayingInfoCenter.shared.update(lecture: self.currentLecture, player: self.player, selectedRate: self.selectedRate)
            if updateServer {
                self.updateLectureProgress()
            }
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

        if seekGesture.state != .changed, let currentLecture = currentLecture {

            let totalSeconds = Float(currentLecture.lengthTime.totalSeconds)
            let playedSeconds = Float(currentTime)
            let progress = playedSeconds / Float(totalSeconds)
            progressView.progress = progress

            miniPlayerView.playedSeconds = playedSeconds
            currentTimeLabel.text = currentTime.toHHMMSS
        }
    }

    private func updatePlayProgressUI(to seconds: Double) {
        guard seekGesture.state != .changed else {
            return
        }

        let roundedUpSeconds: Int = Int(seconds.rounded(.up))

        if let currentLecture = currentLecture {
            if !isSeeking {
                let totalSeconds = Float(currentLecture.lengthTime.totalSeconds)
                let playedSeconds = Float(seconds)
                let progress = playedSeconds / Float(totalSeconds)
                progressView.progress = progress
                miniPlayerView.playedSeconds = playedSeconds
                currentTimeLabel.text = roundedUpSeconds.toHHMMSS

                if roundedUpSeconds % 60 == 0 {
                    DefaultLectureViewModel.defaultModel.offlineUpdateLectureProgress(lecture: currentLecture, lastPlayedPoint: roundedUpSeconds)
                }

                if !isPaused {
                    Self.nowPlaying = (currentLecture, .playing(progress: self.currentProgress))
                }
            }
        } else {
            currentTimeLabel.text = roundedUpSeconds.toHHMMSS
            progressView.progress = 0
            miniPlayerView.playedSeconds = 0
        }
    }
}

extension PlayerViewController {

    @IBAction func backwardXSecondsPressed(_ sender: UIButton) {
        seek(seconds: -10)
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
               let index = currentLectureIDsQueue.firstIndex(where: { $0 == currentLecture.id }),
                (index+1) < currentLectureIDsQueue.count {
                let newLectureID = currentLectureIDsQueue[index+1]
                if let lecture = models.first(where: { $0.id == newLectureID }) {
                    self.currentLecture = lecture

                    if play {
                        self.play()
                    }
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
               let index = currentLectureIDsQueue.firstIndex(where: { $0 == currentLecture.id }),
               index > 0 {
                let newLectureID = currentLectureIDsQueue[index-1]
                if let lecture = models.first(where: { $0.id == newLectureID }) {
                    self.currentLecture = lecture

                    if play {
                        self.play()
                    }
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

        self.updatePlaylistLectureIDs(ids: self.playlistLectureIDs, canShuffle: true, animated: nil) // This is to reload current playlist
    }

    private func updatePreviousNextButtonUI() {

        if let currentLecture = currentLecture {
            if let index = currentLectureIDsQueue.firstIndex(where: { $0 == currentLecture.id }) {
                previousLectureButton.isEnabled = (index != 0)
                nextLectureButton.isEnabled = (index+1 < currentLectureIDsQueue.count)
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

    private func configurePlaylistOptionMenu() {
        var childrens: [SPAction] = []

        let editAction: SPAction = SPAction(title: "Edit", image: UIImage(systemName: "pencil"), identifier: .init("Edit"), handler: { [self] _ in
            self.lectureTebleView.setEditing(true, animated: true)
            playNextMenuButton.isHidden = true
            loopLectureButton.isHidden = true
            shuffleLectureButton.isHidden = true
            playingInfoStackView.isHidden = true

            playNextMenuDoneButton.isHidden = false

        })
        childrens.append(editAction)

        let clearWatchedAction: SPAction = SPAction(title: "Clear Watched", image: UIImage(systemName: "text.badge.minus"), identifier: .init("Clear Watched"), handler: { [self] _ in
            let completedIDs: [Int] = models.filter { $0.isCompleted }.map { $0.id }
            self.removeFromQueue(lectureIDs: completedIDs)
        })
        childrens.append(clearWatchedAction)

        let clearAllAction: SPAction = SPAction(title: "Clear All", image: UIImage(systemName: "text.badge.xmark"), identifier: .init("Clear All"), handler: { [self] _ in
            self.showAlert(title: "Clear Play Next?", message: "Are you sure you would like to clear Play Next Queue?", preferredStyle: .alert, sourceView: playNextMenuButton, cancel: ("Cancel", nil), destructive: ("Clear", {
                self.clearPlayingQueue(keepPlayingLecture: true)
            }))
        })
        clearAllAction.action.attributes = .destructive
        childrens.append(clearAllAction)

        if let playNextMenuButton = playNextMenuButton {
            self.playNextOptionMenu = SPMenu(title: "", image: nil, identifier: .init(rawValue: "PlaylistOption"), options: .displayInline, children: childrens, button: playNextMenuButton)
        }
    }

    @IBAction func playlistMenuDoneButtonPressed(_ sender: UIButton) {
        self.lectureTebleView.setEditing(false, animated: true)
        playNextMenuButton.isHidden = false
        loopLectureButton.isHidden = false
        shuffleLectureButton.isHidden = false
        stackViewMain.isHidden = false
        playingInfoStackView.isHidden = false

        playNextMenuDoneButton.isHidden = true
    }

    @IBAction func videoLectureButtonPressed(_ sender: UIButton) {

        guard let currentLecture = currentLecture,
        let videoURL = currentLecture.resources.videos.first?.videoURL else { return }

        guard UIApplication.shared.canOpenURL(videoURL) else {
            self.showAlert(title: "Error", message: "Sorry, we are unable to show this video.")
            return
        }
        UIApplication.shared.open(videoURL, options: [:], completionHandler: nil)
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

        self.playRateMenu = SPMenu(title: "Speed", image: nil, identifier: .init(rawValue: "PlayRate"), options: .displayInline, children: actions, button: speedMenuButton)

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
    func miniPlayerView(_ playerView: MiniPlayerView, didTemporaryChangeRate rate: Float) {
        player?.rate = rate
    }

    func miniPlayerViewDidClose(_ playerView: MiniPlayerView) {
        self.currentLecture = nil
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

    func miniPlayerViewDidRequestedNext(_ playerView: MiniPlayerView) {
        let isPlaying = !self.isPaused
        gotoNext(play: isPlaying)
    }

    func miniPlayerViewDidExpand(_ playerView: MiniPlayerView) {
        expand(animated: true)
    }
}

extension PlayerViewController: MiniPlayerViewDataSource {
    func miniPlayerViewCurrentRate(_ playerView: MiniPlayerView) -> PlayRate {
        return self.selectedRate
    }
}
