//
//  RCDownloadHelper.h
//  RongIMLib
//
//  Created by rongcloud on 2018/12/17.
//  Copyright © 2018 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RCDownloadHelper : NSObject

- (void)getDownloadFileToken:(int)fileType completeBlock:(void (^)(NSString *token))completion;

@end

NS_ASSUME_NONNULL_END
