//
//  RCGroupMembersCollectionView.m
//  RongIMKit
//
//  Created by zgh on 2024/8/23.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCKitUtility.h"
#import "RCKitCommonDefine.h"

#import "RCGroupMembersCollectionView.h"
@interface RCGroupMembersCollectionView ()<UICollectionViewDataSource, UICollectionViewDelegate, RCCollectionViewModelResponder>

@property (nonatomic, strong) RCGroupMembersCollectionViewModel *viewModel;

@end

@implementation RCGroupMembersCollectionView

- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout {
    self = [super initWithFrame:frame collectionViewLayout:layout];
    if (self) {
        self.delegate = self;
        self.dataSource = self;
        self.backgroundColor = [RCKitUtility generateDynamicColor:HEXCOLOR(0xffffff)
                                                                darkColor:[HEXCOLOR(0x1c1c1e) colorWithAlphaComponent:0.4]];
        [RCGroupMembersCollectionViewModel registerCollectionViewCell:self];
    }
    return self;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self reloadData];
}

- (void)configViewModel:(RCGroupMembersCollectionViewModel *)viewModel {
    if (!viewModel) {
        return;
    }
    self.viewModel = viewModel;
    self.viewModel.responder = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self reloadData];
    });
}

#pragma mark -- RCCollectionViewModelResponder

- (void)reloadCollectionViewData {
    [self reloadData];
}

#pragma mark -- UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.viewModel numberOfItemsInSection:section]; // 每个section有10个item
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self.viewModel collectionView:collectionView cellForItemAtIndexPath:indexPath];
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)collectionViewLayout;
    layout.itemSize = CGSizeMake(RCGroupMembersCollectionViewModelItemWidth, RCGroupMembersCollectionViewModelItemHeight); // 每个item的大小
    layout.minimumLineSpacing = RCGroupMembersCollectionViewModelLineSpace;
    layout.minimumInteritemSpacing = (collectionView.frame.size.width - 5 * layout.itemSize.width - RCGroupMembersCollectionViewModelLineSpace * 2)/4;
    return UIEdgeInsetsMake(0, RCGroupMembersCollectionViewModelLineSpace, 0, RCGroupMembersCollectionViewModelLineSpace);
}

#pragma mark -- UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self.viewModel collectionView:collectionView didSelectItemAtIndexPath:indexPath];
}

@end
