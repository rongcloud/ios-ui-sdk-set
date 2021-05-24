//
//  RCPluginBoardItem.m
//  RongExtensionKit
//
//  Created by Liv on 15/3/15.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCPluginBoardItem.h"
#import "RCKitCommonDefine.h"
#import "UIImage+RCDynamicImage.h"
#import "RCKitConfig.h"
@implementation RCPluginBoardItem

- (instancetype)initWithTitle:(NSString *)title normalImage:(UIImage *)normalImage highlightedImage:(UIImage *)highlightedImage tag:(NSInteger)tag{
    self = [super init];
    if (self) {
        self.title = title;
        self.normalImage = normalImage;
        self.highlightedImage = highlightedImage;
        super.tag = tag;
    }
    return self;
}

- (void)loadView {
    UIView *myView = [UIView new];
    UIButton *imageButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [imageButton setImage:self.normalImage forState:UIControlStateNormal];
    if (self.highlightedImage) {
        [imageButton setImage:self.highlightedImage forState:UIControlStateHighlighted];
    }
    [myView addSubview:imageButton];
    [imageButton addTarget:self action:@selector(imageButtonTouchUpInside) forControlEvents:UIControlEventTouchUpInside];

    UILabel *label = [UILabel new];
    [label setText:_title];
    [label setTextColor:RCDYCOLOR(0xA0A5Ab, 0x9f9f9f)];
    [label setFont:[[RCKitConfig defaultConfig].font fontOfAssistantLevel]];
    [label setTextAlignment:NSTextAlignmentCenter];
    [myView addSubview:label];
    [self.contentView addSubview:myView];

    // add contraints
    [myView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [imageButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [label setTranslatesAutoresizingMaskIntoConstraints:NO];

    [self.contentView
        addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[myView(75)]|"
                                                               options:kNilOptions
                                                               metrics:nil
                                                                 views:NSDictionaryOfVariableBindings(myView)]];
    [self.contentView
        addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[myView]|"
                                                               options:kNilOptions
                                                               metrics:nil
                                                                 views:NSDictionaryOfVariableBindings(myView)]];

    [self.contentView
        addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-7.5-[imageButton(60)]"
                                                               options:kNilOptions
                                                               metrics:nil
                                                                 views:NSDictionaryOfVariableBindings(imageButton)]];

    [self.contentView
        addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[label]|"
                                                               options:kNilOptions
                                                               metrics:nil
                                                                 views:NSDictionaryOfVariableBindings(label, myView)]];
    [self.contentView
        addConstraints:[NSLayoutConstraint
                           constraintsWithVisualFormat:@"V:|[imageButton(60)]-5.5-[label(14)]"
                                               options:kNilOptions
                                               metrics:nil
                                                 views:NSDictionaryOfVariableBindings(label, imageButton)]];
}

- (void)imageButtonTouchUpInside {
    self.Itemclick();
}

@end
