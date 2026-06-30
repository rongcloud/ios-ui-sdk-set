//
//  RCMessageCellReferenceContentView.m
//  RongIMKit
//
//  Created by RongCloud on 2026/6/15.
//  Copyright © 2026 RongCloud. All rights reserved.
//

#import "RCMessageCellReferenceContentView.h"
#import <objc/message.h>

@interface RCMessageCellReferenceContentView ()

@property (nonatomic, strong, readwrite, nullable) RCMessageModel *messageModel;
@property (nonatomic, strong, readwrite, nullable) RCMessageContent *referencedContent;

@end

@implementation RCMessageCellReferenceContentView

+ (CGSize)sizeForReferencedContent:(RCMessageContent *)referencedContent
                       messageModel:(RCMessageModel *)messageModel
                           maxWidth:(CGFloat)maxWidth {
    return CGSizeZero;
}

- (void)setReferencedContent:(RCMessageContent *)referencedContent
                messageModel:(RCMessageModel *)messageModel {
    self.referencedContent = referencedContent;
    self.messageModel = messageModel;
}

- (void)performAction:(NSString *)action
                extra:(nullable NSDictionary *)extra {
    if (action.length <= 0) {
        return;
    }
    SEL selector = NSSelectorFromString(@"messageCellReferenceContentView:didPerformAction:extra:");
    UIView *view = self.superview;
    while (view) {
        if ([view respondsToSelector:selector]) {
            ((void (*)(id, SEL, RCMessageCellReferenceContentView *, NSString *, NSDictionary *))objc_msgSend)(
                view, selector, self, action, extra);
            return;
        }
        view = view.superview;
    }
}

@end
