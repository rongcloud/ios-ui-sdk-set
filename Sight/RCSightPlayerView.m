//
//  RCSightPlayerView.m
//  RongExtensionKit
//
//  Created by zhaobingdong on 2017/4/28.
//  Copyright © 2017年 RongCloud. All rights reserved.
//

#import "RCSightPlayerView.h"
#import "RCSightPlayerOverlayView.h"

@interface RCSightPlayerView ()
@property (strong, nonatomic) RCSightPlayerOverlayView *overlayView;
@end

@implementation RCSightPlayerView
#pragma mark - Properties
- (RCSightPlayerOverlayView *)overlayView {
    if (!_overlayView) {
        _overlayView = [[RCSightPlayerOverlayView alloc] init];
    }
    return _overlayView;
}

#pragma mark - override
+ (Class)layerClass {
    return [AVPlayerLayer class];
}

#pragma mark - api

- (instancetype)init {
    if (self = [super initWithFrame:CGRectZero]) {
        self.backgroundColor = [UIColor blackColor];
        self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [self addSubview:self.overlayView];
    }
    return self;
}

- (instancetype)initWithPlayer:(AVPlayer *)player {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.backgroundColor = [UIColor blackColor];
        self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

        [(AVPlayerLayer *)[self layer] setPlayer:player];

        [self addSubview:self.overlayView];
    }
    return self;
}

- (void)setPlayer:(AVPlayer *)player {
    [(AVPlayerLayer *)[self layer] setPlayer:player];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.overlayView.frame = self.bounds;
}

- (id<RCSightPlayerTransport, RCSightPlayerOverlay>)transport {
    return self.overlayView;
}

- (void)dealloc {
}

@end
