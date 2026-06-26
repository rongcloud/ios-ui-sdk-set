//
//  RCForwardKeyItem.h
//  RongIMKit
//
//  Created by RobinCui on 2022/12/9.
//  Copyright © 2022 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RCForwardKeyItem : NSObject
@property(nonatomic, copy) NSString *title;
@property(nonatomic, copy) NSString *htmlKey;
- (instancetype)initWithTitle:(NSString *)title key:(NSString *)key;
@end

NS_ASSUME_NONNULL_END
