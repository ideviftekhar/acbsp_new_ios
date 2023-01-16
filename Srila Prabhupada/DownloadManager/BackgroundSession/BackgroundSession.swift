//
//  BackgroundSession.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 12/26/22.
//

import UIKit
import os.log

protocol BackgroundSessionDelegate: AnyObject {
    func backgroundSession(_ session: BackgroundSession, lecture: DBLecture, didUpdateProgress progress: Progress)
    func backgroundSession(_ session: BackgroundSession, lecture: DBLecture, didFinish url: URL)
    func backgroundSession(_ session: BackgroundSession, lecture: DBLecture, didFailed error: Error)
}

class BackgroundSession: NSObject {

    let byteFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter
    }()

    private class Task {

        let lecture: DBLecture
        let task: URLSessionDownloadTask
        let progress: Progress

        init(task: URLSessionDownloadTask, lecture: DBLecture) {
            self.task = task

            progress = Progress(totalUnitCount: task.countOfBytesExpectedToReceive)
            progress.completedUnitCount = task.countOfBytesReceived

            self.lecture = lecture
        }
    }

    static let shared = BackgroundSession()
    weak var delegate: BackgroundSessionDelegate?

    var backgroundCompletionHandler: (() -> Void)?

    private var session: URLSession!

    private var tasks: [Task] = []

    private override init() {
        super.init()

        //        let configuration = URLSessionConfiguration.default

        let identifier: String = Bundle.main.bundleIdentifier ?? "URLSessionConfiguration.background"
        let configuration = URLSessionConfiguration.background(withIdentifier: identifier)
        configuration.allowsExpensiveNetworkAccess = true
        configuration.allowsConstrainedNetworkAccess = true
        configuration.shouldUseExtendedBackgroundIdleMode = true
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)

        session.getAllTasks { allSessionTasks in

            self.session.delegateQueue.addOperation {

                let allDownloadTasks: [URLSessionDownloadTask] = allSessionTasks.filter { $0.state == .suspended || $0.state == .running }.compactMap { $0 as? URLSessionDownloadTask }

                if #available(iOS 14.0, *) {
                    os_log(.info, "BackgroundSession: Found \(allDownloadTasks.count) pending tasks")
                }

                self.updateTasksList(existingDownloadTasks: allDownloadTasks)
            }
        }

        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    private func updateTasksList(existingDownloadTasks: [URLSessionDownloadTask]) {
        var allDBLecture = Persistant.shared.getAllDBLectures()

        for downloadTask in existingDownloadTasks {

            if let url: URL = downloadTask.originalRequest?.url {
                if let index = allDBLecture.firstIndex(where: { $0.resources_audios_url.contains(url.absoluteString) && !DownloadManager.shared.localFileExists(for: $0) }) {

                    let dbLecture = allDBLecture.remove(at: index)
                    dbLecture.downloadError = nil
                    if downloadTask.state == .suspended {
                        dbLecture.downloadState = DBLecture.DownloadState.pause.rawValue
                    } else if downloadTask.state == .running {
                        dbLecture.downloadState = DBLecture.DownloadState.downloading.rawValue
                    }

                    let task = Task(task: downloadTask, lecture: dbLecture)
                    self.tasks.append(task)
                } else {
                    downloadTask.cancel()
                }
            } else {
                downloadTask.cancel()
            }
        }

        for dbLecture in allDBLecture {

            let fileExist = DownloadManager.shared.localFileExists(for: dbLecture)

            if fileExist && dbLecture.downloadStateEnum != .downloaded {
                dbLecture.downloadState = DBLecture.DownloadState.downloaded.rawValue
            } else if !fileExist && dbLecture.downloadStateEnum != .error {
                dbLecture.downloadError = "Unable to download the lecture"
                dbLecture.downloadState = DBLecture.DownloadState.error.rawValue
            }
        }

        Persistant.shared.saveMainContext(nil)
    }

    @objc private func appDidEnterForeground() {
        session.getAllTasks(completionHandler: { tasks in

            for task in tasks where task.state == .suspended {
                task.resume()
            }
        })
    }
}

extension BackgroundSession {

    func download(dbLecture: DBLecture) {

        guard let audioURLString = dbLecture.resources_audios_url.first, let audioURL = URL(string: audioURLString) else {
            let error = NSError(domain: "BackgroundSession", code: 0, userInfo: [NSLocalizedDescriptionKey: "No audio to download"])

            dbLecture.downloadState = DBLecture.DownloadState.error.rawValue
            dbLecture.downloadError = error.localizedDescription

            Persistant.shared.saveMainContext {
                self.delegate?.backgroundSession(self, lecture: dbLecture, didFailed: error)
                NotificationCenter.default.post(name: Persistant.Notification.downloadsUpdated, object: [dbLecture])
            }
            return
        }

        let existingTask = self.tasks.first(where: { $0.lecture.id == dbLecture.id })
        // If existing task then do nothing
        guard existingTask == nil else {
            existingTask?.task.resume()
            return
        }

        session.delegateQueue.addOperation {

            let task: URLSessionDownloadTask
            if let resumeData = dbLecture.resumeData {
                task = self.session.downloadTask(withResumeData: resumeData)
            } else {
                task = self.session.downloadTask(with: audioURL)
            }
            task.priority = URLSessionTask.highPriority

            let internalTask = Task(task: task, lecture: dbLecture)
            self.tasks.append(internalTask)
            task.resume()
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
                        mainThreadSafe {
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

    func performFetchWithCompletionHandler(completionHandler: @escaping () -> Void) {
        os_log(.debug, "BackgroundSession: performFetchWithCompletionHandler")
        backgroundCompletionHandler = completionHandler
    }

    func handleEventsForBackgroundURLSession(identifier: String, completionHandler: @escaping () -> Void) {
        os_log(.debug, "BackgroundSession: handleEventsForBackgroundURLSession")
        if identifier == session.configuration.identifier {
            backgroundCompletionHandler = completionHandler
        } else {
            completionHandler()
        }
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        os_log(.debug, "BackgroundSession: urlSessionDidFinishEvents")
        mainThreadSafe {
            self.backgroundCompletionHandler?()
            self.backgroundCompletionHandler = nil
        }
    }
}

extension BackgroundSession: URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {

        let dbLecture: DBLecture?

        if let index = self.tasks.firstIndex(where: { $0.task.taskIdentifier == task.taskIdentifier }) {
            let internalTask = self.tasks.remove(at: index)
            dbLecture = internalTask.lecture
        } else if let url = task.originalRequest?.url, error != nil {    // It may be invoked in background, let's find out which

            let allDBLecture = Persistant.shared.getAllDBLectures()

            if let lecture = allDBLecture.first(where: { $0.resources_audios_url.contains(url.absoluteString) }) {
                dbLecture = lecture
            } else {
                dbLecture = nil
            }
        } else {
            dbLecture = nil
        }

        if let dbLecture = dbLecture {

            if let error = error {
                if #available(iOS 14.0, *) {
                    os_log(.info, "BackgroundSession \(dbLecture.id): didCompleteWithError: \(error)")
                }

                if let resumeData = (error as NSError).userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
                    dbLecture.resumeData = resumeData
                }

                if dbLecture.downloadStateEnum != .pause {
                    dbLecture.downloadState = DBLecture.DownloadState.error.rawValue
                    dbLecture.downloadError = error.localizedDescription
                }

                Persistant.shared.saveMainContext {
                    self.delegate?.backgroundSession(self, lecture: dbLecture, didFailed: error)
                    NotificationCenter.default.post(name: Persistant.Notification.downloadsUpdated, object: [dbLecture])
                }
            } else {
                if #available(iOS 14.0, *) {
                    os_log(.debug, "BackgroundSession \(dbLecture.id): didCompleteWithError: No error")
                }
            }
        } else if error != nil {
            if #available(iOS 14.0, *) {
                os_log(.debug, "BackgroundSession: didCompleteWithError: No DBLecture ID Found")
            }
        }
    }
}

extension BackgroundSession: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let dbLecture: DBLecture?

        if let index = self.tasks.firstIndex(where: { $0.task.taskIdentifier == downloadTask.taskIdentifier }) {
            let internalTask = self.tasks.remove(at: index)
            dbLecture = internalTask.lecture
        } else if let url = downloadTask.originalRequest?.url {    // It may be invoked in background, let's find out which

            let allDBLecture = Persistant.shared.getAllDBLectures()

            if let lecture = allDBLecture.first(where: { $0.resources_audios_url.contains(url.absoluteString) }) {
                dbLecture = lecture
            } else {
                dbLecture = nil
            }
        } else {
            dbLecture = nil
        }

        if let dbLecture = dbLecture {
            let destination = DownloadManager.shared.expectedLocalFileURL(for: dbLecture)

            do {
                if FileManager.default.fileExists(atPath: destination.path) {
                    try FileManager.default.removeItem(at: destination)
                }

                try FileManager.default.moveItem(at: location, to: destination)

                dbLecture.downloadState = DBLecture.DownloadState.downloaded.rawValue
                Persistant.shared.saveMainContext {
                    self.delegate?.backgroundSession(self, lecture: dbLecture, didFinish: destination)
                    NotificationCenter.default.post(name: Persistant.Notification.downloadsUpdated, object: [dbLecture])
                }

                if #available(iOS 14.0, *) {
                    os_log(.debug, "BackgroundSession \(dbLecture.id): didFinishDownloadingTo: File saved")
                }
            } catch let error {

                if dbLecture.downloadStateEnum != .pause {
                    dbLecture.downloadState = DBLecture.DownloadState.error.rawValue
                    dbLecture.downloadError = error.localizedDescription
                }

                Persistant.shared.saveMainContext {
                    self.delegate?.backgroundSession(self, lecture: dbLecture, didFailed: error)
                    NotificationCenter.default.post(name: Persistant.Notification.downloadsUpdated, object: [dbLecture])
                }

                if #available(iOS 14.0, *) {
                    os_log(.debug, "BackgroundSession \(dbLecture.id): didFinishDownloadingTo: failed to save. \(error)")
                }
            }

            mainThreadSafe {
                if UIApplication.shared.applicationState != .active {
                    let center = UNUserNotificationCenter.current()
                    let content = UNMutableNotificationContent()
                    content.title = "Downloaded"
                    content.body = dbLecture.title
                    content.sound = .default

                    let request = UNNotificationRequest(identifier: "\(dbLecture.id)", content: content, trigger: nil)
                    center.add(request, withCompletionHandler: nil)
                }
            }
        } else {
            if #available(iOS 14.0, *) {
                os_log(.debug, "BackgroundSession: didFinishDownloadingTo: No DBLecture ID Found")
            }
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {

        if let index = self.tasks.firstIndex(where: { $0.task.taskIdentifier == downloadTask.taskIdentifier }) {
            let internalTask = self.tasks[index]
            internalTask.progress.totalUnitCount = totalBytesExpectedToWrite
            internalTask.progress.completedUnitCount = totalBytesWritten

            let totalBytesWrittenString: String = byteFormatter.string(fromByteCount: totalBytesWritten)
            let totalBytesExpectedToWriteString: String = byteFormatter.string(fromByteCount: totalBytesExpectedToWrite)
//            let completedPercentage: Int = Int(internalTask.progress.fractionCompleted*100)
//            print("Lecture \(internalTask.lecture.id), \(completedPercentage)%: \(totalBytesWrittenString) of \(totalBytesExpectedToWriteString)")

            if #available(iOS 14.0, *) {
                os_log(.debug, "BackgroundSession \(internalTask.lecture.id): didWriteData: \(totalBytesWrittenString) of \(totalBytesExpectedToWriteString)")
            }

            mainThreadSafe {
                self.delegate?.backgroundSession(self, lecture: internalTask.lecture, didUpdateProgress: internalTask.progress)
            }
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        if let index = self.tasks.firstIndex(where: { $0.task.taskIdentifier == downloadTask.taskIdentifier }) {
            let internalTask = self.tasks[index]
            internalTask.progress.totalUnitCount = expectedTotalBytes
            internalTask.progress.completedUnitCount = fileOffset

            let totalBytesWrittenString: String = byteFormatter.string(fromByteCount: fileOffset)
            let totalBytesExpectedToWriteString: String = byteFormatter.string(fromByteCount: expectedTotalBytes)

            if #available(iOS 14.0, *) {
                os_log(.debug, "BackgroundSession \(internalTask.lecture.id): didResumeAtOffset: \(totalBytesWrittenString) of \(totalBytesExpectedToWriteString)")
            }

            mainThreadSafe {
                self.delegate?.backgroundSession(self, lecture: internalTask.lecture, didUpdateProgress: internalTask.progress)
            }
        }
    }
}
