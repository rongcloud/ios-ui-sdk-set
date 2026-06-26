//
//  RCCCUserListViewController.h
//  RongContactCard
//
//  Created by liulin on 16/11/17.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <RongIMLibCore/RongIMLibCore.h>

@interface RCCCUserListViewController : RCBaseViewController

@property (nonatomic) RCConversationType conversationType;

@property (nonatomic, strong) NSString *targetId;

@end
