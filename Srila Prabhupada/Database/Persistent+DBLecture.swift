//
//  Persistent+DBLecture.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 10/1/22.
//

import Foundation

extension Persistant {

    func verifyDownloads(_ completionHandler: @escaping (() -> Void)) {

        for dbLecture in getAllDBLectures() {

            let fileExist = DownloadManager.shared.localFileExists(for: dbLecture)

            if fileExist {
                dbLecture.downloadState = DBLecture.DownloadState.downloaded.rawValue
            } else {
                let downloadState = dbLecture.downloadStateEnum

                switch downloadState {
                case .downloading, .downloaded:
                    dbLecture.downloadState = DBLecture.DownloadState.error.rawValue
                case .notDownloaded, .error, .pause:
                    break
                }
            }
        }

        saveMainContext(completionHandler)
    }

    enum Status {
        case success
        case failed
        case noPendingDownloads
    }

    func reschedulePendingDownloads(completion: @escaping ((_ status: Status) -> Void)) {

        let dbLectures = getAllDBLectures()
        let dbPendingDownloadLectures: [DBLecture] = dbLectures.filter { $0.downloadStateEnum == .notDownloaded || $0.downloadStateEnum == .error }

        guard !dbPendingDownloadLectures.isEmpty else {
            completion(.noPendingDownloads)
            return
        }
        downloadStage1(dbLectures: dbPendingDownloadLectures, completion: completion)
    }

    func save(lectures: [Lecture], completion: @escaping ((_ status: Status) -> Void)) {

        guard !lectures.isEmpty else {
            completion(.noPendingDownloads)
            return
        }

        var downloadableLectures: [DBLecture] = []

        let dbLectures = getAllDBLectures()

        for lecture in lectures {
            if let dbLecture = dbLectures.first(where: { $0.id == lecture.id }) {

                switch dbLecture.downloadStateEnum {
                case .notDownloaded, .error, .pause:
                    downloadableLectures.append(dbLecture)
                case .downloading, .downloaded:
                    break
                }

            } else {
                let dbLecture = Lecture.createNewDBLecture(lecture: lecture)
                downloadableLectures.append(dbLecture)
            }
        }

        guard !downloadableLectures.isEmpty else {
            completion(.noPendingDownloads)
            return
        }

        downloadStage1(dbLectures: downloadableLectures, completion: completion)
    }

    func delete(lectures: [Lecture]) {

        guard !lectures.isEmpty else {
            return
        }

        var deletableLectures: [DBLecture] = []
        let dbLectures = getAllDBLectures()
        var deletableLectureIDs: [Int] = []

        for lecture in lectures {
            if let dbLecture = dbLectures.first(where: { $0.id == lecture.id }) {

                DownloadManager.shared.deleteLocalFile(for: dbLecture)

                deletableLectures.append(dbLecture)
                deletableLectureIDs.append(dbLecture.id)

                dbLecture.downloadState = DBLecture.DownloadState.notDownloaded.rawValue
                deleteObject(object: dbLecture)
            }
        }

        guard !deletableLectures.isEmpty else {
            return
        }

        DownloadManager.shared.cancelDownloads(for: deletableLectureIDs)

        NotificationCenter.default.post(name: Self.Notification.downloadsRemoved, object: deletableLectures)

        saveMainContext(nil)
    }

    func pauseDownloads(lectures: [Lecture]) {

        guard !lectures.isEmpty else {
            return
        }

        var pausableLectures: [DBLecture] = []

        let dbLectures = getAllDBLectures()

        for lecture in lectures {
            if let dbLecture = dbLectures.first(where: { $0.id == lecture.id }) {

                switch dbLecture.downloadStateEnum {
                case .downloading:
                    pausableLectures.append(dbLecture)
                case .downloaded, .notDownloaded, .error, .pause:
                    break
                }
            }
        }

        guard !pausableLectures.isEmpty else {
            return
        }

        let pausableLectureIds: [Int] = pausableLectures.map { $0.id }

        DownloadManager.shared.pauseDownloads(for: pausableLectureIds, completion: { resumingData in

            for (lectureId, resumeData) in resumingData {
                if let dbLecture = pausableLectures.first(where: { $0.id == lectureId }) {
                    dbLecture.resumeData = resumeData
                    dbLecture.downloadState = DBLecture.DownloadState.pause.rawValue
                }
            }

            self.saveMainContext(nil)
            // Posting pause/cancel notification already done using standard mechanism implemented. so not posting notification here again
        })
    }

    func getAllDBLectures() -> [DBLecture] {

        let finalContext = mainContext

        let objects: [DBLecture] = self.fetch(in: finalContext)

        return objects
    }
}

extension Persistant {

    private func downloadStage1(dbLectures: [DBLecture], completion: @escaping ((_ status: Status) -> Void)) {

        guard !dbLectures.isEmpty else {
            completion(.noPendingDownloads)
            return
        }

        var addedLectures: [DBLecture] = []
        var downloadableLectures: [DBLecture] = []

        for dbLecture in dbLectures {
            // check if it exists before downloading it
            if DownloadManager.shared.localFileExists(for: dbLecture) {
                dbLecture.downloadState = DBLecture.DownloadState.downloaded.rawValue
            } else {
                dbLecture.downloadState = DBLecture.DownloadState.downloading.rawValue
            }

            addedLectures.append(dbLecture)

            if dbLecture.downloadStateEnum != .downloaded {
                downloadableLectures.append(dbLecture)
            }
        }

        self.saveMainContext(nil)

        if !addedLectures.isEmpty {
            NotificationCenter.default.post(name: Self.Notification.downloadsAdded, object: addedLectures)
        }

        guard !downloadableLectures.isEmpty else {
            completion(.noPendingDownloads)
            return
        }

        downloadStage2(dbLectures: downloadableLectures, completion: completion)
    }

    private func downloadStage2(dbLectures: [DBLecture], completion: @escaping ((_ status: Status) -> Void)) {

        guard !dbLectures.isEmpty else {
            completion(.noPendingDownloads)
            return
        }

        var successCount = 0
        var failedCount = 0
        for dbLecture in dbLectures {
            DownloadManager.shared.downloadFile(for: dbLecture) { result in
                switch result {
                case .success:
                    successCount += 1
                    dbLecture.downloadState = DBLecture.DownloadState.downloaded.rawValue
                    self.saveMainContext(nil)
                    NotificationCenter.default.post(name: Self.Notification.downloadsUpdated, object: [dbLecture])

                case .failure(let error):
                    failedCount += 1

                    if let resumeData = (error as NSError).userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
                        dbLecture.resumeData = resumeData
                    }

                    if dbLecture.downloadStateEnum != .pause {
                        dbLecture.downloadState = DBLecture.DownloadState.error.rawValue
                        dbLecture.downloadError = error.localizedDescription
                    }

                    self.saveMainContext(nil)
                    NotificationCenter.default.post(name: Self.Notification.downloadsUpdated, object: [dbLecture])
                }

                if (successCount + failedCount) == dbLectures.count {
                    let status: Status = (successCount == dbLectures.count) ? Status.success : Status.failed
                    completion(status)
                }
            }
        }
    }
}
