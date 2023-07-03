//
//  FilterDetailTableViewCell.swift
//  Srila Prabhupada
//
//  Created by IE03 on 13/09/22.
//

import UIKit
import BEMCheckBox
import IQListKit

class FilterDetailTableViewCell: UITableViewCell, IQModelableCell {

    @IBOutlet private var checkView: BEMCheckBox!
    @IBOutlet private var detailTypeLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        setupCheckView()
        self.checkView.isUserInteractionEnabled = false
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setupCheckView()
    }
    
    func setupCheckView() {
        self.checkView.boxType = .circle
        self.checkView.tintColor = .white
        self.checkView.onFillColor = UIColor.themeColor
        self.checkView.onCheckColor = UIColor.white

        self.checkView.layer.borderWidth = 2.0
        self.checkView.layer.borderColor = UIColor.themeColor.cgColor
        self.checkView.layer.cornerRadius = 10.0

    }

    struct Model: Hashable {
        let details: String
        let isSelected: Bool
    }

    var model: Model? {
        didSet {
            guard let model = model else {
                return
            }
            checkView.on = model.isSelected
            detailTypeLabel.text = model.details
        }
    }

    static func size(for model: AnyHashable?, listView: IQListView) -> CGSize {
        return CGSize(width: listView.frame.width, height: 44)
    }
}
