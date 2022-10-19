//
//  Persistent+DBLecture.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 10/1/22.
//

import Foundation

extension Persistant {

    func verifyDownloads(_ completionHandler: @escaping (() -> Void)) {

        for dbLecture in dbLectures {
            let fileExist = DownloadManager.shared.localFileExists(for: dbLecture)

            if fileExist && dbLecture.downloadStateEnum != .downloaded {
                dbLecture.downloadState = DBLecture.DownloadState.downloaded.rawValue
            } else if !fileExist && dbLecture.downloadStateEnum != .error {
                dbLecture.downloadState = DBLecture.DownloadState.error.rawValue
            }

            saveMainContext(completionHandler)
        }
    }

    func reschedulePendingDownloads() {

        let dbPendingDownloadLectures: [DBLecture] = dbLectures.filter { $0.downloadStateEnum == .notDownloaded || $0.downloadStateEnum == .error }

        guard !dbPendingDownloadLectures.isEmpty else {
            return
        }
        downloadStage1(dbLectures: dbPendingDownloadLectures)
    }

    func save(lectures: [Lecture]) {

        guard !lectures.isEmpty else {
            return
        }

        var downloadableLectures: [DBLecture] = []

        for lecture in lectures {
            if let dbLecture = dbLectures.first(where: { $0.id == lecture.id }) {

                switch dbLecture.downloadStateEnum {
                case .notDownloaded, .error:
                    downloadableLectures.append(dbLecture)
                case .downloading, .downloaded:
                    break
                }

            } else {
                let dbLecture = Lecture.createNewDBLecture(lecture: lecture)
                self.dbLectures.insert(dbLecture, at: 0)
                downloadableLectures.append(dbLecture)
            }
        }

        guard !downloadableLectures.isEmpty else {
            return
        }

        downloadStage1(dbLectures: downloadableLectures)
    }

    func delete(lectures: [Lecture]) {

        guard !lectures.isEmpty else {
            return
        }

        var deletedLectures: [DBLecture] = []

        for lecture in lectures {
            if let index = dbLectures.firstIndex(where: { $0.id == lecture.id }) {
                let dbLecture = dbLectures[index]

                if let localFileURL = DownloadManager.shared.localFileURL(for: dbLecture) {
                    DownloadManager.shared.deleteLocalFile(localFileURL: localFileURL)
                }

                dbLectures.remove(at: index)
                deletedLectures.append(dbLecture)

                dbLecture.downloadState = DBLecture.DownloadState.notDownloaded.rawValue
                deleteObject(object: dbLecture)
            }
        }

        guard !deletedLectures.isEmpty else {
            return
        }

        NotificationCenter.default.post(name: Self.Notification.downloadsRemoved, object: deletedLectures)

        saveMainContext(nil)
    }

    func getDbLectures() -> [DBLecture] {

        let finalContext = mainContext

        let objects: [DBLecture] = self.fetch(in: finalContext)

        return objects
    }

    func lectureDownloadState(lecture: Lecture) -> DBLecture.DownloadState {
        if let object = dbLectures.first(where: { $0.id == lecture.id }) {
            return object.downloadStateEnum
        } else {
            return .notDownloaded
        }
    }
}

extension Persistant {

    private func downloadStage1(dbLectures: [DBLecture]) {

        guard !dbLectures.isEmpty else {
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

        if !downloadableLectures.isEmpty {
            downloadStage2(dbLectures: downloadableLectures)
        }
    }

    private func downloadStage2(dbLectures: [DBLecture]) {

        guard !dbLectures.isEmpty else {
            return
        }

        for dbLecture in dbLectures {
            DownloadManager.shared.downloadFile(for: dbLecture) { result in
                switch result {

                case .success:
                    dbLecture.downloadState = DBLecture.DownloadState.downloaded.rawValue
                    self.saveMainContext(nil)
                    NotificationCenter.default.post(name: Self.Notification.downloadUpdated, object: dbLecture)

                case .failure(let error):
                    dbLecture.downloadState = DBLecture.DownloadState.error.rawValue
                    dbLecture.downloadError = error.localizedDescription
                    self.saveMainContext(nil)
                    NotificationCenter.default.post(name: Self.Notification.downloadUpdated, object: dbLecture)
                }
            }
        }
    }
}
