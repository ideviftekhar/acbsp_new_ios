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

        for dbLecture in dbPendingDownloadLectures {
            downloadStage1(dbLecture: dbLecture)
        }
    }

    func save(lecture: Lecture) {

        if let dbLecture = dbLectures.first(where: { $0.id == lecture.id && $0.creationTimestamp == lecture.creationTimestamp }) {

            switch dbLecture.downloadStateEnum {
            case .notDownloaded, .error:
                downloadStage1(dbLecture: dbLecture)
            case .downloading, .downloaded:
                break
            }

        } else {
            let dbLecture = Lecture.createNewDBLecture(lecture: lecture)
            self.dbLectures.insert(dbLecture, at: 0)
            downloadStage1(dbLecture: dbLecture)
        }
    }

    func delete(lecture: Lecture) {

        guard let index = dbLectures.firstIndex(where: { $0.id == lecture.id && $0.creationTimestamp == lecture.creationTimestamp }) else {
            return
        }

        let dbLecture = dbLectures[index]

        if let localFileURL = DownloadManager.shared.localFileURL(for: dbLecture) {
            DownloadManager.shared.deleteLocalFile(localFileURL: localFileURL)
        }

        dbLectures.remove(at: index)
        dbLecture.downloadState = DBLecture.DownloadState.notDownloaded.rawValue
        NotificationCenter.default.post(name: Self.Notification.downloadRemoved, object: dbLecture)
        deleteObject(object: dbLecture)
        saveMainContext(nil)
    }

    func getDbLectures() -> [DBLecture] {

        let finalContext = mainContext

        let objects: [DBLecture] = self.fetch(in: finalContext)

        return objects
    }

    func lectureDownloadState(lecture: Lecture) -> DBLecture.DownloadState {
        if let object = dbLectures.first(where: { $0.id == lecture.id && $0.creationTimestamp == lecture.creationTimestamp }) {
            return object.downloadStateEnum
        } else {
            return .notDownloaded
        }
    }
}

extension Persistant {

    private func downloadStage1(dbLecture: DBLecture) {

        // check if it exists before downloading it
        if DownloadManager.shared.localFileExists(for: dbLecture) {
            dbLecture.downloadState = DBLecture.DownloadState.downloaded.rawValue
        } else {
            dbLecture.downloadState = DBLecture.DownloadState.downloading.rawValue
        }

        self.saveMainContext(nil)
        NotificationCenter.default.post(name: Self.Notification.downloadAdded, object: dbLecture)

        if dbLecture.downloadStateEnum != .downloaded {
            downloadStage2(dbLecture: dbLecture)
        }
    }

    private func downloadStage2(dbLecture: DBLecture) {

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
