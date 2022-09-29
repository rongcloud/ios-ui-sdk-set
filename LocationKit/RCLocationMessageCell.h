//
//  RCLocationMessageCell.h
//  RongIMKit
//
//  Created by xugang on 15/2/2.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#if __has_include(<RongIMKit/RongIMKit.h>)

#import <RongIMKit/RongIMKit.h>

#else

#import "RongIMKit.h"

#endif


/*!
 位置消息Cell
 */
@interface RCLocationMessageCell : RCMessageCell

/*!
 当前位置在地图中的概览图
 */
@property (nonatomic, strong) UIImageView *pictureView;

/*!
 显示位置名称的Label
 */
@property (nonatomic, strong) UILabel *locationNameLabel;

@end
