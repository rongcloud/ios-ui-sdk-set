//
//  RCMessageCellDelegate.h
//  RongIMKit
//
//  Created by xugang on 3/14/15.
//  Copyright (c) 2015 RongCloud. All rights reserved.
//

#import "RCMessageModel.h"

/*!
 *  \~chinese
 消息Cell点击的回调
 
 *  \~english
 Callback for clicking message Cell  
 */
@protocol RCMessageCellDelegate <NSObject>
@optional

/*!
 *  \~chinese
 点击Cell内容的回调

 @param model 消息Cell的数据模型
 
 *  \~english
 Callback for clicking Cell content.

 @param model Data Model of message Cell
 */
- (void)didTapMessageCell:(RCMessageModel *)model;

/*!
 *  \~chinese
 点击Cell中URL的回调

 @param url   点击的URL
 @param model 消息Cell的数据模型

 @discussion 点击Cell中的URL，会调用此回调，不会再触发didTapMessageCell:。
 
 *  \~english
 Callback for clicking the URL in Cell.

 @param url Clicked URL.
 @param model Data Model of message Cell.

 @ discussion To click URL in Cell, this callback will be called and will not trigger didTapMessageCell:.
 */
- (void)didTapUrlInMessageCell:(NSString *)url model:(RCMessageModel *)model;

/*!
 *  \~chinese
 点击撤回消息Cell中重新编辑的回调

 @param model 消息Cell的数据模型

 @discussion 点击撤回消息Cell中重新编辑，会调用此回调，不会再触发didTapMessageCell:。
 
 *  \~english
 Callback for clicking the recall message Cell to re-edit

 @param model Data Model of message Cell.

 @ discussion Click the recall message Cell to re-edit, this callback will be called and didTapMessageCell: will not be triggered again.
 */
- (void)didTapReedit:(RCMessageModel *)model;

/*!
 *  \~chinese
 点击Cell中电话号码的回调

 @param phoneNumber 点击的电话号码
 @param model       消息Cell的数据模型

 @discussion 点击Cell中的电话号码，会调用此回调，不会再触发didTapMessageCell:。
 
 *  \~english
 Callback for clicking the phone number in Cell.

 @param phoneNumber The phone number clicked.
 @param model Data Model of message Cell.

 @ discussion To click the phone number in Cell, this callback will be called and didTapMessageCell: will not be triggered again.
 */
- (void)didTapPhoneNumberInMessageCell:(NSString *)phoneNumber model:(RCMessageModel *)model;

/*!
 *  \~chinese
 点击Cell中用户头像的回调

 @param userId 头像对应的用户ID
 
 *  \~english
 Callback for clicking the user portrait in Cell.

 @param userId ID of the user corresponding to the portrait.
 */
- (void)didTapCellPortrait:(NSString *)userId;

/*!
 *  \~chinese
 长按Cell中用户头像的回调

 @param userId 头像对应的用户ID
 
 *  \~english
 Callback for holding user portrait in Cell.

 @param model ID of the user corresponding to the portrait.
 */
- (void)didLongPressCellPortrait:(NSString *)userId;

/*!
 *  \~chinese
 长按Cell内容的回调

 @param model 消息Cell的数据模型
 @param view  长按区域的View
 
 *  \~english
 Callback for holding Cell content.

 @param model Data Model of message Cell.
 @param view View of hold area.
 */
- (void)didLongTouchMessageCell:(RCMessageModel *)model inView:(UIView *)view;

/*!
 *  \~chinese
 点击消息发送失败红点的回调

 @param model 消息Cell的数据模型
 
 *  \~english
 Callback for clicking the red point of message sending failure

 @param model Data Model of message Cell.
 */
- (void)didTapmessageFailedStatusViewForResend:(RCMessageModel *)model;

/*!
 *  \~chinese
 点击消息阅读人数View的回调

 @param model 消息Cell的数据模型

 @discussion 仅支持群组和讨论组
 
 *  \~english
 Callback for clicking view of the message reader number

 @param model Data Model of message Cell.

 @ discussion only supports groups and discussion groups.
 */
- (void)didTapReceiptCountView:(RCMessageModel *)model;

/*!
 *  \~chinese
 点击媒体消息取消发送按钮

 @param model 媒体消息Cell的数据模型

 @discussion 仅支持取消文件消息的发送
 
 *  \~english
 Click the media message cancel send button.

 @param model Data Model of Media message Cell.

 @ discussion Only support canceling the sending of file messages.
 */
- (void)didTapCancelUploadButton:(RCMessageModel *)model;

/*!
 *  \~chinese
 点击引用消息中被引用消息内容预览的回调

 @param model 引用消息Cell的数据模型
 
 *  \~english
 Callback for clicking the content preview of the referenced message in the referenced message.

 @param model Data model referencing message Cell.
*/
- (void)didTapReferencedContentView:(RCMessageModel *)model;

#pragma mark - CustomerService
/*!
 *  \~chinese
 机器人解答问题，点击是否解决问题的回调

 @param model 消息Cell的数据模型
 @param isResolved 是否解决问题
 
 *  \~english
 Callback for question answer of the robot and clicking whether or not to solve the problem.

 @param model Data Model of message Cell.
 @param isResolved Whether to solve the problem.
 */
- (void)didTapCustomerService:(RCMessageModel *)model RobotResoluved:(BOOL)isResolved;

/*!
 *  \~chinese
 点击需要消息回执View的回调

 @param model 消息Cell的数据模型

 @discussion 仅支持群组和讨论组
 
 *  \~english
 Callback for clicking the view to require message receipt

 @param model Data Model of message Cell.

 @ discussion Only support groups and discussion groups.
 */
- (void)didTapNeedReceiptView:(RCMessageModel *)model;

@end

/*!
 *  \~chinese
 公众服务会话中消息Cell点击的回调
 
 *  \~english
 Callback for clicking message Cell in public service conversation.
 */
@protocol RCPublicServiceMessageCellDelegate <NSObject>
@optional

/*!
 *  \~chinese
 公众服务会话中，点击Cell内容的回调

 @param model 消息Cell的数据模型
 
 *  \~english
 Callback for clicking Cell content in the public service conversation

 @param model Data Model of message Cell.
 */
- (void)didTapPublicServiceMessageCell:(RCMessageModel *)model;

/*!
 *  \~chinese
 公众服务会话中，点击Cell中URL的回调

 @param url   点击的URL
 @param model 消息Cell的数据模型

 @discussion 点击Cell中的URL，会调用此回调，不会再触发didTapMessageCell:。
 
 *  \~english
 Callback for clicking URL in Cell in the public service conversation

 @param url Clicked URL.
 @param model Data Model of message Cell.

 @ discussion To click URL in Cell, this callback is called and will not trigger didTapMessageCell:.
 */
- (void)didTapUrlInPublicServiceMessageCell:(NSString *)url model:(RCMessageModel *)model;

/*!
 *  \~chinese
 公众服务会话中，点击Cell中电话号码的回调

 @param phoneNumber 点击的电话号码
 @param model       消息Cell的数据模型

 @discussion 点击Cell中的电话号码，会调用此回调，不会再触发didTapMessageCell:。
 
 *  \~english
 Callback for clicking  the phone number in Cell in a public service conversation

 @param phoneNumber The phone number clicked.
 @param model Data Model of message Cell.

 @ discussion To click the phone number in Cell, this callback will be called and didTapMessageCell: will not be triggered again.
 */
- (void)didTapPhoneNumberInPublicServiceMessageCell:(NSString *)phoneNumber model:(RCMessageModel *)model;

/*!
 *  \~chinese
 公众服务会话中，长按Cell内容的回调

 @param model 消息Cell的数据模型
 @param view  长按区域的View
 
 *  \~english
 Callback for holding Cell content in a public service conversation

 @param model Data Model of message Cell.
 @param view View of hold area.
 */
- (void)didLongTouchPublicServiceMessageCell:(RCMessageModel *)model inView:(UIView *)view;

/*!
 *  \~chinese
 公众服务会话中，点击消息发送失败红点的回调

 @param model 消息Cell的数据模型
 
 *  \~english
 Callback  for sending failure red point when clicking to send message in a public service conversation

 @param model Data Model of message Cell
 */
- (void)didTapPublicServiceMessageFailedStatusViewForResend:(RCMessageModel *)model;

@end
