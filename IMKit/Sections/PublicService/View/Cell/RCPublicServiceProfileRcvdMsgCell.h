//
//  RCPublicServiceProfileRcvdMsgCell.h
//  HelloIos
//
//  Created by litao on 15/4/10.
//  Copyright (c) 2015年 litao. All rights reserved.
//

#import <RongIMLibCore/RongIMLibCore.h>
#import <UIKit/UIKit.h>
#import "RCBaseTableViewCell.h"
@class RCPublicServiceProfile;
@interface RCPublicServiceProfileRcvdMsgCell : RCBaseTableViewCell
@property (nonatomic, strong) RCPublicServiceProfile *serviceProfile;
- (void)setTitleText:(NSString *)title;
- (void)setOn:(BOOL)enableNotification;
@end
