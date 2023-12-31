//
//  LectureInfoCell.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 7/5/23.
//

import UIKit
import IQListKit

class LectureInfoCell: UITableViewCell, IQModelableCell {

    @IBOutlet private var stackView: UIStackView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var subtitleLabel: UILabel!

    struct Model: Hashable {
        let title: String
        let subtitle: String
        let axis: NSLayoutConstraint.Axis
    }

    var model: Model? {
        didSet {
            guard let model = model else { return }

            titleLabel.text = model.title
            subtitleLabel.text = model.subtitle
            stackView.axis = model.axis
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
