//
//  LectureHeaderView.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 8/5/23.
//

import UIKit
import IQListKit

protocol LectureHeaderViewDelegate: AnyObject {
    func headerViewDidTapSeeAll(_ headerView: LectureHeaderView)
}

class LectureHeaderView: UICollectionReusableView, IQModelableSupplementaryView {

    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var seeAllButton: UIButton!

    weak var delegate: LectureHeaderViewDelegate?

    struct Model: Hashable {

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.identifier == rhs.identifier &&
            lhs.title == rhs.title &&
            lhs.lectureIDs.count == rhs.lectureIDs.count
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(identifier)
        }

        let identifier: AnyHashable
        let title: String
        let lectureIDs: [Dictionary<Int, Int>.Element]
    }

    var model: Model? {
        didSet {
            guard let model = model else { return }
            titleLabel.text = model.title
            UIView.performWithoutAnimation {
                seeAllButton.isHidden = model.lectureIDs.isEmpty
                seeAllButton.setTitle("See All (\(model.lectureIDs.count))", for: .normal)
                seeAllButton.layoutIfNeeded()
            }
        }
    }

    @IBAction private func seeAllAction(_ sender: UIButton) {
        delegate?.headerViewDidTapSeeAll(self)
    }
}
