//
//  RCSightModel.h
//  RongIMKit
//
//  Created by 张改红 on 2021/5/8.
//  Copyright © 2021 RongCloud. All rights reserved.
//

#if __has_include(<RongIMKit/RongIMKit.h>)

#import <RongIMKit/RongIMKit.h>

#else

#import "RongIMKit.h"

#endif

@interface RCSightModel : NSObject

@property (nonatomic, strong) RCMessage *message;

- (instancetype)initWithMessage:(RCMessage *)rcMessage;
@end

