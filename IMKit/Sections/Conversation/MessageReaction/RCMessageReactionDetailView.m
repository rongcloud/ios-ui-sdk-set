//
//  RCMessageReactionDetailView.m
//  RongIMKit
//
//  Created by RC on 2026/6/9.
//  Copyright © 2026 RongCloud. All rights reserved.
//

#import "RCMessageReactionDetailView.h"
#import "RCMessageReactionDetailUserItem.h"
#import "RCKitCommonDefine.h"
#import "RCKitUtility.h"
#import "RCMJRefresh.h"
#import "RCloudImageView.h"
#import "RCMessageReactionResizablePanelGestureHandler.h"
#import <RongIMLibCore/RongIMLibCore.h>

static CGFloat const RCMessageReactionDetailInitialHeightRatio = 548.0 / 819.0;
static CGFloat const RCMessageReactionDetailMinHeight = 360.0;
static CGFloat const RCMessageReactionDetailReactionBarHeight = 34.0;
static CGFloat const RCMessageReactionDetailTitleTop = 16.0;
static CGFloat const RCMessageReactionDetailTitleHeight = 20.0;
static CGFloat const RCMessageReactionDetailReactionBarTop = 8.0;
static CGFloat const RCMessageReactionDetailUserCellHeight = 54.0;
static CGFloat const RCMessageReactionDetailUserCellAvatarSize = 32.0;
static CGFloat const RCMessageReactionDetailCloseButtonSize = 22.0;
static CGFloat const RCMessageReactionDetailCloseImageSize = 14.0;
static CGFloat const RCMessageReactionDetailHorizontalInset = 16.0;
static CGFloat const RCMessageReactionDetailReactionButtonHeight = 28.0;
static CGFloat const RCMessageReactionDetailReactionButtonSpacing = 6.0;
static CGFloat const RCMessageReactionDetailHeightEpsilon = 0.5;
static CGFloat const RCMessageReactionDetailDismissDistance = 80.0;
static CGFloat const RCMessageReactionDetailDismissVelocity = 800.0;
static NSString *const RCMessageReactionDetailUserCellIdentifier = @"RCMessageReactionDetailUserCellIdentifier";

@interface RCMessageReactionDetailUserCell : UITableViewCell

@property (nonatomic, strong) RCloudImageView *portraitImageView;
@property (nonatomic, strong) UILabel *nameLabel;

- (void)updateWithItem:(RCMessageReactionDetailUserItem *)item;

@end

@implementation RCMessageReactionDetailUserCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = RCDynamicColor(@"message_reaction_detail_bg_color", @"0xffffff", @"0x1f2023");
        self.contentView.backgroundColor = self.backgroundColor;
        [self.contentView addSubview:self.portraitImageView];
        [self.contentView addSubview:self.nameLabel];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.portraitImageView.image = RCDynamicImage(@"conversation-list_cell_portrait_msg_img", @"default_portrait_msg");
    self.nameLabel.text = nil;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat contentHeight = CGRectGetHeight(self.contentView.bounds);
    self.portraitImageView.frame = CGRectMake(RCMessageReactionDetailHorizontalInset,
                                              (contentHeight - RCMessageReactionDetailUserCellAvatarSize) / 2.0,
                                              RCMessageReactionDetailUserCellAvatarSize,
                                              RCMessageReactionDetailUserCellAvatarSize);
    CGFloat nameX = CGRectGetMaxX(self.portraitImageView.frame) + 12.0;
    self.nameLabel.frame = CGRectMake(nameX, 0,
                                      MAX(CGRectGetWidth(self.contentView.bounds) - nameX - RCMessageReactionDetailHorizontalInset, 0),
                                      contentHeight);
    self.portraitImageView.layer.cornerRadius = RCMessageReactionDetailUserCellAvatarSize / 2.0;
}

- (void)updateWithItem:(RCMessageReactionDetailUserItem *)item {
    self.nameLabel.text = item.displayName.length > 0 ? item.displayName : (item.user.userId ?: @"");
    if (item.portraitUri.length > 0) {
        self.portraitImageView.imageURL = [NSURL URLWithString:item.portraitUri];
    } else {
        self.portraitImageView.image = RCDynamicImage(@"conversation-list_cell_portrait_msg_img", @"default_portrait_msg");
    }
}

- (RCloudImageView *)portraitImageView {
    if (!_portraitImageView) {
        _portraitImageView = [[RCloudImageView alloc] initWithPlaceholderImage:RCDynamicImage(@"conversation-list_cell_portrait_msg_img", @"default_portrait_msg")];
        _portraitImageView.clipsToBounds = YES;
    }
    return _portraitImageView;
}

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _nameLabel.font = [UIFont systemFontOfSize:17];
        _nameLabel.textColor = RCDynamicColor(@"text_primary_color", @"0x020814", @"0xFFFFFF");
        _nameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    return _nameLabel;
}

@end

@interface RCMessageReactionDetailView () <UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UIScrollView *reactionScrollView;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray<RCMessageReaction *> *reactions;
@property (nonatomic, copy) NSArray<RCMessageReactionDetailUserItem *> *userItems;
@property (nonatomic, copy) NSString *selectedReactionId;
@property (nonatomic, copy) NSString *nextPageToken;
@property (nonatomic, assign) NSInteger totalCount;
@property (nonatomic, assign) CGFloat currentPanelHeight;
@property (nonatomic, assign) CGFloat panelTranslationY;
@property (nonatomic, assign) BOOL dismissing;
@property (nonatomic, assign) BOOL loadingMoreUsers;
@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *backgroundTapGestureRecognizer;
@property (nonatomic, strong) RCMessageReactionResizablePanelGestureHandler *resizeGestureHandler;

@end

@implementation RCMessageReactionDetailView

- (instancetype)initWithReactions:(NSArray<RCMessageReaction *> *)reactions
                 selectedReactionId:(NSString *)selectedReactionId {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _reactions = [reactions copy] ?: @[];
        _selectedReactionId = [self validSelectedReactionId:selectedReactionId reactions:_reactions];
        _userItems = @[];
        [self setupViews];
    }
    return self;
}

- (NSString *)validSelectedReactionId:(NSString *)selectedReactionId reactions:(NSArray<RCMessageReaction *> *)reactions {
    for (RCMessageReaction *reaction in reactions) {
        if ([reaction.reactionId isEqualToString:selectedReactionId]) {
            return selectedReactionId;
        }
    }
    return reactions.firstObject.reactionId ?: @"";
}

- (void)setupViews {
    self.backgroundColor = [UIColor clearColor];
    [self addSubview:self.contentView];
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.closeButton];
    [self.contentView addSubview:self.reactionScrollView];
    [self.contentView addSubview:self.tableView];
    [self setupContentConstraints];

    self.backgroundTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onBackgroundTap:)];
    self.backgroundTapGestureRecognizer.delegate = self;
    [self addGestureRecognizer:self.backgroundTapGestureRecognizer];

    self.panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPan:)];
    self.panGestureRecognizer.delegate = self;
    [self.contentView addGestureRecognizer:self.panGestureRecognizer];
    [self setupResizeGestureHandler];
    [self reloadReactionButtons];
}

- (void)setupResizeGestureHandler {
    self.resizeGestureHandler =
        [[RCMessageReactionResizablePanelGestureHandler alloc] initWithHeightEpsilon:RCMessageReactionDetailHeightEpsilon
                                                                     dismissDistance:RCMessageReactionDetailDismissDistance
                                                                     dismissVelocity:RCMessageReactionDetailDismissVelocity];

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
        [strongSelf lockTableViewAtTopIfNeeded];
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
    if (self.dismissing) {
        return;
    }
    CGFloat safeBottom = [RCKitUtility getWindowSafeAreaInsets].bottom;
    self.contentView.frame = CGRectMake(0,
                                        CGRectGetHeight(self.bounds) - self.currentPanelHeight + self.panelTranslationY,
                                        CGRectGetWidth(self.bounds),
                                        self.currentPanelHeight);
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, safeBottom, 0);
    self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
    [self.contentView layoutIfNeeded];
    [self layoutReactionButtons];
}

- (void)setupContentConstraints {
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.reactionScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;

    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:RCMessageReactionDetailTitleTop],
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:RCMessageReactionDetailHorizontalInset],
        [self.titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.closeButton.leadingAnchor constant:-8.0],
        [self.titleLabel.heightAnchor constraintEqualToConstant:RCMessageReactionDetailTitleHeight],

        [self.closeButton.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-RCMessageReactionDetailHorizontalInset],
        [self.closeButton.centerYAnchor constraintEqualToAnchor:self.titleLabel.centerYAnchor],
        [self.closeButton.widthAnchor constraintEqualToConstant:RCMessageReactionDetailCloseButtonSize],
        [self.closeButton.heightAnchor constraintEqualToConstant:RCMessageReactionDetailCloseButtonSize],

        [self.reactionScrollView.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:RCMessageReactionDetailReactionBarTop],
        [self.reactionScrollView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
        [self.reactionScrollView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
        [self.reactionScrollView.heightAnchor constraintEqualToConstant:RCMessageReactionDetailReactionBarHeight],

        [self.tableView.topAnchor constraintEqualToAnchor:self.reactionScrollView.bottomAnchor],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor]
    ]];
}

- (void)showInView:(UIView *)view {
    if (!view) {
        return;
    }
    self.frame = view.bounds;
    self.currentPanelHeight = [self initialHeightForContainerHeight:CGRectGetHeight(view.bounds)];
    self.panelTranslationY = 0;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [view addSubview:self];
    [self setNeedsLayout];
    [self layoutIfNeeded];
    self.dismissing = NO;
    [self scrollSelectedReactionButtonToVisibleAnimated:NO];

    CGRect targetFrame = self.contentView.frame;
    self.contentView.frame = CGRectOffset(targetFrame, 0, CGRectGetHeight(targetFrame));
    [UIView animateWithDuration:0.22 animations:^{
        self.contentView.frame = targetFrame;
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
    [self.contentView.layer removeAllAnimations];
    self.contentView.frame = frame;
    if (!animated) {
        [self removeFromSuperview];
    } else {
        [UIView animateWithDuration:0.2 animations:^{
            self.contentView.frame = CGRectOffset(frame, 0, CGRectGetHeight(frame));
        } completion:^(BOOL finished) {
            [self removeFromSuperview];
        }];
    }
    if ([self.delegate respondsToSelector:@selector(messageReactionDetailViewDidDismiss:)]) {
        [self.delegate messageReactionDetailViewDidDismiss:self];
    }
}

- (CGRect)currentContentViewFrameForDismissal {
    CALayer *presentationLayer = self.contentView.layer.presentationLayer;
    return presentationLayer ? presentationLayer.frame : self.contentView.frame;
}

- (void)updateUserItems:(NSArray<RCMessageReactionDetailUserItem *> *)userItems
             totalCount:(NSInteger)totalCount
          nextPageToken:(NSString *)nextPageToken
          forReactionId:(NSString *)reactionId
                 append:(BOOL)append {
    if (![reactionId isEqualToString:self.selectedReactionId]) {
        return;
    }
    self.totalCount = totalCount;
    self.nextPageToken = nextPageToken;
    self.loadingMoreUsers = NO;
    if (append) {
        self.userItems = [self.userItems arrayByAddingObjectsFromArray:userItems ?: @[]];
    } else {
        self.userItems = [userItems copy] ?: @[];
        [self.tableView setContentOffset:CGPointZero animated:NO];
    }
    [self.tableView reloadData];
    [self reloadReactionButtons];
    [self updateLoadMoreFooterState];
}

- (void)endLoadingUsersForReactionId:(NSString *)reactionId {
    if ([reactionId isEqualToString:self.selectedReactionId]) {
        self.loadingMoreUsers = NO;
        [self.tableView.rcmj_footer endRefreshing];
    }
}

- (CGFloat)initialHeightForContainerHeight:(CGFloat)height {
    CGFloat targetHeight = height * RCMessageReactionDetailInitialHeightRatio;
    return MIN(MAX(targetHeight, RCMessageReactionDetailMinHeight), [self maxHeightForContainerHeight:height]);
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
    return self.currentPanelHeight >= [self maximumPanelHeight] - RCMessageReactionDetailHeightEpsilon;
}

- (BOOL)isTableViewAtTop {
    CGFloat topOffset = -self.tableView.contentInset.top;
    return self.tableView.contentOffset.y <= topOffset + RCMessageReactionDetailHeightEpsilon;
}

- (BOOL)shouldLockTableViewAtTop {
    return ![self isPanelAtMaximumHeight];
}

- (BOOL)shouldResizePanelWithTranslationY:(CGFloat)translationY {
    if (![self isPanelAtMaximumHeight]) {
        return YES;
    }
    return translationY > 0 && [self isTableViewAtTop];
}

- (void)lockTableViewAtTopIfNeeded {
    if (![self shouldLockTableViewAtTop]) {
        return;
    }
    CGFloat topOffset = -self.tableView.contentInset.top;
    if (fabs(self.tableView.contentOffset.y - topOffset) > RCMessageReactionDetailHeightEpsilon) {
        [self.tableView setContentOffset:CGPointMake(self.tableView.contentOffset.x, topOffset) animated:NO];
    }
}

#pragma mark - Actions

- (void)onCloseButtonClick:(id)sender {
    [self dismiss];
}

- (void)onBackgroundTap:(UITapGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateRecognized) {
        [self dismiss];
    }
}

- (void)onReactionButtonClick:(UIButton *)sender {
    if (sender.tag < 0 || sender.tag >= self.reactions.count) {
        return;
    }
    RCMessageReaction *reaction = self.reactions[sender.tag];
    if ([reaction.reactionId isEqualToString:self.selectedReactionId]) {
        return;
    }
    self.selectedReactionId = reaction.reactionId ?: @"";
    self.userItems = @[];
    self.nextPageToken = nil;
    self.totalCount = reaction.totalCount;
    self.loadingMoreUsers = YES;
    [self.tableView.rcmj_footer resetNoMoreData];
    [self.tableView.rcmj_footer endRefreshing];
    [self reloadReactionButtons];
    [self.tableView reloadData];
    [self scrollSelectedReactionButtonToVisibleAnimated:YES];
    if ([self.delegate respondsToSelector:@selector(messageReactionDetailView:didSelectReaction:)]) {
        [self.delegate messageReactionDetailView:self didSelectReaction:reaction];
    }
}

- (void)onPan:(UIPanGestureRecognizer *)gestureRecognizer {
    [self.resizeGestureHandler handlePanGesture:gestureRecognizer
                                         inView:self
                             currentPanelHeight:self.currentPanelHeight
                             minimumPanelHeight:[self minimumPanelHeight]
                             maximumPanelHeight:[self maximumPanelHeight]];
}

#pragma mark - Reaction Buttons

- (void)reloadReactionButtons {
    [self.reactionScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    for (NSInteger index = 0; index < self.reactions.count; index++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.tag = index;
        button.titleLabel.font = [UIFont systemFontOfSize:16];
        button.layer.cornerRadius = RCMessageReactionDetailReactionButtonHeight / 2.0;
        button.layer.masksToBounds = YES;
        [button addTarget:self action:@selector(onReactionButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        [self.reactionScrollView addSubview:button];
        [self updateReactionButton:button reaction:self.reactions[index]];
    }
    [self setNeedsLayout];
}

- (void)updateReactionButton:(UIButton *)button reaction:(RCMessageReaction *)reaction {
    BOOL selected = [reaction.reactionId isEqualToString:self.selectedReactionId];
    NSString *countText = reaction.totalCount > 99 ? @"99+" : [NSString stringWithFormat:@"%@", @(MAX(reaction.totalCount, 0))];
    NSString *title = [NSString stringWithFormat:@"%@ %@%@", reaction.reactionId ?: @"", countText, RCLocalizedString(@"MessageReactionUserCountSuffix")];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:selected ? UIColor.whiteColor : RCDynamicColor(@"message_reaction_item_text_color", @"0x565960", @"0xFFFFFF")
                 forState:UIControlStateNormal];
    button.backgroundColor = selected ? RCDynamicColor(@"message_reaction_detail_selected_bg_color", @"0x0047FFCC", @"0x0047FFCC") : RCDynamicColor(@"message_reaction_detail_normal_bg_color", @"0xF1F2F5", @"0x303136");
}

- (void)layoutReactionButtons {
    CGFloat x = RCMessageReactionDetailHorizontalInset;
    CGFloat y = (CGRectGetHeight(self.reactionScrollView.bounds) - RCMessageReactionDetailReactionButtonHeight) / 2.0;
    for (UIButton *button in self.reactionScrollView.subviews) {
        CGSize titleSize = [RCKitUtility getTextDrawingSize:[button titleForState:UIControlStateNormal]
                                                       font:button.titleLabel.font
                                            constrainedSize:CGSizeMake(CGFLOAT_MAX, RCMessageReactionDetailReactionButtonHeight)];
        CGFloat width = ceil(titleSize.width) + 16.0;
        button.frame = CGRectMake(x, y, MAX(width, RCMessageReactionDetailReactionButtonHeight), RCMessageReactionDetailReactionButtonHeight);
        x = CGRectGetMaxX(button.frame) + RCMessageReactionDetailReactionButtonSpacing;
    }
    self.reactionScrollView.contentSize = CGSizeMake(MAX(x - RCMessageReactionDetailReactionButtonSpacing + RCMessageReactionDetailHorizontalInset, CGRectGetWidth(self.reactionScrollView.bounds)),
                                                     CGRectGetHeight(self.reactionScrollView.bounds));
}

- (UIButton *)selectedReactionButton {
    for (UIButton *button in self.reactionScrollView.subviews) {
        if (![button isKindOfClass:UIButton.class] || button.tag < 0 || button.tag >= self.reactions.count) {
            continue;
        }
        RCMessageReaction *reaction = self.reactions[button.tag];
        if ([reaction.reactionId isEqualToString:self.selectedReactionId]) {
            return button;
        }
    }
    return nil;
}

- (void)scrollSelectedReactionButtonToVisibleAnimated:(BOOL)animated {
    [self.contentView layoutIfNeeded];
    [self layoutReactionButtons];
    UIButton *button = [self selectedReactionButton];
    if (!button || CGRectIsEmpty(button.frame)) {
        return;
    }
    CGFloat viewportWidth = CGRectGetWidth(self.reactionScrollView.bounds);
    CGFloat maxOffsetX = MAX(self.reactionScrollView.contentSize.width - viewportWidth, 0);
    if (maxOffsetX <= 0) {
        return;
    }

    CGFloat currentOffsetX = self.reactionScrollView.contentOffset.x;
    CGFloat visibleMinX = currentOffsetX + RCMessageReactionDetailHorizontalInset;
    CGFloat visibleMaxX = currentOffsetX + viewportWidth - RCMessageReactionDetailHorizontalInset;
    CGFloat targetOffsetX = currentOffsetX;
    if (CGRectGetMinX(button.frame) < visibleMinX) {
        targetOffsetX = CGRectGetMinX(button.frame) - RCMessageReactionDetailHorizontalInset;
    } else if (CGRectGetMaxX(button.frame) > visibleMaxX) {
        targetOffsetX = CGRectGetMaxX(button.frame) + RCMessageReactionDetailHorizontalInset - viewportWidth;
    }
    targetOffsetX = MIN(MAX(targetOffsetX, 0), maxOffsetX);
    if (fabs(targetOffsetX - currentOffsetX) <= RCMessageReactionDetailHeightEpsilon) {
        return;
    }
    [self.reactionScrollView setContentOffset:CGPointMake(targetOffsetX, self.reactionScrollView.contentOffset.y)
                                     animated:animated];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.userItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RCMessageReactionDetailUserCell *cell = [tableView dequeueReusableCellWithIdentifier:RCMessageReactionDetailUserCellIdentifier forIndexPath:indexPath];
    RCMessageReactionDetailUserItem *item = self.userItems[indexPath.row];
    [cell updateWithItem:item];
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return RCMessageReactionDetailUserCellHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= self.userItems.count) {
        return;
    }
    RCMessageReactionUser *user = self.userItems[indexPath.row].user;
    RCMessageReaction *reaction = [self selectedReaction];
    if ([self.delegate respondsToSelector:@selector(messageReactionDetailView:didTapUser:reaction:)]) {
        [self.delegate messageReactionDetailView:self didTapUser:user reaction:reaction];
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView == self.tableView && [self shouldLockTableViewAtTop]) {
        [self lockTableViewAtTopIfNeeded];
    }
}

- (RCMessageReaction *)selectedReaction {
    for (RCMessageReaction *reaction in self.reactions) {
        if ([reaction.reactionId isEqualToString:self.selectedReactionId]) {
            return reaction;
        }
    }
    return self.reactions.firstObject;
}

#pragma mark - Load More

- (void)requestMoreUsersIfNeeded {
    if (self.loadingMoreUsers) {
        [self.tableView.rcmj_footer endRefreshing];
        return;
    }
    if (self.nextPageToken.length == 0) {
        [self.tableView.rcmj_footer endRefreshingWithNoMoreData];
        return;
    }
    RCMessageReaction *reaction = [self selectedReaction];
    if (![self.delegate respondsToSelector:@selector(messageReactionDetailView:didRequestMoreUsersForReaction:nextPageToken:)]) {
        [self.tableView.rcmj_footer endRefreshing];
        return;
    }
    self.loadingMoreUsers = YES;
    [self.delegate messageReactionDetailView:self didRequestMoreUsersForReaction:reaction nextPageToken:self.nextPageToken];
}

- (void)updateLoadMoreFooterState {
    if (self.nextPageToken.length > 0) {
        [self.tableView.rcmj_footer resetNoMoreData];
        [self.tableView.rcmj_footer endRefreshing];
    } else {
        [self.tableView.rcmj_footer endRefreshingWithNoMoreData];
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
    if (gestureRecognizer == self.backgroundTapGestureRecognizer) {
        return ![touch.view isDescendantOfView:self.contentView];
    }
    if (gestureRecognizer == self.panGestureRecognizer) {
        return YES;
    }
    return ![touch.view isDescendantOfView:self.tableView];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ((gestureRecognizer == self.panGestureRecognizer && otherGestureRecognizer == self.tableView.panGestureRecognizer) ||
        (gestureRecognizer == self.tableView.panGestureRecognizer && otherGestureRecognizer == self.panGestureRecognizer)) {
        return YES;
    }
    return NO;
}

#pragma mark - Getters

- (UIView *)contentView {
    if (!_contentView) {
        _contentView = [[UIView alloc] initWithFrame:CGRectZero];
        _contentView.backgroundColor = RCDynamicColor(@"message_reaction_detail_bg_color", @"0xffffff", @"0x1f2023");
    }
    return _contentView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.font = [UIFont systemFontOfSize:16];
        _titleLabel.textColor = RCDynamicColor(@"message_reaction_detail_title_color", @"0x111827", @"0xffffff");
        _titleLabel.text = RCLocalizedString(@"MessageReactionDetail");
    }
    return _titleLabel;
}

- (UIButton *)closeButton {
    if (!_closeButton) {
        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_closeButton setImage:RCResourceImage(@"close") forState:UIControlStateNormal];
        _closeButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        CGFloat imageInset = (RCMessageReactionDetailCloseButtonSize - RCMessageReactionDetailCloseImageSize) / 2.0;
        _closeButton.imageEdgeInsets = UIEdgeInsetsMake(imageInset, imageInset, imageInset, imageInset);
        [_closeButton addTarget:self action:@selector(onCloseButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeButton;
}

- (UIScrollView *)reactionScrollView {
    if (!_reactionScrollView) {
        _reactionScrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
        _reactionScrollView.backgroundColor = [UIColor clearColor];
        _reactionScrollView.showsHorizontalScrollIndicator = NO;
        _reactionScrollView.showsVerticalScrollIndicator = NO;
        _reactionScrollView.alwaysBounceHorizontal = YES;
    }
    return _reactionScrollView;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.separatorInset = UIEdgeInsetsMake(0, RCMessageReactionDetailHorizontalInset, 0, 0);
        _tableView.separatorColor = RCDynamicColor(@"message_reaction_detail_separator_color", @"0xE5E7EB", @"0x303136");
        _tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
        _tableView.showsVerticalScrollIndicator = YES;
        __weak typeof(self) weakSelf = self;
        RCMJRefreshAutoNormalFooter *footer = [RCMJRefreshAutoNormalFooter footerWithRefreshingBlock:^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf requestMoreUsersIfNeeded];
        }];
        footer.refreshingTitleHidden = YES;
        _tableView.rcmj_footer = footer;
        [_tableView registerClass:RCMessageReactionDetailUserCell.class forCellReuseIdentifier:RCMessageReactionDetailUserCellIdentifier];
    }
    return _tableView;
}

@end
