//
//  RCIFlySpeechRecognizerManager.m
//  RongiFlyKit
//
//  Created by zhangke on 2018/11/12.
//  Copyright © 2018 Sin. All rights reserved.
//

#import "RCIFlySpeechRecognizerManager.h"
#import <iflyMSC/iflyMSC.h>

@interface RCIFlySpeechRecognizerManager () <IFlySpeechRecognizerDelegate>

@property (nonatomic, retain) IFlySpeechRecognizer *iFlySpeechRecognizer;
@property (nonatomic, retain) NSMutableString *resultString;
@property (nonatomic, copy) void (^convertCallback)(NSDictionary *result);

@end
@implementation RCIFlySpeechRecognizerManager
+ (RCIFlySpeechRecognizerManager *)speechRecognizerSharedManager {
    static RCIFlySpeechRecognizerManager *iflyManager = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        if (iflyManager == nil) {
            iflyManager = [[[self class] alloc] init];
        }
    });
    return iflyManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.resultString = [NSMutableString new];
        self.iFlySpeechRecognizer = [IFlySpeechRecognizer sharedInstance];
        self.iFlySpeechRecognizer.delegate = self;
    }
    return self;
}
- (BOOL)isFlyRecognitioning {
    return self.iFlySpeechRecognizer.isListening;
}

- (void)recognitionSpeech:(NSData *)data Result:(void (^)(NSDictionary *result))recognitionResultBlock {
    [self.iFlySpeechRecognizer setParameter:@"-1" forKey:@"audio_source"];
    [self.iFlySpeechRecognizer setParameter:@"8000" forKey:@"sample_rate"];
    [self.iFlySpeechRecognizer startListening];
    [self.iFlySpeechRecognizer writeAudio:data];
    [self.iFlySpeechRecognizer stopListening];

    //音频写入结束或出错时，必须调用结束识别接口
    self.convertCallback = recognitionResultBlock;
}

- (void)onError:(IFlySpeechError *)errorCode {
    NSLog(@"%s,zhangke:iflyerrorCode:%d,%@,%@", __func__, errorCode.errorCode, errorCode.errorDesc, self.resultString);
    [self.iFlySpeechRecognizer stopListening];
    dispatch_after(1.0, dispatch_get_main_queue(), ^{
        if (errorCode.errorCode != 0) {
            //识别失败
            if (self.convertCallback) {
                self.convertCallback(
                    @{ @"success" : @(0),
                       @"content" : @"",
                       @"errorCode" : @(101),
                       @"message" : @"识别失败" });
            }
        } else {
            //识别成功
            if (self.convertCallback) {
                if (self.resultString.length == 0) {
                    self.convertCallback(
                        @{ @"success" : @(0),
                           @"content" : @"",
                           @"errorCode" : @(101),
                           @"message" : @"识别失败" });
                    self.resultString = [NSMutableString new];
                } else {
                    self.convertCallback(
                        @{ @"success" : @(1),
                           @"content" : self.resultString,
                           @"message" : @"识别失败" });
                    self.resultString = [NSMutableString new];
                }
            }
        }
    });
}
#pragma - mark IFlySpeechRecognizerDelegate
- (void)onResults:(NSArray *)results isLast:(BOOL)isLast {
    NSMutableString *resultString = [[NSMutableString alloc] init];
    NSDictionary *dic = results[0];
    for (NSString *key in dic) {
        [resultString appendFormat:@"%@", key];
    }
    NSString *resultFromJson = [self stringFromJson:resultString];
    [_resultString appendString:resultFromJson];
    if (isLast) {
        [self.iFlySpeechRecognizer stopListening];
    }
}
//获取每次识别之后的结果
- (NSString *)stringFromJson:(NSString *)params {
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
