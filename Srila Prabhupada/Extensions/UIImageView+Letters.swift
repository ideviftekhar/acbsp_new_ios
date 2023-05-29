//
//  UIImageView+Letters.swift
//  Institute
//
//  Created by IE03 on 21/04/20.
//  Copyright © 2020 IE03. All rights reserved.
//

import UIKit

extension UIView {

    public func placeholderImage(text: String?, textAttributes: [NSAttributedString.Key: Any]? = nil) -> UIImage? {

        let color = UIColor.colorHash(name: text)

        let scale = Float(UIScreen.main.scale)
        var size = bounds.size
        if contentMode == .scaleToFill || contentMode == .scaleAspectFill || contentMode == .scaleAspectFit || contentMode == .redraw {
            size.width = CGFloat(floorf((Float(size.width) * scale) / scale))
            size.height = CGFloat(floorf((Float(size.height) * scale) / scale))
        }

        UIGraphicsBeginImageContextWithOptions(size, false, CGFloat(scale))
        let context = UIGraphicsGetCurrentContext()

        // Fill
        context?.setFillColor(color.cgColor)
        context?.fill(CGRect(x: 0, y: 0, width: size.width, height: size.height))

        // initials
        if let initials = text?.initials {

            let defaultFont: UIFont = UIFont(name: "AvenirNextCondensed-Medium", size: min(frame.width, frame.height)/2)!

            let attributes = textAttributes ?? [NSAttributedString.Key.foregroundColor: UIColor.white,
                                                NSAttributedString.Key.font: defaultFont]

            let textSize = initials.size(withAttributes: attributes)
            let bounds = self.bounds
            let rect = CGRect(x: bounds.size.width/2 - textSize.width/2, y: bounds.size.height/2 - textSize.height/2, width: textSize.width, height: textSize.height)

            initials.draw(in: rect, withAttributes: attributes)
        }

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }
}
