//
//  RCSearchItemView.h
//  HelloIos
//
//  Created by litao on 15/4/9.
//  Copyright (c) 2015年 litao. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol RCSearchItemDelegate

- (void)onSearchItemTapped;

@end

@interface RCSearchItemView : UIView

- (void)setKeyContent:(NSString *)keyContent;

@property (nonatomic, weak) id<RCSearchItemDelegate> delegate;

@end
