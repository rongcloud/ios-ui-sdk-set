//
//  RCRecallMessageImageView.m
//  RongIMKit
//
//  Created by liulin on 16/7/17.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCRecallMessageImageView.h"
#import "RCKitCommonDefine.h"
@implementation RCRecallMessageImageView
#pragma mark - Life Cycle
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 150, 20)];
        self.label = label;
        [label setTextAlignment:NSTextAlignmentCenter];
        [self.label setBackgroundColor:[UIColor clearColor]];
        [self.label setTextColor:[UIColor whiteColor]];
        label.text = RCLocalizedString(@"MessageRecalling");
        [self addSubview:label];
        [label setCenter:CGPointMake(frame.size.width / 2, frame.size.height / 2 + 30)];

        [self setBackgroundColor:[UIColor blackColor]];
        [self setAlpha:0.7f];

        self.indicatorView =
            [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [self.indicatorView setFrame:CGRectMake(0, 0, 30, 30)];
        [self addSubview:self.indicatorView];
        [self.indicatorView setCenter:CGPointMake(frame.size.width / 2, frame.size.height / 2 - 13)];
    }
    return self;
}

#pragma mark - Super Methods

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];

    [self.label setCenter:CGPointMake(frame.size.width / 2, frame.size.height / 2 + 13)];
    [self.indicatorView setCenter:CGPointMake(frame.size.width / 2, frame.size.height / 2 - 13)];
}

#pragma mark - Public Methods

- (void)startAnimating {
    if (self.indicatorView.isAnimating == NO) {
        [self.indicatorView startAnimating];
    }
}

- (void)stopAnimating {
    if (self.indicatorView.isAnimating == YES) {
        [self.indicatorView stopAnimating];
    }
}

@end
