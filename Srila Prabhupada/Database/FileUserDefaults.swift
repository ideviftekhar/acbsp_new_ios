//
//  FileUserDefaults.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 7/7/23.
//

import Foundation

class FileUserDefaults {
    static let standard = FileUserDefaults()

    private let documentDirectoryURL: URL = (try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)) ?? URL(fileURLWithPath: NSHomeDirectory())

    private lazy var fileUserDefaultDirectoryURL: URL = {
        let url: URL = documentDirectoryURL.appendingPathComponent("FileUserDefaults", isDirectory: true)
        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            } catch {
                print(error)
            }
        }
        return url
    }()

    private init () {}

    func set(_ data: Data?, for key: String) {
        let url = fileUserDefaultDirectoryURL.appendingPathComponent(key, isDirectory: false)
        do {
            if let data = data {
                try data.write(to: url)
            } else {
                try FileManager.default.removeItem(at: url)
            }
        } catch {
            print(error)
        }
    }

    func data(for key: String) -> Data? {
        let url = fileUserDefaultDirectoryURL.appendingPathComponent(key, isDirectory: false)
        return FileManager.default.contents(atPath: url.path)
    }
}
