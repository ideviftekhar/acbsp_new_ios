//
//  SideMenuCell.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 10/1/22.
//

import UIKit
import IQListKit

class SideMenuCell: UITableViewCell, IQModelableCell {

    @IBOutlet private var iconImageView: UIImageView!
    @IBOutlet private var titleLabel: UILabel!

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

            iconImageView.image = model.image

            if model == .rateUs,
               let infoDictionary = Bundle.main.infoDictionary,
               let version = infoDictionary["CFBundleShortVersionString"] as? String,
               let build = infoDictionary["CFBundleVersion"] as? String {

                titleLabel.text = model.rawValue + " v\(version) (\(build))"
            } else {
                titleLabel.text = model.rawValue
            }
        }
    }

    static func size(for model: AnyHashable?, listView: IQListView) -> CGSize {
        switch Environment.current.device {
        case .mac, .pad:
            return CGSize(width: listView.frame.width, height: 75)
        default:
            return CGSize(width: listView.frame.width, height: 50)
        }
    }
}
