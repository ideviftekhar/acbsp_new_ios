//
//  FilterTypeTableViewCell.swift
//  Srila Prabhupada
//
//  Created by IE03 on 13/09/22.
//

import UIKit
import IQListKit

class FilterTypeTableViewCell: UITableViewCell, IQModelableCell {

    @IBOutlet private var filterTypeLabel: UILabel!
    @IBOutlet private var filterCountLabel: UILabel!

    struct Model: Hashable {
        let filter: Filter
        let selectionCount: Int
    }

    var model: Model? {
        didSet {
            guard let model = model else {
                return
            }

            filterTypeLabel.text = model.filter.rawValue

            filterCountLabel.text = "\(model.selectionCount)"
            filterCountLabel.isHidden = model.selectionCount == 0
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.filterCountLabel.layer.cornerRadius = filterCountLabel.bounds.size.width/2
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
