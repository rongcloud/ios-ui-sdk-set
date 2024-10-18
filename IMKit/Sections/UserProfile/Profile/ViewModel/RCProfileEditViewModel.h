//
//  RCNameEditViewModel.h
//  RongIMKit
//
//  Created by zgh on 2024/8/21.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCUBaseViewModel.h"
#import <RongIMLibCore/RongIMLibCore.h>
NS_ASSUME_NONNULL_BEGIN

@interface RCProfileEditViewModel : RCUBaseViewModel

@property (nonatomic, strong) RCUserProfile *userProfile;

- (void)updateMyProfileName:(NSString *)name
                    success:(void (^)(void))successBlock
                      error:(void (^)(RCErrorCode code, NSString *errorKey))errorBlock;
@end

NS_ASSUME_NONNULL_END
