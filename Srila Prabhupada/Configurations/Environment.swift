//
//  Environment.swift
//  Srila Prabhupada
//
//  Created by IE on 9/12/22.
//

import Foundation
import UIKit

struct Environment {

    enum Device {
        case phone
        case pad
        case mac
    }

    static let current: Environment = Environment(infoDictionary: Bundle.main.infoDictionary)

    let googleServiceFileName: String
    let device: Device

    private init(infoDictionary: [String: Any]?) {

        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            device = .pad
        case .mac:
            device = .mac
        default:
            device = .phone
        }

        guard let infoDictionary = infoDictionary else {
            googleServiceFileName = ""
            return
        }

        googleServiceFileName = (infoDictionary["GOOGLE_SERVICE_FILE_NAME"] as? String) ?? ""
    }
}
