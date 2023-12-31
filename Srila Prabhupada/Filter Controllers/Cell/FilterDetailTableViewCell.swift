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
        self.checkView.tintColor = UIColor.FFFFFF
        self.checkView.onFillColor = UIColor.F96D00
        self.checkView.onCheckColor = UIColor.FFFFFF

        self.checkView.layer.borderWidth = 2.0
        self.checkView.layer.borderColor = UIColor.F96D00.cgColor
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.checkView.layer.cornerRadius = checkView.bounds.size.width/2
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
            detailTypeLabel.text = model.details.capitalized
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
