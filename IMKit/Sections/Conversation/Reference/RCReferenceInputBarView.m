//
//  RCReferenceInputBarView.m
//  RongIMKit
//
//  Created by RongCloud on 2026/6/16.
//  Copyright © 2026 RongCloud. All rights reserved.
//

#import "RCReferenceInputBarView.h"
#import "RCMessageModel.h"

@interface RCReferenceInputBarView ()
@property (nonatomic, strong, readwrite, nullable) RCMessageModel *messageModel;
@end

@implementation RCReferenceInputBarView

- (void)setReferencedMessageModel:(RCMessageModel *)messageModel {
    self.messageModel = messageModel;
}

- (void)setOffsetY:(CGFloat)offsetY {
    [UIView animateWithDuration:0.25
                     animations:^{
                         CGRect rect = self.frame;
                         rect.origin.y = offsetY;
                         self.frame = rect;
                     }];
}

@end
