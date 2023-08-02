//
//  PlaylistOption.swift
//  Srila Prabhupada
//
//  Created by IE on 9/22/22.
//

import Foundation
import UIKit

enum PlaylistOption: String, CaseIterable {

    case edit       =   "Edit"

    case delete     =   "Delete"

    case addToQueue =   "Add to Queue"

    case addToPlayNext          =   "Play Next"

    var image: UIImage? {
        switch self {
        case .edit:
            return UIImage(systemName: "square.and.pencil")
        case .delete:
            return UIImage(systemName: "trash")
        case .addToQueue:
            return UIImage(systemName: "text.badge.plus")?.flipVertically()?.withRenderingMode(.alwaysTemplate)
        case .addToPlayNext:
            return UIImage(systemName: "text.badge.plus")
        }
    }

    var groupIdentifier: Int {
        switch self {
        case .edit, .delete:
            return 1
        case .addToQueue, .addToPlayNext:
            return 2
        }
    }
}
