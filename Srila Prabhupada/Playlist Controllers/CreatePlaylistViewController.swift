//
//  CreatePlaylistViewController.swift
//  Srila Prabhupada
//
//  Created by IE06 on 10/10/22.
//

import UIKit

protocol CreatePlaylistViewControllerDelegate: AnyObject {
    func controller(_ controller: CreatePlaylistViewController, didAdd playlist: Playlist)
}

class CreatePlaylistViewController: UIViewController {

    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var privatePlaylistButton: UIButton!
    @IBOutlet weak var publicPlaylistButton: UIButton!

    @IBOutlet weak var playlistTitleTextField: UITextField!
    @IBOutlet weak var categoryTextField: UITextField!

    @IBOutlet weak var descriptionTextView: UITextView!

    @IBOutlet private var loadingIndicatorView: UIActivityIndicatorView!

    private var playlistType: PlaylistType = .private

    let playlistViewModel: PlaylistViewModel = DefaultPlaylistViewModel()

    weak var delegate: CreatePlaylistViewControllerDelegate?

    var playlist: Playlist?

    override func viewDidLoad() {
        super.viewDidLoad()
        privatePlaylistButton.setImage(UIImage(compatibleSystemName: "circle.inset.filled"), for: .normal)
        publicPlaylistButton.setImage(UIImage(compatibleSystemName: "circle"), for: .normal)
        doneButton.style = .done
        doneButton.tintColor = .white
        cancelButton.tintColor = .white

    }

    @IBAction func cancelBarButtonTapped(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func doneBarButtonTapped(_ sender: UIBarButtonItem) {

        guard let title = playlistTitleTextField.text, !title.isEmpty else {
            showAlert(title: "Invalid Title", message: "Please enter playlist title")
            return
        }

        guard let category = categoryTextField.text, !category.isEmpty else {
            showAlert(title: "Invalid Category", message: "Please enter playlist category")
            return
        }

        guard let description = descriptionTextView.text, !description.isEmpty else {
            showAlert(title: "Invalid Description", message: "Please enter playlist description")
            return
        }

        showLoading()
        playlistViewModel.createPlaylist(title: title, category: category, description: description, listType: playlistType) { [self] result in
            hideLoading()

            switch result {

            case .success(let playlist):
                self.dismiss(animated: true)
                self.delegate?.controller(self, didAdd: playlist)
            case .failure(let error):
                showAlert(title: "Error", message: error.localizedDescription)
            }

        }
        print("done button tapped")
    }

    @IBAction func privateButtonTapped(_ sender: UIButton) {
        playlistType = .private
        privatePlaylistButton.setImage(UIImage(compatibleSystemName: "circle.inset.filled"), for: .normal)
        publicPlaylistButton.setImage(UIImage(compatibleSystemName: "circle"), for: .normal)

    }
    @IBAction func publicButtonTapped(_ sender: UIButton) {
        playlistType = .public
        publicPlaylistButton.setImage(UIImage(compatibleSystemName: "circle.inset.filled"), for: .normal)
        privatePlaylistButton.setImage(UIImage(compatibleSystemName: "circle"), for: .normal)
    }
}

extension CreatePlaylistViewController {

    private func showLoading() {
        loadingIndicatorView.startAnimating()

        cancelButton.isEnabled = false
        doneButton.isEnabled = false

        privatePlaylistButton.isEnabled = false
        publicPlaylistButton.isEnabled = false
        playlistTitleTextField.isEnabled = false
        categoryTextField.isEnabled = false
        descriptionTextView.isEditable = false
    }

    private func hideLoading() {
        loadingIndicatorView.stopAnimating()

        cancelButton.isEnabled = true
        doneButton.isEnabled = true

        privatePlaylistButton.isEnabled = true
        publicPlaylistButton.isEnabled = true
        playlistTitleTextField.isEnabled = true
        categoryTextField.isEnabled = true
        descriptionTextView.isEditable = true
    }
}
