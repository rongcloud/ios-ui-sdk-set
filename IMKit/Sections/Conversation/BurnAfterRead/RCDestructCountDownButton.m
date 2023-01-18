//
//  RCDestructCountDownButton.m
//  RongIMKit
//
//  Created by linlin on 2018/6/7.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import "RCDestructCountDownButton.h"
#import "RCKitUtility.h"
#import "RCKitCommonDefine.h"
#import "RCKitConfig.h"

@implementation RCDestructCountDownButton

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = RCDYCOLOR(0xf4b50b, 0xfa9d3b);
        self.layer.masksToBounds = YES;
        self.layer.cornerRadius = 10;
        self.userInteractionEnabled = NO;
        self.titleLabel.font = [[RCKitConfig defaultConfig].font fontOfAnnotationLevel];
        [self setTitleColor:RCDYCOLOR(0xffffff, 0x111111) forState:(UIControlStateNormal)];
    }
    return self;
}

#pragma mark - Public Methods

- (void)setDestructCountDownButtonHighlighted {
    self.highlighted = YES;
}

- (BOOL)isDestructCountDownButtonHighlighted {
    __block BOOL isHighlighted = NO;
    if (self.highlighted == YES) {
        isHighlighted = YES;
    }
    return isHighlighted;
}

- (void)messageDestructing:(NSInteger)duration {
    NSNumber *whisperMsgDuration = @(duration);

    if (duration <= 0) {
        self.hidden = YES;
    } else {
        self.hidden = NO;
        NSDecimalNumber *subTime =
            [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%@", whisperMsgDuration]];
        NSDecimalNumber *divTime = [NSDecimalNumber decimalNumberWithString:@"1"];
        NSDecimalNumberHandler *handel = [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundBankers
                                                                                                scale:0
                                                                                     raiseOnExactness:NO
                                                                                      raiseOnOverflow:NO
                                                                                     raiseOnUnderflow:NO
                                                                                  raiseOnDivideByZero:NO];
        NSDecimalNumber *showTime = [subTime decimalNumberByDividingBy:divTime withBehavior:handel];
        [self setTitle:[NSString stringWithFormat:@"%@", showTime] forState:UIControlStateHighlighted];
    }
}

@end
