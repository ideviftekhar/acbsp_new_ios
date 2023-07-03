//
//  StatusAlert.swift
//  Srila Prabhupada
//
//  Created by IE on 11/28/22.
//

import Foundation
import StatusAlert

extension StatusAlert {

    static func show(image: UIImage?, title: String?, message: String?, in view: UIView) {
        let statusAlert = StatusAlert()
        statusAlert.appearance.tintColor = .textDarkGray
        statusAlert.appearance.backgroundColor = .popupBackground
        statusAlert.image = image
        statusAlert.title = title
        statusAlert.message = message
        statusAlert.canBePickedOrDismissed = false
        statusAlert.alertShowingDuration = 1.0
        statusAlert.show(in: view)
    }
}
