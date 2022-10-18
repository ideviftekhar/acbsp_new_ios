//
//  PlayerViewController+Observers.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 10/13/22.
//

import Foundation
import UIKit

extension PlayerViewController {

    static func register(observer: NSObject, lectureID: Int, playStateHandler: @escaping (_ state: PlayState) -> Void) {

        if var observers = lecturePlayStateObservers[lectureID] {
            if let existing = observers.first(where: { $0.observer == observer }) {
                existing.stateHandler = playStateHandler
            } else {
                let newObserver = PlayStateObserver(observer: observer, playStateHandler: playStateHandler)
                observers.append(newObserver)
                lecturePlayStateObservers[lectureID] = observers
            }
        } else {
            let newObserver = PlayStateObserver(observer: observer, playStateHandler: playStateHandler)
            lecturePlayStateObservers[lectureID] = [newObserver]
        }

        if let nowPlaying = nowPlaying, nowPlaying.lecture.id == lectureID {
            playStateHandler(nowPlaying.state)
        } else {
            playStateHandler(.stopped)
        }
    }

    static func unregister(observer: NSObject, lectureID: Int) {

        if var observers = lecturePlayStateObservers[lectureID] {
            if let index = observers.firstIndex(where: { $0.observer == observer }) {
                observers.remove(at: index)
                if observers.isEmpty {
                    lecturePlayStateObservers[lectureID] = nil
                } else {
                    lecturePlayStateObservers[lectureID] = observers
                }
            }
        }
    }
}
