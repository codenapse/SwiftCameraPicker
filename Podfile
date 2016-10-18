# Uncomment this line to define a global platform for your project
platform :ios, '9.0'


target 'SwiftCameraPicker' do
  # Comment this line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  pod 'CameraManager', :git => 'git@github.com:codenapse/CameraManager.git', :branch => '2.3-support'
  pod 'CocoaLumberjack/Swift'

  target 'SwiftCameraPickerTests' do
    inherit! :search_paths
    
    #    pod 'CameraManager', '~> 2.2'
  end
  
  post_install do |installer|
      installer.pods_project.targets.each do |target|
          target.build_configurations.each do |config|
              config.build_settings['SWIFT_VERSION'] = '2.3'
          end
      end
  end
  
end
