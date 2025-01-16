//
//  RCStickerHTTPRequestResult.h
//  RongSticker
//
//  Created by Zhaoqianyu on 2018/8/15.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, RCStickerRequestResultCode) {
    RCStickerRequestResultSuccess = 10000,
    RCStickerRequestResultFailure = -10001,
    RCStickerRequestResultUnknow = -10002,
};

@interface RCStickerHTTPRequestResult : NSObject

@property (nonatomic, assign) NSInteger httpCode;

// is success
@property (nonatomic, assign) BOOL success;

// request code
@property (nonatomic, assign) NSInteger code;

// request json
@property (nonatomic, strong) id data;

// error description
@property (nonatomic, strong) NSString *message;

@end
