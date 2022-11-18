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

            for lectureID in lectureIDs {
                if let lecture = lectures.first(where: { $0.id == lectureID }) {
                    filteredLectures.append(lecture)
                }
            }

            lectures = filteredLectures
        }

        if let searchText = searchText, !searchText.isEmpty {

            lectures = lectures.filter { (lecture: Lecture) in
                let matched: Bool = lecture.searchableTexts.first(where: { $0.localizedCaseInsensitiveContains(searchText) }) != nil
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

    static func refreshLectureWithLectureInfo(lectures: [Lecture], lectureInfos: [LectureInfo], downloadedLectures: [DBLecture]) -> [Lecture] {
        let lectures = lectures.map { lecture -> Lecture in
            var lecture = lecture
            if let lectureInfo = lectureInfos.first(where: { $0.id == lecture.id }) {
                lecture.isFavourite = lectureInfo.isFavourite
                lecture.lastPlayedPoint = lectureInfo.lastPlayedPoint
            }

            if let downloadedLecture = downloadedLectures.first(where: { $0.id == lecture.id }) {
                lecture.downloadState = downloadedLecture.downloadStateEnum
            }

            return lecture
        }
        return lectures
    }
}
