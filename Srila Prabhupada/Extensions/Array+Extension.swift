//
//  Array+Extension.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 10/13/22.
//

import Foundation

extension Array {

    @inlinable public func allIndex(where predicate: (Element) throws -> Bool) rethrows -> [Int] {
        var finalResult: [Int] = []
        for (index, element) in self.enumerated() {
            let result = try predicate(element)
            if result {
                finalResult.append(index)
            }
        }
        return finalResult
    }
}
