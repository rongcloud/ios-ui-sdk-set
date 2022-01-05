//
//  RCNumberProgressView.h
//  RCIM
//
//  Created by xugang on 6/5/14.
//  Copyright (c) 2014 Heq.Shinoda. All rights reserved.
//

#import <UIKit/UIKit.h>

/*!
 *  \~chinese
 图片消息进度的View
 
 *  \~english
 View of the progress of the image message 
 */
@interface RCImageMessageProgressView : UIView

/*!
 *  \~chinese
 显示进度的Label
 
 *  \~english
 Label showing progress
 */
@property (nonatomic, weak) UILabel *label;

/*!
 *  \~chinese
 进度指示的View
 
 *  \~english
 View for progress indication
 */
@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;

/*!
 *  \~chinese
 更新进度

 @param progress 进度值，0 <= progress <= 100
 
 *  \~english
 Update Progress.

 @param progress Progress value, 0 < = progress < = 100
 */
- (void)updateProgress:(NSInteger)progress;

/*!
 *  \~chinese
 开始播放动画
 
 *  \~english
 Start playing the animation
 */
- (void)startAnimating;

/*!
 *  \~chinese
 停止播放动画
 
 *  \~english
 Stop playing the animation
 */
- (void)stopAnimating;

@end
