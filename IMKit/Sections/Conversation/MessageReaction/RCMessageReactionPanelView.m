//
//  RCMessageReactionPanelView.m
//  RongIMKit
//
//  Created by RC on 2026/6/2.
//  Copyright © 2026 RongCloud. All rights reserved.
//

#import "RCMessageReactionPanelView.h"
#import "RCKitCommonDefine.h"
#import "RCKitUtility.h"
#import "RCMessageReactionResizablePanelGestureHandler.h"

static CGFloat const RCMessageReactionPanelInitialHeightRatio = 360.0 / 819.0;
static CGFloat const RCMessageReactionPanelMinHeight = 300.0;
static CGFloat const RCMessageReactionPanelHorizontalInset = 20.0;
static CGFloat const RCMessageReactionPanelEmojiItemSize = 30.0;
static CGFloat const RCMessageReactionPanelEmojiHorizontalSpan = 42.0;
static CGFloat const RCMessageReactionPanelEmojiVerticalSpan = 47.0;
static CGFloat const RCMessageReactionPanelEmojiInsetOffset = 6.0;
static CGFloat const RCMessageReactionPanelHeightEpsilon = 0.5;
static CGFloat const RCMessageReactionPanelDismissDistance = 80.0;
static CGFloat const RCMessageReactionPanelDismissVelocity = 800.0;
static NSString *const RCMessageReactionPanelCellIdentifier = @"RCMessageReactionPanelCellIdentifier";
static NSString *const RCMessageReactionPanelHeaderIdentifier = @"RCMessageReactionPanelHeaderIdentifier";

@interface RCMessageReactionPanelCell : UICollectionViewCell

@property (nonatomic, strong) UILabel *emojiLabel;

@end

@implementation RCMessageReactionPanelCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        self.contentView.backgroundColor = UIColor.clearColor;
        [self.contentView addSubview:self.emojiLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.emojiLabel.frame = self.contentView.bounds;
}

- (UILabel *)emojiLabel {
    if (!_emojiLabel) {
        _emojiLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _emojiLabel.textAlignment = NSTextAlignmentCenter;
        _emojiLabel.font = [UIFont systemFontOfSize:26];
        _emojiLabel.adjustsFontSizeToFitWidth = YES;
        _emojiLabel.minimumScaleFactor = 0.7;
    }
    return _emojiLabel;
}

@end

@interface RCMessageReactionPanelHeaderView : UICollectionReusableView

@property (nonatomic, strong) UILabel *titleLabel;

@end

@implementation RCMessageReactionPanelHeaderView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.titleLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.titleLabel.frame = CGRectMake(RCMessageReactionPanelHorizontalInset, 4,
                                       self.bounds.size.width - RCMessageReactionPanelHorizontalInset * 2, 24);
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
        _titleLabel.textColor = RCDynamicColor(@"text_secondary_color", @"0x7C838E", @"0x7C838E");
    }
    return _titleLabel;
}

@end

@interface RCMessageReactionPanelView () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIView *dimmingView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIView *handleView;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, copy) NSArray<NSString *> *recentReactionIds;
@property (nonatomic, copy) NSArray<NSString *> *defaultReactionIds;
@property (nonatomic, assign) CGFloat currentPanelHeight;
@property (nonatomic, assign) CGFloat panelTranslationY;
@property (nonatomic, assign) BOOL dismissing;
@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic, strong) RCMessageReactionResizablePanelGestureHandler *resizeGestureHandler;

@end

@implementation RCMessageReactionPanelView

- (instancetype)initWithRecentReactionIds:(NSArray<NSString *> *)recentReactionIds {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _recentReactionIds = [recentReactionIds copy] ?: @[];
        _defaultReactionIds = [[self class] defaultEmojiReactionIds];
        [self setupViews];
    }
    return self;
}

+ (NSArray<NSString *> *)defaultEmojiReactionIds {
    NSString *emojiPlistPath = [RCKitUtility filePathForName:@"Emoji.plist"];
    NSArray *emojiList = [[NSArray alloc] initWithContentsOfFile:emojiPlistPath];
    NSMutableArray<NSString *> *reactionIds = [NSMutableArray array];
    for (id emoji in emojiList) {
        if ([emoji isKindOfClass:NSString.class] && [emoji length] > 0) {
            [reactionIds addObject:emoji];
        }
    }
    if (reactionIds.count > 0) {
        return reactionIds.copy;
    }
    return @[@"👍", @"❤️", @"😂", @"😮", @"😢", @"🙏", @"👏", @"🔥"];
}

- (void)setupViews {
    self.backgroundColor = [UIColor clearColor];
    [self addSubview:self.dimmingView];
    [self addSubview:self.contentView];
    [self.contentView addSubview:self.handleView];
    [self.contentView addSubview:self.collectionView];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onMaskTap:)];
    tap.delegate = self;
    [self.dimmingView addGestureRecognizer:tap];
    self.panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPan:)];
    self.panGestureRecognizer.delegate = self;
    [self.contentView addGestureRecognizer:self.panGestureRecognizer];
    [self setupResizeGestureHandler];
}

- (void)setupResizeGestureHandler {
    self.resizeGestureHandler =
        [[RCMessageReactionResizablePanelGestureHandler alloc] initWithHeightEpsilon:RCMessageReactionPanelHeightEpsilon
                                                                     dismissDistance:RCMessageReactionPanelDismissDistance
                                                                     dismissVelocity:RCMessageReactionPanelDismissVelocity];

    __weak typeof(self) weakSelf = self;
    self.resizeGestureHandler.shouldResizeBlock = ^BOOL(CGFloat translationY) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        return [strongSelf shouldResizePanelWithTranslationY:translationY];
    };
    self.resizeGestureHandler.applyStateBlock = ^(CGFloat panelHeight, CGFloat panelTranslationY) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.currentPanelHeight = panelHeight;
        strongSelf.panelTranslationY = panelTranslationY;
    };
    self.resizeGestureHandler.layoutBlock = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf lockCollectionViewAtTopIfNeeded];
        [strongSelf setNeedsLayout];
        [strongSelf layoutIfNeeded];
    };
    self.resizeGestureHandler.dismissBlock = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf dismiss];
    };
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.dimmingView.frame = self.bounds;
    if (self.dismissing) {
        return;
    }
    CGFloat safeBottom = [RCKitUtility getWindowSafeAreaInsets].bottom;
    self.contentView.frame = CGRectMake(0,
                                        self.bounds.size.height - self.currentPanelHeight + self.panelTranslationY,
                                        self.bounds.size.width,
                                        self.currentPanelHeight);
    self.handleView.frame = CGRectMake((self.contentView.bounds.size.width - 36) / 2.0, 8, 36, 4);
    self.collectionView.frame = CGRectMake(0, 24, self.contentView.bounds.size.width,
                                           MAX(self.contentView.bounds.size.height - 24 - safeBottom, 0));
}

- (void)showInView:(UIView *)view {
    if (!view) {
        return;
    }
    self.frame = view.bounds;
    self.currentPanelHeight = [self initialHeightForContainerHeight:view.bounds.size.height];
    self.panelTranslationY = 0;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [view addSubview:self];
    [self setNeedsLayout];
    [self layoutIfNeeded];
    self.dismissing = NO;
    CGRect frame = self.contentView.frame;
    self.dimmingView.alpha = 0;
    self.contentView.frame = CGRectOffset(frame, 0, frame.size.height);
    [UIView animateWithDuration:0.22 animations:^{
        self.dimmingView.alpha = 1;
        self.contentView.frame = frame;
    }];
}

- (void)dismiss {
    [self dismissAnimated:YES];
}

- (void)dismissAnimated:(BOOL)animated {
    CGRect frame = [self currentContentViewFrameForDismissal];
    self.panelTranslationY = 0;
    self.dismissing = YES;
    [self.layer removeAllAnimations];
    [self.dimmingView.layer removeAllAnimations];
    [self.contentView.layer removeAllAnimations];
    self.contentView.frame = frame;
    if (!animated) {
        [self removeFromSuperview];
        return;
    }
    [UIView animateWithDuration:0.2 animations:^{
        self.dimmingView.alpha = 0;
        self.contentView.frame = CGRectOffset(frame, 0, frame.size.height);
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

- (CGRect)currentContentViewFrameForDismissal {
    CALayer *presentationLayer = self.contentView.layer.presentationLayer;
    return presentationLayer ? presentationLayer.frame : self.contentView.frame;
}

- (CGFloat)initialHeightForContainerHeight:(CGFloat)height {
    return MIN(MAX(height * RCMessageReactionPanelInitialHeightRatio, RCMessageReactionPanelMinHeight), [self maxHeightForContainerHeight:height]);
}

- (CGFloat)maxHeightForContainerHeight:(CGFloat)height {
    CGFloat topInset = [self effectiveTopLimitInset];
    return MAX(height - topInset, 0);
}

- (CGFloat)effectiveTopLimitInset {
    if (self.topLimitInset > 0) {
        return self.topLimitInset;
    }
    return [RCKitUtility getWindowSafeAreaInsets].top;
}

- (CGFloat)minimumPanelHeight {
    return [self initialHeightForContainerHeight:CGRectGetHeight(self.bounds)];
}

- (CGFloat)maximumPanelHeight {
    return [self maxHeightForContainerHeight:CGRectGetHeight(self.bounds)];
}

- (BOOL)isPanelAtMaximumHeight {
    return self.currentPanelHeight >= [self maximumPanelHeight] - RCMessageReactionPanelHeightEpsilon;
}

- (BOOL)isCollectionViewAtTop {
    CGFloat topOffset = -self.collectionView.contentInset.top;
    return self.collectionView.contentOffset.y <= topOffset + RCMessageReactionPanelHeightEpsilon;
}

- (BOOL)shouldLockCollectionViewAtTop {
    return ![self isPanelAtMaximumHeight];
}

- (BOOL)shouldResizePanelWithTranslationY:(CGFloat)translationY {
    if (![self isPanelAtMaximumHeight]) {
        return YES;
    }
    return translationY > 0 && [self isCollectionViewAtTop];
}

- (void)lockCollectionViewAtTopIfNeeded {
    if (![self shouldLockCollectionViewAtTop]) {
        return;
    }
    CGFloat topOffset = -self.collectionView.contentInset.top;
    if (fabs(self.collectionView.contentOffset.y - topOffset) > RCMessageReactionPanelHeightEpsilon) {
        [self.collectionView setContentOffset:CGPointMake(self.collectionView.contentOffset.x, topOffset) animated:NO];
    }
}

#pragma mark - Actions

- (void)onMaskTap:(UITapGestureRecognizer *)gestureRecognizer {
    [self dismiss];
}

- (void)onPan:(UIPanGestureRecognizer *)gestureRecognizer {
    [self.resizeGestureHandler handlePanGesture:gestureRecognizer
                                         inView:self
                             currentPanelHeight:self.currentPanelHeight
                             minimumPanelHeight:[self minimumPanelHeight]
                             maximumPanelHeight:[self maximumPanelHeight]];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return self.recentReactionIds.count > 0 ? 2 : 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.recentReactionIds.count > 0 && section == 0) {
        return self.recentReactionIds.count;
    }
    return self.defaultReactionIds.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    RCMessageReactionPanelCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:RCMessageReactionPanelCellIdentifier forIndexPath:indexPath];
    cell.emojiLabel.text = [self reactionIdAtIndexPath:indexPath];
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath {
    RCMessageReactionPanelHeaderView *header = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                                                   withReuseIdentifier:RCMessageReactionPanelHeaderIdentifier
                                                                                          forIndexPath:indexPath];
    BOOL recentSection = self.recentReactionIds.count > 0 && indexPath.section == 0;
    header.titleLabel.text = recentSection ? RCLocalizedString(@"MessageReactionFrequentlyUsed") : RCLocalizedString(@"MessageReactionDefaultEmojis");
    return header;
}

- (NSString *)reactionIdAtIndexPath:(NSIndexPath *)indexPath {
    if (self.recentReactionIds.count > 0 && indexPath.section == 0) {
        return self.recentReactionIds[indexPath.item];
    }
    return self.defaultReactionIds[indexPath.item];
}

- (CGFloat)emojiHorizontalInsetForWidth:(CGFloat)width {
    if (width <= 0) {
        return RCMessageReactionPanelEmojiInsetOffset;
    }
    NSInteger left = ((NSInteger)width) % (NSInteger)RCMessageReactionPanelEmojiHorizontalSpan;
    if (left < 12) {
        left += (NSInteger)RCMessageReactionPanelEmojiHorizontalSpan;
    }
    return left / 2.0 + RCMessageReactionPanelEmojiInsetOffset;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSString *reactionId = [self reactionIdAtIndexPath:indexPath];
    if ([self.delegate respondsToSelector:@selector(messageReactionPanelView:didSelectReactionId:)]) {
        [self.delegate messageReactionPanelView:self didSelectReactionId:reactionId];
    }
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(RCMessageReactionPanelEmojiItemSize, RCMessageReactionPanelEmojiItemSize);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout *)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section {
    CGFloat horizontalInset = [self emojiHorizontalInsetForWidth:collectionView.bounds.size.width];
    return UIEdgeInsetsMake(8, horizontalInset, 16, horizontalInset);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout *)collectionViewLayout
minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return RCMessageReactionPanelEmojiHorizontalSpan - RCMessageReactionPanelEmojiItemSize;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout *)collectionViewLayout
minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return RCMessageReactionPanelEmojiVerticalSpan - RCMessageReactionPanelEmojiItemSize;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
referenceSizeForHeaderInSection:(NSInteger)section {
    return CGSizeMake(collectionView.bounds.size.width, 32);
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView == self.collectionView && [self shouldLockCollectionViewAtTop]) {
        [self lockCollectionViewAtTopIfNeeded];
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer == self.panGestureRecognizer) {
        CGPoint velocity = [self.panGestureRecognizer velocityInView:self.contentView];
        return fabs(velocity.y) >= fabs(velocity.x);
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (gestureRecognizer == self.panGestureRecognizer) {
        return YES;
    }
    return touch.view == self.dimmingView;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ((gestureRecognizer == self.panGestureRecognizer && otherGestureRecognizer == self.collectionView.panGestureRecognizer) ||
        (gestureRecognizer == self.collectionView.panGestureRecognizer && otherGestureRecognizer == self.panGestureRecognizer)) {
        return YES;
    }
    return NO;
}

#pragma mark - Getters

- (UIView *)dimmingView {
    if (!_dimmingView) {
        _dimmingView = [[UIView alloc] initWithFrame:CGRectZero];
        _dimmingView.backgroundColor = RCDynamicColor(@"message_reaction_panel_mask_color", @"0x0000003F", @"0x0000003F");
    }
    return _dimmingView;
}

- (UIView *)contentView {
    if (!_contentView) {
        _contentView = [[UIView alloc] initWithFrame:CGRectZero];
        _contentView.backgroundColor = RCDynamicColor(@"common_background_color", @"0xffffff", @"0x2D2D32");
        _contentView.layer.cornerRadius = 8;
        _contentView.layer.masksToBounds = YES;
    }
    return _contentView;
}

- (UIView *)handleView {
    if (!_handleView) {
        _handleView = [[UIView alloc] initWithFrame:CGRectZero];
        _handleView.backgroundColor = RCDynamicColor(@"disabled_color", @"0xD9D9D9", @"0xD9D9D9");
        _handleView.layer.cornerRadius = 2;
        _handleView.layer.masksToBounds = YES;
    }
    return _handleView;
}

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.alwaysBounceVertical = YES;
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.showsVerticalScrollIndicator = NO;
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        [_collectionView registerClass:RCMessageReactionPanelCell.class forCellWithReuseIdentifier:RCMessageReactionPanelCellIdentifier];
        [_collectionView registerClass:RCMessageReactionPanelHeaderView.class
            forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                   withReuseIdentifier:RCMessageReactionPanelHeaderIdentifier];
    }
    return _collectionView;
}

@end
