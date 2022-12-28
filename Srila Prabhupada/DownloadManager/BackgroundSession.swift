//
//  BackgroundSession.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 12/26/22.
//

import UIKit

class BackgroundSession: NSObject {

    let byteFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter
    }()

    typealias ProgressHandler = ((_ progress: Progress) -> Void)
    typealias DownloadCompletion = ((Result<URL, Error>) -> Void)

    private class Task {
        let lecture: DBLecture
        let task: URLSessionDownloadTask
        let progress: Progress = Progress(totalUnitCount: 0)
        let destination: URL
        var progressHandler: ProgressHandler
        var completion: DownloadCompletion

        init(task: URLSessionDownloadTask, lecture: DBLecture, destination: URL, progressHandler: @escaping ProgressHandler, completion: @escaping DownloadCompletion) {
            self.task = task
            self.lecture = lecture
            self.destination = destination
            self.progressHandler = progressHandler
            self.completion = completion
        }
    }

    static let shared = BackgroundSession()
    static let identifier = "com.bvksdigital.acbsp"

    func handleEventsForBackgroundURLSession(identifier: String, completionHandler: @escaping () -> Void) {
        backgroundCompletionHandler = completionHandler
    }

    var backgroundCompletionHandler: (() -> Void)?

    private var session: URLSession!

    private var tasks: [Task] = []

    private override init() {
        super.init()

        let configuration = URLSessionConfiguration.default
//        let configuration = URLSessionConfiguration.background(withIdentifier: BackgroundSession.identifier)
        configuration.sessionSendsLaunchEvents = true
        configuration.allowsCellularAccess = true
        configuration.allowsExpensiveNetworkAccess = true
        configuration.allowsConstrainedNetworkAccess = true
        configuration.waitsForConnectivity = false
        configuration.shouldUseExtendedBackgroundIdleMode = true
        configuration.networkServiceType = .responsiveData
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    @objc private func appDidEnterForeground() {
        session.getAllTasks(completionHandler: { tasks in

            for task in tasks where task.state == .suspended {
                task.resume()
            }
        })
//        resumeNextIfNeeded()
    }

//    private func resumeNextIfNeeded() {
//        if let firstTask = tasks.first {
//            if firstTask.task.state != .running {
//                firstTask.task.resume()
//            }
//        }
//    }
}

extension BackgroundSession {

    func download(dbLecture: DBLecture, progress: @escaping ((_ progress: Progress) -> Void), completion: @escaping ((Result<URL, Error>) -> Void)) {

        guard let audioURLString = dbLecture.resources_audios_url.first, let audioURL = URL(string: audioURLString) else {
            let error = NSError(domain: "BackgroundSession", code: 0, userInfo: [NSLocalizedDescriptionKey: "No audio to download"])
            DispatchQueue.main.async {
                completion(.failure(error))
            }
            return
        }
        session.delegateQueue.addOperation {

            // If existing task then update handlers only
            if let existingTask = self.tasks.first(where: { $0.lecture.id == dbLecture.id }) {
                existingTask.progressHandler = progress
                existingTask.completion = completion
            } else {
                let destination = DownloadManager.shared.expectedLocalFileURL(for: dbLecture)

                let task: URLSessionDownloadTask
                if let resumeData = dbLecture.resumeData {
                    task = self.session.downloadTask(withResumeData: resumeData)
                } else {
                    task = self.session.downloadTask(with: audioURL)
                }
                task.priority = URLSessionTask.highPriority

                let internalTask = Task(task: task, lecture: dbLecture, destination: destination, progressHandler: progress, completion: completion)
                self.tasks.append(internalTask)
                task.resume()
            }
//            self.resumeNextIfNeeded()
        }
    }

    func cancelDownloads(for lectureIds: [Int]) {

        for lectureId in lectureIds {
            if let internalTask = self.tasks.first(where: { $0.lecture.id == lectureId }) {
                internalTask.task.cancel()
            }
        }
    }

    func pauseDownloads(for lectureIds: [Int], completion: @escaping ((_ resumingData: [Int: Data]) -> Void)) {

        var resumingData: [Int: Data] = [:]
        var completedCount = 0

        for lectureId in lectureIds {
            if let internalTask = self.tasks.first(where: { $0.lecture.id == lectureId }) {
                internalTask.task.cancel(byProducingResumeData: { data in
                    completedCount += 1
                    if let data = data {
                        resumingData[lectureId] = data
                    }

                    if completedCount == lectureIds.count {
                        DispatchQueue.main.async {
                            completion(resumingData)
                        }
                    }
                })
            } else {
                completedCount += 1
            }
        }
    }
}

extension BackgroundSession: URLSessionDelegate {

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            self.backgroundCompletionHandler?()
            self.backgroundCompletionHandler = nil
        }
    }
}

extension BackgroundSession: URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {

        if let index = self.tasks.firstIndex(where: { $0.task.taskIdentifier == task.taskIdentifier }) {
            let internalTask = self.tasks.remove(at: index)

            if let error = error {
                DispatchQueue.main.async {
                    internalTask.completion(.failure(error))
                }
            }
        } else if let url = task.originalRequest?.url, let error = error {    // It may be invoked in background, let's find out which

            let allDBLecture = Persistant.shared.getAllDBLectures()

            if let dbLecture = allDBLecture.first(where: { $0.resources_audios_url.contains(url.absoluteString) }) {

                if let resumeData = (error as NSError).userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
                    dbLecture.resumeData = resumeData
                }

                if dbLecture.downloadStateEnum != .pause {
                    dbLecture.downloadState = DBLecture.DownloadState.error.rawValue
                    dbLecture.downloadError = error.localizedDescription
                }

                Persistant.shared.saveMainContext(nil)
                NotificationCenter.default.post(name: Persistant.Notification.downloadsUpdated, object: [dbLecture])
            }
        }

//        resumeNextIfNeeded()
    }
}

extension BackgroundSession: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {

        let downloadedDbLecture: DBLecture?

        if let index = self.tasks.firstIndex(where: { $0.task.taskIdentifier == downloadTask.taskIdentifier }) {
            let internalTask = self.tasks.remove(at: index)

            downloadedDbLecture = internalTask.lecture
            let destination = internalTask.destination
            do {
                if FileManager.default.fileExists(atPath: destination.path) {
                    try FileManager.default.removeItem(at: destination)
                }

                try FileManager.default.moveItem(at: location, to: destination)

                DispatchQueue.main.async {
                    internalTask.completion(.success(destination))
                }
            } catch let error {
                DispatchQueue.main.async {
                    internalTask.completion(.failure(error))
                }
            }
        } else if let url = downloadTask.originalRequest?.url {    // It may be invoked in background, let's find out which

            let allDBLecture = Persistant.shared.getAllDBLectures()

            if let dbLecture = allDBLecture.first(where: { $0.resources_audios_url.contains(url.absoluteString) }) {
                downloadedDbLecture = dbLecture

                let destination = DownloadManager.shared.expectedLocalFileURL(for: dbLecture)

                do {
                    if FileManager.default.fileExists(atPath: destination.path) {
                        try FileManager.default.removeItem(at: destination)
                    }

                    try FileManager.default.moveItem(at: location, to: destination)

                    dbLecture.downloadState = DBLecture.DownloadState.downloaded.rawValue
                    Persistant.shared.saveMainContext(nil)

                } catch let error {
                    print(error)
                }
            } else {
                downloadedDbLecture = nil
            }
        } else {
            downloadedDbLecture = nil
        }

        DispatchQueue.main.async {
            if UIApplication.shared.applicationState != .active, let downloadedDbLecture = downloadedDbLecture {
                let center = UNUserNotificationCenter.current()
                 let content = UNMutableNotificationContent()
                content.title = downloadedDbLecture.title
                 content.body = "Download Completed"
                 content.sound = .default

                 let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0, repeats: false)
                let request = UNNotificationRequest(identifier: "\(downloadedDbLecture.id)", content: content, trigger: trigger)
                center.add(request, withCompletionHandler: nil)
            }
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {

        if let index = self.tasks.firstIndex(where: { $0.task.taskIdentifier == downloadTask.taskIdentifier }) {
            let internalTask = self.tasks[index]
            internalTask.progress.totalUnitCount = totalBytesExpectedToWrite
            internalTask.progress.completedUnitCount = totalBytesWritten

//            let totalBytesWrittenString: String = byteFormatter.string(fromByteCount: totalBytesWritten)
//            let totalBytesExpectedToWriteString: String = byteFormatter.string(fromByteCount: totalBytesExpectedToWrite)
//            let completedPercentage: Int = Int(internalTask.progress.fractionCompleted*100)
//            print("Lecture \(internalTask.lecture.id), \(completedPercentage)%: \(totalBytesWrittenString) of \(totalBytesExpectedToWriteString)")
            DispatchQueue.main.async {
                internalTask.progressHandler(internalTask.progress)
            }
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        if let index = self.tasks.firstIndex(where: { $0.task.taskIdentifier == downloadTask.taskIdentifier }) {
            let internalTask = self.tasks[index]
            internalTask.progress.totalUnitCount = expectedTotalBytes
            internalTask.progress.completedUnitCount = fileOffset
            DispatchQueue.main.async {
                internalTask.progressHandler(internalTask.progress)
            }
        }
    }
}
