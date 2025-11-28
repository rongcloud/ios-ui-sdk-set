//
//  RCStreamViewModelProtocol.h
//  RongIMKit
//
//  Created by zgh on 2025/3/5.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol RCStreamViewModelProtocol <NSObject>

- (CGSize)calculateContentSize;

- (void)streamContentDidUpdate:(NSString *)content;

@end

NS_ASSUME_NONNULL_END
