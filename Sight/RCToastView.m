//
//  RCToastView.m
//  RongExtensionKit
//
//  Created by chinaspx on 2022/5/19.
//  Copyright © 2022 RongCloud. All rights reserved.
//

#import "RCToastView.h"

#define kToastViewDuring          2.0f
#define kToastViewFont            15.0f
#define kToastViewLeftSpace       10.0f
#define kMCToastViewTopSpace      10.0f
#define kToastViewAlpha           0.8f
#define KToastViewBottomSpace     200.0f

@interface RCToastView ()

@property (nonatomic, strong) UIView * bgView;
/** 文字文本 */
@property (nonatomic, strong) UILabel * titleLabel;

@end

static RCToastView *s_toastView = nil;

@implementation RCToastView

- (void)createMainView {
    self.bgView = [[UIView alloc] init];
    self.bgView.backgroundColor = [UIColor grayColor];
    self.bgView.layer.cornerRadius = 5.0f;
    self.bgView.layer.masksToBounds = YES;
    self.bgView.alpha = kToastViewAlpha;
    [self addSubview:self.bgView];

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = [UIFont systemFontOfSize:kToastViewFont];
    self.titleLabel.numberOfLines = 0;
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.textColor = [UIColor whiteColor];
    [self.bgView addSubview:self.titleLabel];
}

+ (void)showToast:(NSString *)toastString rootView:(UIView *)rootView {
    s_toastView = [[RCToastView alloc] init];
    [rootView addSubview:s_toastView];
    [s_toastView createMainView];
    [s_toastView changeSubViewsFrameAndAnimation:toastString];
}

- (void)changeSubViewsFrameAndAnimation:(NSString *)toastString {
    if (toastString == nil) {
        toastString = @"";
    }
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    UIFont *font = [UIFont systemFontOfSize:kToastViewFont];
    NSMutableDictionary *attrs = [NSMutableDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
    CGSize size = [toastString boundingRectWithSize:CGSizeMake(screenWidth - kToastViewLeftSpace*4, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:attrs context:nil].size;
    
    self.titleLabel.text = toastString;
    self.titleLabel.hidden = NO;
    
    self.titleLabel.frame = CGRectMake(kToastViewLeftSpace, kMCToastViewTopSpace, size.width, size.height);
    self.bgView.frame = CGRectMake((screenWidth - _titleLabel.frame.size.width - kToastViewLeftSpace*2)/2, (screenHeight - KToastViewBottomSpace - _titleLabel.frame.size.height - kMCToastViewTopSpace*2), _titleLabel.frame.size.width + kToastViewLeftSpace*2, _titleLabel.frame.size.height + kMCToastViewTopSpace*2);
    
    dispatch_time_t toastDelay = dispatch_time(DISPATCH_TIME_NOW, kToastViewDuring * NSEC_PER_SEC);
    dispatch_queue_t currentQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_after(toastDelay, currentQueue, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self stopToastView];
        });
    });
}

- (void)stopToastView {
    self.hidden = YES;
    [self removeFromSuperview];
    s_toastView = nil;
}

@end
