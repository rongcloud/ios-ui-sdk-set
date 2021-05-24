//
//  RCSightMessageCell.m
//  RongIMKit
//
//  Created by LiFei on 2016/12/5.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCSightMessageCell.h"
#import "RCKitCommonDefine.h"
#import "RCSightMessageProgressView.h"
#import "RCMessageCellTool.h"
#import "RCKitConfig.h"
#import "RCResendManager.h"
extern NSString *const RCKitDispatchDownloadMediaNotification;

@interface RCSightMessageCell ()
@property (nonatomic, strong) UIView *playButtonView;
@property (nonatomic, strong) UILabel *durationLabel;
@property (nonatomic, strong) UIImageView *playImage;
@property (nonatomic, strong) UIImageView *destructPicture;
@property (nonatomic, strong) UILabel *destructLabel;
@property (nonatomic, strong) UILabel *destructDurationLabel;
@property (nonatomic, strong) UIImageView *destructBackgroundView;
@end

@implementation RCSightMessageCell

#pragma mark - Life Cycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Super Methods

+ (CGSize)sizeForMessageModel:(RCMessageModel *)model
      withCollectionViewWidth:(CGFloat)collectionViewWidth
         referenceExtraHeight:(CGFloat)extraHeight {
    CGFloat messagecontentview_height = 0.0f;
    if (model.content.destructDuration > 0) {
        messagecontentview_height = DestructBackGroundHeight;
    } else {
        messagecontentview_height = [self getSightImageSize:model].height;
    }
    if (messagecontentview_height < RCKitConfigCenter.ui.globalMessagePortraitSize.height) {
        messagecontentview_height = RCKitConfigCenter.ui.globalMessagePortraitSize.height;
    }
    messagecontentview_height += extraHeight;
    return CGSizeMake(collectionViewWidth, messagecontentview_height);
}

- (void)setDataModel:(RCMessageModel *)model {
    [super setDataModel:model];
    self.thumbnailView.image = nil;
    RCSightMessage *sightMessage = (RCSightMessage *)model.content;
    if (sightMessage) {
        if (sightMessage.destructDuration <= 0) {
            self.destructBackgroundView.frame = CGRectZero;
            self.destructBackgroundView.hidden = YES;
            CGSize imageSize = [RCSightMessageCell getSightImageSize:self.model];
            self.durationLabel.text = [self getSightDurationLabelText:sightMessage.duration];
            self.thumbnailView.image = sightMessage.thumbnailImage;
    
            self.messageContentView.contentSize = imageSize;
            self.thumbnailView.frame = self.messageContentView.bounds;
            if (self.progressView.superview) {
                [self.progressView removeFromSuperview];
            }
            self.progressView = [[RCSightMessageProgressView alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
            [self.progressView setHidden:YES];
            self.progressView.progressTintColor = [UIColor whiteColor];
            [self.thumbnailView addSubview:self.progressView];
            [self.playImage setCenter:CGPointMake(self.thumbnailView.bounds.size.width / 2,
                                                  self.thumbnailView.bounds.size.height / 2)];
            self.progressView.center = self.playImage.center;
            CGRect durationLabelBgFrame =
                CGRectMake(0, self.thumbnailView.bounds.size.height - 21, self.thumbnailView.bounds.size.width, 21);
            self.durationLabel.superview.frame = durationLabelBgFrame;
            self.durationLabel.frame =
                CGRectMake(0, 0, durationLabelBgFrame.size.width-5, durationLabelBgFrame.size.height);
        }
    } else {
        DebugLog(@"[RongIMKit]: RCMessageModel.content is NOT RCsightMessage object");
    }

    [self updateStatusContentView:self.model];
    
    [self updateSightPlayStatus];
}

- (void)updateSightPlayStatus{
    if (self.model.sentStatus == SentStatus_SENDING || [[RCResendManager sharedManager] needResend:self.model.messageId]) {
        [self.playButtonView setHidden:YES];
        [self.progressView startIndeterminateAnimation];
        [self.progressView setHidden:NO];
    } else {
        [self.playButtonView setHidden:NO];
        [self.progressView stopIndeterminateAnimation];
        [self.progressView setHidden:YES];
    }
}

- (void)updateStatusContentView:(RCMessageModel *)model{
    [super updateStatusContentView:model];
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (model.content.destructDuration <= 0) {
            weakSelf.messageActivityIndicatorView.hidden = YES;
        }
    });
}

#pragma mark - 阅后即焚

- (void)setDestructViewLayout {
    if (self.model.content.destructDuration > 0) {
        RCSightMessage *sightMessage = (RCSightMessage *)self.model.content;
        self.destructDurationLabel.text = [self getSightDurationLabelText:sightMessage.duration];
        [self updateDestructViews];
    }
    [super setDestructViewLayout];
}

- (void)updateDestructViews{
    self.destructBackgroundView.hidden = NO;
    self.destructBackgroundView.frame = CGRectZero;
    self.thumbnailView.frame = CGRectZero;
    self.messageContentView.contentSize = CGSizeMake(DestructBackGroundWidth, DestructBackGroundWidth);
    self.destructBackgroundView.frame = self.messageContentView.bounds;
    self.destructBackgroundView.image = [RCMessageCellTool getDefaultMessageCellBackgroundImage:self.model];
    self.destructPicture.frame = CGRectMake(55, 43, 22, 22);
    self.destructLabel.frame = CGRectMake(0, CGRectGetMaxY(self.destructPicture.frame)+8, self.destructBackgroundView.frame.size.width, 14);
    CGRect durationLabelFrame = CGRectMake(0, self.destructBackgroundView.bounds.size.height - 20, self.destructBackgroundView.bounds.size.width - 8, 14);
    self.destructDurationLabel.frame = durationLabelFrame;
    if (self.model.messageDirection == MessageDirection_SEND) {
        self.destructDurationLabel.textColor = RCDYCOLOR(0x111f2c, 0x040a0f);
        self.destructLabel.textColor = RCDYCOLOR(0x111f2c, 0x040a0f);
        self.destructPicture.image = RCResourceImage(@"burn_video_picture");
    }else{
        self.destructDurationLabel.textColor = [RCKitUtility generateDynamicColor:HEXCOLOR(0x111f2c) darkColor:RCMASKCOLOR(0xffffff, 0.8)];
        self.destructLabel.textColor = [RCKitUtility generateDynamicColor:HEXCOLOR(0x111f2c) darkColor:RCMASKCOLOR(0xffffff, 0.8)];
        self.destructPicture.image = RCResourceImage(@"from_burn_video_picture");
    }
}

#pragma mark - Private Methods
+ (CGSize)getSightImageSize:(RCMessageModel *)model{
    RCSightMessage *sightMessage = (RCSightMessage *)model.content;

    CGSize imageSize = sightMessage.thumbnailImage.size;
    //兼容240
    CGFloat rate = imageSize.width / imageSize.height;
    CGFloat imageWidth = 0;
    CGFloat imageHeight = 0;

    if (imageSize.width != 0 && imageSize.height != 0) {
        if (rate > 1.0f) {
            imageWidth = 160;
            imageHeight = 160 / rate;
        } else {
            imageHeight = 160;
            imageWidth = 160 * rate;
        }
    } else {
        imageWidth = imageSize.width;
        imageHeight = imageSize.height;
    }
    return CGSizeMake(imageWidth, imageHeight);
}

- (void)initialize {
    [self.messageContentView addSubview:self.thumbnailView];
    [self.messageContentView addSubview:self.destructBackgroundView];

    [self.destructBackgroundView addSubview:self.destructPicture];
    [self.destructBackgroundView addSubview:self.destructLabel];
    [self.destructBackgroundView addSubview:self.destructDurationLabel];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateDownloadMediaStatus:)
                                                 name:RCKitDispatchDownloadMediaNotification
                                               object:nil];
}

- (NSString *)getSightDurationLabelText:(long)duration{
    NSInteger minutes = duration / 60;
    NSInteger seconds = round(duration - minutes * 60);
    if (seconds == 60) {
        minutes += 1;
        seconds = 0;
    }
    return [NSString stringWithFormat:@"%02ld:%02ld", (long)minutes, (long)seconds];
}

- (void)updateDownloadMediaStatus:(NSNotification *)notify {
    NSDictionary *statusDic = notify.userInfo;
    if (self.model.messageId == [statusDic[@"messageId"] longValue]) {
        if ([statusDic[@"type"] isEqualToString:@"progress"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([self.progressView isHidden]) {
                    [self.progressView setHidden:NO];
                    [self.progressView startIndeterminateAnimation];
                }
                [self.progressView setProgress:[statusDic[@"progress"] intValue] animated:YES];
            });
        } else if ([statusDic[@"type"] isEqualToString:@"success"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.progressView stopIndeterminateAnimation];
                [self.progressView setHidden:YES];
                RCSightMessage *sightContent = (RCSightMessage *)self.model.content;
                [sightContent setValue:statusDic[@"mediaPath"] forKey:@"localPath"];
            });
        } else if ([statusDic[@"type"] isEqualToString:@"error"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (![self.progressView isHidden]) {
                    [self.progressView stopIndeterminateAnimation];
                    [self.progressView setHidden:YES];
                }

                UIViewController *rootVC = [RCKitUtility getKeyWindow].rootViewController;
                UIAlertController *alertController = [UIAlertController
                    alertControllerWithTitle:nil
                                     message:RCLocalizedString(@"FileDownloadFailed")
                              preferredStyle:UIAlertControllerStyleAlert];
                [alertController
                    addAction:[UIAlertAction actionWithTitle:RCLocalizedString(@"OK")
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *_Nonnull action){
                                                     }]];
                [rootVC presentViewController:alertController animated:YES completion:nil];
            });
        }
    }
}

- (void)messageCellUpdateSendingStatusEvent:(NSNotification *)notification {
    [super messageCellUpdateSendingStatusEvent:notification];
    RCMessageCellNotificationModel *notifyModel = notification.object;
    NSInteger progress = notifyModel.progress;
    if (self.model.messageId == notifyModel.messageId) {
        DebugLog(@"messageCellUpdateSendingStatusEvent >%@ ", notifyModel.actionName);
        if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_BEGIN]) {
            [self.progressView startIndeterminateAnimation];
            [self.progressView setHidden:NO];
        } else if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_FAILED]) {
            if (self.model.sentStatus == SentStatus_SENDING) {
                [self.progressView startIndeterminateAnimation];
                [self.progressView setHidden:NO];
            } else {
                [self.playButtonView setHidden:NO];
                [self.progressView stopIndeterminateAnimation];
                [self.progressView setHidden:YES];
            }
        } else if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_SUCCESS]) {
            if (self.model.sentStatus != SentStatus_READ) {
                [self.playButtonView setHidden:NO];
                [self.progressView stopIndeterminateAnimation];
                [self.progressView setHidden:YES];
            }
        } else if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_PROGRESS]) {
            float pro = progress / 100.0f;
            [self.progressView setProgress:pro animated:YES];
        } else if (self.model.sentStatus == SentStatus_READ && self.isDisplayReadStatus) {
            [self.progressView stopIndeterminateAnimation];
            [self.progressView setHidden:YES];
        }
    }
}

#pragma mark - Getters and Setters

- (UILabel *)durationLabel {
    if (!_durationLabel) {
        _durationLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 120, 21)];
        [_durationLabel setTextAlignment:NSTextAlignmentRight];
        [_durationLabel setBackgroundColor:[UIColor clearColor]];
        [_durationLabel setTextColor:[UIColor whiteColor]];
        [_durationLabel setFont:[[RCKitConfig defaultConfig].font fontOfAnnotationLevel]];
    }
    return _durationLabel;
}

- (UIImageView *)playImage {
    if (!_playImage) {
        _playImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 41, 41)];
        UIImage *image = RCResourceImage(@"sight_message_icon");
        _playImage.image = image;
    }
    return _playImage;
}

- (UIView *)playButtonView {
    if (!_playButtonView) {
        _playButtonView = [[UIView alloc] initWithFrame:self.thumbnailView.bounds];
        [_playButtonView addSubview:self.playImage];
        [self.thumbnailView addSubview:_playButtonView];
        UIImageView *backgroudView =
            [[UIImageView alloc] initWithFrame:CGRectMake(0, self.thumbnailView.bounds.size.height - 21,
                                                          self.thumbnailView.bounds.size.width, 21)];
        backgroudView.image = RCResourceImage(@"player_shadow_bottom");
        [_playButtonView addSubview:backgroudView];
        [backgroudView addSubview:self.durationLabel];
    }
    return _playButtonView;
}

- (UIImageView *)thumbnailView{
    if (!_thumbnailView) {
        _thumbnailView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _thumbnailView.layer.masksToBounds = YES;
        _thumbnailView.layer.cornerRadius = 6;
    }
    return _thumbnailView;
}

- (UIImageView *)destructBackgroundView{
    if (!_destructBackgroundView) {
        _destructBackgroundView = [[UIImageView alloc] initWithFrame:CGRectZero];
    }
    return _destructBackgroundView;
}

- (UIImageView *)destructPicture{
    if (!_destructPicture) {
        _destructPicture = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 31, 26)];
    }
    return _destructPicture;
}

- (UILabel *)destructLabel{
    if (!_destructLabel) {
        _destructLabel = [[UILabel alloc] init];
        _destructLabel.text = RCLocalizedString(@"ClickToPlay");
        _destructLabel.font = [[RCKitConfig defaultConfig].font fontOfAnnotationLevel];
        _destructLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _destructLabel;
}

- (UILabel *)destructDurationLabel{
    if (!_destructDurationLabel) {
        _destructDurationLabel = [[UILabel alloc] init];
        _destructDurationLabel.font = [[RCKitConfig defaultConfig].font fontOfAnnotationLevel];
        [_destructDurationLabel setTextAlignment:NSTextAlignmentRight];
        [_destructDurationLabel setBackgroundColor:[UIColor clearColor]];
    }
    return _destructDurationLabel;
}

@end
