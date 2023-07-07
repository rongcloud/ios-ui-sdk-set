//
//  RCEmojiBottomTab.m
//  RongIMKit
//
//  Created by 张改红 on 2020/7/9.
//  Copyright © 2020 RongCloud. All rights reserved.
//

#import "RCEmojiTabView.h"
#import "RCKitCommonDefine.h"
#import "RCKitConfig.h"
#define RCEmotionCollectCellIdentifier @"RCEmotionCollectCell"
@interface RCEmojiTabView()<UICollectionViewDelegate,UICollectionViewDataSource>
@property (nonatomic, assign) BOOL showAddButton;
@property (nonatomic, assign) BOOL showSettingButton;
@property (nonatomic, strong) UIButton *addBtn;
@property (nonatomic, strong) UIButton *settingBtn;
@property (nonatomic, strong) UIButton *sendBtn;
@property (nonatomic, strong) UICollectionView *emotionsListView;
@property (nonatomic, strong) NSArray *emotionsListData;
@property (nonatomic, assign) int currentIndex;
@end
@implementation RCEmojiTabView
- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {;
        [self setupSubViews];
    }
    return self;
}

- (void)setFrame:(CGRect)frame{
    [super setFrame:frame];
    [self updateSubViewFrame];
}

- (void)showAddButton:(BOOL)showAddButton showSettingButton:(BOOL)showSettingButton{
    self.showAddButton = showAddButton;
    self.showSettingButton = showSettingButton;
    if (self.showAddButton) {
        [self addSubview:self.addBtn];
    }
    if (self.showSettingButton) {
        [self addSubview:self.settingBtn];
    }
    [self updateSubViewFrame];
}

- (void)reloadTabView:(NSArray *)emotionsListData{
    self.emotionsListData = emotionsListData;
    [self.emotionsListView reloadData];
}

- (void)showEmotion:(int)index{
    int beforeIndex = self.currentIndex;
    if (beforeIndex != index ) {
        self.currentIndex = index;
        NSMutableArray *reloadIndexPaths = [NSMutableArray array];
        if (index < self.emotionsListData.count) {
            [reloadIndexPaths addObject:[NSIndexPath indexPathForRow:index inSection:0]];
        }
        if (beforeIndex < self.emotionsListData.count) {
            [reloadIndexPaths addObject:[NSIndexPath indexPathForRow:beforeIndex inSection:0]];
        }
        [self.emotionsListView reloadItemsAtIndexPaths:reloadIndexPaths.copy];
        [self updateSendAndSettingStatus];
    }
}

#pragma mark - UICollectionViewDelegate && UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.emotionsListData.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:RCEmotionCollectCellIdentifier
                                                                           forIndexPath:indexPath];
    for (UIView *view in cell.contentView.subviews) {
        [view removeFromSuperview];
    }
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(12, 8, cell.contentView.frame.size.width-24, cell.contentView.frame.size.height-16)];
    imageView.image = self.emotionsListData[indexPath.row];
    [cell.contentView addSubview:imageView];
    
    if (self.currentIndex == indexPath.row) {
        cell.contentView.backgroundColor = RCDYCOLOR(0xf5f6f9, 0x1c1c1c);
    }else{
        cell.contentView.backgroundColor = [UIColor clearColor];
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    [self showEmotion:(int)indexPath.row];
    if (self.delegate && [self.delegate respondsToSelector:@selector(emojiTabView:didSelectEmotion:)]) {
        [self.delegate emojiTabView:self didSelectEmotion:(int)indexPath.row];
    }
}

#pragma mark - Target Action
- (void)sendBtnHandle:(UIButton *)button{
    if (self.delegate && [self.delegate respondsToSelector:@selector(emojiTabView:didSelectEmotion:)]) {
        [self.delegate emojiTabView:self didClickSendButton:button];
    }
}

- (void)addBtnHandle:(UIButton *)button{
    if (self.delegate && [self.delegate respondsToSelector:@selector(emojiTabView:didClickAddButton:)]) {
        [self.delegate emojiTabView:self didClickAddButton:button];
    }
}

- (void)settingBtnHandle:(UIButton *)button{
    if (self.delegate && [self.delegate respondsToSelector:@selector(emojiTabView:didClickSettingButton:)]) {
        [self.delegate emojiTabView:self didClickSettingButton:button];
    }
}

#pragma mark - Privite

- (void)updateSendAndSettingStatus{
    if (self.currentIndex > 0) {
        [self.settingBtn setHidden:NO];
        [self.sendBtn setHidden:YES];
    }else{
        [self.settingBtn setHidden:YES];
        [self.sendBtn setHidden:NO];
    }
}

- (void)setupSubViews{
    [self addSubview:self.sendBtn];
    [self addSubview:self.emotionsListView];
    [self updateSubViewFrame];
}

- (void)updateSubViewFrame{
    [UIView animateWithDuration:0.1 animations:^{
        if ([RCKitUtility isRTL]) {
            self.sendBtn.frame = CGRectMake(0, 0, 52, 38);
            if (self.showAddButton) {
                self.addBtn.frame = CGRectMake(self.frame.size.width - 28 - 9, 5, 28, 28);
            }
            if (self.showSettingButton) {
                self.settingBtn.frame = CGRectMake(7, 4, 31, 31);
            }
            CGFloat emotionsListViewX = self.showAddButton?28:0;
            self.emotionsListView.frame = CGRectMake(self.sendBtn.frame.size.width, 0, self.frame.size.width-emotionsListViewX-self.sendBtn.frame.size.width, self.frame.size.height);
        } else {
            self.sendBtn.frame = CGRectMake(self.frame.size.width - 52, 0, 52, 38);
            if (self.showAddButton) {
                self.addBtn.frame = CGRectMake(9, 5, 28, 28);
            }
            if (self.showSettingButton) {
                self.settingBtn.frame = CGRectMake(self.frame.size.width - 38, 4, 31, 31);
            }
            CGFloat emotionsListViewX = self.showAddButton?CGRectGetMaxX(self.addBtn.frame):0;
            self.emotionsListView.frame = CGRectMake(emotionsListViewX, 0, self.frame.size.width-emotionsListViewX-self.sendBtn.frame.size.width, self.frame.size.height);
        }
    }];
}

#pragma mark - Getter
- (UIButton *)sendBtn{
    if (!_sendBtn) {
        _sendBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _sendBtn.tag = 333;
        _sendBtn.titleLabel.font = [[RCKitConfig defaultConfig].font fontOfFourthLevel];
        [_sendBtn setTitle:RCLocalizedString(@"Send") forState:UIControlStateNormal];
        [_sendBtn addTarget:self action:@selector(sendBtnHandle:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _sendBtn;
}

- (UIButton *)addBtn{
    if (!_addBtn) {
        _addBtn = [[UIButton alloc] initWithFrame:CGRectZero];
        [_addBtn setImage:RCResourceImage(@"add") forState:UIControlStateNormal];
        [_addBtn addTarget:self action:@selector(addBtnHandle:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _addBtn;
}

- (UIButton *)settingBtn{
    if (!_settingBtn) {
        _settingBtn = [[UIButton alloc] init];
        [_settingBtn setImage:RCResourceImage(@"rc_setting") forState:UIControlStateNormal];
        [_settingBtn addTarget:self
                            action:@selector(settingBtnHandle:)
                  forControlEvents:UIControlEventTouchUpInside];
        _settingBtn.hidden = YES;
    }
    return _settingBtn;
}

- (UICollectionView *)emotionsListView{
    if (!_emotionsListView) {
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        flowLayout.itemSize = CGSizeMake(46, self.frame.size.height);
        flowLayout.minimumLineSpacing = 0;
        _emotionsListView =
            [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
        _emotionsListView.delegate = self;
        _emotionsListView.dataSource = self;
        _emotionsListView.scrollEnabled = YES;
        _emotionsListView.backgroundColor = RCDYCOLOR(0xffffff, 0x000000);
        [_emotionsListView registerClass:[UICollectionViewCell class]
                         forCellWithReuseIdentifier:RCEmotionCollectCellIdentifier];
    }
    return _emotionsListView;
}
@end
