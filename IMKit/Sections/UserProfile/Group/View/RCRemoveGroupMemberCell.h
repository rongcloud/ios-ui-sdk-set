//
//  RCSelectGroupMemberCell.h
//  RongIMKit
//
//  Created by zgh on 2024/8/27.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCSelectUserCell.h"

UIKIT_EXTERN NSString  * _Nonnull const RCRemoveGroupMemberCellIdentifier;


NS_ASSUME_NONNULL_BEGIN

@interface RCRemoveGroupMemberCell : RCSelectUserCell

@property (nonatomic, strong) UILabel *roleLabel;

@end

NS_ASSUME_NONNULL_END
