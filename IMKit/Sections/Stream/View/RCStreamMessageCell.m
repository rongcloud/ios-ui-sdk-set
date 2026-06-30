//
//  RCStreamMessageCellCollectionViewCell.m
//  SealTalk
//
//  Created by zgh on 2025/2/20.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCStreamMessageCell.h"
#import "RCMessageModel+StreamCellVM.h"
#import "RCKitConfig.h"
#import "RCStreamMessageCellViewModel.h"
#import "RCStreamContentView.h"
#import "RCKitCommonDefine.h"
#import "RCMessageCellTool.h"
#import "RCStreamMarkdownContentViewModel.h"
#import "RCStreamTextContentViewModel.h"

NSString *const RCStreamMessageCellUpdateEndNotification = @"RCStreamMessageCellUpdateEndNotification";

extern NSString *const RCConversationViewScrollNotification;

@interface RCStreamMessageCell()<RCReferencedContentViewDelegate, RCStreamMessageCellViewModelDelegate, RCStreamContentViewDelegate>
/*!
 文本内容的Label
*/
@property (strong, nonatomic) RCStreamContentView *streamContentView;

/*!
 文本内容的Label
*/
@property (strong, nonatomic) RCButton *unfoldButton;

@property (strong, nonatomic) UIView *lineView;

@property (nonatomic, strong) RCStreamMessageCellViewModel *cellViewModel;

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, assign) NSInteger dotCount;

@property (nonatomic, assign) BOOL isScrolling;

@property (nonatomic, assign) BOOL needLoad;

@end

@implementation RCStreamMessageCell
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

- (void)layoutSubviews {
    [super layoutSubviews];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.streamContentView.frame = CGRectZero;
    [self.streamContentView cleanView];
    self.referencedContentView.frame = CGRectZero;
    self.unfoldButton.frame = CGRectZero;
    [self.unfoldButton setTitle:@"" forState:(UIControlStateNormal)];
    self.unfoldButton.hidden = YES;
    [self invalidTimer];
}

- (void)dealloc {
    [self invalidTimer];
}

#pragma mark -- over method

+ (CGSize)sizeForMessageModel:(RCMessageModel *)model withCollectionViewWidth:(CGFloat)collectionViewWidth referenceExtraHeight:(CGFloat)extraHeight {
    [self configModelWithCellVM:model];
    RCStreamMessageCellViewModel *cellVM = (RCStreamMessageCellViewModel *)model.cellViewModel;
    CGSize contentSize = [cellVM getMessageContentViewSize];
    return CGSizeMake(collectionViewWidth, contentSize.height + extraHeight);
}

- (void)setDataModel:(RCMessageModel *)model {
    [super setDataModel:model];
    [[self class] configModelWithCellVM:model];
    self.cellViewModel = (RCStreamMessageCellViewModel *)model.cellViewModel;
    self.cellViewModel.delegate = self;
    [self updateContentLayout];
}

#pragma mark -- private

+ (void)configModelWithCellVM:(RCMessageModel *)model {
    if (!model.cellViewModel) {
        model.cellViewModel = [RCStreamMessageCellViewModel viewModelWithModel:model];
    }
}

- (void)initialize {
    [self showBubbleBackgroundView:YES];
    [self.messageContentView addSubview:self.referencedContentView];
    [self.messageContentView addSubview:self.unfoldButton];
    [self.unfoldButton addSubview:self.lineView];
    self.contentView.layer.masksToBounds = YES;
    [self registerNotification];
}


- (void)updateContentLayout {
    self.messageContentView.contentSize = self.cellViewModel.contentViewSize;;

    CGFloat leadingX = rcTextLeadingX;
    CGFloat referTopY = rcContentTop;
    CGFloat streamTopY = rcContentTop;
    if (self.cellViewModel.showReferMessage) {
        CGSize referSize = [self.cellViewModel referViewSize];
        [self.referencedContentView setMessage:self.model contentSize:referSize];
        self.referencedContentView.frame = CGRectMake(leadingX, referTopY, referSize.width, referSize.height);
        streamTopY = CGRectGetMaxY(self.referencedContentView.frame) + rcContentSpace;
    } else {
        self.referencedContentView.frame = CGRectZero;
    }

    CGSize textSize = [self.cellViewModel textViewSize];
    self.streamContentView.frame = CGRectMake(leadingX, streamTopY, textSize.width, textSize.height);
    if (self.cellViewModel.status == RCStreamMessageStatusContentLoading) {
        [self.streamContentView showLoading];
    } else if (self.cellViewModel.status == RCStreamMessageStatusContentFailedWhenLoading) {
        [self.streamContentView showFailed];
    } else if (self.cellViewModel.status != RCStreamMessageStatusNone){
        [self.streamContentView configViewModel:self.cellViewModel.contentViewModel];
        [self updateUnfoldButton];
    }
}

- (void)updateUnfoldButton {
    switch (self.cellViewModel.status) {
        case RCStreamMessageStatusBottomUnfold:{
            self.unfoldButton.hidden = NO;
            self.unfoldButton.enabled = YES;
            self.unfoldButton.frame = CGRectMake(0, self.messageContentView.frame.size.height - rcUnfoldButtonHeight, self.messageContentView.frame.size.width, rcUnfoldButtonHeight);
            [self.unfoldButton setTitle:RCLocalizedString(@"StreamMessageUnfold") forState:(UIControlStateNormal)];
            [self.unfoldButton setTitleColor:RCDynamicColor(@"primary_color", @"0x0099ff", @"0x0099ff") forState:UIControlStateNormal];
        } break;
        case RCStreamMessageStatusBottomLoading:{
            self.unfoldButton.hidden = NO;
            self.unfoldButton.enabled = NO;
            self.unfoldButton.frame = CGRectMake(0, self.messageContentView.frame.size.height - rcUnfoldButtonHeight, self.messageContentView.frame.size.width, rcUnfoldButtonHeight);
            [self.unfoldButton setTitle:RCLocalizedString(@"StreamMessageLoading") forState:(UIControlStateNormal)];
            [self.unfoldButton setTitleColor:RCDynamicColor(@"primary_color", @"0x0099ff", @"0x0099ff") forState:UIControlStateNormal];
            if (self.timer) {
                return;
            }
            // 初始化计数器和定时器
            self.dotCount = 1;
            self.timer = [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(updateLoadingText) userInfo:nil repeats:YES];
        } break;
        case RCStreamMessageStatusBottomFailed:{
            self.unfoldButton.hidden = NO;
            self.unfoldButton.enabled = YES;
            self.unfoldButton.frame = CGRectMake(0, self.messageContentView.frame.size.height - rcUnfoldButtonHeight, self.messageContentView.frame.size.width, rcUnfoldButtonHeight);
            [self.unfoldButton setTitle:RCLocalizedString(@"StreamMessageRequestFailed") forState:(UIControlStateNormal)];
            [self.unfoldButton setTitleColor:RCDynamicColor(@"primary_color", @"0x0099ff", @"0x0099ff") forState:UIControlStateNormal];
        } break;
        default:{
            if (self.unfoldButton.hidden) {
                return;
            }
            self.unfoldButton.hidden = YES;
            self.unfoldButton.enabled = NO;
            [self.unfoldButton setTitle:@"" forState:(UIControlStateNormal)];
            self.unfoldButton.frame = CGRectZero;
        } break;
    }
    if (self.cellViewModel.status != RCStreamMessageStatusBottomLoading) {
        [self invalidTimer];
    }
}

- (void)updateLoadingText {
    if (self.cellViewModel.status != RCStreamMessageStatusBottomLoading) {
        [self invalidTimer];
        return;
    }
    // 更新省略号数量
    NSString *dots = @"";
    for (int i = 0; i < self.dotCount; i++) {
        dots = [dots stringByAppendingString:@"."];
    }
    NSString *loading = [NSString stringWithFormat:@"%@%@", RCLocalizedString(@"StreamMessageLoading"), dots];
    [self.unfoldButton setTitle:loading forState:(UIControlStateNormal)];
    // 循环控制省略号数量
    if (self.dotCount == 6) {
        self.dotCount = 1;
    } else {
        self.dotCount++;
    }
}

- (void)invalidTimer {
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (void)reloadLayout {
    [UIView animateWithDuration:0.1 animations:^{
        [self updateContentLayout];
    } completion:^(BOOL finished) {
        [self.messageContentView setNeedsLayout]; // 动画完成后触发重绘
        [self.streamContentView setNeedsLayout];
        [self.hostView performBatchUpdates:^{
            [self.hostView.collectionViewLayout invalidateLayout];
        } completion:^(BOOL finished) {
            [[NSNotificationCenter defaultCenter] postNotificationName:RCStreamMessageCellUpdateEndNotification object:self.model.messageUId];
        }];
    }];
}

#pragma mark -- RCStreamMessageCellViewModelDelegate

- (void)contentLayoutDidUpdate {
    if (self.isScrolling) {
        self.needLoad = YES;
        return;
    }
    if (!self.cellViewModel.delegate) {
        return;
    }
    [self reloadLayout];
}

#pragma mark -- RCReferencedContentViewDelegate

- (void)didTapReferencedContentView:(RCMessageModel *)message {
    RCStreamMessage *refer = (RCStreamMessage *)message.content;
    if ([refer.referMsg isKindOfClass:[RCFileMessage class]] ||
        [refer.referMsg isKindOfClass:[RCImageMessage class]]  ||
        [refer.referMsg isKindOfClass:[RCTextMessage class]]) {
        if ([self.delegate respondsToSelector:@selector(didTapReferencedContentView:)]) {
            [self.delegate didTapReferencedContentView:message];
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(didTapMessageCell:)]) {
            [self.delegate didTapMessageCell:self.model];
        }
    }
}

#pragma mark -- RCStreamContentViewDelegate

- (void)streamContentViewDidLongPress {
    [self longPressedStreamContentView:nil];
}

- (void)streamContentViewDidClickUrl:(NSString *)url {
    if ([self.delegate respondsToSelector:@selector(didTapUrlInMessageCell:model:)]) {
        [self.delegate didTapUrlInMessageCell:url model:self.model];
    }
}

#pragma mark -- notification

- (void)registerNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(conversationViewScrollDidChange:) name:RCConversationViewScrollNotification object:nil];
}

- (void)conversationViewScrollDidChange:(NSNotification *)notifi {
    self.isScrolling = [notifi.object boolValue];
    if (!self.isScrolling && self.needLoad) {
        self.needLoad = NO;
        [self reloadLayout];
    }
}


#pragma mark -- action

- (void)longPressedStreamContentView:(id)sender {
    UILongPressGestureRecognizer *press = (UILongPressGestureRecognizer *)sender;
    if (press.state == UIGestureRecognizerStateEnded) {
        return;
    } else if (press.state == UIGestureRecognizerStateBegan) {
        [self.delegate didLongTouchMessageCell:self.model inView:self.messageContentView];
    }
}

- (void)didTapStreamContentView{
    DebugLog(@"%s", __FUNCTION__);
    if ([self.delegate respondsToSelector:@selector(didTapMessageCell:)]) {
        [self.delegate didTapMessageCell:self.model];
    }
}

- (void)unfoldButtonDidClick {
    [self.cellViewModel reloadStreamContent:(RCStreamMessageStatusBottomLoading)];
    [self.cellViewModel requestStreamMessage];
}

#pragma mark -- getter

- (RCReferencedContentView *)referencedContentView{
    if (!_referencedContentView) {
        _referencedContentView = [[RCReferencedContentView alloc] init];
        _referencedContentView.delegate = self;
    }
    return _referencedContentView;
}

- (RCStreamContentView *)streamContentView {
    if (!_streamContentView) {
        _streamContentView = [self.cellViewModel.contentViewModel streamContentView];
        _streamContentView.delegate = self;
        [self.messageContentView addSubview:_streamContentView];
        [self.messageContentView bringSubviewToFront:self.unfoldButton];
        UILongPressGestureRecognizer *longPress =
        [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressedStreamContentView:)];
        [self.messageContentView addGestureRecognizer:longPress];

        UITapGestureRecognizer *tap =
            [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapStreamContentView)];
        tap.numberOfTapsRequired = 1;
        tap.numberOfTouchesRequired = 1;
        [self.messageContentView addGestureRecognizer:tap];
    }
    return _streamContentView;
}

- (RCButton *)unfoldButton {
    if (!_unfoldButton) {
        _unfoldButton = [RCButton new];
        _unfoldButton.titleLabel.font = [[RCKitConfig defaultConfig].font fontOfThirdLevel];
        [_unfoldButton addTarget:self action:@selector(unfoldButtonDidClick) forControlEvents:(UIControlEventTouchUpInside)];
        CAGradientLayer *gradientLayer = [CAGradientLayer layer];
        gradientLayer.frame = CGRectMake(0, -50, [RCMessageCellTool getMessageContentViewMaxWidth], 50);
        UIColor *color = RCDynamicColor(@"common_background_color", @"0xffffff", @"0x111111");
        if (color) {
            gradientLayer.colors = @[
                (id)[UIColor clearColor].CGColor,
                (id)color.CGColor];
        } else {
            gradientLayer.colors = @[
                (id)[RCDYCOLOR(0xffffff, 0x111111) colorWithAlphaComponent:0.0].CGColor,
                (id)RCDYCOLOR(0xffffff, 0x111111).CGColor];
        }
      
        gradientLayer.locations = @[@0, @1];
        // 添加渐变层
        [_unfoldButton.layer addSublayer:gradientLayer];
        _unfoldButton.hidden = YES;
    }
    return _unfoldButton;
}

- (UIView *)lineView {
    if (!_lineView) {
        _lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [RCMessageCellTool getMessageContentViewMaxWidth], 0.5)];
        _lineView.backgroundColor = RCDynamicColor(@"line_background_color", @"0xE2E4E5", @"0xE2E4E5");
    }
    return _lineView;
}
@end
