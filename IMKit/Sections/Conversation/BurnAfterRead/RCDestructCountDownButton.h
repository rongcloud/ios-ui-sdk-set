//
//  RCDestructCountDownButton.h
//  RongIMKit
//
//  Created by linlin on 2018/6/7.
//  Copyright © 2018 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RCDestructCountDownButton : UIButton

- (void)setDestructCountDownButtonHighlighted;

- (void)messageDestructing:(NSInteger)duration;

- (BOOL)isDestructCountDownButtonHighlighted;

@end
