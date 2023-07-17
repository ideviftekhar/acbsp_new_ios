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
            guard let image = UIImage(systemName: "text.badge.plus"), let cgImage = image.cgImage else {
                return nil
            }

            let flippedImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: .downMirrored)
            return flippedImage
        case .addToPlayNext:
            return UIImage(systemName: "text.badge.plus")
        }
    }
}
