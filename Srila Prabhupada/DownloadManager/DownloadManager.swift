//
//  DownloadManager.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 9/29/22.
//

import Foundation
import Alamofire

private class ProgressObserver {
    let observer: NSObject
    var progressHandler: ((_ progress: CGFloat) -> Void)

    init(observer: NSObject, progressHandler: @escaping ((_ progress: CGFloat) -> Void)) {
        self.observer = observer
        self.progressHandler = progressHandler
    }
}

final class DownloadManager {

    static let shared = DownloadManager()

    private var lectureDownloadTasks = [Int: [ProgressObserver]]()
    private var lastProgressInfo = [Int: CGFloat]()
    private let documentDirectoryURL: URL = (try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)) ?? URL(fileURLWithPath: NSHomeDirectory())

    @discardableResult func deleteLocalFile(localFileURL: URL) -> Bool {

        if FileManager.default.fileExists(atPath: localFileURL.path) {
            do {
                try FileManager.default.removeItem(at: localFileURL)
                return true
            } catch let error {
                print(error)
                return false
            }
        }

        return false
    }

    func registerProgress(observer: NSObject, lectureID: Int, progressHandler: @escaping (_ progress: CGFloat) -> Void) {

        if var observers = lectureDownloadTasks[lectureID] {
            if let existing = observers.first(where: { $0.observer == observer }) {
                existing.progressHandler = progressHandler
            } else {
                let newObserver = ProgressObserver(observer: observer, progressHandler: progressHandler)
                observers.append(newObserver)
                lectureDownloadTasks[lectureID] = observers
            }
        }

        let fractionCompleted: CGFloat = lastProgressInfo[lectureID] ?? 0
        progressHandler(fractionCompleted)
    }

    func unregisterProgress(observer: NSObject, lectureID: Int) {

        if var observers = lectureDownloadTasks[lectureID] {
            if let index = observers.firstIndex(where: { $0.observer == observer }) {
                observers.remove(at: index)
                lectureDownloadTasks[lectureID] = observers
            }
        }
    }
}

extension DownloadManager {

    func localFileURL(for lecture: Lecture) -> URL? {

        guard lecture.downloadingState == .downloaded,
              let audios = lecture.resources.audios.first,
              let audioURL = audios.audioURL else {
            return nil
        }

        let fileName = "\(lecture.id).\(audioURL.pathExtension)"
        let localAudioURL = documentDirectoryURL.appendingPathComponent(fileName)

        if FileManager.default.fileExists(atPath: localAudioURL.path) {
            return audioURL
        }
        return nil
    }
}

extension DownloadManager {

    func localFileExists(for dbLecture: DBLecture) -> Bool {
        localFileURL(for: dbLecture) != nil
    }

    func localFileURL(for dbLecture: DBLecture) -> URL? {

        let localAudioURL = documentDirectoryURL.appendingPathComponent(dbLecture.fileName)

        if FileManager.default.fileExists(atPath: localAudioURL.path) {
            return localAudioURL
        }

        return nil
    }

    private func expectedLocalFileURL(for dbLecture: DBLecture) -> URL {

        let localAudioURL = documentDirectoryURL.appendingPathComponent(dbLecture.fileName)
        return localAudioURL
    }

    func downloadFile(for dbLecture: DBLecture, completion: @escaping ((Result<URL, Error>) -> Void)) {

        guard let audioURLString = dbLecture.resources_audios_url.first, let audioURL = URL(string: audioURLString) else {
            return
        }

        AF.download(audioURL).downloadProgress { progress in

            let fractionCompleted: CGFloat = CGFloat(progress.fractionCompleted)
            self.lastProgressInfo[dbLecture.id] = fractionCompleted

            if let observers = self.lectureDownloadTasks[dbLecture.id] {
                for observer in observers {
                    observer.progressHandler(fractionCompleted)
                }
            }
        }.responseURL { response in

            self.lectureDownloadTasks.removeValue(forKey: dbLecture.id)

            switch response.result {
            case .success(let url):

                let expectedLocalFileURL = self.expectedLocalFileURL(for: dbLecture)
                do {
                    self.deleteLocalFile(localFileURL: expectedLocalFileURL)
                    try FileManager.default.moveItem(at: url, to: expectedLocalFileURL)

                    completion(.success(expectedLocalFileURL))
                } catch let error {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }

            case .failure(let error):
                completion(.failure(error))
            }
        }

        self.lectureDownloadTasks[dbLecture.id] = []
    }
}
