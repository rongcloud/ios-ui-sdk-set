//
//  RCSTTLabel.m
//  RongIMKit
//
//  Created by RobinCui on 2025/6/9.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCSTTLabel.h"
@interface RCSTTLabel()
@property (nonatomic, assign) UIEdgeInsets textInsets;
@end
@implementation RCSTTLabel


- (instancetype)initWithFrame:(CGRect)frame {
   self = [super initWithFrame:frame];
   if (self) {
       self.textInsets = UIEdgeInsetsMake(10, 14, 10, 14);
   }
   return self;
}

- (CGRect)textRectForBounds:(CGRect)bounds limitedToNumberOfLines:(NSInteger)numberOfLines {
   UIEdgeInsets insets = self.textInsets;
   CGRect rect = [super textRectForBounds:UIEdgeInsetsInsetRect(bounds, insets)
                   limitedToNumberOfLines:numberOfLines];
   
   rect.origin.x -= insets.left;
   rect.origin.y -= insets.top;
   rect.size.width += (insets.left + insets.right);
   rect.size.height += (insets.top + insets.bottom);
   
   return rect;
}

- (void)drawTextInRect:(CGRect)rect {
   [super drawTextInRect:UIEdgeInsetsInsetRect(rect, self.textInsets)];
}
@end
