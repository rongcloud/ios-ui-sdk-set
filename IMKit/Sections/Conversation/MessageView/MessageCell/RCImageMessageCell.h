//
//  RCImageMessageCell.h
//  RongIMKit
//
//  Created by xugang on 15/2/2.
//  Copyright (c) 2015 RongCloud. All rights reserved.
//

#import "RCImageMessageProgressView.h"
#import "RCMessageCell.h"

/*!
 *  \~chinese
 图片消息Cell
 
 *  \~english
 Image message Cell 
 */
@interface RCImageMessageCell : RCMessageCell

/*!
 *  \~chinese
 显示图片缩略图的View
 
 *  \~english
 View that displays thumbnails of images
 */
@property (nonatomic, strong) UIImageView *pictureView;

/*!
 *  \~chinese
 显示发送进度的View
 
 *  \~english
 View showing sending progress
 */
@property (nonatomic, strong) RCImageMessageProgressView *progressView;

@end
