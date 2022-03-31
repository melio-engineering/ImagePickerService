//
//  CustomImagePickerController.swift
//  MelioSDK
//
//  Created by Sion Sasson on 31/03/2022.
//

import UIKit
import Combine

/// This is Custom image picker that can publish when it was dragged down for dismissal
class CustomImagePickerController: UIImagePickerController {
    
    //MARK: - Internal variables
    /// Publisher that will tell when the `CustomImagePickerController` was dismissed by the user by dragging down
    let dismissedByUser: PassthroughSubject<Void, Never> = PassthroughSubject<Void, Never>()
    
    //MARK: - Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        presentationController?.delegate = self
    }
}

//MARK: - UIAdaptivePresentationControllerDelegate
extension CustomImagePickerController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        dismissedByUser.send()
    }
}
