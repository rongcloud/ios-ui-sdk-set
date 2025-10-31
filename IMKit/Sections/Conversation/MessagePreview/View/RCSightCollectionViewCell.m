//
//  RCSightCollectionViewCell.m
//  RongIMKit
//
//  Created by zhaobingdong on 2017/5/3.
//  Copyright © 2017年 RongCloud. All rights reserved.
//

#import "RCSightCollectionViewCell.h"
#import "RongIMKit.h"
#import "RCCoreClient+Destructing.h"
#import "RCSightPlayerController+imkit.h"
#import "RCSightModel.h"
#import "RCSightModel+internal.h"
#import "RCBaseImageView.h"
@interface RCSightCollectionViewCell ()

@property (nonatomic, strong) RCBaseImageView *thumbnailView;

@property (nonatomic, strong) UIButton *playBtn;

@property (nonatomic, strong) RCSightPlayerController *playerController;

@property (nonatomic, strong) RCSightModel *messageModel;

@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;

@end

@implementation RCSightCollectionViewCell
#pragma mark - Life Cycle

#pragma mark - Public Methods
- (void)setDataModel:(RCSightModel *)model {
    self.messageModel = model;
    Class playerType = NSClassFromString(@"RCSightPlayerController");
    if (playerType) {
        self.playerController = model.playerController;
        self.playerController.delegate = self;
        self.playerController.autoPlay = YES;
        [self.contentView addSubview:self.playerController.view];
        [self strechToSuperview:self.playerController.view];
        UILongPressGestureRecognizer *longPress =
            [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressed:)];
        [self.playerController.view addGestureRecognizer:longPress];
    }
    self.label.text = [NSString stringWithFormat:@"%ld", model.message.messageId];
}

- (void)stopPlay {
    if (self.playerController) {
        [self.playerController resetSightPlayer:YES];
    }
}

- (void)resetPlay {
    if (self.playerController) {
        [self.playerController resetSightPlayer:NO];
    }
}

#pragma mark - constraint helpers
- (void)strechToSuperview:(UIView *)view {
    view.translatesAutoresizingMaskIntoConstraints = NO;
    NSArray *formats = @[ @"H:|[view]|", @"V:|[view]|" ];
    for (NSString *each in formats) {
        NSArray *constraints =
            [NSLayoutConstraint constraintsWithVisualFormat:each options:0 metrics:nil views:@{
                @"view" : view
            }];
        [view.superview addConstraints:constraints];
    }
}

- (void)constraintCenterInSuperview:(UIView *)view {
    view.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *constraintY = [NSLayoutConstraint constraintWithItem:view
                                                                   attribute:NSLayoutAttributeCenterY
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:view.superview
                                                                   attribute:NSLayoutAttributeCenterY
                                                                  multiplier:1.0f
                                                                    constant:0];
    [view.superview addConstraint:constraintY];

    NSLayoutConstraint *constraintX = [NSLayoutConstraint constraintWithItem:view
                                                                   attribute:NSLayoutAttributeCenterX
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:view.superview
                                                                   attribute:NSLayoutAttributeCenterX
                                                                  multiplier:1.0f
                                                                    constant:0];

    [view.superview addConstraint:constraintX];
}

- (void)constrainView:(UIView *)view toSize:(CGSize)size {

    view.translatesAutoresizingMaskIntoConstraints = NO;
    NSArray *formats = @[ @"H:[view(==width)]", @"V:[view(==height)]" ];

    for (NSString *each in formats) {
        NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:each
                                                                       options:0
                                                                       metrics:@{
                                                                           @"width" : @(size.width),
                                                                           @"height" : @(size.height)
                                                                       }
                                                                         views:@{
                                                                             @"view" : view
                                                                         }];
        [view addConstraints:constraints];
    }
}

#pragma mark - Private Methods
- (void)setAutoPlay:(BOOL)autoPlay {
    _autoPlay = autoPlay;
    if (_autoPlay) {
        [self.playerController play];
    }
}

- (void)closeSightPlayer {
    [self.delegate closeSight];
}

- (void)playToEnd {
    if ([self.delegate respondsToSelector:@selector(playEnd)]) {
        [self.delegate performSelector:@selector(playEnd) withObject:nil];
    }
}

- (void)longPressed:(id)sender {
    RCSightMessage *sightMessage = (RCSightMessage *)self.messageModel.message.content;
    NSString *localPath = nil;
    if (sightMessage.localPath && [[NSFileManager defaultManager] fileExistsAtPath:sightMessage.localPath]) {
        localPath = sightMessage.localPath;
    } else if (sightMessage.sightUrl && sightMessage.sightUrl.length > 0) {
        localPath = [RCFileUtility getSightCachePath:sightMessage.sightUrl];
    } else {
        RCLogV(@"LocalPath and sightUrl are nil");
    }

    if (localPath && [[NSFileManager defaultManager] fileExistsAtPath:localPath]) {
        UILongPressGestureRecognizer *press = (UILongPressGestureRecognizer *)sender;
        if (press.state == UIGestureRecognizerStateEnded) {
            return;
        } else if (press.state == UIGestureRecognizerStateBegan) {
            if ([self.delegate respondsToSelector:@selector(sightLongPressed:)]) {
                [self.delegate performSelector:@selector(sightLongPressed:) withObject:localPath];
            }
        }
    }
}

@end
