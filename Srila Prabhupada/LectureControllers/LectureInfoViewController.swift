//
//  LectureInfoViewController.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 7/5/23.
//

import UIKit
import AlamofireImage
import IQListKit

class LectureInfoViewController: UIViewController {

    @IBOutlet var thumbnailBackgroundImageView: UIImageView!
    @IBOutlet var thumbnailImageView: UIImageView!

    @IBOutlet private var lectureInfoTebleView: UITableView!

    var lecture: Lecture?

    private(set) lazy var list = IQList(listView: lectureInfoTebleView, delegateDataSource: self)
    private lazy var serialListKitQueue = DispatchQueue(label: "ListKitQueue_\(Self.self)", qos: .userInteractive)

    override func viewDidLoad() {
        super.viewDidLoad()
        refreshUI(animated: false)
    }

    @IBAction func doneAction(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
}

extension LectureInfoViewController: IQListViewDelegateDataSource {

    private func refreshUI(animated: Bool? = nil) {

        let placeholderImage: UIImage? = UIImage(named: "playerViewLogo")?.withRadius(radius: 10)
        if let url = lecture?.thumbnailURL {
            thumbnailImageView.af.setImage(withURL: url, placeholderImage: placeholderImage, filter: RoundedCornersFilter(radius: 10))
            thumbnailBackgroundImageView.af.setImage(withURL: url, placeholderImage: placeholderImage, filter: RoundedCornersFilter(radius: 10))
        } else {
            thumbnailImageView.image = placeholderImage
            thumbnailBackgroundImageView.image = placeholderImage
        }

        let headerFooterSize = CGSize(width: self.lectureInfoTebleView.frame.width, height: 30)

        serialListKitQueue.async { [self] in

            var userModels: [LectureInfoCell.Model] = []
            var legacyDataModels: [LectureInfoCell.Model] = []
            var developerModels: [LectureInfoCell.Model] = []

            if let lecture = lecture {
                userModels.append(.init(title: "Title", subtitle: lecture.titleDisplay, axis: .vertical))
                userModels.append(.init(title: "Duration", subtitle: lecture.lengthTime.displayString, axis: .vertical))
                userModels.append(.init(title: "Recording Date", subtitle: lecture.dateOfRecording.display_dd_MMM_yyyy, axis: .vertical))
                userModels.append(.init(title: "Location", subtitle: lecture.location.displayString, axis: .vertical))

                let places = lecture.place.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                if !places.isEmpty {
                    userModels.append(.init(title: "Place", subtitle: places.joined(separator: ", "), axis: .vertical))
                }

                let lengthTypes = lecture.lengthType.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                if !lengthTypes.isEmpty {
                    userModels.append(.init(title: "Length Type", subtitle: lengthTypes.joined(separator: ", "), axis: .vertical))
                }

                let categories = lecture.category.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                if !categories.isEmpty {
                    userModels.append(.init(title: "Category", subtitle: categories.joined(separator: ", "), axis: .vertical))
                }

                if !lecture.language.main.isEmpty {
                    userModels.append(.init(title: "Main Language", subtitle: lecture.language.main, axis: .vertical))
                }

                let translations = lecture.language.translations.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                if !translations.isEmpty {
                    userModels.append(.init(title: "Translations", subtitle: translations.joined(separator: ", "), axis: .vertical))
                }

                let tags = lecture.tags.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                if !tags.isEmpty {
                    userModels.append(.init(title: "Tags", subtitle: tags.joined(separator: ", "), axis: .vertical))
                }

                let descriptions = lecture.description.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                if !descriptions.isEmpty {
                    userModels.append(.init(title: "Description", subtitle: descriptions.joined(separator: "\n\n"), axis: .vertical))
                }

                if !lecture.legacyData.lectureCode.isEmpty {
                    legacyDataModels.append(.init(title: "Lecture Code", subtitle: lecture.legacyData.lectureCode, axis: .vertical))
                }
                if !lecture.legacyData.slug.isEmpty {
                    legacyDataModels.append(.init(title: "Slug", subtitle: lecture.legacyData.slug, axis: .vertical))
                }
                if !lecture.legacyData.verse.isEmpty {
                    legacyDataModels.append(.init(title: "Verse", subtitle: lecture.legacyData.verse, axis: .vertical))
                }
                if lecture.legacyData.wpId != 0 {
                    legacyDataModels.append(.init(title: "WP ID", subtitle: "\(lecture.legacyData.wpId)", axis: .vertical))
                }

                developerModels.append(.init(title: "Lecture ID", subtitle: "\(lecture.id)", axis: .vertical))
                if let creationTimestamp = lecture.creationTimestamp {
                    let dateTimeString = DateFormatter.localizedString(from: creationTimestamp, dateStyle: .medium, timeStyle: .short)
                    developerModels.append(.init(title: "Created Date", subtitle: dateTimeString, axis: .vertical))
                }
                if let lastModifiedTimestamp = lecture.lastModifiedTimestamp, lastModifiedTimestamp != lecture.creationTimestamp {
                    let dateTimeString = DateFormatter.localizedString(from: lastModifiedTimestamp, dateStyle: .medium, timeStyle: .short)
                    developerModels.append(.init(title: "Modified Date", subtitle: dateTimeString, axis: .vertical))
                }
            }

            list.reloadData({

                let userModelsSection = IQSection(identifier: "userModels", header: "Lecture Information", headerSize: headerFooterSize, footerSize: headerFooterSize)
                list.append([userModelsSection])
                list.append(LectureInfoCell.self, models: userModels, section: userModelsSection)

                if !legacyDataModels.isEmpty {
                    let legacyDataSection = IQSection(identifier: "legacyDataModels", header: "Data", headerSize: headerFooterSize, footerSize: headerFooterSize)
                    list.append([legacyDataSection])
                    list.append(LectureInfoCell.self, models: legacyDataModels, section: legacyDataSection)
                }

                if !developerModels.isEmpty {
                    let developerSection = IQSection(identifier: "developerModels", header: "Others", headerSize: headerFooterSize, footerSize: headerFooterSize)
                    list.append([developerSection])
                    list.append(LectureInfoCell.self, models: developerModels, section: developerSection)
                }

            }, animatingDifferences: animated ?? false, completion: nil)
        }
    }
}

//let resources: Resources
//let search: Search

//var downloadState: DBLecture.DownloadState = .notDownloaded
//var downloadError: String?
//var isFavorite: Bool
//var lastPlayedPoint: Int = 0
//
//var isCompleted: Bool {
//    lastPlayedPoint == length || lastPlayedPoint == -1
//}
//
//var playProgress: CGFloat {
//    let progress: CGFloat
//
//    if length != 0 {
//        progress = CGFloat(lastPlayedPoint) / CGFloat(length)
//    } else {
//        progress = 0
//    }
//
//    return progress
//}
