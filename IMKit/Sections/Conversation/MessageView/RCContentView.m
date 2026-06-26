//
//  RCContentView.m
//  RongIMKit
//
//  Created by xugang on 3/31/15.
//  Copyright (c) 2015 RongCloud. All rights reserved.
//

#import "RCContentView.h"
@interface RCContentView()
/*!
 Frame发生变化的回调
 */
@property (nonatomic, copy) void (^eventBlock)(CGRect frame);

/*!
 size 发生变化的回调
 */
@property (nonatomic, copy) void (^changeSizeBlock)(CGSize size);
@end
@implementation RCContentView

- (id)init {
    self = [super init];
    if (self) {
        _eventBlock = NULL;
    }
    return self;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    self.contentSize = frame.size;
    if (_eventBlock) {
        _eventBlock(frame);
    }

}

- (void)registerFrameChangedEvent:(void (^)(CGRect frame))eventBlock {
    self.eventBlock = eventBlock;
}

- (void)registerSizeChangedEvent:(void (^)(CGSize size))eventBlock{
    self.changeSizeBlock = eventBlock;
}

- (void)setContentSize:(CGSize)contentSize{
    CGSize beforeSize = self.contentSize;
    _contentSize = contentSize;
    if (beforeSize.width != contentSize.width || beforeSize.height != contentSize.height) {
        if (_changeSizeBlock) {
            _changeSizeBlock(contentSize);
        }
    }
}
@end
