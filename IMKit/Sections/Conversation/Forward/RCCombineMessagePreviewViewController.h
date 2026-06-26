//
//  RCCombineMessagePreviewViewController.h
//  RongIMKit
//
//  Created by liyan on 2019/8/9.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCMessageModel.h"
#import "RCBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface RCCombineMessagePreviewViewController : RCBaseViewController

- (instancetype)initWithRemoteURL:(NSString *)remoteURL
                 conversationType:(RCConversationType)conversationType
                         targetId:(NSString *)targetId
                         navTitle:(NSString *)navTitle;

- (instancetype)initWithMessageModel:(RCMessageModel *)messageModel navTitle:(NSString *)navTitle;

@end

NS_ASSUME_NONNULL_END
