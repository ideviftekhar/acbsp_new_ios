//
//  DateFormatter+Extension.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 10/4/22.
//

import Foundation

extension DateFormatter {

    static let dd_MMM_yyyy: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MMM-yyyy"
        return formatter
    }()

}
