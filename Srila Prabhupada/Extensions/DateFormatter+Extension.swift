//
//  DateFormatter+Extension.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 10/4/22.
//

import Foundation

extension DateFormatter {

    static let isoDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        return formatter
    }()

    static let dd_MMM_yyyy: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        return formatter
    }()

    static let dd_MM_yyyy: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        return formatter
    }()

    static let d_M_yyyy: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d-M-yyyy"
        return formatter
    }()
}
