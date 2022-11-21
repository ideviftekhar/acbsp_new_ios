
platform :ios, '13.0'

target 'Srila Prabhupada' do
	
	use_frameworks!
  inhibit_all_warnings!

	pod 'SideMenu'

  pod 'FirebaseAuth'
  pod 'FirebaseCore'
  pod 'FirebaseCrashlytics'
  pod 'FirebaseDynamicLinks'
  pod 'FirebaseFirestore'
  pod 'FirebaseFirestoreSwift'
  pod 'FirebaseMessaging'

  pod 'GoogleSignIn'
  pod 'GoogleSignInSwiftSupport'

  pod 'SkyFloatingLabelTextField'
  pod 'IQKeyboardManagerSwift'
  pod 'IQListKit', :git => 'https://github.com/hackiftekhar/IQListKit.git', :tag => '3.0.0'

  pod 'BEMCheckBox'

  pod 'Alamofire'
  pod 'AlamofireImage'

  pod "MBCircularProgressBar"
#  pod 'LoadingPlaceholderView'

  pod 'ProgressHUD'

  pod 'ReachabilitySwift'

  pod'Charts'
  pod'SwiftLint'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    if target.respond_to?(:product_type) and target.product_type == "com.apple.product-type.bundle"
      target.build_configurations.each do |config|
          config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
      end
    end
  end
end
