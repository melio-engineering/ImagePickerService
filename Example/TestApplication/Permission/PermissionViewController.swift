//
//  PermissionViewController.swift
//  TestApplication
//
//  Created by Sion Sasson on 31/03/2022.
//

import UIKit
import ImagePickerService
import Combine

class PermissionViewController: PermissionedViewController {
    
    //MARK: - PermissionedViewController
    var actionTapSubject: PassthroughSubject<PermissionViewControllerAction, Never> = PassthroughSubject<PermissionViewControllerAction, Never>()
    var source: ImagePickerServiceSource!
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    @IBAction func clostTapped(_ sender: Any) {
        actionTapSubject.send(.close)
    }
    
    @IBAction func allowTapped(_ sender: Any) {
        actionTapSubject.send(.allow)
    }
    
    @IBAction func goToSettingsTapped(_ sender: Any) {
        actionTapSubject.send(.settings)
    }
    
    @IBAction func dontAllowTapped(_ sender: Any) {
        actionTapSubject.send(.dontAllow)
    }
}
