//
//  RCISRDataHelper.m
//  RongiFlyKit
//
//  Created by ypzhao on 12-11-19.
//  Copyright (c) 2012年 iflytek. All rights reserved.
//

#import "RCISRDataHelper.h"

@implementation RCISRDataHelper

/**
 解析听写json格式的数据
 params例如：
 {"sn":1,"ls":true,"bg":0,"ed":0,"ws":[{"bg":0,"cw":[{"w":"白日","sc":0}]},{"bg":0,"cw":[{"w":"依山","sc":0}]},{"bg":0,"cw":[{"w":"尽","sc":0}]},{"bg":0,"cw":[{"w":"黄河入海流","sc":0}]},{"bg":0,"cw":[{"w":"。","sc":0}]}]}
 ****/
+ (NSString *)stringFromJson:(NSString *)params {
    if (params == NULL) {
        return nil;
    }

    NSMutableString *tempStr = [[NSMutableString alloc] init];
    NSDictionary *resultDic = [NSJSONSerialization JSONObjectWithData: //返回的格式必须为utf8的,否则发生未知错误
                                                       [params dataUsingEncoding:NSUTF8StringEncoding]
                                                              options:kNilOptions
                                                                error:nil];

    if (resultDic != nil) {
        NSArray *wordArray = [resultDic objectForKey:@"ws"];

        for (int i = 0; i < [wordArray count]; i++) {
            NSDictionary *wsDic = [wordArray objectAtIndex:i];
            NSArray *cwArray = [wsDic objectForKey:@"cw"];

            for (int j = 0; j < [cwArray count]; j++) {
                NSDictionary *wDic = [cwArray objectAtIndex:j];
                NSString *str = [wDic objectForKey:@"w"];
                [tempStr appendString:str];
            }
        }
    }
    return tempStr;
}

@end
