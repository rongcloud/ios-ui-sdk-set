//
//  RCSightMessageCell.h
//  RongIMKit
//
//  Created by LiFei on 2016/12/5.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RongIMKit.h"

@class RCSightMessageProgressView;
@interface RCSightMessageCell : RCMessageCell

/*!
 显示小视频缩略图的View
 */
@property (nonatomic, strong) UIImageView *thumbnailView;

/*!
 显示发送进度的View
 */
@property (nonatomic, strong) RCSightMessageProgressView *progressView;

@end
