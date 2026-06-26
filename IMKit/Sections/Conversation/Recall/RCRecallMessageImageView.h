//
//  RCRecallMessageImageView.h
//  RongIMKit
//
//  Created by liulin on 16/7/17.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>

/*!
 撤回消息进度的View
 */
@interface RCRecallMessageImageView : UIView

/*!
 显示字体
 */
@property (nonatomic, weak) UILabel *label;

/*!
 进度指示的View
 */
@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;

/*!
 开始播放动画
 */
- (void)startAnimating;

/*!
 停止播放动画
 */
- (void)stopAnimating;

@end
