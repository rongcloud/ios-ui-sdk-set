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
    self.contentView.backgroundColor = [RCKitUtility generateDynamicColor:HEXCOLOR(0xffffff)
                                                            darkColor:[HEXCOLOR(0x1c1c1e) colorWithAlphaComponent:0.4]];
    [self.contentView addSubview:self.membersView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.membersView.frame = CGRectMake(0, RCGroupProfileMembersCellTextTopSpace, self.frame.size.width, self.frame.size.height - RCGroupProfileMembersCellTextTopSpace - RCGroupProfileMembersCellTextBottomSpace);
}

#pragma mark -- getter

- (RCGroupMembersCollectionView *)membersView {
    if (!_membersView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        _membersView = [[RCGroupMembersCollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    }
    return _membersView;
}

@end
