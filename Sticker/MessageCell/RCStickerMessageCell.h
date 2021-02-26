//
//  RCStickerMessageCell.h
//  RongSticker
//
//  Created by liyan on 2018/8/7.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import "RongIMKitHeader.h"
#import "RCAnimated.h"
#import "RCAnimatedView.h"
#import "RCStickerDataManager.h"

/*!
表情消息Cell
 */
@interface RCStickerMessageCell : RCMessageCell

/*!
 表情背景View
 */
@property (nonatomic, strong) RCAnimatedView *rcStickerView;

@end
