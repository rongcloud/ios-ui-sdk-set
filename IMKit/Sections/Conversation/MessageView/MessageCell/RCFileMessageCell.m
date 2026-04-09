//
//  RCFileMessageCell.m
//  RongIMKit
//
//  Created by liulin on 16/7/21.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCFileMessageCell.h"
#import "RCKitCommonDefine.h"
#import "RCKitUtility.h"
#import "RCMessageCellTool.h"
#import "RCKitConfig.h"
#import "RCResendManager.h"
extern NSString *const RCKitDispatchDownloadMediaNotification;

#define FILE_CONTENT_HEIGHT 69.f

@interface RCFileMessageCell ()

@property (nonatomic, strong) NSMutableArray *messageContentConstraint;

@end

@implementation RCFileMessageCell

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
    CGFloat __messagecontentview_height = FILE_CONTENT_HEIGHT;

    if (__messagecontentview_height < RCKitConfigCenter.ui.globalMessagePortraitSize.height) {
        __messagecontentview_height = RCKitConfigCenter.ui.globalMessagePortraitSize.height;
    }
    __messagecontentview_height += extraHeight;
    return CGSizeMake(collectionViewWidth, __messagecontentview_height);
}

- (void)setDataModel:(RCMessageModel *)model {
    [super setDataModel:model];
    RCFileMessage *fileMessage = (RCFileMessage *)self.model.content;
    self.nameLabel.text = fileMessage.name;
    self.sizeLabel.text = [RCKitUtility getReadableStringForFileSize:fileMessage.size];
    self.typeIconView.image = [RCKitUtility imageWithFileSuffix:fileMessage.type];
    [self setAutoLayout];
}

- (void)updateStatusContentView:(RCMessageModel *)model {
    if (self.model.sentStatus == SentStatus_SENDING) {
        self.messageFailedStatusView.hidden = YES;
        self.progressView.hidden = NO;
        self.cancelSendButton.hidden = NO;
        self.messageActivityIndicatorView.hidden = YES;
    } else {
        [super updateStatusContentView:model];
    }
}

#pragma mark - Target Action
- (void)cancelSend {
    if ([self.delegate respondsToSelector:@selector(didTapCancelUploadButton:)]) {
        [self.delegate didTapCancelUploadButton:self.model];
    }
}

- (void)updateDownloadMediaStatus:(NSNotification *)notify {
    NSDictionary *statusDic = notify.userInfo;
    if (self.model.messageId == [statusDic[@"messageId"] longValue]) {
        if ([statusDic[@"type"] isEqualToString:@"success"]) {
            RCFileMessage *fileMessage = (RCFileMessage *)self.model.content;
            fileMessage.localPath = statusDic[@"mediaPath"];
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
            self.cancelSendButton.hidden = YES;
            [self updateProgressView:progress];
        } else if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_FAILED]) {
            self.cancelSendButton.hidden = YES;
            [self updateProgressView:progress];
        } else if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_SUCCESS]) {
            if (self.model.sentStatus != SentStatus_READ) {
                [self updateProgressView:progress];
            }
            self.cancelSendButton.hidden = YES;
        } else if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_PROGRESS]) {
            [self updateProgressView:progress];
        } else if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_CANCELED]) {
            self.cancelSendButton.hidden = YES;
            self.progressView.hidden = YES;
            [self displayCancelLabel];
        } else if (self.model.sentStatus == SentStatus_READ && self.isDisplayReadStatus) {
            self.progressView.hidden = YES;
            self.progressView.progress = 0;
        }
    }
}

#pragma mark - Private Methods

- (void)initialize {
    self.messageContentConstraint = [[NSMutableArray alloc] init];

    [self showBubbleBackgroundView:YES];
    [self.messageContentView addSubview:self.nameLabel];
    [self.messageContentView addSubview:self.sizeLabel];
    [self.messageContentView addSubview:self.typeIconView];
    [self.typeIconView addSubview:self.progressView];
    [self.messageContentView addSubview:self.cancelLabel];

    [self updateBubbleBackgroundViewConstraints];
    self.messageActivityIndicatorView.hidden = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateDownloadMediaStatus:)
                                                 name:RCKitDispatchDownloadMediaNotification
                                               object:nil];
}

- (void)setAutoLayout {
    self.cancelSendButton.hidden = YES;
    self.cancelLabel.hidden = YES;
    self.messageContentView.contentSize = CGSizeMake([RCMessageCellTool getMessageContentViewMaxWidth], FILE_CONTENT_HEIGHT);
    if (MessageDirection_RECEIVE == self.messageDirection) {
        self.progressView.hidden = YES;
    } else {
        self.progressView.hidden = YES;
        if (self.model.sentStatus == SentStatus_CANCELED) {
            [self displayCancelLabel];
        }else if (self.model.sentStatus == SentStatus_SENDING) {
            self.progressView.hidden = NO;
            [self updateProgressView:self.progressView.progress];
        }else if (self.model.sentStatus == SentStatus_SENT || self.model.sentStatus == SentStatus_RECEIVED) {
            self.progressView.hidden = YES;
            self.messageActivityIndicatorView.hidden = YES;
        } else if (self.model.sentStatus == SentStatus_FAILED) {
            self.cancelSendButton.hidden = YES;
            if ([[RCResendManager sharedManager] needResend:self.model.messageId]) {
                self.messageActivityIndicatorView.hidden = NO;
                [self.messageActivityIndicatorView startAnimating];
                self.progressView.hidden = NO;
            } else {
                self.progressView.hidden = YES;
                self.messageActivityIndicatorView.hidden = YES;
            }
        }
    }
}

- (void)updateProgressView:(NSUInteger)progress {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ((self.model.sentStatus == SentStatus_SENDING && progress != 100) || [[RCResendManager sharedManager] needResend:self.model.messageId]) {
            self.progressView.hidden = NO;
            self.progressView.progress = (float)progress / 100.f;
            // 发送失败时 progress = 0，此时显示菊花，当 progress > 0 时显示取消按钮
            if ([[RCResendManager sharedManager] needResend:self.model.messageId] && progress == 0) {
                self.cancelSendButton.hidden = YES;
                self.messageActivityIndicatorView.hidden = NO;
                [self.messageActivityIndicatorView startAnimating];
            } else {
                self.cancelSendButton.hidden = NO;
                self.messageActivityIndicatorView.hidden = YES;
            }
        } else {
            self.progressView.hidden = YES;
        }
    });
}

- (void)updateBubbleBackgroundViewConstraints{
    self.nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.sizeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.typeIconView.translatesAutoresizingMaskIntoConstraints = NO;
    self.cancelSendButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.cancelLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self displayCancelButton];
    
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_nameLabel, _sizeLabel, _typeIconView);
    [self.messageContentView
     addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[_typeIconView(48)]"
                                                            options:0
                                                            metrics:nil
                                                              views:views]];
    [self.messageContentView
     addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-12-[_typeIconView(48)]-10-[_nameLabel]-12-|"
                                                            options:0
                                                            metrics:nil
                                                              views:views]];
    [self.messageContentView
     
     addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[_typeIconView(48)]"
                                                            options:0
                                                            metrics:nil
                                                              views:views]];
 
    [self.messageContentView
     
     addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-12-[_typeIconView(48)]-10-[_nameLabel]-12-|"
                                                            options:0
                                                            metrics:nil
                                                              views:views]];
    [self.messageContentView
     addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[_nameLabel]-(>=0)-[_sizeLabel(13)]-10-|"
                                                            options:0
                                                            metrics:nil
                                                              views:views]];
    [self.messageContentView
     addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_typeIconView]-12-[_sizeLabel]"
                                                            options:0
                                                            metrics:nil
                                                              views:views]];
}

- (void)displayCancelLabel {
    [self.messageContentView addSubview:self.cancelLabel];
    [self.messageContentConstraint
        addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_cancelLabel]-16.5-|"
                                                                    options:0
                                                                    metrics:nil
                                                                      views:NSDictionaryOfVariableBindings(
                                                                                _nameLabel, _sizeLabel, _typeIconView, _cancelLabel)]];
    [self.messageContentView addConstraint:[NSLayoutConstraint constraintWithItem:_cancelLabel
                                                                          attribute:NSLayoutAttributeCenterY
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:self.sizeLabel
                                                                          attribute:NSLayoutAttributeCenterY
                                                                         multiplier:1
                                                                           constant:0]];
    [self.messageContentView addConstraints:self.messageContentConstraint];
    self.cancelLabel.hidden = NO;
}

- (void)displayCancelButton {
    dispatch_async(dispatch_get_main_queue(), ^{
        if([RCKitUtility isRTL]){
            self.baseContentView.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
        }else{
            self.baseContentView.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
        }
        [self.baseContentView addSubview:self.cancelSendButton];
        RCContentView *messageContentView = self.messageContentView;
        [self.baseContentView
            addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"V:[_cancelSendButton(20)]"
                                                   options:0
                                                   metrics:nil
                                                     views:NSDictionaryOfVariableBindings(_cancelSendButton)]];

        [self.baseContentView
            addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"H:[_cancelSendButton(20)]-13-[messageContentView]"
                                                   options:0
                                                   metrics:nil
                                                     views:NSDictionaryOfVariableBindings(messageContentView,
                                                                                          _cancelSendButton)]];

        [self.baseContentView addConstraint:[NSLayoutConstraint constraintWithItem:_cancelSendButton
                                                                         attribute:NSLayoutAttributeCenterY
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.messageContentView
                                                                         attribute:NSLayoutAttributeCenterY
                                                                        multiplier:1
                                                                          constant:0]];

    });
}

#pragma mark - Getter
- (UILabel *)nameLabel{
    if(!_nameLabel){
        _nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        [_nameLabel setFont:[[RCKitConfig defaultConfig].font fontOfGuideLevel]];
        _nameLabel.numberOfLines = 2;
        _nameLabel.textColor = RCDynamicColor(@"text_primary_color", @"0x111f2c", @"0xffffffcc");
        _nameLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        if([RCKitUtility isRTL]){
            _nameLabel.textAlignment = NSTextAlignmentRight;
        }else{
            _nameLabel.textAlignment = NSTextAlignmentLeft;
        }
    }
    return _nameLabel;
}

- (UILabel *)sizeLabel{
    if (!_sizeLabel) {
        _sizeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        [_sizeLabel setFont:[[RCKitConfig defaultConfig].font fontOfAnnotationLevel]];
        _sizeLabel.textColor = RCDynamicColor(@"text_secondary_color", @"0xc7cbce", @"0xffffff66");
    }
    return _sizeLabel;
}

- (RCBaseImageView *)typeIconView{
    if (!_typeIconView) {
        _typeIconView = [[RCBaseImageView alloc] initWithFrame:CGRectMake(0, 0, 48, 48)];
        _typeIconView.clipsToBounds = YES;
    }
    return _typeIconView;
}

- (RCProgressView *)progressView{
    if (!_progressView) {
        _progressView = [[RCProgressView alloc] initWithFrame:CGRectMake(-10, -10, self.typeIconView.frame.size.width+20, self.typeIconView.frame.size.height+20)];
        [_progressView setHidden:YES];
    }
    return _progressView;
}

- (RCBaseButton *)cancelSendButton{
    if (!_cancelSendButton) {
        _cancelSendButton = [[RCBaseButton alloc] initWithFrame:CGRectZero];
        [_cancelSendButton setImage:RCDynamicImage(@"conversation_msg_cell_cancel_img",@"cancelButton") forState:UIControlStateNormal];
        [_cancelSendButton addTarget:self action:@selector(cancelSend) forControlEvents:UIControlEventTouchUpInside];
        _cancelSendButton.hidden = YES;
    }
    return _cancelSendButton;
}

- (UILabel *)cancelLabel{
    if (!_cancelLabel) {
        _cancelLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _cancelLabel.text = RCLocalizedString(@"CancelSendFile");
        _cancelLabel.textColor = RCDynamicColor(@"text_secondary_color", @"0xa8a8a8", @"0xa8a8a8");
        _cancelLabel.font = [[RCKitConfig defaultConfig].font fontOfAnnotationLevel];
        _cancelLabel.hidden = YES;
    }
    return _cancelLabel;
}
@end
