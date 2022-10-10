//
//  Int+Extension.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 10/10/22.
//

import Foundation

extension Int {

    var toHHMMSS: String {

        let hour = self / 3600
        let minute = (self % 3600) / 60
        let second = (self % 3600) % 60

        if hour <= 0 {
            return String(format: "%02i:%02i", minute, second)
        } else {
            return String(format: "%02i:%02i:%02i", hour, minute, second)
        }
    }
}
