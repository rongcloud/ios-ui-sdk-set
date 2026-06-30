//
//  RCMessageCellReferenceContentViewRegistry.m
//  RongIMKit
//
//  Created by RongCloud on 2026/6/25.
//  Copyright © 2026 RongCloud. All rights reserved.
//

#import "RCMessageCellReferenceContentViewRegistry.h"

@implementation RCMessageCellReferenceContentViewRegistry

+ (NSMutableDictionary<NSString *, Class> *)contentViewClassDict {
    static NSMutableDictionary<NSString *, Class> *dict = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dict = [NSMutableDictionary dictionary];
    });
    return dict;
}

+ (void)registerContentViewClass:(Class)viewClass forMessageClass:(Class)messageClass {
    if (!viewClass || !messageClass) {
        return;
    }
    if (![viewClass isSubclassOfClass:RCMessageCellReferenceContentView.class]) {
        return;
    }
    if (![messageClass isSubclassOfClass:RCMessageContent.class]) {
        return;
    }
    NSString *objectName = [messageClass getObjectName];
    if (objectName.length <= 0) {
        return;
    }
    [[self contentViewClassDict] setObject:viewClass forKey:objectName];
}

+ (Class)contentViewClassForObjectName:(NSString *)objectName {
    if (objectName.length <= 0) {
        return nil;
    }
    return [[self contentViewClassDict] objectForKey:objectName];
}

+ (Class)contentViewClassForMessageContent:(RCMessageContent *)content objectName:(NSString *)objectName {
    Class viewClass = [self contentViewClassForObjectName:objectName];
    if (viewClass) {
        return viewClass;
    }
    NSString *contentObjectName = [[content class] getObjectName];
    return [self contentViewClassForObjectName:contentObjectName];
}

@end
