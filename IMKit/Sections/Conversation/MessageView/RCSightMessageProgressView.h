//
//  RCSightMessageProgressView.h
//  RongIMKit
//
//  Created by zhaobingdong on 2017/5/18.
//  Copyright © 2017年 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RCSightMessageProgressView : UIControl

@property (nonatomic) float progress;

@property (nonatomic, strong) UIColor *progressTintColor;

- (instancetype)initWithFrame:(CGRect)frame;

- (void)setProgress:(float)progress animated:(BOOL)animated;

- (void)startIndeterminateAnimation;

- (void)stopIndeterminateAnimation;

- (void)resetStatus;

@end
