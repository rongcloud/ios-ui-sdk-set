//
//  RCGIFMessageCell.h
//  RongIMKit
//
//  Created by liyan on 2018/12/20.
//  Copyright © 2018 RongCloud. All rights reserved.
//

#import "RCMessageCell.h"
#import "RCGIFImageView.h"
#import "RCImageMessageProgressView.h"

NS_ASSUME_NONNULL_BEGIN

@interface RCGIFMessageCell : RCMessageCell

/*!
 *  \~chinese
 显示图片缩略图的View
 
 *  \~english
 View that displays thumbnails of images
 */
@property (nonatomic, strong) RCGIFImageView *gifImageView;

/*!
 *  \~chinese
 显示发送进度的View
 
 *  \~english
 View showing sending progress 
 */
@property (nonatomic, strong) RCImageMessageProgressView *progressView;

@end

NS_ASSUME_NONNULL_END
