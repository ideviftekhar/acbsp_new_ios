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
                var lecture = lecture
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

    static func refreshLectureWithLectureInfo(lectures: [Lecture], lectureInfos: [LectureInfo], downloadedLectures: [DBLecture], progress: ((_ progress: CGFloat) -> Void)?) -> [Lecture] {

        let total: CGFloat = CGFloat(lectures.count)
        var iteration: CGFloat = 0

        var updatedLectures: [Lecture] = []
        for var lecture in lectures {
            if let lectureInfo = lectureInfos.first(where: { $0.id == lecture.id }) {
                lecture.isFavourite = lectureInfo.isFavourite
                if lectureInfo.lastPlayedPoint == -1 {
                    lecture.lastPlayedPoint = lecture.length
                } else {
                    lecture.lastPlayedPoint = lectureInfo.lastPlayedPoint
                }
            }

            if let downloadedLecture = downloadedLectures.first(where: { $0.id == lecture.id }) {
                lecture.downloadState = downloadedLecture.downloadStateEnum
                lecture.downloadError = downloadedLecture.downloadError
            }

            updatedLectures.append(lecture)

            iteration += 1
            if let progress = progress {
                DispatchQueue.main.async {
                    progress(iteration/total)
                }
            }
        }

        return updatedLectures
    }
}
