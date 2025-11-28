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

+ (NSString *)localizedString:(NSString *)key table:(NSString *)table {
    
    NSString *language = [[NSLocale preferredLanguages] firstObject];
    if (language.length == 0) {
        return key;
    }
    NSString *fileNamePrefix = @"en";
    if([language hasPrefix:@"zh"]) {
        fileNamePrefix = @"zh-Hans";
    } else if ([language hasPrefix:@"ar"]) {
        fileNamePrefix = @"ar";
    }
    NSString *fullName = [NSString stringWithFormat:@"%@.strings", table];
  
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *path = [mainBundle pathForResource:fileNamePrefix ofType:@"lproj"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *filePath = [path stringByAppendingPathComponent:fullName];
    if (![fileManager fileExistsAtPath:filePath]) {
        NSBundle *frameworkBundle = [NSBundle bundleForClass:[self class]];
        path = [frameworkBundle pathForResource:fileNamePrefix ofType:@"lproj"];
    }
    
    NSBundle *bundle = [NSBundle bundleWithPath:path];
    NSString *localizedString = [bundle localizedStringForKey:key value:nil table:table];
    if (!localizedString) {
        localizedString = key;
    }
    return localizedString;
}


+ (UIImage *)imageNamed:(NSString *)name ofBundle:(NSString *)bundleName {
    UIImage *image = nil;
    NSString *image_name = name;
    if (![image_name hasSuffix:@".png"]) {
        image_name = [NSString stringWithFormat:@"%@.png", name];
    }
    
    NSString *bundlePath = nil;

    NSString *bundleNameString = [bundleName stringByDeletingPathExtension];
    NSURL *rootBundleURL = [[NSBundle mainBundle] URLForResource:bundleNameString withExtension:@"bundle"];
    if (rootBundleURL) {
        NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
        bundlePath = [resourcePath stringByAppendingPathComponent:bundleName];
    } else {
        NSBundle *innerBundle = [NSBundle bundleForClass:[self class]];
        NSString *resourcePath = [innerBundle resourcePath];
        bundlePath = [resourcePath stringByAppendingPathComponent:bundleName];
    }
    NSString *image_path = [bundlePath stringByAppendingPathComponent:image_name];
    image = [UIImage imageWithContentsOfFile:image_path];
    return image;
}

@end
