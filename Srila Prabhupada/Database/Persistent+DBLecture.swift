//
//  Persistent+DBLecture.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 10/1/22.
//

import Foundation

extension Persistant {

    enum Status {
        case success
        case failed
        case noPendingDownloads
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

        let dbLectures = getAllDBLectures()

        for lecture in lectures {
            if let dbLecture = dbLectures.first(where: { $0.id == lecture.id }) {

                DownloadManager.shared.deleteLocalFile(for: dbLecture)
                dbLecture.downloadState = DBLecture.DownloadState.notDownloaded.rawValue
                deleteObject(object: dbLecture)
            }
        }

        let deletableLectureIDs: [Int] = lectures.map { $0.id }

        DownloadManager.shared.cancelDownloads(for: deletableLectureIDs)

        NotificationCenter.default.post(name: Self.Notification.downloadsRemoved, object: deletableLectureIDs)

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
                case .failure:
                    failedCount += 1
                }

                if (successCount + failedCount) == dbLectures.count {
                    let status: Status = (successCount == dbLectures.count) ? Status.success : Status.failed
                    completion(status)
                }
            }
        }
    }
}
