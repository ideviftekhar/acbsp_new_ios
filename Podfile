
platform :ios, '14.0'

target 'Srila Prabhupada' do
	
	use_frameworks!
  inhibit_all_warnings!

	pod 'SideMenu'

  pod 'FirebaseFirestoreSwift'
  pod 'FirebaseCore'
  pod 'FirebaseAuth'
  pod 'FirebaseFirestore'
  pod 'FirebaseCrashlytics'
  pod 'FirebaseMessaging'
  
  pod 'GoogleSignIn'
  pod 'GoogleSignInSwiftSupport'

  pod 'SkyFloatingLabelTextField'
  pod 'IQKeyboardManagerSwift'
  pod 'IQListKit'

  pod 'BEMCheckBox'

  pod 'Alamofire'
  pod 'AlamofireImage'

  pod "MBCircularProgressBar"
#  pod 'LoadingPlaceholderView'

  pod 'ProgressHUD'

  pod 'ARNTransitionAnimator'

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
