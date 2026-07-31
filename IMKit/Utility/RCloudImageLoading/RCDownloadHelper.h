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

- (void)getDownloadFileToken:(int)fileType
                    queryUrl:(NSString *)queryUrl
               completeBlock:(void (^)(NSString *_Nullable token, NSString *_Nullable authInfo))completion;

+ (void)handleRequest:(NSMutableURLRequest *)request
                token:(nullable NSString *)token
             authInfo:(nullable NSString *)authInfo;

+ (NSString *)getMinioOSSAddr;

@end

NS_ASSUME_NONNULL_END
