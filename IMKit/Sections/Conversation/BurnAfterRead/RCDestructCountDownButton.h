//
//  RCDestructCountDownButton.h
//  RongIMKit
//
//  Created by linlin on 2018/6/7.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import "RCBaseButton.h"

@interface RCDestructCountDownButton : RCBaseButton

- (void)setDestructCountDownButtonHighlighted;

- (void)messageDestructing:(NSInteger)duration;

- (BOOL)isDestructCountDownButtonHighlighted;

@end
