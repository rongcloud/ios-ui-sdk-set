//
//  RCSightSlideViewController.h
//  RongIMKit
//
//  Created by zhaobingdong on 2017/5/2.
//  Copyright © 2017年 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCBaseViewController.h"

@class RCMessageModel;

@interface RCSightSlideViewController : RCBaseViewController

/*!
 当前消息的数据模型
 */
@property (nonatomic, strong) RCMessageModel *messageModel;

@property (nonatomic, assign) BOOL topRightBtnHidden;

/*!
 是否只预览当前视频消息，默认为 NO，支持当前会话视频消息滑动预览，如果设置为 YES， 只预览当前视频消息
*/
@property (nonatomic, assign) BOOL onlyPreviewCurrentMessage;

@end
