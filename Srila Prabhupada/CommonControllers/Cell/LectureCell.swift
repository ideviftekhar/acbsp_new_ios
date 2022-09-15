//
//  LectureCell.swift
//  Srila Prabhupada
//
//  Created by IE06 on 08/09/22.
//

import UIKit
import IQListKit

class LectureCell: UITableViewCell, IQModelableCell {

    @IBOutlet private var downloadedIconImageView: UIImageView!
    @IBOutlet private var thumbnailImageView: UIImageView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var verseLabel: UILabel!
    @IBOutlet private var durationLabel: UILabel!
    @IBOutlet private var locationLabel: UILabel!
    @IBOutlet private var dateLabel: UILabel!
    @IBOutlet private var menuButton: UIButton!
    @IBOutlet private var progressView: UIView!
    @IBOutlet private var completedCheckbox: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    typealias Model = Lecture

    var model: Model? {
        didSet {
            guard let model = model else {
                return
            }

            titleLabel.text = model.titleDisplay
            verseLabel.text = model.language["main"] as? String
//            verseLabel.text = model.legacyData["verse"] as? String
            durationLabel.text = model.length.displayString
            locationLabel.text = model.locationDisplay
            dateLabel.text = "\(model.dateOfRecording.year)/\(model.dateOfRecording.month)/\(model.dateOfRecording.day)/"
        }
    }
    
}
