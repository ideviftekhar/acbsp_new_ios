//
//  Lecture+Operations.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 8/4/23.
//

import Foundation

extension Lecture {

    static func filter(lectures: [Lecture], lectureIDs: [Int], excludePlayed: Bool, maxCount: Int? = nil) -> (filtered: [Lecture], remaining: [Lecture]) {
        guard !lectureIDs.isEmpty else {
            return ([], lectures)
        }

        let lectureIdIndexHashTable: [Int: Int] = lectures.enumerated().reduce(into: [Int: Int]()) { result, obj in
            if result[obj.element.id] == nil {
                result[obj.element.id] = obj.offset
            }
        }

        var filteredLectures: [Lecture] = []
        var removedIndexes: IndexSet = IndexSet()
        for lectureID in lectureIDs {
            if let index = lectureIdIndexHashTable[lectureID] {
                let lecture: Lecture = lectures[index]
                if excludePlayed && lecture.isCompleted {
                    continue
                }

                filteredLectures.append(lecture)
                removedIndexes.insert(index)

                if let maxCount = maxCount, filteredLectures.count >= maxCount {
                    break
                }
            }
        }

        var remainingLectures = lectures
        remainingLectures.remove(atOffsets: removedIndexes)
        return (filteredLectures, remainingLectures)
    }
}
