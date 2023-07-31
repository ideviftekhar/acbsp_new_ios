//
//  PlayerViewController+MiniPlayer.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 7/31/23.
//

import UIKit

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
