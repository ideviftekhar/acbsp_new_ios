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

    var image: UIImage? {
        switch self {
        case .edit:
            return UIImage(systemName: "square.and.pencil")
        case .delete:
            return UIImage(systemName: "trash")
        case .addToQueue:
            return UIImage(systemName: "text.badge.plus")
        }
    }
}
