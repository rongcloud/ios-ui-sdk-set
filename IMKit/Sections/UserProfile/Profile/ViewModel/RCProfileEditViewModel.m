//
//  RCNameEditViewModel.m
//  RongIMKit
//
//  Created by zgh on 2024/8/21.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCProfileEditViewModel.h"

@implementation RCProfileEditViewModel

- (void)updateMyProfileName:(NSString *)name success:(void (^)(void))successBlock error:(void (^)(RCErrorCode, NSString * _Nonnull))errorBlock {
    [[RCCoreClient sharedCoreClient] getMyUserProfile:^(RCUserProfile * _Nonnull userProfile) {
        [[RCCoreClient sharedCoreClient] updateMyUserProfile:self.userProfile success:^{
            
        } error:^(RCErrorCode errorCode, NSString * _Nullable errorKey) {
            
        }];
    } error:^(RCErrorCode errorCode) {
        
    }];
}

@end
