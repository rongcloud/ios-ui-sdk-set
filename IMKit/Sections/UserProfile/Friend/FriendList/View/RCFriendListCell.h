//
//  RCFriendListCell.h
//  RongIMKit
//
//  Created by RobinCui on 2024/8/20.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCFriendListPermanentCell.h"
UIKIT_EXTERN NSString * _Nullable const RCFriendListCellIdentifier;

NS_ASSUME_NONNULL_BEGIN

@interface RCFriendListCell : RCFriendListPermanentCell
- (void)showPortrait:(NSString *)url;
@end

NS_ASSUME_NONNULL_END
