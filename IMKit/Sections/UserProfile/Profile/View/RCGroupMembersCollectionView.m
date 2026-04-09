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
        self.backgroundColor = RCDynamicColor(@"common_background_color", @"0xffffff", @"0x1c1c1e66");
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

#pragma mark -- UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self.viewModel collectionView:collectionView didSelectItemAtIndexPath:indexPath];
}

@end
