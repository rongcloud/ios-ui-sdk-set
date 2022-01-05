//
//  RCCSLeaveMsgCell.h
//  RongIMKit
//
//  Created by RongCloud on 2016/12/7.
//  Copyright © 2016 RongCloud. All rights reserved.
//

#import "RCAttributedLabel.h"
#import "RongIMKit.h"
@interface RCCSPullLeaveMessageCell : RCMessageBaseCell <RCAttributedLabelDelegate>
@property (nonatomic, strong) RCAttributedLabel *contentLabel;
@end
