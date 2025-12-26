//
//  RCGroupProfileMembersCell.m
//  RongIMKit
//
//  Created by zgh on 2024/8/23.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCGroupProfileMembersCell.h"
#import "RCKitCommonDefine.h"

NSString  * const RCGroupProfileMembersCellIdentifier = @"RCGroupProfileMembersCellIdentifier";


@implementation RCGroupProfileMembersCell

- (void)setupView {
    [super setupView];
    [self.paddingContainerView addSubview:self.membersView];
}

- (void)setupConstraints {
    [super setupConstraints];
    [NSLayoutConstraint activateConstraints:@[
           [self.membersView.leadingAnchor constraintEqualToAnchor:self.paddingContainerView.leadingAnchor],
           [self.membersView.trailingAnchor constraintEqualToAnchor:self.paddingContainerView.trailingAnchor],
           [self.membersView.topAnchor constraintEqualToAnchor:self.paddingContainerView.topAnchor constant:RCGroupProfileMembersCellTextTopSpace],
           [self.membersView.bottomAnchor constraintEqualToAnchor:self.paddingContainerView.bottomAnchor]
       ]];
}

#pragma mark -- getter

- (RCGroupMembersCollectionView *)membersView {
    if (!_membersView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.itemSize = CGSizeMake(RCGroupMembersCollectionViewModelItemWidth, RCGroupMembersCollectionViewModelItemHeight); // 每个item的大小
        layout.minimumLineSpacing = RCGroupMembersCollectionViewModelLineSpace;
        layout.sectionInset = UIEdgeInsetsMake(0, RCGroupMembersCollectionViewModelLineSpace, 0, RCGroupMembersCollectionViewModelLineSpace);
        CGFloat width = [UIScreen mainScreen].bounds.size.width;
        CGFloat padding = (width-32 - 5 * layout.itemSize.width - RCGroupMembersCollectionViewModelLineSpace * 2)/4;
        if (padding<0) { // 如果屏幕宽度无法满足布局, 则压缩宽度
            CGFloat newWidth = RCGroupMembersCollectionViewModelItemWidth - (5*4-padding)/5;
            if (newWidth !=0) {
                layout.itemSize = CGSizeMake(newWidth, RCGroupMembersCollectionViewModelItemHeight);
            }
            padding = 5;
        }
        layout.minimumInteritemSpacing = padding;
        _membersView = [[RCGroupMembersCollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _membersView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _membersView;
}

@end
