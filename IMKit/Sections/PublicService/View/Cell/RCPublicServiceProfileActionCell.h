//
//  RCPublicServiceProfileActionCell.h
//  HelloIos
//
//  Created by litao on 15/4/10.
//  Copyright (c) 2015年 litao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCBaseTableViewCell.h"
typedef void (^clickDone)(void);

@protocol RCPublicServiceProfileActionDelegate
- (void)onAction;
@end

@interface RCPublicServiceProfileActionCell : RCBaseTableViewCell
- (void)setTitleText:(NSString *)title andBackgroundColor:(UIColor *)color;

@property (nonatomic, copy) clickDone onClickEvent;

@end
