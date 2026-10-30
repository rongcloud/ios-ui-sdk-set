//
//  RCSizeCalculateLabel.m
//  RongIMKit
//
//  Created by RobinCui on 2025/11/14.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCSizeCalculateLabel.h"

@implementation RCSizeCalculateLabel
- (void)layoutSubviews {
    [super layoutSubviews];
    if ([self.delegate respondsToSelector:@selector(labelLayoutFinished:natureSize:)]) {
        CGSize size = [self sizeThatFits:CGSizeMake(self.bounds.size.width, 1000)];
        [self.delegate labelLayoutFinished:self natureSize:size];
    }
}
@end
