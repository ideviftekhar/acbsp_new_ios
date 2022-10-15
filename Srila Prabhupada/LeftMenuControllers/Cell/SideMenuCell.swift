//
//  SideMenuCell.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 10/1/22.
//

import UIKit
import IQListKit

class SideMenuCell: UITableViewCell, IQModelableCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    typealias Model = SideMenuItem

    var model: Model? {
        didSet {
            guard let model = model else {
                return
            }

            if model == .rateUs,
               let infoDictionary = Bundle.main.infoDictionary,
               let version = infoDictionary["CFBundleShortVersionString"] as? String,
               let build = infoDictionary["CFBundleVersion"] as? String {

                textLabel?.text = model.rawValue + " v\(version) (\(build))"
            } else {
                textLabel?.text = model.rawValue
            }
        }
    }
}
