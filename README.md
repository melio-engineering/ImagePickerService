# ImagePickerService

[![Version](https://img.shields.io/cocoapods/v/ImagePickerService.svg?style=flat)](https://cocoapods.org/pods/ImagePickerService)
[![License](https://img.shields.io/cocoapods/l/ImagePickerService.svg?style=flat)](https://cocoapods.org/pods/ImagePickerService)
[![Platform](https://img.shields.io/cocoapods/p/ImagePickerService.svg?style=flat)](https://cocoapods.org/pods/ImagePickerService)
[![MobSF](https://github.com/melio-engineering/ImagePickerService/actions/workflows/mobsf.yml/badge.svg?branch=main)](https://github.com/melio-engineering/ImagePickerService/actions/workflows/mobsf.yml)
[![UI Tests](https://github.com/melio-engineering/ImagePickerService/actions/workflows/ios.yml/badge.svg)](https://github.com/melio-engineering/ImagePickerService/actions/workflows/ios.yml)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

ImagePickerService is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'ImagePickerService'
```

## How to use?

That's simple :)

```swift
//PermissionedViewController is a UIViewController that conforms to PermissionViewControllerProtocol
let permissionController: PermissionedViewController = ....
let presentingController: UIViewController = ....
let source: ImagePickerServiceSource = ... //Camera or library

ImagePickerService.runImagePickingService(withSource: source,
                                          permissionController: permissionController,
                                          fromController: presentingController)
.sink { completion in
    switch completion {
    case .failure(let error):
        //got an error - oh boy...
        break
    case .finished:
        //service is done with flying colors..
        break
    }
} receiveValue: { image in
    //User selected/scanned/took picture an image
}
.store(in: &anyCancellables)
```

## Do you want to use the iOS native scanner?

Easy... simply run the service with the parameter 
```swift
useNativeScanner = true
```

## Author

Sion Sasson, sion.sasson@melio.com

## License

ImagePickerService is available under the MIT license. See the LICENSE file for more info.
