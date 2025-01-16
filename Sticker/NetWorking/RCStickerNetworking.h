//
//  RCStickerNetworking.h
//  RongSticker
//
//  Created by Zhaoqianyu on 2018/8/3.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, RCStickerRequestMethod) {
    RCStickerRequestMethodGet = 1,
    RCStickerRequestMethodPost = 2,
    RCStickerRequestMethodHead = 3,
    RCStickerRequestMethodPut = 4,
    RCStickerRequestMethodDelete = 5
};

/**
 Net working class
 */
@interface RCStickerNetworking : NSObject

+ (void)requestWithMethod:(RCStickerRequestMethod)method
                URLString:(NSString *_Nullable)URLString
                  headers:(NSDictionary *_Nullable)headers
               parameters:(NSDictionary *_Nullable)parameters
        completionHandler:(void (^_Nullable)(NSData *_Nullable data, NSURLResponse *_Nullable response,
                                             NSError *_Nullable error))completionHandler;

+ (void)downloadWithURLString:(NSString *_Nullable)URLString
                saveLocalPath:(NSString *_Nullable)saveLocalPath
            completionHandler:(void (^_Nullable)(NSURL *_Nullable location, NSURLResponse *_Nullable response,
                                                 NSError *_Nullable error))completionHandler;

@end
