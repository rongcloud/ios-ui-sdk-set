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
        self.currentPageIndicatorTintColor = RCDynamicColor(@"text_secondary_color", @"0x868686", @"0xcccccc");
        self.pageIndicatorTintColor = RCDynamicColor(@"auxiliary_background_1_color", @"0xBFBFBF", @"0x666666");
        self.hidesForSinglePage = YES;
        self.enabled = NO;
        self.currentPage = 0;
        if([RCKitUtility isRTL]) {
            self.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
        } else {
            self.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
        }
        
    }
    return self;
}
@end
