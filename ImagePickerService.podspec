Pod::Spec.new do |s|
  s.name             = 'ImagePickerService'
  s.version          = '1.0.0'
  s.summary          = 'A delightful image picker service for iOS 14 and up - including scanning option'

  s.description      = <<-DESC
This small library contains a service which handle a single (soon to be multiply) image picking from camera and the device library.
It handles the whole process inculding:

1. Permissing handling
2. Displaying a controller (optional) before asking the user for permission with the native popup
3. Displaying a controller (optional) for handling denied status by the user - with go to settings option
4. Scanning using the Vision framework - optional - instead of using the default camera
5. Custom errors published so whoever uses this service will know what is going on.
                       DESC

  s.homepage         = 'https://github.com/melio-engineering/ImagePickerService'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Sion Sasson' => 'sion.sasson@melio.com' }
  s.source           = { :git => 'https://github.com/melio-engineering/ImagePickerService.git', :tag => s.version.to_s }

  s.ios.deployment_target = '14.0'
  s.swift_versions = ['5.0']
  s.source_files = 'ImagePickerService/Classes/**/*.{swift}'
  s.frameworks = 'UIKit', 'VisionKit', 'Photos', 'CoreServices', 'Combine', 'OSLog'
end
