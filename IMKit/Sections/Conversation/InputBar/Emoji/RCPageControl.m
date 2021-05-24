//
//  RCEmojiPageControl.m
//  RongExtensionKit
//
//  Created by Heq.Shinoda on 14-7-12.
//  Copyright (c) 2014年 Heq.Shinoda. All rights reserved.
//

#import "RCPageControl.h"
#import "RCKitCommonDefine.h"

@interface RCPageControl ()
@property (nonatomic) CGSize size;
@end
@implementation RCPageControl
#pragma mark - Super Methods
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.currentPageIndicatorTintColor = RCDYCOLOR(0x868686, 0xcccccc);
        self.pageIndicatorTintColor = RCDYCOLOR(0xBFBFBF,0x666666);
        self.hidesForSinglePage = YES;
        self.enabled = NO;
        self.currentPage = 0;
    }
    return self;
}
@end
