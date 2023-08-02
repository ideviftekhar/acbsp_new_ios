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
import Combine
import MarqueeLabel

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
        case playing(progress: CGFloat, audioPower: CGFloat)
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
    @IBOutlet internal var stackViewMain: UIStackView!
    @IBOutlet private var stackViewMinimize: UIStackView!
    @IBOutlet internal var thumbnailImageView: UIImageView!
    @IBOutlet private var titleLabel: MarqueeLabel!
    @IBOutlet private var verseLabel: UILabel!
    @IBOutlet private var languageLabel: UILabel!
    @IBOutlet private var categoryLabel: UILabel!
    @IBOutlet private var locationLabel: UILabel!
    @IBOutlet private var dateLabel: UILabel!
    @IBOutlet private var firstDotLabel: UILabel?
    @IBOutlet private var secondDotLabel: UILabel?
    @IBOutlet internal var waveformView: WaveformView!
    @IBOutlet internal var audioVisualizerView: ESTMusicIndicatorView!

    @IBOutlet internal var bufferingActivityIndicator: UIActivityIndicatorView!
    @IBOutlet internal var currentTimeLabel: UILabel!
    @IBOutlet internal var totalTimeLabel: UILabel!
    @IBOutlet internal var loadingProgressView: UIProgressView!
    @IBOutlet internal var progressView: UIProgressView!

    var showRemainingDuration: Bool = false

    @IBOutlet internal var videoButton: UIButton!
    @IBOutlet internal var menuButton: UIButton!
    @IBOutlet internal var playlistButton: UIButton!
    @IBOutlet internal var playPauseButton: UIButton!
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
    @IBOutlet internal var loopLectureButton: UIButton!
    @IBOutlet internal var shuffleLectureButton: UIButton!
    @IBOutlet internal var playNextMenuButton: UIButton!
    @IBOutlet internal var playNextMenuDoneButton: UIButton!

    @IBOutlet private var forwardTenSecondsButton: UIButton!
    @IBOutlet private var backwardTenSecondsButton: UIButton!

    @IBOutlet var miniPlayerView: MiniPlayerView!
    @IBOutlet var fullPlayerContainerView: UIView!

    internal let playerContainerView: UIView = UIView()

    internal var timeControlStatusObserver: NSKeyValueObservation?
    internal var itemStatusObserver: NSKeyValueObservation?
    internal var itemRateObserver: NSKeyValueObservation?
    internal var itemTracksObserver: NSKeyValueObservation?
    internal var itemDidPlayToEndObserver: AnyObject?

    internal var playerItemLoadedTimeRangesPublisher: AnyCancellable?
    internal var playerItemTracksPowerMeterPublisher: AnyCancellable?

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

    internal var isSeeking = false
    internal var lastAudioPower: CGFloat = 0
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

                let loadWaveformUserDefaultKey: String = "\(Self.self).\(WaveformView.self)"
//                let loadWaveform = UserDefaults.standard.bool(forKey: loadWaveformUserDefaultKey)
                let loadWaveform = true

                let waveformURL: URL?

                if currentLecture.downloadState == .downloaded,
                   let audioURL = DownloadManager.shared.localFileURL(for: currentLecture) {
                    let item = AVPlayerItem(url: audioURL)
                    player = AVPlayer(playerItem: item)
                    if loadWaveform {
                        waveformURL = audioURL
                    } else {
                        waveformURL = nil
                    }
                } else if let firstAudio = currentLecture.resources.audios.first,
                          let audioURL = firstAudio.audioURL {
                    let item = AVPlayerItem(url: audioURL)
                    player = AVPlayer(playerItem: item)
                    waveformURL = nil
                } else {
                    player = nil
                    waveformURL = nil
                }

                waveformView.audioURL = waveformURL

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
                audioVisualizerView.state = .paused

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
                waveformView.audioURL = nil
                videoButton.isHidden = true

                close(animated: true)
                Self.nowPlaying = nil
                audioVisualizerView.state = .stopped

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

        lectureTebleView.contentInset = .init(top: 30, left: 0, bottom: 30, right: 0)
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
            titleLabel.type = .continuous
            titleLabel.speed = .duration(10)
            titleLabel.fadeLength = 30.0
            titleLabel.trailingBuffer = 30.0
        }

        do {
            previousLongPressGesture.isEnabled = false
            nextLongPressGesture.isEnabled = false
            nextLectureButton.addGestureRecognizer(nextLongPressGesture)
            previousLectureButton.addGestureRecognizer(previousLongPressGesture)
            stackViewMain.addGestureRecognizer(seekGesture)
            stackViewMinimize.addGestureRecognizer(minimizeGesture)
            playNextOptionStackView.addGestureRecognizer(minimize2Gesture)

            lectureTebleView.panGestureRecognizer.addTarget(self, action: #selector(tableViewPanRecognized(_:)))
        }

//        do {
//            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(visualizerTapped))
//            audioVisualizerView.addGestureRecognizer(gestureRecognizer)
//        }

        do {
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(totalTimeTapped))
            totalTimeLabel.addGestureRecognizer(gestureRecognizer)
            let userDefaultKey: String = "\(Self.self).showRemainingDuration"
            showRemainingDuration = UserDefaults.standard.bool(forKey: userDefaultKey)
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

    @objc private func totalTimeTapped() {
        let userDefaultKey: String = "\(Self.self).showRemainingDuration"
        showRemainingDuration = !UserDefaults.standard.bool(forKey: userDefaultKey)
        UserDefaults.standard.set(showRemainingDuration, forKey: userDefaultKey)
        UserDefaults.standard.synchronize()
        updateTotalTime(seconds: self.currentTime)
    }

    internal func updateTotalTime(seconds: Int) {
        if showRemainingDuration {
            totalTimeLabel.text = Time(totalSeconds: self.totalDuration - seconds).displayString
        } else {
            totalTimeLabel.text = Time(totalSeconds: self.totalDuration).displayString
        }
    }

//    @objc private func visualizerTapped() {
//        let userDefaultKey: String = "\(Self.self).\(WaveformView.self)"
//        let newSettings = !UserDefaults.standard.bool(forKey: userDefaultKey)
//        UserDefaults.standard.set(newSettings, forKey: userDefaultKey)
//        UserDefaults.standard.synchronize()
//
//        UIView.animate(withDuration: 0.2, animations: { [self] in
//            if newSettings {
//                if waveformView.audioURL != nil {
//                    waveformView.isHidden = false
//                } else {
//                    if let currentLecture = currentLecture,
//                       currentLecture.downloadState == .downloaded,
//                       let audioURL = DownloadManager.shared.localFileURL(for: currentLecture) {
//                        waveformView.audioURL = audioURL
//                    }
//                }
//            } else {
//                waveformView.isHidden = true
//            }
//            self.view.setNeedsLayout()
//            self.view.layoutIfNeeded()
//        })
//    }

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
            updateTotalTime(seconds: currentLecture.lastPlayedPoint)
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

            previousLongPressGesture.isEnabled = miniPlayerView.isPlaying
            nextLongPressGesture.isEnabled = miniPlayerView.isPlaying

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

    internal func updatePlayProgressUI(to seconds: Double) {
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
                waveformView.progress = progress
                miniPlayerView.playedSeconds = playedSeconds
                currentTimeLabel.text = roundedUpSeconds.toHHMMSS
                updateTotalTime(seconds: roundedUpSeconds)

                if roundedUpSeconds % 60 == 0 {
                    DefaultLectureViewModel.defaultModel.offlineUpdateLectureProgress(lecture: currentLecture, lastPlayedPoint: roundedUpSeconds)
                }

                if !isPaused {
                    Self.nowPlaying = (currentLecture, .playing(progress: self.currentProgress, audioPower: self.lastAudioPower))
                }
            }
        } else {
            currentTimeLabel.text = roundedUpSeconds.toHHMMSS
            progressView.progress = 0
            loadingProgressView.progress = 0
            waveformView.progress = 0
            miniPlayerView.playedSeconds = 0
        }
    }
}

extension PlayerViewController {

    @IBAction func backwardXSecondsPressed(_ sender: UIButton) {
        Haptic.softImpact()
        seek(seconds: -10)
    }

    @IBAction func forwardXSecondPressed(_ sender: UIButton) {
        Haptic.softImpact()
        seek(seconds: 10)
    }

    @IBAction func nextLecturePressed(_ sender: UIButton) {
        Haptic.selection()
        gotoNext(play: !isPaused)
    }

    @IBAction func previousLecturePressed(_ sender: UIButton) {
        Haptic.selection()
        gotoPrevious(play: !isPaused)
    }

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

    @IBAction func videoLectureButtonPressed(_ sender: UIButton) {

        Haptic.softImpact()
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

        for option in PlayRate.allCases {

            let state: UIAction.State = (lastRate == option ? .on : .off)

            let action: SPAction = SPAction(title: option.rawValue, image: nil, identifier: .init(option.rawValue), state: state, groupIdentifier: option.groupIdentifier, handler: { [self] action in
                Haptic.selection()
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
