//
//  RCKitUtility.h
//  iOS-IMKit
//
//  Created by xugang on 7/7/14.
//  Copyright (c) 2014 Heq.Shinoda. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RongIMLibCore/RongIMLibCore.h>
#import <UIKit/UIKit.h>
#import "RCMessageModel.h"

@class RCConversationModel;

/// IMKit工具类
@interface RCKitUtility : NSObject

/*!
 会话列表会话时间转换

 - Parameter secs:    Unix时间戳（秒）
 - Returns: 可视化的时间字符串

  如果该时间是今天的，则返回值为"HH:mm"格式的字符串；
 如果该时间是昨天的，则返回字符串资源中Yesterday对应语言的字符串；
 如果该时间是昨天之前或者今天之后的，则返回"yyyy-MM-dd"的字符串。
 */
+ (NSString *)convertConversationTime:(long long)secs;

/*!
 聊天页面消息时间转换

 - Parameter secs:    Unix时间戳（秒）
 - Returns: 可视化的时间字符串

  如果该时间是今天的，则返回值为"HH:mm"格式的字符串；
 如果该时间是昨天的，则返回"Yesterday HH:mm"的字符串（其中，Yesterday为字符串资源中Yesterday对应语言的字符串）；
 如果该时间是昨天之前或者今天之后的，则返回"yyyy-MM-dd HH:mm"的字符串。
 */
+ (NSString *)convertMessageTime:(long long)secs;

/*!
 获取资源包中的图片

 - Parameter name:        图片名
 - Parameter bundleName:  图片所在的Bundle名
 - Returns: 图片
 */
+ (UIImage *)imageNamed:(NSString *)name ofBundle:(NSString *)bundleName;

/*!
 根据文件类型返回会话中的图标
 - Parameter type: 文件类型
  如果 RCKitUIConf 的 reigsterFileSuffixTypes 中有自定义图标，返回自定义图标，否则，返回 RongCloud.bundle 中的默认图标
 
 - Since: 5.3.4
 */
+ (UIImage *)imageWithFileSuffix:(NSString *)type;

/*!
 获取文字显示的尺寸

 - Parameter text: 文字
 - Parameter font: 字体
 - Parameter constrainedSize: 文字显示的容器大小

 - Returns: 文字显示的尺寸

  该方法在计算iOS 7以下系统显示的时候默认使用NSLineBreakByTruncatingTail模式。
 */
+ (CGSize)getTextDrawingSize:(NSString *)text font:(UIFont *)font constrainedSize:(CGSize)constrainedSize;

/*!
 获取指定会话类型的消息内容的摘要

 - Parameter messageContent:  消息内容
 - Parameter targetId:  会话 Id
 - Parameter conversationType:  会话类型
 - Parameter isAllMessage:  是否获取全部摘要内容，如果设置为 NO，摘要内容长度大于 500 时可能被截取
 - Returns: 消息内容的摘要

  SDK默认的消息有内置的处理，自定义消息会调用 RCMessageContent 中 RCMessageContentView 协议的
 conversationDigest 获取消息摘要。
*/
+ (NSString *)formatMessage:(RCMessageContent *)messageContent
                   targetId:(NSString *)targetId
           conversationType:(RCConversationType)conversationType
               isAllMessage:(BOOL)isAllMessage;

/*!
 获取消息通知时需展示的内容摘要

 - Parameter message:  消息
 - Returns: 消息内容的摘要

  SDK默认的消息有内置的处理，自定义消息会调用 RCMessageContent 中 RCMessageContentView 协议的
 conversationDigest 获取消息摘要。
*/
+ (NSString *)formatLocalNotification:(RCMessage *)message;

/*!
 获取指定会话类型的消息内容的摘要

 - Parameter messageContent:  消息内容
 - Parameter targetId:  会话 Id
 - Parameter conversationType:  会话类型
 - Returns: 消息内容的摘要

  SDK默认的消息有内置的处理，
 自定义消息会调用RCMessageContent中RCMessageContentView协议的conversationDigest获取消息摘要。
  与 formatMessage:targetId:conversationType:isAllMessage 区别是，该方法在摘要内容长度大于 500 时可能被截取
 */
+ (NSString *)formatMessage:(RCMessageContent *)messageContent
                   targetId:(NSString *)targetId
           conversationType:(RCConversationType)conversationType;

/*!
 获取消息内容的摘要

 - Parameter messageContent:  消息内容
 - Returns: 消息内容的摘要

  SDK默认的消息有内置的处理，
 自定义消息会调用RCMessageContent中RCMessageContentView协议的conversationDigest获取消息摘要。
  与 formatMessage:targetId:conversationType:isAllMessage 区别是，该方法在摘要内容长度大于 500 时可能被截取
 */
+ (NSString *)formatMessage:(RCMessageContent *)messageContent;

/*!
 消息是否需要显示

 - Parameter message: 消息
 - Returns: 是否需要显示
 */
+ (BOOL)isVisibleMessage:(RCMessage *)message;

/*!
 消息是否需要显示

 - Parameter messageId: 消息ID
 - Parameter content:   消息内容
 - Returns: 是否需要显示
 */
+ (BOOL)isUnkownMessage:(long)messageId content:(RCMessageContent *)content;

/*!
 获取消息对应的本地消息Dictionary

 - Parameter message: 消息实体
 - Returns: 本地通知的Dictionary
 */
+ (NSDictionary *)getNotificationUserInfoDictionary:(RCMessage *)message;

/*!
 获取消息对应的本地消息Dictionary

 - Parameter conversationType:    会话类型
 - Parameter fromUserId:          发送者的用户ID
 - Parameter targetId:            消息的目标会话ID
 - Parameter objectName:          消息的类型名
 - Returns: 本地通知的Dictionary
 */
+ (NSDictionary *)getNotificationUserInfoDictionary:(RCConversationType)conversationType
                                         fromUserId:(NSString *)fromUserId
                                           targetId:(NSString *)targetId
                                         objectName:(NSString *)objectName;

/*!
 获取文件消息中消息类型对应的图片名称

 - Parameter fileType:    文件类型
 - Returns: 图片名称
 */
+ (NSString *)getFileTypeIcon:(NSString *)fileType;

/*!
 获取文件大小的字符串，单位是k

 - Parameter byteSize:    文件大小，单位是byte
 - Returns: 文件大小的字符串
 */
+ (NSString *)getReadableStringForFileSize:(long long)byteSize;

/*!
 获取会话默认的占位头像

 - Parameter model: 会话数据模型
 - Returns: 默认的占位头像
 */
+ (UIImage *)defaultConversationHeaderImage:(RCConversationModel *)model;

/*!
 获取聚合显示的会话标题

 - Parameter conversationType: 聚合显示的会话类型
 - Returns: 显示的标题
 */
+ (NSString *)defaultTitleForCollectionConversation:(RCConversationType)conversationType;

/*!
 获取会话模型对应的未读数

 - Parameter model: 会话数据模型
 - Returns: 未读消息数
 */
+ (int)getConversationUnreadCount:(RCConversationModel *)model;

/*!
 会话模型未读的@消息数

 - Parameter model: 会话数据模型
 */
+ (void)getConversationUnreadMentionedCount:(RCConversationModel *)model result:(void(^)(int num))result;

/*!
 会话模型是否包含未读的@消息

 - Parameter model: 会话数据模型
 - Returns: 是否包含未读的@消息
 */
+ (BOOL)getConversationUnreadMentionedStatus:(RCConversationModel *)model;

/*!
 同步会话多端阅读状态

 - Parameter conversation: 会话

  会根据已经设置的RCIM的enabledReadReceiptConversationTypeList属性进行过滤、同步。
 */
+ (void)syncConversationReadStatusIfEnabled:(RCConversationModel *)conversation;

/*!
 获取汉字对应的拼音首字母

 - Parameter hanZi: 汉字

 - Returns: 拼音首字母
 */
+ (NSString *)getPinYinUpperFirstLetters:(NSString *)hanZi;

/*!
 在SFSafariViewController或WebViewController中打开URL

 - Parameter url:             URL
 - Parameter viewController:  基于哪个页面弹出新的页面
 */
+ (void)openURLInSafariViewOrWebView:(NSString *)url base:(UIViewController *)viewController;

/**
 检查url是否以http或https开头，如果不是，为其头部追加http://

 - Parameter url: url

 - Returns: 以http或者https开头的url
 */
+ (NSString *)checkOrAppendHttpForUrl:(NSString *)url;

/**
获取 keyWindow

- Returns: UIWindow
*/
+ (UIWindow *)getKeyWindow;

/**
 获取 AppDelegate window 的 safeAreaInsets

 - Returns: AppDelegate window 的 safeAreaInsets
 */
+ (UIEdgeInsets)getWindowSafeAreaInsets;

/**
 修正iOS系统图片的图片方向

 - Parameter image: 需要修正的图片
 - Returns: 修正后的图片
 */
+ (UIImage *)fixOrientation:(UIImage *)image;

/// 判断当前设备是否是 iPad
+ (BOOL)currentDeviceIsIPad;

/**
动态颜色设置，暗黑模式

 - Parameter lightColor:  亮色
 - Parameter darkColor:  暗色
 - Returns: 修正后的颜色
*/
+ (UIColor *)generateDynamicColor:(UIColor *)lightColor darkColor:(UIColor *)darkColor;

/// 根据图片消息的 imageUrl 判断图片是否加载
+ (BOOL)hasLoadedImage:(NSString *)imageUrl;

/**
根据图片消息的 imageUrl 获取已下载的图片 data

 - Parameter imageUrl:  图片消息的 imageUrl
 - Returns: 图片 data
*/
+ (NSData *)getImageDataForURLString:(NSString *)imageUrl;

/**
 获取RCColor.plist文件中色值
 
 - Parameter key: 色值对应的key
 - Parameter colorStr: 原始颜色
 - Returns: 最终返回的颜色
 */
+ (UIColor *)color:(NSString *)key originalColor:(NSString *)colorStr;

/**
 显示进度提示框
 
 - Parameter view: view
 - Parameter text: 提示文字
 - Parameter animated: 动画
 */
+ (BOOL)showProgressViewFor:(UIView *)view text:(NSString *)text animated:(BOOL)animated;

/**
 隐藏进度提示框
 
 - Parameter view: view
 - Parameter animated: 动画
 */
+ (BOOL)hideProgressViewFor:(UIView *)view animated:(BOOL)animated;

/**
 获取导航左按钮
 
 - Parameter image:  亮色
 - Parameter title:  暗色，可为 nil
 - Returns: 导航左按钮
  布局为 RTL 时，图片会在内部进行翻转，无需开发者处理
 */
+ (NSArray <UIBarButtonItem *> *)getLeftNavigationItems:(UIImage *)image title:(NSString *)title target:(id)target action:(SEL)action;

/**
 判断是否需要 RTL 布局
 
  当前系统高于 9.0，并且满足手机系统为 UISemanticContentAttributeForceRightToLeft 布局或者  App 被修改为 UISemanticContentAttributeForceRightToLeft 布局时才会返回 YES，否则为 NO
 */
+ (BOOL)isRTL;

/**
 判断其他模块是否正在使用声音通道
 
  主要检测 IMKit 子模块和 IMLib 子模块是否占用
 */
+ (BOOL)isAudioHolding;

/**
 判断其他模块是否正在使用摄像头
 
  主要检测 IMKit 子模块和 IMLib 子模块是否占用
 */
+ (BOOL)isCameraHolding;

/**
 获取需要显示的用户名
 
  优先返回 alias，如果 alias 没有值，返回 name
 */
+ (NSString *)getDisplayName:(RCUserInfo *)userInfo;


/// 本地化字符串
/// - Parameters:
///   - key: key
///   - table: 本地化文件名
+ (NSString *)localizedString:(NSString *)key table:(NSString *)table;

/// 查找文件
/// - Parameter name: 文件名[先找根目录, 再找framework]
+ (NSString *)filePathForName:(NSString *)name;

/// 按照名称查找bundle
/// - Parameter bundleName: 名称[先找根目录, 再找framework]
+ (NSString *)bundlePathWithName:(NSString *)bundleName;

/// 获取公众号 WebViewController
/// - Parameter URLString: URL
+ (nullable UIViewController *)getPublicServiceWebViewController:(NSString *)URLString;

+ (NSString *)formatStreamDigest:(RCMessage *)message;

//判断是否是暗黑模式
+ (BOOL)isDarkMode;
@end
