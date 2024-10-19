//
//  RCGroupMembersCollectionView.h
//  RongIMKit
//
//  Created by zgh on 2024/8/23.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCBaseCollectionView.h"
#import "RCGroupMembersCollectionViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface RCGroupMembersCollectionView : RCBaseCollectionView

- (void)configViewModel:(RCGroupMembersCollectionViewModel *)viewModel;

@end

NS_ASSUME_NONNULL_END
