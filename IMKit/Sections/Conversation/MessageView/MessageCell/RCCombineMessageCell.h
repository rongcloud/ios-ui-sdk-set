//
//  RCCombineMessageCell.h
//  RongIMKit
//
//  Created by liyan on 2019/8/13.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import "RongIMKit.h"
#import "RCBaseView.h"
NS_ASSUME_NONNULL_BEGIN

@interface RCCombineMessageCell : RCMessageCell

/// 消息的背景 View
@property (nonatomic, strong) RCBaseView *backView;

/// 展示消息的 title
@property (nonatomic, strong) RCBaseLabel *titleLabel;

/// 展示消息的缩略内容
@property (nonatomic, strong) RCBaseLabel *contentLabel;

/// 展示消息的聊天记录字样
@property (nonatomic, strong) RCBaseLabel *historyLabel;

@end

NS_ASSUME_NONNULL_END
