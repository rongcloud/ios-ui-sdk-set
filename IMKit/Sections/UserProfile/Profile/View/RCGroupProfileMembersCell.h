//
//  RCGroupProfileMembersCell.h
//  RongIMKit
//
//  Created by zgh on 2024/8/23.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCBaseTableViewCell.h"
#import "RCGroupMembersCollectionView.h"

UIKIT_EXTERN NSString  * _Nonnull const RCGroupProfileMembersCellIdentifier;

#define RCGroupProfileMembersCellTextTopSpace 9
#define RCGroupProfileMembersCellTextBottomSpace (RCGroupProfileMembersCellTextTopSpace * 2)

NS_ASSUME_NONNULL_BEGIN

@interface RCGroupProfileMembersCell : RCBaseTableViewCell

@property (nonatomic, strong) RCGroupMembersCollectionView *membersView;

@end

NS_ASSUME_NONNULL_END
