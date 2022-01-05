//
//  RCKitUtility.h
//  iOS-IMKit
//
//  Created by xugang on 7/7/14.
//  Copyright (c) 2014 Heq.Shinoda. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RongIMLib/RongIMLib.h>
#import <UIKit/UIKit.h>
#import "RCMessageModel.h"

@class RCConversationModel;

/*!
 *  \~chinese
 IMKit工具类
 
 *  \~english
 IMKit utility class.
 */
@interface RCKitUtility : NSObject

/*!
 *  \~chinese
 会话列表会话时间转换

 @param secs    Unix时间戳（秒）
 @return        可视化的时间字符串

 @discussion 如果该时间是今天的，则返回值为"HH:mm"格式的字符串；
 如果该时间是昨天的，则返回字符串资源中Yesterday对应语言的字符串；
 如果该时间是昨天之前或者今天之后的，则返回"yyyy-MM-dd"的字符串。
 
 *  \~english
 Time conversion of conversation list conversation

 @param secs Unix timestamp (seconds).
 @ return visual time string.

 @ discussion If the time is today, the return value is a string of "HH:mm" format.
 If the time is yesterday, the string of the Yesterday corresponding language in the string resource is returned.
 If the time is before yesterday or after today, the string "yyyy-MM-dd" is returned.
 */
+ (NSString *)convertConversationTime:(long long)secs;

/*!
 *  \~chinese
 聊天页面消息时间转换

 @param secs    Unix时间戳（秒）
 @return        可视化的时间字符串

 @discussion 如果该时间是今天的，则返回值为"HH:mm"格式的字符串；
 如果该时间是昨天的，则返回"Yesterday HH:mm"的字符串（其中，Yesterday为字符串资源中Yesterday对应语言的字符串）；
 如果该时间是昨天之前或者今天之后的，则返回"yyyy-MM-dd HH:mm"的字符串。
 
 *  \~english
 Time conversion of chat page message

 @param secs Unix timestamp (seconds).
 @ return visual time string.

 @ discussion If the time is today, the return value is a string of "HH:mm" format.
 If the time is yesterday, the string of "Yesterday HH:mm" is returned (where Yesterday is the string of the Yesterday corresponding language in the string resource).
 If the time is before yesterday or after today, the string "yyyy-MM-dd HH:mm" is returned.
 */
+ (NSString *)convertMessageTime:(long long)secs;

/*!
 *  \~chinese
 获取资源包中的图片

 @param name        图片名
 @param bundleName  图片所在的Bundle名
 @return            图片
 
 *  \~english
 Get the images in the resource kit.

 @param name image name.
 @param bundleName The Bundle name of the image.
 @ return image.
 */
+ (UIImage *)imageNamed:(NSString *)name ofBundle:(NSString *)bundleName;

/*!
 *  \~chinese
 获取文字显示的尺寸

 @param text 文字
 @param font 字体
 @param constrainedSize 文字显示的容器大小

 @return 文字显示的尺寸

 @discussion 该方法在计算iOS 7以下系统显示的时候默认使用NSLineBreakByTruncatingTail模式。
 
 *  \~english
 Get the size of the text display.

 @param text Words.
 @param font Font.
 @param constrainedSize Container size for text display.

 @ return The display size of text

 @ discussion This method The default value is NSLineBreakByTruncatingTail mode when calculating the system display below iOS 7.
 */
+ (CGSize)getTextDrawingSize:(NSString *)text font:(UIFont *)font constrainedSize:(CGSize)constrainedSize;

/*!
 *  \~chinese
 获取指定会话类型的消息内容的摘要

 @param messageContent  消息内容
 @param targetId  会话 Id
 @param conversationType  会话类型
 @param isAllMessage  是否获取全部摘要内容，如果设置为 NO，摘要内容长度大于 500 时可能被截取
 @return                消息内容的摘要

 @discussion SDK默认的消息有内置的处理，自定义消息会调用 RCMessageContent 中 RCMessageContentView 协议的
 conversationDigest 获取消息摘要。
 
 *  \~english
 Get a digest of the message content of the specified conversation type.

 @param messageContent Message content.
 @param targetId conversation Id.
 @param conversationType Conversation type
 @param isAllMessage Whether to get all the digest content. If it is set to NO, the digest content may be intercepted if the length of the digest content is greater than 500.
 @ return digest of message content

 @ discussion SDK default messages have built-in processing, and custom messages call the RCMessageContentView protocol in RCMessageContent.
 ConversationDigest Get the message digest.
*/
+ (NSString *)formatMessage:(RCMessageContent *)messageContent
                   targetId:(NSString *)targetId
           conversationType:(RCConversationType)conversationType
               isAllMessage:(BOOL)isAllMessage;

/*!
 *  \~chinese
 获取消息通知时需展示的内容摘要

 @param message  消息
 @return                消息内容的摘要

 @discussion SDK默认的消息有内置的处理，自定义消息会调用 RCMessageContent 中 RCMessageContentView 协议的
 conversationDigest 获取消息摘要。
 
 *  \~english
 A digest of the content to be displayed when getting a message notification.

 @param message Message.
 @ return digest of message content.

 @ discussion SDK default messages have built-in processing, and custom messages call the RCMessageContentView protocol in RCMessageContent.
 ConversationDigest Get the message digest.
*/
+ (NSString *)formatLocalNotification:(RCMessage *)message;

/*!
 *  \~chinese
 获取指定会话类型的消息内容的摘要

 @param messageContent  消息内容
 @param targetId  会话 Id
 @param conversationType  会话类型
 @return                消息内容的摘要

 @discussion SDK默认的消息有内置的处理，
 自定义消息会调用RCMessageContent中RCMessageContentView协议的conversationDigest获取消息摘要。
 @discussion 与 formatMessage:targetId:conversationType:isAllMessage 区别是，该方法在摘要内容长度大于 500 时可能被截取
 
 *  \~english
 Get a digest of the message content of the specified conversation type.

 @param messageContent Message content.
 @param targetId conversation Id.
 @param conversationType Conversation type
 @ returndigest of message content.

 @ discussion SDK default messages have built-in processing.
 The custom message calls the conversationDigest of the RCMessageContentView protocol in RCMessageContent to get the message digest.
  @ discussion Unlike formatMessage:targetId:conversationType:isAllMessage,  this method may be intercepted when the digest content length is greater than 500.
 */
+ (NSString *)formatMessage:(RCMessageContent *)messageContent
                   targetId:(NSString *)targetId
           conversationType:(RCConversationType)conversationType;

/*!
 *  \~chinese
 获取消息内容的摘要

 @param messageContent  消息内容
 @return                消息内容的摘要

 @discussion SDK默认的消息有内置的处理，
 自定义消息会调用RCMessageContent中RCMessageContentView协议的conversationDigest获取消息摘要。
 @discussion 与 formatMessage:targetId:conversationType:isAllMessage 区别是，该方法在摘要内容长度大于 500 时可能被截取
 
 *  \~english
 Get a digest of the content of the message.

 @param messageContent Message content.
 @ returndigest of message content.

 @ discussion SDK default messages have built-in processing.
 The custom message calls the conversationDigest of the RCMessageContentView protocol in RCMessageContent to get the message digest.
  @ discussion Unlike formatMessage:targetId:conversationType:isAllMessage,  this method may be intercepted when the digest content length is greater than 500.
 */
+ (NSString *)formatMessage:(RCMessageContent *)messageContent;

/*!
 *  \~chinese
 消息是否需要显示

 @param message 消息
 @return 是否需要显示
 
 *  \~english
 Whether the message shall be displayed.

 @param message Message.
 @ return Display or not
 */
+ (BOOL)isVisibleMessage:(RCMessage *)message;

/*!
 *  \~chinese
 消息是否需要显示

 @param messageId 消息ID
 @param content   消息内容
 @return 是否需要显示
 
 *  \~english
 Whether the message shall be displayed.

 @param messageId Message ID.
 @param content Message con
 */
+ (BOOL)isUnkownMessage:(long)messageId content:(RCMessageContent *)content;

/*!
 *  \~chinese
 获取消息对应的本地消息Dictionary

 @param message 消息实体
 @return 本地通知的Dictionary
 
 *  \~english
 Get the local message Dictionary corresponding to the message.

 @param message Message entity.
 @ return Dictionary of local notification.
 */
+ (NSDictionary *)getNotificationUserInfoDictionary:(RCMessage *)message;

/*!
 *  \~chinese
 获取消息对应的本地消息Dictionary

 @param conversationType    会话类型
 @param fromUserId          发送者的用户ID
 @param targetId            消息的目标会话ID
 @param objectName          消息的类型名
 @return                    本地通知的Dictionary
 
 *  \~english
 Get the local message Dictionary corresponding to the message.

 @param conversationType Conversation type
 @param fromUserId Sender's user ID.
 @param targetId The target conversation ID of the message.
 @param objectName The type name of the message.
 @ return Dictionary of local notification.
 */
+ (NSDictionary *)getNotificationUserInfoDictionary:(RCConversationType)conversationType
                                         fromUserId:(NSString *)fromUserId
                                           targetId:(NSString *)targetId
                                         objectName:(NSString *)objectName;

/*!
 *  \~chinese
 获取文件消息中消息类型对应的图片名称

 @param fileType    文件类型
 @return            图片名称
 
 *  \~english
 Get the image name corresponding to the message type in the file message.

 @param fileType File type.
 @ return image name.
 */
+ (NSString *)getFileTypeIcon:(NSString *)fileType;

/*!
 *  \~chinese
 获取文件大小的字符串，单位是k

 @param byteSize    文件大小，单位是byte
 @return 文件大小的字符串
 
 *  \~english
 Get the string of the file size in k.

 @param byteSize File size in byte.
 @ return file size string.
 */
+ (NSString *)getReadableStringForFileSize:(long long)byteSize;

/*!
 *  \~chinese
 获取会话默认的占位头像

 @param model 会话数据模型
 @return 默认的占位头像
 
 *  \~english
 Get the default placeholder portrait of the conversation.

 @param model conversation data model.
 @ return default placeholder portrait.
 */
+ (UIImage *)defaultConversationHeaderImage:(RCConversationModel *)model;

/*!
 *  \~chinese
 获取聚合显示的会话标题

 @param conversationType 聚合显示的会话类型
 @return 显示的标题
 
 *  \~english
 Get the conversation title displayed in the aggregate.

 @param conversationType The type of conversation displayed by the aggregation.
 @ return Displayed title
 */
+ (NSString *)defaultTitleForCollectionConversation:(RCConversationType)conversationType;

/*!
 *  \~chinese
 获取会话模型对应的未读数

 @param model 会话数据模型
 @return 未读消息数
 
 *  \~english
 Get the unread corresponding to the conversation model.

 @param model conversation data model.
 @ return number of unread messages.
 */
+ (int)getConversationUnreadCount:(RCConversationModel *)model;

/*!
 *  \~chinese
 会话模型是否包含未读的@消息

 @param model 会话数据模型
 @return 是否包含未读的@消息
 
 *  \~english
 Does the conversation model contain unread @ messages.

 @param model conversation data model.
 @ return Whether unread @ messages are included
 */
+ (BOOL)getConversationUnreadMentionedStatus:(RCConversationModel *)model;

/*!
 *  \~chinese
 同步会话多端阅读状态

 @param conversation 会话

 @discussion 会根据已经设置的RCIM的enabledReadReceiptConversationTypeList属性进行过滤、同步。
 
 *  \~english
 Synchronize conversation multiterminal reading state.

 @param conversation Conversation.

 @ discussion Filter and synchronize based on the enabledReadReceiptConversationTypeList property of the RCIM that has been set.
 */
+ (void)syncConversationReadStatusIfEnabled:(RCConversationModel *)conversation;

/*!
 *  \~chinese
 获取汉字对应的拼音首字母

 @param hanZi 汉字

 @return 拼音首字母
 
 *  \~english
 Get the first letter of pinyin corresponding to Chinese characters.

 @param hanZi Chinese characters.

 @ return Pinyin initials.
 */
+ (NSString *)getPinYinUpperFirstLetters:(NSString *)hanZi;

/*!
 *  \~chinese
 在SFSafariViewController或WebViewController中打开URL

 @param url             URL
 @param viewController  基于哪个页面弹出新的页面
 
 *  \~english
 Open URL in SFSafariViewController or WebViewController.

 @param url URL.
 @param viewController Based on which page the new page pops up.
 */
+ (void)openURLInSafariViewOrWebView:(NSString *)url base:(UIViewController *)viewController;

/**
 *  \~chinese
 检查url是否以http或https开头，如果不是，为其头部追加http://

 @param url url

 @return 以http或者https开头的url
 
 *  \~english
 Check to see if url starts with http or https. If not, append http:// to its header.

 @param url Url.

 @ return url that begins with http or https.
 */
+ (NSString *)checkOrAppendHttpForUrl:(NSString *)url;

/**
 *  \~chinese
获取 keyWindow

@return UIWindow
 
 *  \~english
 Get keyWindow.

 @ return UIWindow.
*/
+ (UIWindow *)getKeyWindow;

/**
 *  \~chinese
 获取 AppDelegate window 的 safeAreaInsets

 @return AppDelegate window 的 safeAreaInsets
 
 *  \~english
 Get the safeAreaInSet of AppDelegate window.

 @ return AppDelegate window's safeAreaInSet.
 */
+ (UIEdgeInsets)getWindowSafeAreaInsets;

/**
 *  \~chinese
 修正iOS系统图片的图片方向

 @param image 需要修正的图片
 @return 修正后的图片
 
 *  \~english
 Correct the image direction of the image in the iOS system.

 @param image images that shall be corrected.
 @ return corrected image.
 */
+ (UIImage *)fixOrientation:(UIImage *)image;

/**
 *  \~chinese
判断当前设备是否是 iPad
 
 *  \~english
 Determine whether the current device is an iPad.
*/
+ (BOOL)currentDeviceIsIPad;

/**
 *  \~chinese
动态颜色设置，暗黑模式

 @param lightColor  亮色
 @param darkColor  暗色
 @return 修正后的颜色
 
 *  \~english
 Dynamic color setting, dark mode.

 @param lightColor Bright color.
 @param darkColor Dark color.
 @ return corrected color.
*/
+ (UIColor *)generateDynamicColor:(UIColor *)lightColor darkColor:(UIColor *)darkColor;

/**
 *  \~chinese
根据图片消息的 imageUrl 判断图片是否加载
 
 *  \~english
 Judge whether the image is loaded according to the imageUrl of the image message.
*/
+ (BOOL)hasLoadedImage:(NSString *)imageUrl;

/**
 *  \~chinese
根据图片消息的 imageUrl 获取已下载的图片 data

 @param imageUrl  图片消息的 imageUrl
 @return 图片 data
 
 *  \~english
 Get the downloaded image data according to the imageUrl of the image message.

 @param imageUrl ImageUrl of image message.
 @ return image data.
*/
+ (NSData *)getImageDataForURLString:(NSString *)imageUrl;

/**
 *  \~chinese
 获取RCColor.plist文件中色值
 
 @param key 色值对应的key
 @param colorStr 原始颜色
 @return 最终返回的颜色
 
 *  \~english
 Get the color value in the RCColor.plist file.

 @param key Key corresponding to color value.
 @param colorStr Original color.
 @ return The final returned color
 */
+ (UIColor *)color:(NSString *)key originalColor:(NSString *)colorStr;

/**
 *  \~chinese
 显示进度提示框
 
 @param view view
 @param text 提示文字
 @param animated 动画
 
 *  \~english
 Show progress prompt box.

 @param view View.
 @param text Prompt text.
 @param animated Animation.
 */
+ (BOOL)showProgressViewFor:(UIView *)view text:(NSString *)text animated:(BOOL)animated;

/**
 *  \~chinese
 隐藏进度提示框
 
 @param view view
 @param animated 动画
 
 *  \~english
 Hide progress prompt box.

 @param view View.
 @param animated Animation.
 */
+ (BOOL)hideProgressViewFor:(UIView *)view animated:(BOOL)animated;

/**
 *  \~chinese
 获取导航左按钮
 
 @param image  亮色
 @param title  暗色，可为 nil
 @return 导航左按钮
 @discussion 布局为 RTL 时，图片会在内部进行翻转，无需开发者处理
 
 *  \~english
 Get navigation left button.

 @param image Bright color.
 @param title Dark, but nil.
 @ return navigation left button.
 @ discussion When it is laid out as RTL, the image will be flipped internally without the need for developers to deal with it.
 */
+ (NSArray <UIBarButtonItem *> *)getLeftNavigationItems:(UIImage *)image title:(NSString *)title target:(id)target action:(SEL)action;

/**
 *  \~chinese
 判断是否需要 RTL 布局
 
 @discussion 当前系统高于 9.0，并且满足手机系统为 UISemanticContentAttributeForceRightToLeft 布局或者  App 被修改为 UISemanticContentAttributeForceRightToLeft 布局时才会返回 YES，否则为 NO
 
 *  \~english
 Determine if RTL layout is required.

 @ discussion The current system is higher than 9.0. YES will be returned only if the mobile system is UISemanticContentAttributeForceRightToLeft layout or App is modified to UISemanticContentAttributeForceRightToLeft layout. Otherwise, NO will be returned.
 */
+ (BOOL)isRTL;

/**
 *  \~chinese
 判断其他模块是否正在使用声音通道
 
 @discussion 主要检测 IMKit 子模块和 IMLib 子模块是否占用
 
 *  \~english
 Determine whether other modules are using sound channels.

 @ discussion It mainly detects whether IMKit sub-module and IMLib sub-module are occupied.
 */
+ (BOOL)isAudioHolding;

/**
 *  \~chinese
 判断其他模块是否正在使用摄像头
 
 @discussion 主要检测 IMKit 子模块和 IMLib 子模块是否占用
 
 *  \~english
 Determine if other modules are using the camera.

 @ discussion mainly detects whether IMKit sub-module and IMLib sub-module are occupied.
 */
+ (BOOL)isCameraHolding;
@end
