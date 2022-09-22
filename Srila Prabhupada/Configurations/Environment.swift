//
//  Environment.swift
//  Srila Prabhupada
//
//  Created by IE on 9/12/22.
//

import Foundation

struct Environment {

    static let current: Environment = Environment(infoDictionary: Bundle.main.infoDictionary)

    let googleServiceFileName: String

    private init(infoDictionary: [String: Any]?) {
        guard let infoDictionary = infoDictionary else {
            googleServiceFileName = ""
            return
        }

        googleServiceFileName = (infoDictionary["GOOGLE_SERVICE_FILE_NAME"] as? String) ?? ""
    }
}
