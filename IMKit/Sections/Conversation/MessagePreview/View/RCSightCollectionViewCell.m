//
//  RCSightCollectionViewCell.m
//  RongIMKit
//
//  Created by zhaobingdong on 2017/5/3.
//  Copyright © 2017年 RongCloud. All rights reserved.
//

#import "RCSightCollectionViewCell.h"
#import "RongIMKit.h"
#import "RCIMClient+Destructing.h"
#import "RCSightPlayerController+imkit.h"

@interface RCSightCollectionViewCell ()

@property (nonatomic, strong) UIImageView *thumbnailView;

@property (nonatomic, strong) UIButton *playBtn;

@property (nonatomic, strong) RCSightPlayerController *playerController;

@property (nonatomic, strong) RCMessageModel *messageModel;

@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;

@end

@implementation RCSightCollectionViewCell
#pragma mark - Life Cycle
- (instancetype)init {
    if (self = [super init]) {
        [self setUp];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setUp];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self setUp];
    }
    return self;
}

#pragma mark - Public Methods
- (void)setDataModel:(RCMessageModel *)model {
    self.messageModel = model;
    RCSightMessage *sightMessage = (RCSightMessage *)model.content;
    [self.playerController setFirstFrameThumbnail:sightMessage.thumbnailImage];
    self.label.text = [NSString stringWithFormat:@"%ld", model.messageId];
    //判断如果 localPath 有效，优先使用。之前的逻辑无法使用本地路径插入小视频消息。
    NSString *localPath = nil;
    if (sightMessage.localPath != nil && sightMessage.localPath.length > 0) {
        localPath = sightMessage.localPath;
    } else if (sightMessage.sightUrl != nil && sightMessage.sightUrl.length > 0) {
        localPath = [RCFileUtility getSightCachePath:sightMessage.sightUrl];
    } else {
        RCLogV(@"LocalPath and sightUrl are nil");
    }

    if ([[NSFileManager defaultManager] fileExistsAtPath:localPath]) {
        self.playerController.rcSightURL = [[NSURL alloc] initFileURLWithPath:localPath];
        [self.playerController setFirstFrameThumbnail:self.playerController.firstFrameImage];
    } else {
        self.playerController.rcSightURL = [NSURL URLWithString:sightMessage.sightUrl];
    }
}


- (void)stopPlay {
    if (self.playerController) {
        [self.playerController reset:YES];
    }
}

- (void)resetPlay {
    if (self.playerController) {
        [self.playerController reset:NO];
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
- (void)setUp {
    Class playerType = NSClassFromString(@"RCSightPlayerController");
    if (playerType) {
        self.playerController = [[playerType alloc] init];
        self.playerController.delegate = self;
        self.playerController.autoPlay = YES;
        [self.contentView addSubview:self.playerController.view];
        [self strechToSuperview:self.playerController.view];
        UILongPressGestureRecognizer *longPress =
            [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressed:)];
        [self.playerController.view addGestureRecognizer:longPress];
    }
}

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
    RCSightMessage *sightMessage = (RCSightMessage *)self.messageModel.content;
    NSString *localPath = nil;
    if (sightMessage.localPath != nil && sightMessage.localPath.length > 0) {
        localPath = sightMessage.localPath;
    } else if (sightMessage.sightUrl != nil && sightMessage.sightUrl.length > 0) {
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
