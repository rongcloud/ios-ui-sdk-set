//
//  RCStickerUtility.m
//  RongSticker
//
//  Created by Zhaoqianyu on 2018/8/9.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import "RCStickerUtility.h"
#import <CommonCrypto/CommonDigest.h>
#import "RongStickerAdaptiveHeader.h"
@implementation RCStickerUtility

+ (NSString *)sha1:(NSString *)input {
    NSData *data = [input dataUsingEncoding:NSUTF8StringEncoding];
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(data.bytes, (unsigned int)data.length, digest);
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    return output;
}

+ (UIColor *)generateDynamicColor:(UIColor *)lightColor darkColor:(UIColor *)darkColor {
    return [RCKitUtility generateDynamicColor:lightColor darkColor:darkColor];
}

+ (NSURLSessionConfiguration *)rcSessionConfiguration {
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    RCIMProxy *currentProxy = [[RCCoreClient sharedCoreClient] getCurrentProxy];
    
    if (currentProxy && [currentProxy isValid]) {
        NSString *proxyHost = currentProxy.host;
        NSNumber *proxyPort = @(currentProxy.port);
        NSString *proxyUserName = currentProxy.userName;
        NSString *proxyPassword = currentProxy.password;

        NSDictionary *proxyDict = @{
            (NSString *)kCFStreamPropertySOCKSProxyHost: proxyHost,
            (NSString *)kCFStreamPropertySOCKSProxyPort: proxyPort,
            (NSString *)kCFStreamPropertySOCKSUser : proxyUserName,
            (NSString *)kCFStreamPropertySOCKSPassword: proxyPassword
        };

        sessionConfiguration.connectionProxyDictionary = proxyDict;
    }
    return sessionConfiguration;
}

@end
