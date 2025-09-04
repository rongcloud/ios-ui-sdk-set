//
//  RCStreamContentViewModel.m
//  RongIMKit
//
//  Created by zgh on 2025/3/5.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCStreamContentViewModel.h"
#import "RCStreamContentView.h"
#import "RCKitCommonDefine.h"
#import "RCMessageCellTool.h"
extern CGFloat const rcTextLeadingX;
@implementation RCStreamContentViewModel

+ (NSString *)failedInfo {
    return RCLocalizedString(@"StreamFailedWithAutoRequest");
}

- (instancetype)init {
    if (self = [super init]) {

    }
    return self;
}

- (RCStreamContentView *)streamContentView {
    return nil;
}

- (CGFloat)contentMaxWidth {
    return [RCMessageCellTool getMessageContentViewMaxWidth] - rcTextLeadingX*2;
}

#pragma mark -- RCStreamViewModelProtocol

- (CGSize)calculateContentSize {
    return CGSizeMake(0, 0);
}

- (void)streamContentDidUpdate:(nonnull NSString *)content {
    if ([self.content isEqualToString:content]) {
        return;
    }
    self.content = content;
}

@end
