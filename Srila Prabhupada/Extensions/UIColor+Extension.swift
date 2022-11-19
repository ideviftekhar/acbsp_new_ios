//
//  UIColor+Extension.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 10/17/22.
//

import UIKit

extension UIColor {

    static let zero_0099CC: UIColor = UIColor(named: "0099CC")!
    static let F96D00: UIColor = UIColor(named: "F96D00")!

    private static let predefinedHashColorGroup: [UIColor] = [UIColor.systemRed,
                                                              UIColor.systemGreen,
                                                              UIColor.systemBlue,
                                                              UIColor.systemOrange,
                                                              UIColor.systemYellow,
                                                              UIColor.systemPink,
                                                              UIColor.systemPurple,
                                                              UIColor.systemTeal,
                                                              UIColor.systemIndigo,
                                                              UIColor.systemBrown]

    static func colorHash(name: String?) -> UIColor {

        let counter: Int = abs(name?.hash ?? 0)
        let index = counter % predefinedHashColorGroup.count
        let color = UIColor.predefinedHashColorGroup[index]
        return color
    }
}