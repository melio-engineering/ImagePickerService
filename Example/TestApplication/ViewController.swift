//
//  ViewController.swift
//  TestApplication
//
//  Created by Sion Sasson on 31/03/2022.
//

import UIKit
import ImagePickerService
import Combine

class ViewController: UIViewController {
    
    //MARK: - Private variables
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var errorLabel: UILabel!
    private var anyCancellables: Set<AnyCancellable> = []
    
    //MARK: - Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    //MARK: - Actions
    @IBAction func openCamera(_ sender: Any) {
        runService(withSource: .camera)
    }
    
    @IBAction func pickImageTapped(_ sender: Any) {
        runService(withSource: .library)
    }
}

private extension ViewController {
    func runService(withSource source: ImagePickerServiceSource) {
        errorLabel.text = nil
        ImagePickerService.runImagePickingService(withSource: source,
                                                  permissionController: PermissionViewController(),
                                                  fromController: self)
        .sink { [unowned self] completion in
            switch completion {
            case .finished:
                break
            case .failure(let error):
                errorLabel.text = error.localizedDescription
            }
        } receiveValue: { [unowned self] image in
            imageView.image = image
        }
        .store(in: &anyCancellables)
    }
}

