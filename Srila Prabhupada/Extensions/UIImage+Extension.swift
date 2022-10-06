//
//  UIImage+Extension.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 10/1/22.
//

import Foundation
import UIKit

extension UIImage {

    convenience init?(compatibleSystemName systemName: String) {

        if #available(iOS 13.0, *) {
            self.init(systemName: systemName)
        } else {
            self.init(named: systemName)
        }
    }
}
