//
//  ImagePickerService.swift
//  MelioSDK
//
//  Created by Sion Sasson on 22/03/2022.
//

import Combine
import UIKit
import MobileCoreServices
import Photos
import VisionKit

/// This service handles image picking and regular camera.
public class ImagePickerService: NSObject {
    
    /// Return the photo library auth status
    class var photoAuthorizationStatus: PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }
    
    /// Return the current camera authorization status
    class var cameraAuthorizationStatus: AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .video)
    }
    
    //Publisher that sends log strings with log type.. You can subscribe to it and add it to you log system
    var logSubject: PassthroughSubject<ServiceLog, Never> = PassthroughSubject<ServiceLog, Never>()
    /// Setting this to `True` will use the `VNDocumentCameraViewController` to capture image when using the camera source
    var useNativeScanner: Bool = false
    
    //MARK: - Private class variables
    private static var service: ImagePickerService?
    
    //MARK: - Private variables
    private var serviceFinished: PassthroughSubject<UIImage?, Error> = PassthroughSubject<UIImage?, Error>()
    private var pickerDismissedSubject: PassthroughSubject<Void, Error> = PassthroughSubject<Void, Error>()
    private var anyCancellables: Set<AnyCancellable> = []
    private var permissionController: PermissionedViewController?
    private weak var presentedController: UIViewController?
    private weak var presentingController: UIViewController?
    private let source: ImagePickerServiceSource
    private let mediaTypes: [String]
    private var isSourceSupported: Bool {
        switch source {
        case .library:
            return UIImagePickerController.isSourceTypeAvailable(.photoLibrary)
        case .camera where useNativeScanner == false:
            return UIImagePickerController.isSourceTypeAvailable(.camera)
        case .camera where useNativeScanner == true:
            return VNDocumentCameraViewController.isSupported && UIImagePickerController.isSourceTypeAvailable(.camera)
        default:
            return true
        }
    }
    
    //MARK: - Publisher
    public class func runImagePickingService(withSource source: ImagePickerServiceSource,
                                      permissionController: PermissionedViewController? = nil,
                                      fromController controller: UIViewController) -> Future<UIImage?, Error> {
        service = ImagePickerService(withSource: source)
        
        service?.permissionController = permissionController
        service?.permissionController?.source = source
        
        return Future() { promise in
            service?.serviceFinished
                .sink { completion in
                    switch completion {
                    case .finished:
                        //If we're here there's something wrong cause if the service finished with no error the promise should be completed..
                        //That's why we will send an unknown error here..
                        promise(.failure(ImagePickerServiceError.unknownError))
                    case .failure(let err):
                        promise(.failure(err))
                    }
                    
                    service = nil
                } receiveValue: { image in
                    promise(.success(image))
                }
                .store(in: &service!.anyCancellables)
            
            service?.start(fromController: controller)
        }
    }
    
    //MARK: - Initializer
    /// Initialize this service with capturing or library image picking
    /// - Parameters:
    ///   - source: Which source are we using... supports camera and library at the moment
    ///   - mediaTypes: Which media type we support? default is `kUTTypeImage`
    private init(withSource source: ImagePickerServiceSource = .library,
         mediaTypes: [String] = [kUTTypeImage as String]) {
        self.mediaTypes = mediaTypes
        self.source = source
        super.init()
    }
}

//MARK: - Private extension
private extension ImagePickerService {
    /// Starting everything..
    /// 1. First we will check that the source is supported
    /// 2. Then we will check that the user authorised that source - and if not we will ask him/her
    /// 3. Show the UI and wait for the user to do stuff
    /// - Parameter controller: Which controller are we presenting from
    func start(fromController controller: UIViewController) {
        guard isSourceSupported else {
            sendFailure(withError: ImagePickerServiceError.notSupported)
            return
        }
        
        presentingController = controller
        
        switch source {
        case .library:
            checkLibraryPermission()
        case .camera:
            checkCameraPermission()
        }
    }

    func checkCameraPermission() {
        let cameraAuthorizationStatus = ImagePickerService.cameraAuthorizationStatus
        logSubject.send(("Camera current permission is \(cameraAuthorizationStatus)", .info))
        
        switch cameraAuthorizationStatus {
        case .authorized:
            presentUI()
        case .notDetermined:
            //If the service holds a pre permission screen we will present it
            guard presentPermissionControllerIfNeeded() == false else {
                return
            }
            
            requestCameraAuthorization()
        case .denied, .restricted:
            //If the service holds a pre permission screen we will present it
            guard presentPermissionControllerIfNeeded() == false else {
                return
            }
            
            sendFailure(withError: ImagePickerServiceError.missingPermission)
        @unknown default:
            sendFailure(withError: ImagePickerServiceError.unknownPermissionState)
        }
    }
    
    func checkLibraryPermission() {
        let photoAuthorizationStatus = ImagePickerService.photoAuthorizationStatus
        logSubject.send(("Library current permission is \(photoAuthorizationStatus)", .info))
        
        switch photoAuthorizationStatus {
        case .notDetermined:
            //If the service holds a pre permission screen we will present it
            guard presentPermissionControllerIfNeeded() == false else { return }
            requestLibraryAuthorization()
        case .restricted, .denied:
            //We might wanna show a controller that explains that we're missing permissions and maybe send the user to the settings
            guard presentPermissionControllerIfNeeded() == false else { return }
            sendFailure(withError: ImagePickerServiceError.missingPermission)
        case .authorized, .limited:
            presentUI()
        @unknown default:
            sendFailure(withError: ImagePickerServiceError.unknownPermissionState)
        }
    }
    
    /// Handling the error publishing, call it if you have a failing point in this service
    /// - Parameter error: Which error occoured
    func sendFailure(withError error: Error) {
        logSubject.send(("Image picker service: \(source) completed with failure - due to \(error)", .error))
        Just(true)
            .flatMap { [unowned self] _ -> Future<UIImage?, Never> in
                dismissIfNeeded(withImage: nil)
            }
            .sink(receiveCompletion: { [weak self] _ in
                self?.serviceFinished.send(completion: Subscribers.Completion.failure(error))
            }, receiveValue: { _ in })
            .store(in: &anyCancellables)
    }
    
    /// Send completion publish with selected image
    /// - Parameter image: The image the selected
    func sendCompletion(withImage image: UIImage? = nil) {
        logSubject.send(("Image picker service completed", .info))
        Just(image)
            .flatMap { [unowned self] image -> Future<UIImage?, Never> in
                dismissIfNeeded(withImage: image)
            }
            .sink(receiveCompletion: { [weak self] _ in
                if let image = image { self?.serviceFinished.send(image) }
                self?.serviceFinished.send(completion: Subscribers.Completion.finished)
            }, receiveValue: { _ in })
            .store(in: &anyCancellables)
    }
    
    /// This will decide which UI to present
    func presentUI() {
        switch source {
        case .camera where useNativeScanner == true:
            showScanner()
        default:
            showImagePickerContorller()
        }
    }
    
    /// This will show the image picker with the class source and media type
    func showImagePickerContorller() {
        let imagePickerViewController: CustomImagePickerController = CustomImagePickerController()
        imagePickerViewController.sourceType = source == .camera ? .camera : .photoLibrary
        imagePickerViewController.mediaTypes = mediaTypes
        imagePickerViewController.delegate = self
        
        //We force popover so avoid unbalaced calls when showing camera over permission screen
        //So we ask we the source is camera and nothing is presented..
        if source == .camera, presentedController != nil {
            imagePickerViewController.modalPresentationStyle = .popover
        }
        
        imagePickerViewController.dismissedByUser
            .sink { [weak self] _ in
                self?.sendCompletion()
            }
            .store(in: &anyCancellables)
        
        switch presentedController {
        case nil:
            //Nothing is presented - no permission screen is displayed... so we can simply present the image picker
            presentingController?.present(imagePickerViewController, animated: true)
            presentedController = imagePickerViewController
        case _:
            //We already presenting something - probably the permission controller.. so it is the one who should present
            presentedController?.present(imagePickerViewController, animated: true)
        }
    }
    
    /// This will show the `VNDocumentCameraViewController` scanner controller
    func showScanner() {
        let documentCameraViewController = VNDocumentCameraViewController()
        documentCameraViewController.delegate = self
        presentingController?.present(documentCameraViewController, animated: true)
        presentedController = documentCameraViewController
    }
    
    /// If the service presented a controller it will dismiss it before completing...
    /// - Parameter image: The output of the service.. once it completes the dismissing it will publish the image
    /// - Returns: Future publisher to notify when the dismiss was done...
    func dismissIfNeeded(withImage image: UIImage?) -> Future<UIImage?, Never> {
        Future() { [weak self] promise in
            switch self?.presentedController {
            case nil:
                promise(.success(image))
            case _:
                self?.presentingController?.dismiss(animated: true, completion: {
                    promise(.success(image))
                })
            }
        }
    }
    
    /// Present the pre permission controller if exist
    /// - Returns: `true` if it was displayed..  `false` otherwised
    func presentPermissionControllerIfNeeded() -> Bool {
        guard let controller = permissionController else {
            return false
        }
        
        controller.actionTapSubject
            .sink { [weak self] action in
                switch action {
                case .settings:
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(settingsUrl) }
                case .dontAllow:
                    self?.sendFailure(withError: ImagePickerServiceError.missingPermission)
                case .close:
                    self?.sendCompletion()
                case .allow where self?.source == .library:
                    self?.requestLibraryAuthorization()
                case .allow where self?.source == .camera:
                    self?.requestCameraAuthorization()
                default:
                    //Not support to be here...
                    assert(true, "You shouldn't be here")
                    self?.sendCompletion()
                }
            }
            .store(in: &anyCancellables)
        
        controller.modalTransitionStyle = .crossDissolve
        controller.modalPresentationStyle = .fullScreen
        
        presentingController?.present(controller, animated: true)
        presentedController = controller
        
        return true
    }
    
    
    /// Asking for native permission to see the library
    /// 1. If user allow we will show the picker
    /// 2. if not... we will finish this service
    func requestLibraryAuthorization() {
        //Now we will see the native popup and we will continue only if the user chose allow/limited
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
            self?.logSubject.send(("New library permission status: \(status)", .info))
            DispatchQueue.main.async {
                
                switch status {
                case .limited, .authorized:
                    self?.presentUI()
                default:
                    self?.sendFailure(withError: ImagePickerServiceError.missingPermission)
                }
            }
        }
    }
    
    /// Asking for native permission to use the camera
    /// 1. If user allow we will show the camera (scanner to reg camera)
    /// 2. if not... we will finish this service
    func requestCameraAuthorization() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] authorized in
            self?.logSubject.send(("New camera permission: \(authorized ? "authorized" : "not authorized")", .info))
            DispatchQueue.main.async {
                authorized ? self?.presentUI() : self?.sendFailure(withError: ImagePickerServiceError.missingPermission)
            }
        }
    }
}

//MARK: - UIImagePickerControllerDelegate, UINavigationControllerDelegate
extension ImagePickerService: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        logSubject.send(("User canceled the image picker", .info))
        sendCompletion()
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else  {
            sendFailure(withError: ImagePickerServiceError.imageDoesNotExist)
            return
        }
        
        logSubject.send(("Image was picked", .info))
        sendCompletion(withImage: image)
    }
}

extension ImagePickerService: VNDocumentCameraViewControllerDelegate {
    // The client is responsible for dismissing the document camera in these callbacks.
    // The delegate will receive one of the following calls, depending whether the user saves or cancels, or if the session fails.
    public func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        logSubject.send(("User completed a scan with \(scan.pageCount) pages", .info))
        guard scan.pageCount > 0 else {
            sendFailure(withError: ImagePickerServiceError.emptyScan)
            return
        }
        
        sendCompletion(withImage: scan.imageOfPage(at: 0))
    }
    
    // The delegate will receive this call when the user cancels.
    public func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        logSubject.send(("User canceled the scanner", .info))
        sendCompletion()
    }

    // The delegate will receive this call when the user is unable to scan, with the following error.
    public func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        sendFailure(withError: error)
    }
}
