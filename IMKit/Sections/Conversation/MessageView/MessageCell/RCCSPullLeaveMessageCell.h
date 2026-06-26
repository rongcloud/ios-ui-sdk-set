//
//  RCCSLeaveMsgCell.h
//  RongIMKit
//
//  Created by 张改红 on 2016/12/7.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCAttributedLabel.h"
#import "RongIMKit.h"
@interface RCCSPullLeaveMessageCell : RCMessageBaseCell <RCAttributedLabelDelegate>
@property (nonatomic, strong) RCAttributedLabel *contentLabel;
@end
