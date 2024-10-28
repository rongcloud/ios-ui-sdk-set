//
//  RCButtonItemModel.m
//  RongIMKit
//
//  Created by zgh on 2024/8/22.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCButtonItem.h"

@implementation RCButtonItem
+ (instancetype)itemWithTitle:(NSString *)title
                   titleColor:(UIColor *)titleColor
              backgroundColor:(UIColor *)backgroundColor {
    RCButtonItem *item = [RCButtonItem new];
    item.title = title;
    item.titleColor = titleColor;
    item.backgroundColor = backgroundColor;
    return item;
}

@end
