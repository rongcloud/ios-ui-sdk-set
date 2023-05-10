//
//  RCPublicServiceProfileActionCell.m
//  HelloIos
//
//  Created by litao on 15/4/10.
//  Copyright (c) 2015年 litao. All rights reserved.
//

#import "RCPublicServiceProfileActionCell.h"
#import "RCPublicServiceViewConstants.h"
#import "RCKitConfig.h"

@interface RCPublicServiceProfileActionCell ()
@property (nonatomic, strong) UIButton *button;
@end

@implementation RCPublicServiceProfileActionCell

- (instancetype)init {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"hello"];
    if (self) {
        [self setup];
    }
    return self;
}

#pragma mark – Private Methods

- (void)setup {
    CGRect bounds = [[UIScreen mainScreen] bounds];
    bounds.size.height = 0;

    self.frame = bounds;

    self.button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.button.layer setCornerRadius:5.0];
    CGRect frame = self.button.frame;
    self.backgroundColor = [UIColor clearColor];
    frame.origin.x = RCPublicServiceProfileCellPaddingLeft;
    frame.origin.y = RCPublicServiceProfileCellPaddingTop;
    frame.size.width =
        self.frame.size.width - RCPublicServiceProfileCellPaddingLeft - RCPublicServiceProfileCellPaddingRight;
    frame.size.height = RCPublicServiceProfileCellActionButtonHeigh;
    self.button.frame = frame;
    [self.button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.button setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    self.button.titleLabel.font = [[RCKitConfig defaultConfig].font fontOfFirstLevel];
    [self.button setBackgroundColor:[UIColor redColor]];

    [self.contentView addSubview:self.button];

    [self.button addTarget:self action:@selector(onButtonPushDown:) forControlEvents:UIControlEventTouchDown];
}

- (void)onButtonPushDown:(id)sender {
    if (self.onClickEvent) {
        self.onClickEvent();
    }
}

- (void)setTitleText:(NSString *)title andBackgroundColor:(UIColor *)color {
    [self.button setTitle:title forState:UIControlStateNormal];
    [self.button setTitle:title forState:UIControlStateSelected];

    [self.button setBackgroundColor:color];
    [self updateFrame];
}

- (void)updateFrame {
    CGRect contentViewFrame = self.frame;

    contentViewFrame.size.height =
        self.button.frame.size.height + RCPublicServiceProfileCellPaddingTop + RCPublicServiceProfileCellPaddingBottom;
    self.frame = contentViewFrame;
}
@end
