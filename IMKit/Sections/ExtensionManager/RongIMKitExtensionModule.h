//
//  RongIMKitExtensionModule.h
//  RongIMKit
//
//  Created by RongCloud on 16/7/2.
//  Copyright © 2016 RongCloud. All rights reserved.
//

#import "RCExtensionMessageCellInfo.h"
#import "RCExtensionModule.h"
#import "RCMessageModel.h"
#import <Foundation/Foundation.h>

/*!
 *  \~chinese
 RongCloud IM扩展模块协议
 
 *  \~english
 RongCloud IM extension module protocol. 
 */
@protocol RongIMKitExtensionModule <RCExtensionModule>

@optional

#pragma mark - Cell
/*!
 *  \~chinese
 获取会话页面的cell信息。

 @param conversationType  会话类型
 @param targetId          targetId

 @return cell信息列表。

 @discussion 当进入到会话页面时，SDK需要了解扩展模块的消息对应的MessageCell和reuseIdentifier。
 
 *  \~english
 Get the cell information for the conversation page.

  @param conversationType  Conversation type
 @param targetId TargetId.

 @ return cell information list.

  @ discussion When entering the conversation page, SDK shall know the MessageCell and reuseIdentifier corresponding to the messages of the extension module.
 */
- (NSArray<RCExtensionMessageCellInfo *> *)getMessageCellInfoList:(RCConversationType)conversationType
                                                         targetId:(NSString *)targetId;

/*!
 *  \~chinese
 点击MessageCell的处理

 @param messageModel   被点击MessageCell的model
 
 *  \~english
 Click on the processing of MessageCell.

 @param targetId Model of clicked MessageCell
 */
- (void)didTapMessageCell:(RCMessageModel *)messageModel;

/**
 *  \~chinese
 会话页面 WillAppear 时会调用，可以自己修改 extensionView 的 frame 及内容

 @param conversationType 会话类型
 @param targetId         targetId
 @param extensionView    扩展view
 
 *  \~english
 It is called upon the conversation page WillAppear, and you can modify the frame and content of extensionView yourself.

 @param targetId Conversation type
 @param targetId TargetId.
 @param targetId Extended view.
 */
- (void)extensionViewWillAppear:(RCConversationType)conversationType
                       targetId:(NSString *)targetId
                  extensionView:(UIView *)extensionView;

/**
 *  \~chinese
 会话页面 WillDisappear 时会调用（如果您的扩展模块里有其他需要改变会话页面的
 extensionView,在收到这个方法之后就应该终止修改）

 @param conversationType 会话类型
 @param targetId         targetId
 
 *  \~english
 It will be called upon the conversation page WillDisappear  (if there is ExtensionView else in your extension module that will change the conversation page, the modification shall be terminated after receiving this method).

 @param conversationType Conversation type
 @param targetId TargetId.
 */
- (void)extensionViewWillDisappear:(RCConversationType)conversationType targetId:(NSString *)targetId;

/**
 *  \~chinese
 会话页面即将被销毁，点击会话页面左上角的“返回”按钮会触发这个回调

 @param conversationType 会话类型
 @param targetId targetId
 
 *  \~english
 The conversation page is about to be destroyed. Clicking the "back" button at the upper left corner of the conversation page will trigger this callback.

 Conversation type
 TargetId.
 */
- (void)containerViewWillDestroy:(RCConversationType)conversationType targetId:(NSString *)targetId;

@end
