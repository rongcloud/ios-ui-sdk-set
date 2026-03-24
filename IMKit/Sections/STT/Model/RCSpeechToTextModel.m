//
//  RCSpeechToTextModel.m
//  RongIMKit
//
//  Created by RobinCui on 2025/6/25.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCSpeechToTextModel.h"

@interface RCSpeechToTextModel()
@property (nonatomic, strong, readwrite) RCSpeechToTextInfo *sttInfo;

@end

@implementation RCSpeechToTextModel
- (instancetype)initWithSTTInfo:(RCSpeechToTextInfo *)info
{
    self = [super init];
    if (self) {
        self.sttInfo = info;
        self.status = info.status;
        self.isVisible = info.isVisible;
    }
    return self;
}

- (void)synchronizeSTTInfo:(RCSpeechToTextInfo *)info {
    self.sttInfo = info;
    self.status = info.status;
}
@end
