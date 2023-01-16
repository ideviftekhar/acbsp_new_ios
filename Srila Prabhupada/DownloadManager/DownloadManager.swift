//
//  DownloadManager.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 9/29/22.
//

import Foundation

private class ProgressObserver {
    let observer: NSObject
    var progressHandler: ((_ progress: Progress) -> Void)

    init(observer: NSObject, progressHandler: @escaping ((_ progress: Progress) -> Void)) {
        self.observer = observer
        self.progressHandler = progressHandler
    }
}

final class DownloadManager {

    static let shared = DownloadManager()

    private init() {
        BackgroundSession.shared.delegate = self
    }

    private var lectureDownloadTasks = [Int: [ProgressObserver]]()
    private var lastProgressInfo = [Int: Progress]()
    private var lectureCompletionObserver = [Int: ((Result<URL, Error>) -> Void)]()
    private let documentDirectoryURL: URL = (try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)) ?? URL(fileURLWithPath: NSHomeDirectory())

    func registerProgress(observer: NSObject, lectureID: Int, progressHandler: @escaping (_ progress: Progress) -> Void) {

        if var observers = lectureDownloadTasks[lectureID] {
            if let existing = observers.first(where: { $0.observer == observer }) {
                existing.progressHandler = progressHandler
            } else {
                let newObserver = ProgressObserver(observer: observer, progressHandler: progressHandler)
                observers.append(newObserver)
                lectureDownloadTasks[lectureID] = observers
            }
        } else {
            let newObserver = ProgressObserver(observer: observer, progressHandler: progressHandler)
            lectureDownloadTasks[lectureID] = [newObserver]
        }

        if let fractionCompleted: Progress = lastProgressInfo[lectureID] {
            progressHandler(fractionCompleted)
        }
    }

    func unregisterProgress(observer: NSObject, lectureID: Int) {

        if var observers = lectureDownloadTasks[lectureID] {
            if let index = observers.firstIndex(where: { $0.observer == observer }) {
                observers.remove(at: index)
                if observers.isEmpty {
                    lectureDownloadTasks[lectureID] = nil
                } else {
                    lectureDownloadTasks[lectureID] = observers
                }
            }
        }
    }
}

extension DownloadManager {

    func downloadFile(for dbLecture: DBLecture, completion: @escaping ((Result<URL, Error>) -> Void)) {

        BackgroundSession.shared.download(dbLecture: dbLecture)
        lectureCompletionObserver[dbLecture.id] = completion
    }

    func cancelDownloads(for lectureIds: [Int]) {
        BackgroundSession.shared.cancelDownloads(for: lectureIds)
    }

    func pauseDownloads(for lectureIds: [Int], completion: @escaping ((_ resumingData: [Int: Data]) -> Void)) {
        BackgroundSession.shared.pauseDownloads(for: lectureIds, completion: completion)
    }
}

extension DownloadManager: BackgroundSessionDelegate {
    func backgroundSession(_ session: BackgroundSession, lecture: DBLecture, didUpdateProgress progress: Progress) {
        self.lastProgressInfo[lecture.id] = progress

        if let observers = self.lectureDownloadTasks[lecture.id] {
            for observer in observers {
                observer.progressHandler(progress)
            }
        }
    }

    func backgroundSession(_ session: BackgroundSession, lecture: DBLecture, didFinish url: URL) {
        Haptic.success()

        if let completion = lectureCompletionObserver[lecture.id] {
            completion(.success(url))
        }

        self.lectureDownloadTasks.removeValue(forKey: lecture.id)
        self.lectureCompletionObserver.removeValue(forKey: lecture.id)
        self.lastProgressInfo.removeValue(forKey: lecture.id)
    }

    func backgroundSession(_ session: BackgroundSession, lecture: DBLecture, didFailed error: Error) {
        Haptic.error()

        if let completion = lectureCompletionObserver[lecture.id] {
            completion(.failure(error))
        }

        self.lectureDownloadTasks.removeValue(forKey: lecture.id)
        self.lectureCompletionObserver.removeValue(forKey: lecture.id)
        self.lastProgressInfo.removeValue(forKey: lecture.id)
    }
}

extension DownloadManager {

    func localFileURL(for lecture: Lecture) -> URL? {

        guard lecture.downloadState == .downloaded,
              let audios = lecture.resources.audios.first,
              let audioURL = audios.audioURL else {
            return nil
        }

        let fileName = "\(lecture.id).\(audioURL.pathExtension)"
        let localAudioURL = documentDirectoryURL.appendingPathComponent(fileName)

        if FileManager.default.fileExists(atPath: localAudioURL.path) {
            return localAudioURL
        }
        return nil
    }
}

extension DownloadManager {

    func localFileExists(for dbLecture: DBLecture) -> Bool {
        localFileURL(for: dbLecture) != nil
    }

    func localFileURL(for dbLecture: DBLecture) -> URL? {

        let localAudioURL = expectedLocalFileURL(for: dbLecture)

        if FileManager.default.fileExists(atPath: localAudioURL.path) {
            return localAudioURL
        }

        return nil
    }

    func expectedLocalFileURL(for dbLecture: DBLecture) -> URL {

        let localAudioURL = documentDirectoryURL.appendingPathComponent(dbLecture.fileName)
        return localAudioURL
    }

    @discardableResult func deleteLocalFile(for dbLecture: DBLecture) -> Bool {

        guard let localFileURL = localFileURL(for: dbLecture) else {
            return false
        }

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

}
