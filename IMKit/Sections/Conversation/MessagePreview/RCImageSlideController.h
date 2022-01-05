//
//  RCImageSlideController.h
//  RongIMKit
//
//  Created by zhanggaihong on 2021/5/27.
//  Copyright © 2021 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCBaseViewController.h"

@class RCMessageModel;

@interface RCImageSlideController : RCBaseViewController

/*!
 *  \~chinese
 图片预览初始化的数据模型
 
 *  \~english
 Image preview initialized data model 
 */
@property (nonatomic, strong) RCMessageModel *messageModel;

/*!
 *  \~chinese
 当前预览的图片消息
 
 *  \~english
 Current preview image message
 */
@property (nonatomic, strong) RCImageMessage *currentPreviewImage;

/*!
 *  \~chinese
 是否只预览当前图片消息，默认为 NO，支持当前会话图片消息滑动预览，如果设置为 YES， 只预览当前图片消息
 
 *  \~english
 Whether to preview only the current image message. The default value is NO. It supports sliding preview of the current conversation image message. If it is set to YES, only the current image message is previewed.
 */
@property (nonatomic, assign) BOOL onlyPreviewCurrentMessage;

/**
 *  \~chinese
 长按图片内容的回调

 @param sender 长按手势

 @discussion 如需使用SDK的长按图片内容处理，请调用父类方法 [super longPressed:sender];
 
 *  \~english
 Callback for holding the content of the image.

 @param sender Press the gesture for a long time.

 @ discussion If the SDK is used to process holding image content, please call the parent method [super longPressed:sender].
 */
- (void)longPressed:(id)sender;

@end
