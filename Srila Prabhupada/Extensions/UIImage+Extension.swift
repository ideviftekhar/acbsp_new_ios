//
//  UIImage+Extension.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 10/1/22.
//

import Foundation
import UIKit

extension UIImage {

    convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 1.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }

    public func withRadius(radius: CGFloat? = nil) -> UIImage? {
        let maxRadius = min(size.width, size.height) / 2
        let cornerRadius: CGFloat
        if let radius = radius, radius > 0 && radius <= maxRadius {
            cornerRadius = radius
        } else {
            cornerRadius = maxRadius
        }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        let rect = CGRect(origin: .zero, size: size)
        UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius).addClip()
        draw(in: rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    public func flipHorizontally() -> UIImage? {
        guard let cgImage = cgImage else {
            return self
        }

        let flippedImage = UIImage(cgImage: cgImage, scale: scale, orientation: .upMirrored).withRenderingMode(renderingMode)
        return flippedImage
    }

    public func flipVertically() -> UIImage? {
        guard let cgImage = cgImage else {
            return self
        }

        let flippedImage = UIImage(cgImage: cgImage, scale: scale, orientation: .downMirrored).withRenderingMode(renderingMode)
        return flippedImage
    }
}
