
Pod::Spec.new do |s|


  s.name         = "RongCloudOpenSource"
  s.version      = "5.28.0"
  s.summary      = "RongCloud UI SDK SourceCode."


  s.description  = <<-DESC
                   RongCloud SDK for iOS.
                   DESC


  s.homepage     = "https://www.rongcloud.cn/"
  s.license      = { :type => "Copyright", :text => "Copyright 2021 RongCloud" }
  s.author             = { "qixinbing" => "https://www.rongcloud.cn/" }
  s.social_media_url   = "https://www.rongcloud.cn/"
  s.platform     = :ios, "9.0"
  s.source           = { :git => 'https://github.com/rongcloud/ios-ui-sdk-set.git', :tag => s.version.to_s }
  s.requires_arc = true
  s.static_framework = true
  s.pod_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64', 'VALID_ARCHS' => 'arm64 armv7 x86_64'
  }
  s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }

  s.subspec 'IMKit' do |kit|
    kit.resources = "Resources/RongCloud.bundle", "Resources/en.lproj", "Resources/zh-Hans.lproj", "Resources/ar.lproj", "Resources/Emoji.plist", "Resources/RCColor.plist", "IMKit/Supporting\ Files/PrivacyInfo.xcprivacy"
    kit.source_files = 'IMKit/RongIMKit.h','IMKit/**/*.{h,m,c}'
    kit.private_header_files = 'IMKit/Utility/Extension/*.h'
    kit.frameworks = "AssetsLibrary", "MapKit", "ImageIO", "CoreLocation", "SystemConfiguration", "QuartzCore", "OpenGLES", "CoreVideo", "CoreTelephony", "CoreMedia", "CoreAudio", "CFNetwork", "AudioToolbox", "AVFoundation", "UIKit", "CoreGraphics", "SafariServices"
    kit.dependency 'RongCloudIM/IMLib','5.28.0'
  end

  s.subspec 'RongSticker' do |rs|
  	rs.resources = "Resources/RongSticker.bundle"
    rs.source_files = 'Sticker/RongSticker.h','Sticker/**/*.{h,m,c}'
    rs.private_header_files = 'Sticker/Extension/*.h','Sticker/Utilities/RCUnzip.h'
    rs.dependency 'RongCloudOpenSource/IMKit'
  end

  s.subspec 'Sight' do |st|
    st.source_files = 'Sight/RongSight.h','Sight/**/*.{h,m}'
    st.private_header_files = 'Sight/RCDownloadHelper.h'
    st.dependency 'RongCloudOpenSource/IMKit'
  end

  s.subspec 'IFly' do |fly|
    fly.libraries = "z"
    fly.frameworks = "AddressBook", "SystemConfiguration", "CoreTelephony", "CoreServices", "Contacts"
    fly.resources = "Resources/RongCloudiFly.bundle"
    fly.source_files = 'iFlyKit/RongiFlyKit.h','iFlyKit/**/*.{h,m}'
    fly.dependency 'RongCloudOpenSource/IMKit'
    fly.vendored_frameworks = "iFlyKit/Engine/iflyMSC.framework"
  end

  s.subspec 'ContactCard' do |cc|
    cc.source_files = 'ContactCard/RongContactCard.h','ContactCard/**/*.{h,m,c}'
    cc.private_header_files = 'ContactCard/Header/*.h'
    cc.dependency 'RongCloudOpenSource/IMKit'
  end

  s.subspec 'LocationKit' do |lokit|
    lokit.source_files = 'locationkit/**/*.{h,m,c}'
    lokit.dependency 'RongCloudOpenSource/IMKit'
    lokit.dependency 'RongCloudIM/Location'
  end

  # s.subspec 'RongCallKit' do |ck|
  #   ck.source_files = 'CallKit/RongCallKit.h','CallKit/**/*.{h,m,mm}'
  #   ck.private_header_files = 'CallKit/Header/*.h'
  #   ck.resources = "Resources/RongCallKit.bundle"
  #   ck.dependency 'RongCloudOpenSource/IMKit'
  #   ck.dependency 'RongCloudRTC/RongCallLib'
  # end

end
