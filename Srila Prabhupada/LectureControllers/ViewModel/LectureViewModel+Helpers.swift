//
//  LectureViewModel+Helpers.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 10/17/22.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

extension DefaultLectureViewModel {

    static func filter(lectures: [Lecture], searchText: String?, sortType: LectureSortType?, filter: [Filter: [String]], lectureIDs: [Int]?) -> [Lecture] {
        var lectures: [Lecture] = lectures

        if let lectureIDs = lectureIDs {

            var filteredLectures: [Lecture] = []

            let lecturesHashTable: [Int: Lecture] = lectures.reduce(into: [Int: Lecture]()) { result, lecture in
                result[lecture.id] = lecture
            }

            for lectureID in lectureIDs {
                if let lecture = lecturesHashTable[lectureID] {
                    filteredLectures.append(lecture)
                }
            }

            lectures = filteredLectures
        }

        if let searchText = searchText, !searchText.isEmpty {

            lectures = lectures.filter { (lecture: Lecture) in
                var lecture = lecture
                let matched: Bool = lecture.searchableTexts.first(where: { $0.localizedStandardContains(searchText) }) != nil
                return matched
            }
        }

        for (filter, subtypes) in filter {
            lectures = filter.filter(lectures, selectedSubtypes: subtypes)
        }

        if let sortType = sortType {
            lectures = sortType.sort(lectures)
        }
        return lectures
    }

    static func refreshLectureWithLectureInfo(lectures: [Lecture], lectureInfos: [LectureInfo], downloadedLectures: [DBLecture], progress: ((_ progress: CGFloat) -> Void)?) -> [Lecture] {

        let total: CGFloat = CGFloat(lectures.count)

        let startDate = Date()

        var updatedLectures: [Lecture] = []

        do {
            var lectureInfoIDHashTable: [Int: Int] = lectureInfos.enumerated().reduce(into: [Int: Int]()) { result, lecture in
                if result[lecture.element.id] == nil {
                    result[lecture.element.id] = lecture.offset
                }
            }

            var downloadedLectureIDHashTable: [Int: Int] = downloadedLectures.enumerated().reduce(into: [Int: Int]()) { result, lecture in
                if result[lecture.element.id] == nil {
                    result[lecture.element.id] = lecture.offset
                }
            }

            lectures.enumerated().forEach { obj in
                if let progress = progress {
                    DispatchQueue.main.async {
                        progress(CGFloat(obj.offset+1)/total)
                    }
                }

                var lecture: Lecture = obj.element

                if let index = lectureInfoIDHashTable[lecture.id] {
                    let lectureInfo = lectureInfos[index]
                    lectureInfoIDHashTable[lecture.id] = nil

                    lecture.isFavorite = lectureInfo.isFavorite
                    if lectureInfo.lastPlayedPoint == -1 {
                        lecture.lastPlayedPoint = lecture.length
                    } else {
                        lecture.lastPlayedPoint = lectureInfo.lastPlayedPoint
                    }
                }

                if let index = downloadedLectureIDHashTable[lecture.id] {
                    let downloadedLecture = downloadedLectures[index]
                    downloadedLectureIDHashTable[lecture.id] = nil

                    lecture.downloadState = downloadedLecture.downloadStateEnum
                    lecture.downloadError = downloadedLecture.downloadError
                }

                updatedLectures.append(lecture)
            }
        }

        let endDate = Date()
        print("Took \(endDate.timeIntervalSince1970-startDate.timeIntervalSince1970) seconds to merge \(lectures.count) lectures with \(lectureInfos.count) lectureInfos")

        return updatedLectures
    }
}
