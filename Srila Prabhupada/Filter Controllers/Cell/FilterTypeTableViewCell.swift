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
}
