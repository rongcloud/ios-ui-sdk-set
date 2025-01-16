//
//  RCStickerNetworking.m
//  RongSticker
//
//  Created by Zhaoqianyu on 2018/8/3.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import "RCStickerNetworking.h"
#import "RCStickerUtility.h"

NSInteger const timeoutInterval = 30;

@implementation RCStickerNetworking

+ (void)requestWithMethod:(RCStickerRequestMethod)method
                URLString:(NSString *)URLString
                  headers:(NSDictionary *)headers
               parameters:(NSDictionary *)parameters
        completionHandler:(void (^)(NSData *_Nullable data, NSURLResponse *_Nullable response,
                                    NSError *_Nullable error))completionHandler {
    switch (method) {
    case RCStickerRequestMethodGet:
        [self getWithURLString:URLString headers:headers parameters:parameters completionHandler:completionHandler];
        break;
    case RCStickerRequestMethodPost:
        [self postWithURLString:URLString headers:headers parameters:parameters completionHandler:completionHandler];
        break;
    default:
        break;
    }
}

+ (void)getWithURLString:(NSString *)URLString
                 headers:(NSDictionary *)headers
              parameters:(NSDictionary *)parameters
       completionHandler:(void (^)(NSData *_Nullable data, NSURLResponse *_Nullable response,
                                   NSError *_Nullable error))completionHandler {
    NSString *urlString = [NSString string];
    if (parameters && parameters.allKeys.count > 0) {
        NSString *paramStr = [self dealWithParam:parameters];
        urlString = [URLString stringByAppendingString:paramStr];
    } else {
        urlString = URLString;
    }
    NSString *pathStr =
        [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:pathStr]];
    [request setHTTPMethod:@"GET"];
    for (NSString *headerKey in headers.allKeys) {
        [request setValue:headers[headerKey] forHTTPHeaderField:headerKey];
    }
    request.timeoutInterval = timeoutInterval;

    NSURLSessionDataTask *task = [[NSURLSession sessionWithConfiguration:[RCStickerUtility rcSessionConfiguration]]
        dataTaskWithRequest:request
          completionHandler:^(NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error) {
              if (completionHandler) {
                  completionHandler(data, response, error);
              }
          }];

    [task resume];
}

+ (void)postWithURLString:(NSString *)URLString
                  headers:(NSDictionary *)headers
               parameters:(NSDictionary *)parameters
        completionHandler:(void (^)(NSData *_Nullable data, NSURLResponse *_Nullable response,
                                    NSError *_Nullable error))completionHandler {

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:URLString]];
    [request setHTTPMethod:@"POST"];

    if (parameters.allKeys.count > 0) {
        NSString *body = [self dealWithParam:parameters];
        NSData *bodyData = [body dataUsingEncoding:NSUTF8StringEncoding];
        [request setHTTPBody:bodyData];
    }

    for (NSString *headerKey in headers.allKeys) {
        [request setValue:headers[headerKey] forHTTPHeaderField:headerKey];
    }
    request.timeoutInterval = timeoutInterval;

    NSURLSessionTask *task = [[NSURLSession sessionWithConfiguration:[RCStickerUtility rcSessionConfiguration]]
        dataTaskWithRequest:request
          completionHandler:^(NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error) {
              if (completionHandler) {
                  completionHandler(data, response, error);
              }
          }];
    [task resume];
}

+ (void)downloadWithURLString:(NSString *)URLString
                saveLocalPath:(NSString *)saveLocalPath
            completionHandler:(void (^)(NSURL *_Nullable location, NSURLResponse *_Nullable response,
                                        NSError *_Nullable error))completionHandler {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:URLString]];
    request.timeoutInterval = timeoutInterval;
    NSURLSessionTask *task = [[NSURLSession sessionWithConfiguration:[RCStickerUtility rcSessionConfiguration]]
        downloadTaskWithRequest:request
              completionHandler:^(NSURL *_Nullable location, NSURLResponse *_Nullable response,
                                  NSError *_Nullable error) {
                  if (completionHandler) {
                      completionHandler(location, response, error);
                  }
              }];
    [task resume];
}

+ (NSString *)dealWithParam:(NSDictionary *)param {
    NSArray *allkeys = [param allKeys];
    NSMutableString *result = [NSMutableString string];

    for (NSString *key in allkeys) {
        NSString *string = [NSString stringWithFormat:@"%@=%@&", key, param[key]];
        [result appendString:string];
    }
    return result;
}

@end
