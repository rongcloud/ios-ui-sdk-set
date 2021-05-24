//
//  RCMessageBaseCell.m
//  RongIMKit
//
//  Created by xugang on 15/1/28.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCMessageBaseCell.h"
#import "RCKitCommonDefine.h"
#import "RCKitUtility.h"
#import "RCMessageSelectionUtility.h"
#import "RCIM.h"
#import "RCAlertView.h"
#import "RCKitConfig.h"
NSString *const KNotificationMessageBaseCellUpdateSendingStatus = @"KNotificationMessageBaseCellUpdateSendingStatus";
#define SelectButtonSize CGSizeMake(20, 20)
#define SelectButtonSpaceLeft 8 //选择按钮据屏幕左侧 5

@interface RCMessageBaseCell ()

@property (nonatomic, strong) UITapGestureRecognizer *multiSelectTap;
@property (nonatomic, strong) UIButton *selectButton;

@end

@implementation RCMessageBaseCell

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupMessageBaseCellView];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupMessageBaseCellView];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Public Methods

+ (CGSize)sizeForMessageModel:(RCMessageModel *)model
      withCollectionViewWidth:(CGFloat)collectionViewWidth
         referenceExtraHeight:(CGFloat)extraHeight {
    NSLog(@"Warning, you not implement sizeForMessageModel:withCollectionViewWidth:referenceExtraHeight: method for "
          @"you custom cell %@",
          NSStringFromClass(self));
    return CGSizeMake(0, 0);
}

- (void)setDataModel:(RCMessageModel *)model {
    self.model = model;
    self.messageDirection = model.messageDirection;
    _isDisplayMessageTime = model.isDisplayMessageTime;
    if (self.isDisplayMessageTime) {
        [self.messageTimeLabel setText:[RCKitUtility convertMessageTime:model.sentTime / 1000]
                   dataDetectorEnabled:NO];
    }

    [self setBaseAutoLayout];
    [self updateUIForMultiSelect];
}

#pragma mark - Private Methods

- (void)setupMessageBaseCellView {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(messageCellUpdateSendingStatusEvent:)
                                                 name:KNotificationMessageBaseCellUpdateSendingStatus
                                               object:nil];
    self.model = nil;
    self.baseContentView = [[UIView alloc] initWithFrame:CGRectZero];
    self.isDisplayReadStatus = NO;
    [self.contentView addSubview:_baseContentView];
}

- (void)setBaseAutoLayout {
    if (self.isDisplayMessageTime) {
        CGSize timeTextSize_ = [RCKitUtility getTextDrawingSize:self.messageTimeLabel.text
                                                           font:[[RCKitConfig defaultConfig].font fontOfAnnotationLevel]
                                                constrainedSize:CGSizeMake(self.bounds.size.width, TIME_LABEL_HEIGHT)];
        timeTextSize_ = CGSizeMake(ceilf(timeTextSize_.width + 10), ceilf(timeTextSize_.height));

        self.messageTimeLabel.hidden = NO;
        [self.messageTimeLabel setFrame:CGRectMake((self.bounds.size.width - timeTextSize_.width) / 2, TIME_LABEL_TOP,
                                                   timeTextSize_.width, TIME_LABEL_HEIGHT)];
        [self.baseContentView setFrame:CGRectMake(0, CGRectGetMaxY(self.messageTimeLabel.frame)+TIME_LABEL_AND_BASE_CONTENT_VIEW_SPACE, self.bounds.size.width, self.bounds.size.height - CGRectGetMaxY(self.messageTimeLabel.frame)-TIME_LABEL_AND_BASE_CONTENT_VIEW_SPACE-BASE_CONTENT_VIEW_BOTTOM)];
    } else {
        if (self.messageTimeLabel) {
            self.messageTimeLabel.hidden = YES;
        }
        [self.baseContentView setFrame:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height - (BASE_CONTENT_VIEW_BOTTOM))];
    }
}

- (void)messageCellUpdateSendingStatusEvent:(NSNotification *)notification {
    DebugLog(@"%s", __FUNCTION__);
}

#pragma mark - Multi select
- (void)onChangedMessageMultiSelectStatus:(NSNotification *)notification {
    [self setDataModel:self.model];
}

- (void)updateUIForMultiSelect {
    [self.contentView removeGestureRecognizer:self.multiSelectTap];
    if ([RCMessageSelectionUtility sharedManager].multiSelect) {
        self.baseContentView.userInteractionEnabled = NO;
        if (self.allowsSelection) {
            self.selectButton.hidden = NO;
            [self.contentView addGestureRecognizer:self.multiSelectTap];
        }
    } else {
        self.baseContentView.userInteractionEnabled = YES;
        self.selectButton.hidden = YES;
        CGRect frame = self.baseContentView.frame;
        frame.origin.x = 0;
        self.baseContentView.frame = frame;
        return;
    }
    [self updateSelectButtonStatus];

    CGRect frame = self.baseContentView.frame;
    CGFloat selectButtonY = frame.origin.y +
                            (RCKitConfigCenter.ui.globalMessagePortraitSize.height - SelectButtonSize.height) /
                                2; //如果消息有头像，头像距离 baseContentView 顶部距离为 10
    if (MessageDirection_RECEIVE == self.model.messageDirection) {
        if (frame.origin.x < 3) { // cell不是左顶边的时候才会偏移
            if ([RCKitUtility isRTL]) {
                frame.origin.x = frame.origin.x - 12 - SelectButtonSpaceLeft;
            } else {
                frame.origin.x = SelectButtonSpaceLeft + 12;
            }
        }
        self.baseContentView.frame = frame;
    }
    CGRect selectButtonFrame = CGRectMake(SelectButtonSpaceLeft, selectButtonY, 20, 20);
    if ([RCKitUtility isRTL]) {
        if (MessageDirection_RECEIVE == self.model.messageDirection) {
            selectButtonFrame.origin.x = frame.origin.x + frame.size.width - SelectButtonSpaceLeft;
        } else {
            selectButtonFrame.origin.x = frame.origin.x + frame.size.width - SelectButtonSpaceLeft - SelectButtonSpaceLeft - 20;
        }
    }
    self.selectButton.frame = selectButtonFrame;
}

- (void)setAllowsSelection:(BOOL)allowsSelection {
    _allowsSelection = allowsSelection;
    if (self.model) {
        [self updateUIForMultiSelect];
    }
}

- (void)onSelectMessageEvent {
    if ([[RCMessageSelectionUtility sharedManager] isContainMessage:self.model]) {
        [[RCMessageSelectionUtility sharedManager] removeMessageModel:self.model];
        [self updateSelectButtonStatus];
    } else {
        if ([RCMessageSelectionUtility sharedManager].selectedMessages.count >= 100) {
            [RCAlertView showAlertController:nil message:RCLocalizedString(@"ChatTranscripts") cancelTitle:RCLocalizedString(@"OK")];
        } else {
            [[RCMessageSelectionUtility sharedManager] addMessageModel:self.model];
            [self updateSelectButtonStatus];
        }
    }
}

- (void)updateSelectButtonStatus {
    NSString *imgName = [[RCMessageSelectionUtility sharedManager] isContainMessage:self.model]
                            ? @"message_cell_select"
                            : @"message_cell_unselect";
    UIImage *image = RCResourceImage(imgName);
    [self.selectButton setImage:image forState:UIControlStateNormal];
}

#pragma mark - Getters and Setters

- (UIButton *)selectButton {
    if (!_selectButton) {
        _selectButton = [[UIButton alloc] initWithFrame:CGRectZero];
        [_selectButton setImage:RCResourceImage(@"message_cell_unselect") forState:UIControlStateNormal];
        [_selectButton addTarget:self
                          action:@selector(onSelectMessageEvent)
                forControlEvents:UIControlEventTouchUpInside];
        _selectButton.hidden = YES;
        [self.contentView addSubview:_selectButton];
        CGRect selectButtonFrame = CGRectMake(SelectButtonSpaceLeft, 0, 20, 20);
        _selectButton.frame = selectButtonFrame;
    }
    return _selectButton;
}

- (UITapGestureRecognizer *)multiSelectTap {
    if (!_multiSelectTap) {
        _multiSelectTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onSelectMessageEvent)];
        _multiSelectTap.numberOfTapsRequired = 1;
        _multiSelectTap.numberOfTouchesRequired = 1;
    }
    return _multiSelectTap;
}

//大量cell不显示时间，使用延时加载
- (RCTipLabel *)messageTimeLabel {
    if (!_messageTimeLabel) {
        _messageTimeLabel = [RCTipLabel greyTipLabel];
        _messageTimeLabel.backgroundColor = [UIColor clearColor];
        _messageTimeLabel.textColor = RCDYCOLOR(0xA0A5AB, 0x585858);
        _messageTimeLabel.font = [[RCKitConfig defaultConfig].font fontOfAnnotationLevel];
        [self.contentView addSubview:_messageTimeLabel];
    }
    return _messageTimeLabel;
}
@end
