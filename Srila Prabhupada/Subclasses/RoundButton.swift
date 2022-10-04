//
//  RoundButton.swift
//  Srila Prabhupada
//
//  Created by IE on 9/12/22.
//

import UIKit

@IBDesignable final class RoundButton: UIButton {

    var dictBackgroundColorState: [UIControl.State.RawValue: UIColor] = [:]

    @IBInspectable var normalBackgroundColor: UIColor? {
        didSet {
            setBackgroundColor(color: normalBackgroundColor, state: .normal)
        }
    }

    @IBInspectable var highlightedBackgroundColor: UIColor? {
        didSet {
            setBackgroundColor(color: highlightedBackgroundColor, state: .highlighted)
        }
    }

    @IBInspectable var selectedBackgroundColor: UIColor? {
        didSet {
            setBackgroundColor(color: selectedBackgroundColor, state: .selected)
        }
    }

    @IBInspectable var disabledBackgroundColor: UIColor? {
        didSet {
            setBackgroundColor(color: disabledBackgroundColor, state: .disabled)
        }
    }

    func setBackgroundColor(color: UIColor?, state: UIControl.State) {
        self.dictBackgroundColorState[state.rawValue] = color

        if let color = color {
            let originalImage = UIImage.imageWithColor(color: color)
            let stretchedImage =  originalImage.resizableImage(withCapInsets: UIEdgeInsets.zero, resizingMode: .stretch)
            self.setBackgroundImage(stretchedImage, for: state)
        } else {
            self.setBackgroundImage(nil, for: state)
        }
    }

    func backgroundColorForState(state: UIControl.State) -> UIColor? {

        return self.dictBackgroundColorState[state.rawValue]
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }

    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        sharedInit()
    }

    func sharedInit() {
    }
}

fileprivate extension UIImage {

    static func imageWithColor(color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()

        var red: CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue: CGFloat = 0.0
        var alpha: CGFloat = 0.0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        context?.setAlpha(alpha)
        context!.setFillColor(color.cgColor)
        context!.fill(rect)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!
    }

}
