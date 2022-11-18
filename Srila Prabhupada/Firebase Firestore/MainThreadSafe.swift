//
//  MainThreadSafe.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 11/18/22.
//

import Foundation

func mainThreadSafe(block: @escaping () -> Void) {
    if Thread.isMainThread {
        block()
    } else {
        DispatchQueue.main.async {
            block()
        }
    }
}
