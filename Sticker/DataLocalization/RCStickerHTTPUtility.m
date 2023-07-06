//
//  RCStickerHTTPUtility.m
//  RongSticker
//
//  Created by Zhaoqianyu on 2018/8/15.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import "RCStickerHTTPUtility.h"
#import "RCStickerNetworking.h"
#import "RCStickerUtility.h"
#import "RCStickerModule.h"

#ifdef DEBUG
//#define URLHost @"https://rcx-api-emoticon.rongcloud.net/"
#define URLHost @"https://stickerservice.ronghub.com/"
#else
#define URLHost @"https://stickerservice.ronghub.com/"
#endif
#define PackageConfigPrefix @"emoticonservice/emopkgs"
#define PackageZipPrefix @"emoticonservice/emopkgs/%@"
#define StickerPrefix @"emoticonservice/emopkgs/%@/stickers/%@"

@implementation RCStickerHTTPUtility

+ (void)syncAllPackagesConfig:(void (^)(RCStickerHTTPRequestResult *))completionHandle {

    NSString *fullURL = [URLHost stringByAppendingString:PackageConfigPrefix];
    [RCStickerNetworking
        requestWithMethod:RCStickerRequestMethodGet
                URLString:fullURL
                  headers:[self getHTTPHeaderDict]
               parameters:nil
        completionHandler:^(NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error) {
            if (error) {
                RongStickerLog(@"RCStickerHTTPUtility GET url is %@, error is %@", fullURL, error.localizedDescription);
            }
            RCStickerHTTPRequestResult *result = [[RCStickerHTTPRequestResult alloc] init];
            result.httpCode = ((NSHTTPURLResponse *)response).statusCode;
            NSDictionary *responseDict = [self dataConvertDict:data];
            result.success = NO;
            if (responseDict != nil) {
                result.code = [responseDict[@"code"] integerValue];
                result.data = responseDict[@"data"];
                result.message = responseDict[@"message"];
                if (result.code == 200) {
                    result.success = YES;
                } else {
                    RongStickerLog(@"RCStickerHTTPUtility GET url is %@, error is %@", fullURL, result.message);
                }
            }
            if (completionHandle) {
                completionHandle(result);
            }

        }];
}

+ (void)getPackageZipWith:(NSString *)packageId
         completionHandle:(void (^)(RCStickerHTTPRequestResult *))completionHandle {

    NSString *fullURL = [URLHost stringByAppendingString:[NSString stringWithFormat:PackageZipPrefix, packageId]];
    [RCStickerNetworking
        requestWithMethod:RCStickerRequestMethodGet
                URLString:fullURL
                  headers:[self getHTTPHeaderDict]
               parameters:nil
        completionHandler:^(NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error) {

            if (error) {
                RongStickerLog(@"RCStickerHTTPUtility GET url is %@, error is %@", fullURL, error.localizedDescription);
            }
            RCStickerHTTPRequestResult *result = [[RCStickerHTTPRequestResult alloc] init];
            result.httpCode = ((NSHTTPURLResponse *)response).statusCode;
            NSDictionary *responseDict = [self dataConvertDict:data];
            result.success = NO;
            if (responseDict != nil) {
                result.code = [responseDict[@"code"] integerValue];
                result.data = responseDict[@"data"];
                result.message = responseDict[@"message"];
                if (result.code == 200) {
                    result.success = YES;
                } else {
                    RongStickerLog(@"RCStickerHTTPUtility GET url is %@, error is %@", fullURL, result.message);
                }
            }
            if (completionHandle) {
                completionHandle(result);
            }

        }];
}

+ (void)getStickerWith:(NSString *)packageId
             stickerId:(NSString *)stickerId
      completionHandle:(void (^)(RCStickerHTTPRequestResult *))completionHandle {

    NSString *fullURL =
        [URLHost stringByAppendingString:[NSString stringWithFormat:StickerPrefix, packageId, stickerId]];
    [RCStickerNetworking
        requestWithMethod:RCStickerRequestMethodGet
                URLString:fullURL
                  headers:[self getHTTPHeaderDict]
               parameters:nil
        completionHandler:^(NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error) {

            if (error) {
                RongStickerLog(@"RCStickerHTTPUtility GET url is %@, error is %@", fullURL, error.localizedDescription);
            }
            RCStickerHTTPRequestResult *result = [[RCStickerHTTPRequestResult alloc] init];
            result.httpCode = ((NSHTTPURLResponse *)response).statusCode;
            NSDictionary *responseDict = [self dataConvertDict:data];
            result.success = NO;
            if (responseDict != nil) {
                result.code = [responseDict[@"code"] integerValue];
                result.data = responseDict[@"data"];
                result.message = responseDict[@"message"];
                if (result.code == 200) {
                    result.success = YES;
                } else {
                    RongStickerLog(@"RCStickerHTTPUtility GET url is %@, error is %@", fullURL, result.message);
                }
            }
            if (completionHandle) {
                completionHandle(result);
            }

        }];
}

+ (NSDictionary *)getHTTPHeaderDict {
    NSString *appKey = [RCStickerModule sharedModule].appKey;
    if (appKey.length == 0) {
        RongStickerLog(@"error: appKey 为空，请先初始化: [RCIM.sharedRCIM initWithAppKey:AppKey option:nil];!!!");
        return @{};
    }
    NSString *sha1AppKey = [RCStickerUtility sha1:appKey];
    int num = (arc4random() % 10000);
    NSString *nonce = [NSString stringWithFormat:@"%.4d", num];
    NSString *timestamp = [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970] * 1000];
    NSString *signature = [RCStickerUtility sha1:[NSString stringWithFormat:@"%@%@%@", sha1AppKey, nonce, timestamp]];
    NSDictionary *headerDict = @{
        @"AppKey" : appKey,
        @"Nonce" : nonce,
        @"Timestamp" : timestamp,
        @"Signature" : signature,
    };
    return headerDict;
}

+ (NSDictionary *)dataConvertDict:(NSData *)data {
    if (!data) {
        RongStickerLog(@"error: data is nil");
        return nil;
    }
    NSError *error;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    if (error) {
        RongStickerLog(@"NSData -> JSON error: %@", error.localizedDescription);
        return nil;
    }
    return dict;
}

@end
