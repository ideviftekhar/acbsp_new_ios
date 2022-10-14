/*
See LICENSE folder for this sample’s licensing information.

Abstract:
`SPNowPlayableCommand` identifies remote command center commands.
*/

import Foundation
import MediaPlayer

enum SPNowPlayableCommand: CaseIterable {

    case pause, play, stop, togglePausePlay
    case nextTrack, previousTrack, changeRepeatMode, changeShuffleMode
    case changePlaybackRate, skipBackward, skipForward, changePlaybackPosition

    // The underlying `MPRemoteCommandCenter` command for this `NowPlayable` command.
    var remoteCommand: MPRemoteCommand {

        let remoteCommandCenter = MPRemoteCommandCenter.shared()

        switch self {

        case .pause:
            return remoteCommandCenter.pauseCommand
        case .play:
            return remoteCommandCenter.playCommand
        case .stop:
            return remoteCommandCenter.stopCommand
        case .togglePausePlay:
            return remoteCommandCenter.togglePlayPauseCommand
        case .nextTrack:
            return remoteCommandCenter.nextTrackCommand
        case .previousTrack:
            return remoteCommandCenter.previousTrackCommand
        case .changeRepeatMode:
            return remoteCommandCenter.changeRepeatModeCommand
        case .changeShuffleMode:
            return remoteCommandCenter.changeShuffleModeCommand
        case .changePlaybackRate:
            return remoteCommandCenter.changePlaybackRateCommand
        case .skipBackward:
            return remoteCommandCenter.skipBackwardCommand
        case .skipForward:
            return remoteCommandCenter.skipForwardCommand
        case .changePlaybackPosition:
            return remoteCommandCenter.changePlaybackPositionCommand
        }
    }

    // Remove all handlers associated with this command.
    func removeHandler() {
        remoteCommand.removeTarget(nil)
    }

    // Install a handler for this command.
    func addHandler(_ handler: @escaping (SPNowPlayableCommand, MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus) {

        switch self {
        case .skipBackward:
            MPRemoteCommandCenter.shared().skipBackwardCommand.preferredIntervals = [10.0]
        case .skipForward:
            MPRemoteCommandCenter.shared().skipForwardCommand.preferredIntervals = [10.0]
        default:
            break
        }
        remoteCommand.addTarget { handler(self, $0) }
    }
}
