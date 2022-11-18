//
//  RCGIFMessageCell.m
//  RongIMKit
//
//  Created by liyan on 2018/12/20.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import "RCGIFMessageCell.h"
#import "RCIM.h"
#import "RCKitUtility.h"
#import "RCGIFImage.h"
#import "RCKitCommonDefine.h"
#import "RCGIFMessageProgressView.h"
#import "RCGIFUtility.h"
#import "RCMessageCellTool.h"
#import "RCKitConfig.h"
#import "RCResendManager.h"
#define GIFLOADIMAGEWIDTH 36.0f
#define GIFLABLEWIGHT 40.0f
#define GIFLABLEHEIGHT 10.0f

extern NSString *const RCKitDispatchDownloadMediaNotification;

@interface RCGIFMessageCell ()

@property (nonatomic, strong) RCMessageModel *currentModel;

@property (nonatomic, strong) RCGIFMessageProgressView *gifDownLoadPropressView;

@property (nonatomic, strong) UIButton *loadBackButton;

@property (nonatomic, strong) UIImageView *needLoadImageView;

@property (nonatomic, strong) UIImageView *loadingImageView;

@property (nonatomic, strong) UIImageView *loadfailedImageView;

@property (nonatomic, strong) UILabel *sizeLabel;

@property (nonatomic, strong) UIImageView *destructPicture;

@property (nonatomic, strong) UILabel *destructLabel;

@property (nonatomic, strong) UIImageView *destructBackgroundView;

@end

@implementation RCGIFMessageCell
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

#pragma mark - Super Methods

+ (CGSize)sizeForMessageModel:(RCMessageModel *)model
      withCollectionViewWidth:(CGFloat)collectionViewWidth
         referenceExtraHeight:(CGFloat)extraHeight {
    CGFloat __messagecontentview_height = 0.0f;
    CGSize size = [RCGIFUtility calculatecollectionViewHeight:model];
    if (model.content.destructDuration > 0) {
        __messagecontentview_height = DestructBackGroundHeight;
    } else {
        __messagecontentview_height = size.height;
    }
    if (__messagecontentview_height < RCKitConfigCenter.ui.globalMessagePortraitSize.height) {
        __messagecontentview_height = RCKitConfigCenter.ui.globalMessagePortraitSize.height;
    }
    __messagecontentview_height += extraHeight;
    return CGSizeMake(collectionViewWidth, __messagecontentview_height);
}

- (void)setDataModel:(RCMessageModel *)model {
    [self resetSubViews];
    if (!model) {
        return;
    }
    [super setDataModel:model];
    self.currentModel = model;
    __block RCGIFMessage *gifMessage = (RCGIFMessage *)model.content;
    [self calculateContenViewSize:gifMessage];
    self.destructBackgroundView.hidden = YES;
    if (gifMessage.destructDuration > 0) {
        self.messageContentView.contentSize = CGSizeMake(DestructBackGroundWidth, DestructBackGroundHeight);
        self.destructBackgroundView.image = [RCMessageCellTool getDefaultMessageCellBackgroundImage:self.model];
        self.destructBackgroundView.frame = CGRectMake(0, 0, DestructBackGroundWidth, DestructBackGroundHeight);
        self.destructPicture.frame = CGRectMake(50, 43, 31, 25);
        self.destructLabel.frame = CGRectMake(0,CGRectGetMaxY(self.destructPicture.frame)+4, self.destructBackgroundView.frame.size.width, 17);
        if (self.model.messageDirection == MessageDirection_SEND) {
            [self.destructLabel setTextColor:RCDYCOLOR(0x111f2c, 0x040a0f)];
            self.destructPicture.image = RCResourceImage(@"burnPicture");
        }else{
            [self.destructLabel setTextColor:[RCKitUtility generateDynamicColor:HEXCOLOR(0x111f2c) darkColor:RCMASKCOLOR(0xffffff, 0.8)]];
            self.destructPicture.image = RCResourceImage(@"from_burn_picture");
        }
    }

    //需要根据用户设置的大小去决定是否自动下载
    NSInteger maxAutoSize = RCKitConfigCenter.message.GIFMsgAutoDownloadSize;
    NSString *localPath = gifMessage.localPath;
    if (localPath && [RCFileUtility isFileExist:localPath]) {
        [self showGifImageView:localPath];
    } else {
        if (gifMessage.remoteUrl.length > 0 && gifMessage.gifDataSize > maxAutoSize * 1024) {
            if (self.model.content.destructDuration > 0) {
                self.gifImageView.hidden = YES;
                self.destructBackgroundView.hidden = NO;
            }else{
                //超过限制，需要点击下载
                [self showView:self.needLoadImageView];
            }
        } else {
            self.messageContentView.userInteractionEnabled = NO;
            //没超过限制，自动下载
            [self downLoadGif];
        }
    }

    [self updateStatusContentView:self.model];
    if (model.sentStatus == SentStatus_SENDING || [[RCResendManager sharedManager] needResend:self.model.messageId]) {
        [self showProgressView];
    } else {
        [self hiddenProgressView];
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

#pragma mark - Private Methods

- (void)initialize {
    [self.messageContentView addSubview:self.gifImageView];
    [self.messageContentView addSubview:self.loadBackButton];
    [self.messageContentView addSubview:self.destructBackgroundView];
    
    [self.destructBackgroundView addSubview:self.destructPicture];
    [self.destructBackgroundView addSubview:self.destructLabel];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(networkChanged:)
                                                 name:@"kRCNetworkReachabilityChangedNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateDownloadMediaStatus:)
                                                 name:RCKitDispatchDownloadMediaNotification
                                               object:nil];

}

- (void)prepareForReuse {
    [super prepareForReuse];
}

- (void)calculateContenViewSize:(RCGIFMessage *)gifMessage {
    CGSize gifSize = [RCGIFUtility calculatecollectionViewHeight:self.currentModel];
    self.messageContentView.contentSize = CGSizeMake(gifSize.width, gifSize.height);
    self.gifImageView.frame = CGRectMake(0, 0, gifSize.width, gifSize.height);
    self.progressView.frame = self.gifImageView.bounds;
    self.loadBackButton.frame = self.gifImageView.frame;
}

- (void)didClickLoadBackButton:(UIButton *)button {
    if (!self.needLoadImageView.hidden) {
        [self downLoadGif];
        return;
    } else if (!self.loadfailedImageView.hidden) {
        [self downLoadGif];
        return;
    }
}

- (void)downLoadGif {
    [self showView:self.loadingImageView];
    __weak typeof(self) weakSelf = self;
    [[RCIM sharedRCIM] downloadMediaMessage:weakSelf.currentModel.messageId
        progress:^(int progress) {
        }
        success:^(NSString *mediaPath) {
        }
        error:^(RCErrorCode errorCode) {
        }
        cancel:^{

        }];
}

- (void)showGifImageView:(NSString *)localPath {
    self.messageContentView.userInteractionEnabled = YES;
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *data = [NSData dataWithContentsOfFile:[RCUtilities getCorrectedFilePath:localPath]];
        RCGIFImage *gifImage = [RCGIFImage animatedImageWithGIFData:data];
        dispatch_main_async_safe(^{
            if (gifImage) {
                if (self.model.content.destructDuration > 0) {
                    weakSelf.gifImageView.hidden = YES;
                    weakSelf.destructBackgroundView.hidden = NO;
                } else {
                    weakSelf.destructBackgroundView.hidden = YES;
                    weakSelf.gifImageView.hidden = NO;
                    weakSelf.loadBackButton.hidden = YES;
                    weakSelf.loadingImageView.hidden = YES;
                    weakSelf.gifImageView.animatedImage = gifImage;
                }
            } else {
                DebugLog(@"[RongIMKit]: RCMessageModel.content is NOT RCGIFMessage object");
            }
        });
    });
}

- (void)messageCellUpdateSendingStatusEvent:(NSNotification *)notification {
    [super messageCellUpdateSendingStatusEvent:notification];
    RCMessageCellNotificationModel *notifyModel = notification.object;
    NSInteger progress = notifyModel.progress;
    if (self.model.messageId == notifyModel.messageId) {
        DebugLog(@"messageCellUpdateSendingStatusEvent >%@ ", notifyModel.actionName);
        if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_BEGIN]) {
            [self showProgressView];
        } else if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_FAILED]) {
            if (self.model.sentStatus == SentStatus_SENDING) {
                [self showProgressView];
            } else {
                [self hiddenProgressView];
            }
        } else if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_SUCCESS]) {
            if (self.model.sentStatus != SentStatus_READ) {
                [self hiddenProgressView];
            }
        } else if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_PROGRESS]) {
            [self showProgressView];
            [self.progressView updateProgress:progress];
        } else if (self.model.sentStatus == SentStatus_READ && self.isDisplayReadStatus) {
            [self hiddenProgressView];
        }
    }
}

- (void)showView:(UIView *)showView {
    showView.center = self.loadBackButton.center;
    if (self.loadBackButton.hidden) {
        self.loadBackButton.hidden = NO;
    }
    self.sizeLabel.center =
        CGPointMake(self.loadBackButton.center.x, self.loadBackButton.center.y + 10 + GIFLOADIMAGEWIDTH / 2);
    RCGIFMessage *gifMessage = (RCGIFMessage *)self.model.content;

    NSString *size = [self getGIFSize:gifMessage.gifDataSize];
    if (size.length > 0) {
        self.sizeLabel.hidden = NO;
        self.sizeLabel.text = size;
    }
    switch (showView.tag) {
    case 1:
        self.needLoadImageView.hidden = NO;
        self.loadingImageView.hidden = YES;
        self.gifDownLoadPropressView.hidden = YES;
        self.messageContentView.userInteractionEnabled = YES;
        self.loadfailedImageView.hidden = YES;
        [self stopAnimation];

        break;
    case 2:
        self.needLoadImageView.hidden = YES;
        self.loadingImageView.hidden = NO;
        self.gifDownLoadPropressView.hidden = YES;
        self.loadfailedImageView.hidden = YES;
        [self startAnimation];
        break;
    case 3:
        self.needLoadImageView.hidden = YES;
        self.loadingImageView.hidden = YES;
        self.gifDownLoadPropressView.hidden = NO;
        self.loadfailedImageView.hidden = YES;
        [self stopAnimation];

        break;
    case 4:
        self.needLoadImageView.hidden = YES;
        self.loadingImageView.hidden = YES;
        self.gifDownLoadPropressView.hidden = YES;
        self.loadfailedImageView.hidden = NO;
        self.messageContentView.userInteractionEnabled = YES;
        [self stopAnimation];

        break;
    default:
        self.needLoadImageView.hidden = YES;
        self.loadingImageView.hidden = YES;
        self.gifDownLoadPropressView.hidden = YES;
        self.loadfailedImageView.hidden = YES;
        self.loadBackButton.hidden = YES;
        self.sizeLabel.hidden = YES;
        self.gifImageView.animatedImage = nil;
        break;
    }
}

- (NSString *)getGIFSize:(CGFloat)size {
    NSString *GIFSize = nil;
    if (size / 1024 / 1024 < 1) {
        GIFSize = [NSString stringWithFormat:@"%dK", (int)size / 1024];
    } else {
        GIFSize = [NSString stringWithFormat:@"%0.2fM", size / 1024 / 1024];
    }

    return GIFSize;
}

- (void)startAnimation {
    CABasicAnimation *rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat:M_PI * 2.0];
    rotationAnimation.duration = 1.5;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = MAXFLOAT;
    [self.loadingImageView.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
}

- (void)stopAnimation {
    if (self.loadfailedImageView) {
        [self.loadingImageView.layer removeAnimationForKey:@"rotationAnimation"];
    }
}

- (void)resetSubViews {
    self.gifImageView.animatedImage = nil;
    [self.gifDownLoadPropressView setProgress:0];
    self.loadBackButton.hidden = YES;
    self.needLoadImageView.hidden = YES;
    self.loadingImageView.hidden = YES;
    self.gifDownLoadPropressView.hidden = YES;
    self.loadfailedImageView.hidden = YES;
    self.sizeLabel.text = nil;
    self.sizeLabel.hidden = YES;
}

- (void)networkChanged:(NSNotification *)note {
    RCNetworkStatus status = [[RCIMClient sharedRCIMClient] getCurrentNetworkStatus];
    if (status != RC_NotReachable && ( !self.loadingImageView.hidden || !self.gifDownLoadPropressView.hidden)) {
        [[RCIMClient sharedRCIMClient] cancelDownloadMediaMessage:self.currentModel.messageId];
        [self downLoadGif];
    }
}

- (void)showProgressView{
    if (self.progressView.hidden) {
        self.progressView.hidden = NO;
        [self.progressView startAnimating];
    }
}

- (void)hiddenProgressView{
    if (!self.progressView.hidden) {
        self.progressView.hidden = YES;
        [self.progressView stopAnimating];
    }
}

#pragma mark - NSNotification
- (void)updateDownloadMediaStatus:(NSNotification *)notify {
    NSDictionary *statusDic = notify.userInfo;
    if (self.model.messageId == [statusDic[@"messageId"] longValue]) {
        if ([statusDic[@"type"] isEqualToString:@"progress"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                CGFloat progress = (CGFloat)[statusDic[@"progress"] intValue];
                if (self.gifDownLoadPropressView.hidden) {
                    [self showView:self.gifDownLoadPropressView];
                }
                [self.gifDownLoadPropressView setProgress:progress];
            });
        } else if ([statusDic[@"type"] isEqualToString:@"success"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                RCGIFMessage *gifContent = (RCGIFMessage *)self.model.content;
                gifContent.localPath = statusDic[@"mediaPath"];
                
                [self showView:self.gifImageView];
                [self showGifImageView:statusDic[@"mediaPath"]];

            });
        } else if ([statusDic[@"type"] isEqualToString:@"error"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showView:self.loadfailedImageView];
            });
        }
    }
}

#pragma mark - Getters and Setters

- (RCGIFImageView *)gifImageView {
    if (!_gifImageView) {
        _gifImageView = [[RCGIFImageView alloc] initWithFrame:CGRectZero];
        _gifImageView.layer.masksToBounds = YES;
        [_gifImageView setContentMode:UIViewContentModeScaleAspectFill];
        _gifImageView.tag = 5;
    }
    return _gifImageView;
}

- (RCImageMessageProgressView *)progressView {
    if (!_progressView) {
        _progressView = [[RCImageMessageProgressView alloc] init];
        [self.gifImageView addSubview:_progressView];
        _progressView.hidden = YES;
    }
    return _progressView;
}

- (UIButton *)loadBackButton {
    if (!_loadBackButton) {
        _loadBackButton = [[UIButton alloc] initWithFrame:CGRectZero];
        _loadBackButton.backgroundColor = RGBCOLOR(216, 216, 216);
        [_loadBackButton addTarget:self
                            action:@selector(didClickLoadBackButton:)
                  forControlEvents:(UIControlEventTouchUpInside)];
        _loadBackButton.hidden = YES;
    }
    return _loadBackButton;
}

- (UIImageView *)needLoadImageView {
    if (!_needLoadImageView) {
        _needLoadImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, GIFLOADIMAGEWIDTH, GIFLOADIMAGEWIDTH)];
        _needLoadImageView.image = RCResourceImage(@"gif_needload");
        _needLoadImageView.hidden = YES;
        _needLoadImageView.tag = 1;
        [self.loadBackButton addSubview:_needLoadImageView];
    }
    return _needLoadImageView;
}

- (UIImageView *)loadingImageView {
    if (!_loadingImageView) {
        _loadingImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, GIFLOADIMAGEWIDTH, GIFLOADIMAGEWIDTH)];
        _loadingImageView.image = RCResourceImage(@"gif_loading");
        _loadingImageView.hidden = YES;
        _loadingImageView.tag = 2;
        [self.loadBackButton addSubview:_loadingImageView];
    }
    return _loadingImageView;
}

- (RCGIFMessageProgressView *)gifDownLoadPropressView {
    if (!_gifDownLoadPropressView) {
        _gifDownLoadPropressView = [[RCGIFMessageProgressView alloc] initWithFrame:CGRectMake(0, 0, 36, 36)];
        _gifDownLoadPropressView.backgroundColor = [UIColor colorWithPatternImage:RCResourceImage(@"gif_loadprogress")];
        _gifDownLoadPropressView.tag = 3;
        _gifDownLoadPropressView.hidden = YES;
        [self.loadBackButton addSubview:_gifDownLoadPropressView];
    }
    return _gifDownLoadPropressView;
}

- (UIImageView *)loadfailedImageView {
    if (!_loadfailedImageView) {
        _loadfailedImageView =
            [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, GIFLOADIMAGEWIDTH, GIFLOADIMAGEWIDTH)];
        _loadfailedImageView.image = RCResourceImage(@"gif_loadfailed");
        _loadfailedImageView.hidden = YES;
        _loadfailedImageView.tag = 4;
        [self.loadBackButton addSubview:_loadfailedImageView];
    }
    return _loadfailedImageView;
}

- (UILabel *)sizeLabel {
    if (!_sizeLabel) {
        _sizeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, GIFLABLEWIGHT, GIFLABLEHEIGHT)];
        _sizeLabel.font = [[RCKitConfig defaultConfig].font fontOfAssistantLevel];
        _sizeLabel.numberOfLines = 1;
        _sizeLabel.textAlignment = NSTextAlignmentCenter;
        _sizeLabel.backgroundColor = [UIColor clearColor];
        _sizeLabel.textColor = [UIColor whiteColor];
        _sizeLabel.hidden = YES;
        [self.loadBackButton addSubview:_sizeLabel];
    }
    return _sizeLabel;
}

- (UIImageView *)destructBackgroundView{
    if (!_destructBackgroundView) {
        _destructBackgroundView = [[UIImageView alloc] initWithFrame:CGRectZero];
    }
    return _destructBackgroundView;
}

- (UILabel *)destructLabel{
    if (!_destructLabel) {
        _destructLabel = [[UILabel alloc] init];
        _destructLabel.text = RCLocalizedString(@"ClickToView");
        _destructLabel.font = [[RCKitConfig defaultConfig].font fontOfAnnotationLevel];
        _destructLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _destructLabel;
}

- (UIImageView *)destructPicture{
    if (!_destructPicture) {
        _destructPicture = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 31, 26)];
    }
    return _destructPicture;
}
@end
