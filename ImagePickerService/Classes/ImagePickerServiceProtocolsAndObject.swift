//
//  ImagePickerServiceProtocolsAndObject.swift
//  MelioSDK
//
//  Created by Sion Sasson on 29/03/2022.
//

import Combine
import UIKit
import OSLog

//MARK: - Typealiases that the service uses
typealias PermissionedViewController = PermissionViewControllerProtocol & UIViewController
typealias ServiceLog = (String, OSLogType)

enum PermissionViewControllerAction {
    case close
    case allow
    case dontAllow
    case settings
}

/// The protocol of the auth contorller with the needed functions and action
protocol PermissionViewControllerProtocol {
    /// Publisher that show which action the user chose...
    var actionTapSubject: PassthroughSubject<PermissionViewControllerAction, Never> { get }
    /// The source of the permission we're displaying - probably will change the message
    var source: ImagePickerServiceSource! { get set }
}

/// The possible values for the service source
enum ImagePickerServiceSource {
    case camera
    case library
}

/// What kind of error this service can produce
enum ImagePickerServiceError: Error {
    case notSupported
    case imageDoesNotExist
    case missingPermission
    case unknownPermissionState
    case unknownError
    case emptyScan
}
