platform :ios, '15.0'

target 'newTestSwiftData' do
  use_frameworks!

  # Pods for newTestSwiftData
  pod 'JXPhotoBrowser'
  pod 'Alamofire'
  pod 'BBSwiftUIKit'
  pod 'SDWebImageSwiftUI'

  post_install do |installer|
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
        config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
      end
    end
  end
end
