//
//  RCVideoPreviewCell.m
//  RongExtensionKit
//
//  Created by zhaobingdong on 2018/7/5.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import "RCVideoPreviewCell.h"
#import "RCAssetModel.h"
#import "RCKitCommonDefine.h"
#import "RCAssetHelper.h"
#import "RCVideoPlayer.h"
#import "RCBaseButton.h"
#import "RCBaseImageView.h"
@interface RCVideoPreviewCell () <RCVideoPlayerDelegate>
@property (nonatomic, strong) RCBaseImageView *thumbnailView;
@property (nonatomic, strong) RCBaseButton *playBtn;
@property (nonatomic, strong) RCVideoPlayer *player;
@end

@implementation RCVideoPreviewCell

#pragma mark - override
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

- (void)layoutSubviews {
    self.player.frame = self.bounds;
    self.thumbnailView.frame = self.bounds;
    self.playBtn.center = CGPointMake(self.bounds.size.width / 2.0f, self.bounds.size.height / 2.0f);
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Public Methods
- (void)configPreviewCellWithItem:(RCAssetModel *)model {
    [[RCAssetHelper shareAssetHelper] getPreviewWithAsset:model.asset
                                                   result:^(UIImage *photo, NSDictionary *info) {
                                                       dispatch_async(dispatch_get_main_queue(), ^{
                                                           self.thumbnailView.image = photo;
                                                       });
                                                   }];
}

- (void)play:(PHAsset *)asset {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
        options.networkAccessAllowed = YES;
        options.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
        options.version = PHVideoRequestOptionsVersionOriginal;

        options.progressHandler =
            ^(double progress, NSError *_Nullable error, BOOL *_Nonnull stop, NSDictionary *_Nullable info) {
                DebugLog(@"PHVideoRequestOptions progressHandler progress %f", progress);
            };
        [[PHImageManager defaultManager]
            requestPlayerItemForVideo:asset
                              options:options
                        resultHandler:^(AVPlayerItem *_Nullable playerItem, NSDictionary *_Nullable info) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                self.player.playerItem = playerItem;
                                self.player.delegate = self;
                                [self.player play];
                            });
                        }];
    });
}

- (void)stop {
    [self.player pause];
    self.playBtn.hidden = NO;
    self.thumbnailView.hidden = NO;
    [[AVAudioSession sharedInstance] setActive:NO
                                   withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation
                                         error:nil];
}

#pragma mark - RCVideoPlayerDelegate
- (void)itemWillPlay {
    self.thumbnailView.hidden = YES;
    self.playBtn.hidden = YES;
}

- (void)itemDidPlayToEnd {
    self.playBtn.hidden = NO;
    self.thumbnailView.hidden = NO;
}

#pragma mark - Target Action
- (void)playAction {
    [self.delegate sendPlayActionInCell:self];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleWillResignActive)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
}

#pragma mark - Private Methods
- (void)setup {
    [self.contentView addSubview:self.player];
    [self.contentView addSubview:self.thumbnailView];
    [self.contentView addSubview:self.playBtn];
}

- (void)handleWillResignActive {
    [self stop];
}

#pragma mark - Getters and Setters
- (RCBaseImageView *)thumbnailView {
    if (!_thumbnailView) {
        _thumbnailView = [[RCBaseImageView alloc] initWithFrame:CGRectZero];
        _thumbnailView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _thumbnailView;
}

- (RCBaseButton *)playBtn {
    if (!_playBtn) {
        _playBtn = [[RCBaseButton alloc] initWithFrame:(CGRect){0, 0, 80, 80}];
        [_playBtn setImage:RCDynamicImage(@"video_preview_play_btn_normal_img", @"play_btn_normal") forState:UIControlStateNormal];
        [_playBtn addTarget:self action:@selector(playAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playBtn;
}

- (RCVideoPlayer *)player {
    if (!_player) {
        _player = [[RCVideoPlayer alloc] initWithFrame:CGRectZero];
    }
    return _player;
}
@end
