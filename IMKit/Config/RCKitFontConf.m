//
//  RCKitFontConf.m
//  RongIMKit
//
//  Created by Sin on 2020/6/23.
//  Copyright © 2020 RongCloud. All rights reserved.
//

#import "RCKitFontConf.h"

@implementation RCKitFontConf
- (instancetype)init{
    self = [super init];
    if (self) {
        self.firstLevel = 18;
        self.secondLevel = 17;
        self.thirdLevel = 15;
        self.fourthLevel = 14;
        self.guideLevel = 13;
        self.annotationLevel = 12;
        self.assistantLevel = 10;
    }
    return self;
}

- (UIFont *)fontOfFirstLevel {
    return [self fontOfSize:self.firstLevel];
}

- (UIFont *)fontOfSecondLevel {
    return [self fontOfSize:self.secondLevel];
}

- (UIFont *)fontOfThirdLevel {
    return [self fontOfSize:self.thirdLevel];
}

- (UIFont *)fontOfFourthLevel {
    return [self fontOfSize:self.fourthLevel];
}

- (UIFont *)fontOfGuideLevel {
    return [self fontOfSize:self.guideLevel];
}

- (UIFont *)fontOfAnnotationLevel {
    return [self fontOfSize:self.annotationLevel];
}

- (UIFont *)fontOfAssistantLevel {
    return [self fontOfSize:self.assistantLevel];
}

- (UIFont *)fontOfSize:(CGFloat)size {
    return [UIFont systemFontOfSize:size];
}
@end
