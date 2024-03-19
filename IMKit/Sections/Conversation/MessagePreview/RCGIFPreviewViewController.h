//
//  RCGIFPreviewViewController.h
//  RongIMKit
//
//  Created by liyan on 2018/12/24.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import "RCBaseViewController.h"
#import "RCMessageModel.h"
#import "RCGIFImageView.h"

NS_ASSUME_NONNULL_BEGIN

@interface RCGIFPreviewViewController : RCBaseViewController

/*!
 消息的数据模型
 */
@property (nonatomic, strong) RCMessageModel *messageModel;

@end

NS_ASSUME_NONNULL_END
