platform :ios, '13.0'

def shared_pods
  use_frameworks!
  inhibit_all_warnings!
  
  pod 'SideMenu'

  pod 'FirebaseAuth'
  pod 'FirebaseCore'
#  pod 'FirebaseAnalytics'
  pod 'FirebaseCrashlytics'
  pod 'FirebaseDynamicLinks'
  pod 'FirebaseFirestore'
  pod 'FirebaseFirestoreSwift'
  pod 'FirebaseMessaging'

  pod 'GoogleSignIn'
  pod 'GoogleSignInSwiftSupport'

  pod 'SkyFloatingLabelTextField'
  pod 'IQKeyboardManagerSwift'
  pod 'IQListKit'

  pod 'BEMCheckBox'
  pod 'DeviceKit'
  pod 'AlamofireImage'

  pod "MBCircularProgressBar"

  pod 'StatusAlert'
  pod 'SKActivityIndicatorView'

  pod 'MarqueeLabel'

  pod'Charts'
  pod'SwiftLint'
  
  #pod 'SimplePDF'
end

target 'Srila Prabhupada' do
    shared_pods
end

target 'BVKS' do
    shared_pods
end

post_install do |installer|

  installer.pods_project.targets.each do |target|

    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      if config.name == 'Debug'|| config.name == 'Debug-Client'
        config.build_settings["[sdk=iphoneos*]]"] = "x86_64"
        config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64" # For apple silicon, it should be "x86_64"
      end
     end
    if target.respond_to?(:product_type) and target.product_type == "com.apple.product-type.bundle"
      target.build_configurations.each do |config|
        config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
      end
    end
  end
end
