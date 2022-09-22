//
//  FilterDetailTableViewCell.swift
//  Srila Prabhupada
//
//  Created by IE03 on 13/09/22.
//

import UIKit
import BEMCheckBox

class FilterDetailTableViewCell: UITableViewCell {

    @IBOutlet weak var checkView: BEMCheckBox!
    @IBOutlet weak var detailTypeLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        addAnimationToCheckView()
        self.checkView.isUserInteractionEnabled = false
    }

    func addAnimationToCheckView() {
        self.checkView.boxType = .square
        self.checkView.onAnimationType = .fill
        self.checkView.offAnimationType = .fill
        self.checkView.tintColor = .white

        self.checkView.layer.borderWidth = 2.0
        self.checkView.layer.borderColor = UIColor(named: "ThemeColor")?.cgColor
        self.checkView.layer.cornerRadius = 3.0

    }
}
