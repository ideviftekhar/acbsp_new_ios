//
//  PlaylistViewController.swift
//  SrilaPrabhupada
//
//  Created by IE06 on 20/08/22.
//

import UIKit
import FirebaseFirestore

class PlaylistViewController: BaseSearchViewController {

    @IBOutlet weak var playlistSegmentControl: UISegmentedControl!

    @IBOutlet weak var playlistTableView: UITableView!

    private let cellIdentifier = "PlaylistCell"
    private let loadingIndicator: UIActivityIndicatorView = UIActivityIndicatorView(style: .medium)

    let playlistViewModel: PlaylistViewModel = DefaultPlaylistViewModel()
    var playlists: [Playlist] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        playlistTableView.register(UINib(nibName: cellIdentifier, bundle: nil), forCellReuseIdentifier: cellIdentifier)

        do {
            loadingIndicator.color = UIColor.gray
            self.view.addSubview(loadingIndicator)
            loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
            loadingIndicator.hidesWhenStopped = true
            loadingIndicator.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
            loadingIndicator.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        }

        refreshAsynchronous()
    }

    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        refreshAsynchronous()
    }

    override func refreshAsynchronous() {

        switch playlistSegmentControl.selectedSegmentIndex {
        case 0:

            showLoading()
            playlistViewModel.getPublicPlaylist(searchText: searchText, sortyType: selectedSortType, filter: selectedFilters, completion: { [self] result in
                hideLoading()

                switch result {
                case .success(let playlists):
                    reloadData(with: playlists)
                case .failure(let error):
                    showAlert(title: "Error", message: error.localizedDescription)
                }
            })
        case 1:

            showLoading()
            playlistViewModel.getPrivatePlaylist(searchText: searchText, sortyType: selectedSortType, filter: selectedFilters, completion: { [self] result in
                hideLoading()

                switch result {
                case .success(let playlists):
                    reloadData(with: playlists)
                case .failure(let error):
                    showAlert(title: "Error", message: error.localizedDescription)
                }
            })
        default:
            break
        }

    }
}

extension PlaylistViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return playlists.count
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! PlaylistCell

        let playlist = playlists[indexPath.row]

        cell.model = playlist

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let playlist = playlists[indexPath.row]

        let controller = UIStoryboard.playlists.instantiate(PlaylistLecturesViewController.self)
        controller.playlist = playlist
        self.navigationController?.pushViewController(controller, animated: true)
    }
}

extension PlaylistViewController {

    func showLoading() {
        loadingIndicator.startAnimating()
        playlistSegmentControl.isEnabled = false
    }

    func hideLoading() {
        loadingIndicator.stopAnimating()
        playlistSegmentControl.isEnabled = true
   }

    func reloadData(with playlists: [Playlist]) {
        self.playlists = playlists
        self.playlistTableView.reloadData()
    }
}
