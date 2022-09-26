//
//  PoppularLectureViewController.swift
//  SrilaPrabhupada
//
//  Created by IE06 on 29/08/22.
//

import UIKit

class PopularLectureViewController: BaseLectureViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        do {
            list.noItemTitle = "No Popular Lectures"
            list.noItemMessage = "Popular lectures will display here"
        }
    }
}
