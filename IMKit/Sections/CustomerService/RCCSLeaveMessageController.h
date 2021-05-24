//
//  RCCSLeaveMessageController.h
//  RongIMKit
//
//  Created by 张改红 on 2016/12/5.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCConversationViewController.h"
#import <RongIMLib/RongIMLib.h>
#import <UIKit/UIKit.h>
#import "RCBaseTableViewController.h"
@class RCCSLeaveMessageItem;
@interface RCCSLeaveMessageController : RCBaseTableViewController
@property (nonatomic, strong) NSArray<RCCSLeaveMessageItem *> *leaveMessageConfig;
@property (nonatomic, copy) NSString *targetId;
@property (nonatomic, assign) RCConversationType conversationType;
@property (nonatomic, copy) void (^leaveMessageSuccess)(void);
@end
