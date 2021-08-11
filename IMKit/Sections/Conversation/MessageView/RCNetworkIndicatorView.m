//
//  RCNetworkIndicatorView.m
//  RongIMKit
//
//  Created by MiaoGuangfa on 3/16/15.
//  Copyright (c) 2015 RongCloud. All rights reserved.
//

#import "RCNetworkIndicatorView.h"
#import "RCKitCommonDefine.h"
#import "RCKitUtility.h"
#import "RCKitConfig.h"
@interface RCNetworkIndicatorView ()
@property (nonatomic, strong) UILabel *networkUnreachableDescriptionLabel;
@end

@implementation RCNetworkIndicatorView
- (instancetype)initWithText:(NSString *)text {
    self = [super init];
    if (self) {
        self.networkUnreachableImageView = [[UIImageView alloc] init];
        self.networkUnreachableImageView.image = RCResourceImage(@"network_fail");
        self.networkUnreachableDescriptionLabel = [[UILabel alloc] init];
        self.networkUnreachableDescriptionLabel.textColor = RCDYCOLOR(0x111f2c, 0xBE9393);
        self.networkUnreachableDescriptionLabel.font = [[RCKitConfig defaultConfig].font fontOfFourthLevel];
        self.networkUnreachableDescriptionLabel.text = text;
        self.networkUnreachableDescriptionLabel.backgroundColor = [UIColor clearColor];

        [self addSubview:self.networkUnreachableImageView];
        [self addSubview:self.networkUnreachableDescriptionLabel];

        // self.translatesAutoresizingMaskIntoConstraints = NO;
        self.networkUnreachableImageView.translatesAutoresizingMaskIntoConstraints = NO;
        self.networkUnreachableDescriptionLabel.translatesAutoresizingMaskIntoConstraints = NO;

        // set autoLayout
        NSDictionary *bindingViews = NSDictionaryOfVariableBindings(_networkUnreachableImageView,
                                                                    _networkUnreachableDescriptionLabel);

        [self addConstraints:[NSLayoutConstraint
                                 constraintsWithVisualFormat:@"H:|-19-[_networkUnreachableImageView(24)]-12-[_"
                                                             @"networkUnreachableDescriptionLabel]"
                                                     options:0
                                                     metrics:nil
                                                       views:bindingViews]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_networkUnreachableImageView(24)]"
                                                                     options:0
                                                                     metrics:nil
                                                                       views:bindingViews]];

        [self addConstraint:[NSLayoutConstraint constraintWithItem:_networkUnreachableDescriptionLabel
                                                         attribute:NSLayoutAttributeCenterY
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeCenterY
                                                        multiplier:1.0f
                                                          constant:0]];

        [self addConstraint:[NSLayoutConstraint constraintWithItem:_networkUnreachableImageView
                                                         attribute:NSLayoutAttributeCenterY
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeCenterY
                                                        multiplier:1.0f
                                                          constant:0]];
    }
    return self;
}

- (void)setText:(NSString *)text{
    self.networkUnreachableDescriptionLabel.text = text;
}
@end
