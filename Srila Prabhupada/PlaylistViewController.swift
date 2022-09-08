//
//  PlaylistViewController.swift
//  SrilaPrabhupada
//
//  Created by IE06 on 20/08/22.
//

import UIKit

class PlaylistViewController: BaseSearchViewController {
 
    @IBOutlet weak var playlistSegmentControl: UISegmentedControl!
    
    @IBOutlet weak var playListTableView: UITableView!
    private let cellIdentifier = "PlaylistCell"

    var playlists: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        playlists = ["Public Playlist 1", "Public Playlist 2", "Public Playlist 3", "Public Playlist 4", "Public Playlist 5"]
    }
    
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            playlists = ["Public Playlist 1", "Public Playlist 2", "Public Playlist 3", "Public Playlist 4", "Public Playlist 5"]
        case 1:
            playlists = ["Private Playlist 1", "Private Playlist 2", "Private Playlist 3", "Private Playlist 4", "Private Playlist 5"]
        default:
            break
        }
        playListTableView.reloadData()
    }
}

extension PlaylistViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playlists.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlaylistCell", for: indexPath)

        let playlist = playlists[indexPath.row]
        cell.textLabel?.text = playlist

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let storyboard = UIStoryboard(name: "Playlists", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "PlaylistLecturesViewController") as! PlaylistLecturesViewController
        self.navigationController?.pushViewController(controller, animated: true)
    }
}
