# Uncomment this line to define a global platform for your project
# platform :ios, '8.0'
# Uncomment this line if you're using Swift
# use_frameworks!


target 'AWARE' do
pod 'MQTTKit' 
pod 'SCNetworkReachability'
pod 'Google/SignIn'
pod 'DeployGateSDK'
pod 'ios-ntp'
pod 'EZAudio'
pod 'SVProgressHUD'
pod 'EAIntroView', '~> 2.9.0'
#pod 'RNGridMenu', '~> 0.1.2'
#pod 'Google/CloudMessaging'
#pod 'Google-API-Client'
#pod 'Podfile'
#pod 'ResearchKit'
end

target 'AWARETests' do
pod 'MQTTKit' 
pod 'SCNetworkReachability'
pod 'Google/SignIn'
pod 'DeployGateSDK'
pod 'ios-ntp'
pod 'EZAudio'
pod 'SVProgressHUD'
pod 'EAIntroView', '~> 2.9.0'

end

target 'AWAREUITests' do

end

post_install do | installer |
  require 'fileutils'
    FileUtils.cp_r('Pods/Target Support Files/Pods-AWARE/Pods-AWARE-acknowledgements.plist', 'AWARE/Settings.bundle/Acknowledgements.plist', :remove_destination => true)
end


#post_install do | installer |
#    require 'fileutils'
#    FileUtils.cp_r('Pods/Target Support Files/Pods-AWARE/Pods-AWARE-acknowledgements.plist', 'Settings.bundle/Acknowledgements.plist', :remove_destination => true)
#end
