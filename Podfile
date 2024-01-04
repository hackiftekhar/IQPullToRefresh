project 'Pull To Refresh Demo.xcodeproj'

platform :ios, '13.0'
use_frameworks!

target 'Pull To Refresh Demo' do
    pod 'IQPullToRefresh', :path => '.'
    pod 'IQAPIClient'
    pod 'SwiftLint'
    pod 'IQListKit'
    pod 'AlamofireImage'
end

post_install do |installer|

  installer.pods_project.targets.each do |target|

    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      if config.name == 'Debug'
        config.build_settings["EXCLUDED_ARCHS[sdk=iphoneos*]"] = "x86_64"
        config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64" # For apple silicon, it should be "x86_64"
        config.build_settings["EXCLUDED_ARCHS[sdk=macosx*]"] = "arm64" # For apple silicon, it should be "x86_64"
      end
     end
    if target.respond_to?(:product_type) and target.product_type == "com.apple.product-type.bundle"
      target.build_configurations.each do |config|
        config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
      end
    end
  end
end
