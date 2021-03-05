
Pod::Spec.new do |s|


  s.name         = "RongCloudOpenSource"
  s.version      = "5.1.0"
  s.summary      = "RongCloud UI SDK SourceCode."


  s.description  = <<-DESC
                   RongCloud SDK for iOS.
                   DESC


  s.homepage     = "https://www.rongcloud.cn/"
  s.license      = { :type => "Copyright", :text => "Copyright 2021 RongCloud" }
  s.author             = { "qixinbing" => "https://www.rongcloud.cn/" }
  s.social_media_url   = "https://www.rongcloud.cn/"
  s.platform     = :ios, "8.0"
  s.source           = { :git => 'https://github.com/rongcloud/ios-ui-sdk-set.git', :tag => s.version.to_s }
  s.requires_arc = true
  s.static_framework = true
  s.pod_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
  }
  s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }

  s.subspec 'IMKit' do |kit|
    kit.resources = "IMKit/Resource/ar.lproj/RongCloudKit.strings","IMKit/Resource/en.lproj/RongCloudKit.strings","IMKit/Resource/zh-Hans.lproj/RongCloudKit.strings","IMKit/Resource/Emoji.plist","IMKit/Resource/RCColor.plist","IMKit/Resource/RongCloud.bundle"
    kit.source_files = 'IMKit/RongIMKit.h','IMKit/**/*.{h,m,c}'
    kit.frameworks = "AssetsLibrary", "MapKit", "ImageIO", "CoreLocation", "SystemConfiguration", "QuartzCore", "OpenGLES", "CoreVideo", "CoreTelephony", "CoreMedia", "CoreAudio", "CFNetwork", "AudioToolbox", "AVFoundation", "UIKit", "CoreGraphics", "SafariServices"
    kit.dependency 'RongCloudIM/IMLib','5.1.0'
  end

  s.subspec 'RongSticker' do |rs|
  	rs.resources = "Sticker/Resource/ar.lproj/RongSticker.strings","Sticker/Resource/en.lproj/RongSticker.strings","Sticker/Resource/zh-Hans.lproj/RongSticker.strings","Sticker/Resource/RongSticker.bundle"
    rs.source_files = 'Sticker/RongSticker.h','Sticker/**/*.{h,m,c}'
    rs.dependency 'RongCloudOpenSource/IMKit'
  end

  s.subspec 'Sight' do |st|
    st.source_files = 'Sight/RongSight.h','Sight/**/*.{h,m}'
    st.dependency 'RongCloudOpenSource/IMKit'
  end

  s.subspec 'IFly' do |fly|
    fly.libraries = "z"
    fly.frameworks = "AddressBook", "SystemConfiguration", "CoreTelephony", "CoreServices", "Contacts"
    fly.resources = "iFlyKit/Resource/RongCloudiFly.bundle"
    fly.source_files = 'iFlyKit/RongiFlyKit.h','iFlyKit/**/*.{h,m}'
    fly.dependency 'RongCloudOpenSource/IMKit'
    fly.vendored_frameworks = "iFlyKit/Engine/iflyMSC.framework"
  end

  s.subspec 'ContactCard' do |cc|
    cc.source_files = 'ContactCard/RongContactCard.h','ContactCard/**/*.{h,m,c}'
    cc.dependency 'RongCloudOpenSource/IMKit'
  end

  s.subspec 'RongCallKit' do |ck|
    ck.source_files = 'CallKit/RongCallKit.h','CallKit/**/*.{h,m,mm}'
    ck.resources = "CallKit/Resources/ar.lproj/RongCallKit.strings","CallKit/Resources/en.lproj/RongCallKit.strings","CallKit/Resources/zh-Hans.lproj/RongCallKit.strings","CallKit/Resources/RongCallKit.bundle"
    ck.dependency 'RongCloudOpenSource/IMKit'
    ck.dependency 'RongCloudRTC/RongCallLib','5.1.0'
  end

end
