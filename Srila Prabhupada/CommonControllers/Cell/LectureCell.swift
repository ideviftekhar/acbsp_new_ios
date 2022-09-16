//
//  LectureCell.swift
//  Srila Prabhupada
//
//  Created by IE06 on 08/09/22.
//

import UIKit
import IQListKit
import MBCircularProgressBar
import AlamofireImage

class LectureCell: UITableViewCell, IQModelableCell {

    @IBOutlet private var downloadedIconImageView: UIImageView!
    @IBOutlet private var thumbnailImageView: UIImageView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var verseLabel: UILabel!
    @IBOutlet private var durationLabel: UILabel!
    @IBOutlet private var locationLabel: UILabel!
    @IBOutlet private var dateLabel: UILabel!
    @IBOutlet private var menuButton: UIButton!
    @IBOutlet private var progressView: MBCircularProgressBarView!
    @IBOutlet private var completedCheckbox: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        configureMenuButton()
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    typealias Model = Lecture

    var model: Model? {
        didSet {
            guard let model = model else {
                return
            }

            titleLabel.text = model.titleDisplay
//            verseLabel.text = model.language["main"] as? String
            verseLabel.text = model.legacyData["verse"] as? String
            durationLabel.text = model.length.displayString
            locationLabel.text = model.locationDisplay
            dateLabel.text = "\(model.dateOfRecording.year)/\(model.dateOfRecording.month)/\(model.dateOfRecording.day)/"
            progressView.value = CGFloat.random(in: 0...100)

            if let url = model.thumbnail {
                thumbnailImageView.af.setImage(withURL: url, placeholderImage: UIImage(named: "logo_40"))
            } else {
                thumbnailImageView.image = UIImage(named: "logo_40")
            }
        }
    }

    private func configureMenuButton() {
        var actions: [UIAction] = []

        let options = ["Download", "Mark as Favorite", "Add to playlist", "Mark as heard", "Share"]

        for option in options {
            let action: UIAction = UIAction(title: option, image: nil, identifier: UIAction.Identifier(option), handler: { [self] action in
            })
            actions.append(action)
        }

        let menu = UIMenu(title: "", image: nil, identifier: UIMenu.Identifier.init(rawValue: "Option"), options: UIMenu.Options.displayInline, children: actions)
        menuButton.menu = menu
    }
}
