//
//  RCKitUIConf.h
//  RongIMKit
//
//  Created by Sin on 2020/6/23.
//  Copyright © 2020 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCThemeDefine.h"

@interface RCKitUIConf : NSObject
#pragma mark Avatar

/*!
 *  \~chinese
 SDK中全局的导航按钮字体颜色

 @discussion 默认值为[UIColor whiteColor]
 
 *  \~english
 Global navigation button font color in SDK.

 @ discussion The default value is [UIColor whiteColor].
 */
@property (nonatomic, strong) UIColor *globalNavigationBarTintColor;

/*!
 *  \~chinese
 SDK会话列表界面中显示的头像形状，矩形或者圆形

 @discussion 默认值为矩形，即RC_USER_AVATAR_RECTANGLE
 
 *  \~english
 Avatar shape, rectangle or circle displayed in the SDK conversation list interface.

 @ discussion The default value is rectangle, that is, RC_USER_AVATAR_RECTANGLE.
 */
@property (nonatomic, assign) RCUserAvatarStyle globalConversationAvatarStyle;

/*!
 *  \~chinese
 SDK会话列表界面中显示的头像大小，高度必须大于或者等于36

 @discussion 默认值为46*46
 
 *  \~english
 The size of the portrait displayed in the SDK conversation list interface must be greater than or equal to 36.

 @ discussion The default value is 46*46.
 */
@property (nonatomic, assign) CGSize globalConversationPortraitSize;

/*!
 *  \~chinese
 SDK会话页面中显示的头像形状，矩形或者圆形

 @discussion 默认值为矩形，即RC_USER_AVATAR_RECTANGLE
 
 *  \~english
 Avatar shape, rectangle or circle displayed on the SDK conversation page.

 @ discussion The default value is rectangle, that is, RC_USER_AVATAR_RECTANGLE.
 */
@property (nonatomic, assign) RCUserAvatarStyle globalMessageAvatarStyle;

/*!
 *  \~chinese
 SDK会话页面中显示的头像大小

 @discussion 默认值为40*40
 
 *  \~english
 The size of the portrait displayed on the SDK conversation page.

 @ discussion The default value is 40*40.
 */
@property (nonatomic, assign) CGSize globalMessagePortraitSize;

/*!
 *  \~chinese
 SDK会话列表界面和会话页面的头像的圆角曲率半径

 @discussion 默认值为4，只有当头像形状设置为矩形时才会生效。
 参考RCIM的globalConversationAvatarStyle和globalMessageAvatarStyle。
 
 *  \~english
 The radius of fillet curvature of the portrait of the SDK conversation list interface and conversation page.

 @ discussion The default value is 4, which takes effect only if the portrait shape is set to rectangle.
  Refer to RCIM's globalConversationAvatarStyle and globalMessageAvatarStyle.
 */
@property (nonatomic, assign) CGFloat portraitImageViewCornerRadius;

/*!
 *  \~chinese
是否支持暗黑模式，默认值是NO，开启之后 UI 支持暗黑模式，可以跟随系统切换
 
 *  \~english
 Whether dark mode is supported. The default value is NO. After it is enabled,  UI supports dark mode and it can switch with the system.
*/
@property (nonatomic, assign) BOOL enableDarkMode;
@end

