//
//  String+Extension.swift
//  Srila Prabhupada
//
//  Created by IE06 on 09/09/22.
//

import Foundation

extension String {
    var isValidEmail: Bool {
        // regEx regex for email
        NSPredicate(format: "SELF MATCHES %@", "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}").evaluate(with: self)
    }
}
