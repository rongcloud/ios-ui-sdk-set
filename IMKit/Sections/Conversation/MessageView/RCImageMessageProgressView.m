//
//  RCNumberProgressView.m
//  RCIM
//
//  Created by xugang on 6/5/14.
//  Copyright (c) 2014 Heq.Shinoda. All rights reserved.
//

#import "RCImageMessageProgressView.h"
#import "RCKitConfig.h"

@implementation RCImageMessageProgressView
#pragma mark - Life Cycle
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 50, 30)];
        self.label = label;
        [label setTextAlignment:NSTextAlignmentCenter];
        self.label.font = [[RCKitConfig defaultConfig].font fontOfSecondLevel];
        [self.label setBackgroundColor:[UIColor clearColor]];
        [self.label setTextColor:[UIColor whiteColor]];
        label.text = @"0%";
        [self addSubview:label];
        [label setCenter:CGPointMake(frame.size.width / 2 - 4, frame.size.height / 2 + 13)];

        [self setBackgroundColor:[UIColor blackColor]];
        [self setAlpha:0.7f];

        self.indicatorView =
            [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [self.indicatorView setFrame:CGRectMake(0, 0, 30, 30)];
        [self addSubview:self.indicatorView];
        [self.indicatorView setCenter:CGPointMake(frame.size.width / 2 - 4, frame.size.height / 2 - 13)];
    }
    return self;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];

    [self.label setCenter:CGPointMake(frame.size.width / 2 - 4, frame.size.height / 2 + 13)];
    [self.indicatorView setCenter:CGPointMake(frame.size.width / 2 - 4, frame.size.height / 2 - 13)];
}

#pragma mark - Public Methods

- (void)updateProgress:(NSInteger)progress {
    NSString *numStr = [NSString stringWithFormat:@"%ld%%", (long)progress];
    [self.label setText:numStr];
    // DebugLog(@"-----###%@",self.label.text);
}
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
