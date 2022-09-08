//
//  BaseLectureViewController.swift
//  SrilaPrabhupada
//
//  Created by IE06 on 08/09/22.
//

import UIKit

class BaseLectureViewController: BaseSearchViewController {

    @IBOutlet weak var lectureTebleView : UITableView!
    private let cellIdentifier =  "LectureCell"

    var lectures: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
       
    }
}

extension BaseLectureViewController : UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return lectures.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        
        let aLecture = lectures[indexPath.row]
        cell.textLabel?.text = aLecture

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
