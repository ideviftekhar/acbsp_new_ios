//
//  TappableLabel.swift
//  Srila Prabhupada
//
//  Created by IE06 on 13/09/22.
//

import Foundation
import UIKit

protocol TappableLabelDelegate: AnyObject {
    func tappableLabel(_ label: TappableLabel, didTap string: String)
}

//Custom label used for terms and condition like tapable string in it
class TappableLabel: UILabel {
    
    private let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer()
    
    weak var delegate: TappableLabelDelegate?

    private var links: Set<String> = []

    var linkAttributes: [ NSAttributedString.Key: Any] = [:]

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func commonInit() {
        self.isUserInteractionEnabled = true
        lineBreakMode = .byWordWrapping

        tapGesture.addTarget(self, action: #selector(handleLabelTap(gesture:)))
        tapGesture.numberOfTapsRequired = 1
        tapGesture.isEnabled = true
        addGestureRecognizer(tapGesture)

        linkAttributes[.foregroundColor] = UIColor.systemRed
        linkAttributes[.underlineStyle] = NSNumber(value: 1)
    }
    
    func addLink(_ string: String) {
        links.insert(string)

        guard let text = self.attributedText?.string ?? self.text else {
            return
        }

        let range = (text as NSString).range(of: string)

        if range.location != NSNotFound {

            let mutableAttributedString: NSMutableAttributedString

            if let attributedText = self.attributedText {
                mutableAttributedString = NSMutableAttributedString(attributedString: attributedText)
            } else {
                mutableAttributedString = NSMutableAttributedString(string: text)
            }

            mutableAttributedString.addAttributes(linkAttributes, range: range)

            self.text = mutableAttributedString.string
            self.attributedText = mutableAttributedString
        }
    }

    func removeLink(_ string: String) {
        links.remove(string)
    }
}

extension TappableLabel {

    @objc func handleLabelTap(gesture: UITapGestureRecognizer) {

        guard let text = text as NSString? else {
            return
        }

        for linkString in links {
            let range = text.range(of: linkString)
            if isGestureTappedInRange(gesture: gesture, inRange: range) {
                self.delegate?.tappableLabel(self, didTap: linkString)
                break
            }
        }
    }

    private func isGestureTappedInRange(gesture: UITapGestureRecognizer, inRange targetRange: NSRange) -> Bool {

        // Create instances of NSLayoutManager, NSTextContainer and NSTextStorage
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: CGSize.zero)
        let textStorage = NSTextStorage(attributedString: self.attributedText!)

        // Configure layoutManager and textStorage
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        // Configure textContainer
        textContainer.lineFragmentPadding = 0.0
        textContainer.lineBreakMode = self.lineBreakMode
        textContainer.maximumNumberOfLines = self.numberOfLines
        let labelSize = self.bounds.size
        textContainer.size = labelSize

        // Find the tapped character location and compare it to the specified range
        let locationOfTouchInLabel = gesture.location(in: self)
        let textBoundingBox = layoutManager.usedRect(for: textContainer)
        let textContainerOffset = CGPoint(x: (labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x, y: (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y)
        let locationOfTouchInTextContainer = CGPoint(x: locationOfTouchInLabel.x - textContainerOffset.x, y: locationOfTouchInLabel.y - textContainerOffset.y)
        let indexOfCharacter = layoutManager.characterIndex(for: locationOfTouchInTextContainer, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)

        return NSLocationInRange(indexOfCharacter, targetRange)
    }
}

