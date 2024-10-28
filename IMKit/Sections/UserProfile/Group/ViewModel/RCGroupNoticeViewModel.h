//
//  RCGroupNoticeViewModel.h
//  RongIMKit
//
//  Created by zgh on 2024/8/28.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCBaseViewModel.h"
#import <RongIMLibCore/RongIMLibCore.h>
NS_ASSUME_NONNULL_BEGIN

@interface RCGroupNoticeViewModel : RCBaseViewModel

@property (nonatomic, strong, readonly) RCGroupInfo *group;

@property (nonatomic, assign, readonly) BOOL canEdit;

@property (nonatomic, assign, readonly) NSInteger limit;


- (instancetype)initWithGroup:(RCGroupInfo *)group canEdit:(BOOL)canEdit;

- (void)updateNotice:(NSString *)notice inViewController:(UIViewController *)viewController;

- (NSString *)tip;

@end

NS_ASSUME_NONNULL_END
