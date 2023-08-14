//
//  SegmentedControl.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 8/14/23.
//

import UIKit

class SegmentedControl: UISegmentedControl {

    override init(items: [Any]?) {
        super.init(items: items)
        setup()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }

    private func setup() {
        let font = UIFont(name: "AvenirNextCondensed-Regular", size: 14)!
        setTitleTextAttributes([NSAttributedString.Key.font: font], for: .normal)
        setTitleTextAttributes([NSAttributedString.Key.font: font], for: .selected)

    }
}
