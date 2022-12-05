//
//  Haptic.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 12/5/22.
//

import Foundation
import UIKit

final class Haptic {

    private static let impactSoft: UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .soft)
    private static let notificationHaptic: UINotificationFeedbackGenerator = UINotificationFeedbackGenerator()
    private static let selectionHaptic: UISelectionFeedbackGenerator = UISelectionFeedbackGenerator()

    private init() {
    }

    static func softImpact() {
        impactSoft.prepare()
        impactSoft.impactOccurred()
    }

    static func success() {
        notificationHaptic.prepare()
        notificationHaptic.notificationOccurred(.success)
    }

    static func warning() {
        notificationHaptic.prepare()
        notificationHaptic.notificationOccurred(.warning)
    }

    static func error() {
        notificationHaptic.prepare()
        notificationHaptic.notificationOccurred(.error)
    }

    static func selection() {
        selectionHaptic.prepare()
        selectionHaptic.selectionChanged()
    }
}
