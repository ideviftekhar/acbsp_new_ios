//
//  PlaylistOption.swift
//  Srila Prabhupada
//
//  Created by IE on 9/22/22.
//

import Foundation
import UIKit

enum PlaylistOption: String, CaseIterable {

    case edit =   "Edit"

    case delete =   "Delete"

    var image: UIImage? {
        switch self {
        case .edit:
            return UIImage(compatibleSystemName: "square.and.pencil")
        case .delete:
            return UIImage(compatibleSystemName: "trash")
        }
    }
}
