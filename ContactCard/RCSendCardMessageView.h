//
//  RCSendCardMessageView.h
//  RongContactCard
//
//  Created by Jue on 2016/12/19.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <RongIMLibCore/RongIMLibCore.h>
#import "RCCCGroupInfo.h"

FOUNDATION_EXPORT NSString *const RCCC_CardMessageSend;

@interface RCSendCardMessageView : UIView

@property (nonatomic, strong) RCUserInfo *cardUserInfo;

@property (nonatomic, strong) RCUserInfo *targetUserInfo;

@property (nonatomic, strong) RCCCGroupInfo *targetgroupInfo;

- (id)initWithFrame:(CGRect)frame ConversationType:(RCConversationType)conversationType targetId:(NSString *)targetId;

@end
