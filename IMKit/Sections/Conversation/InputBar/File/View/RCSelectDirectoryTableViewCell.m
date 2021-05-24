//
//  RCSelectDirectoryTableViewCell.m
//  RongExtensionKit
//
//  Created by Jue on 16/8/17.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCSelectDirectoryTableViewCell.h"
#import "RCKitCommonDefine.h"
#import "RCKitConfig.h"

@implementation RCSelectDirectoryTableViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupSelectDirectoryCellView];
        self.contentView.backgroundColor =RCDYCOLOR(0xffffff, 0x191919);
    }
    return self;
}

- (void)setupSelectDirectoryCellView {
    //加载两个UI控件

    _directoryImageView = [UIImageView new];
    _directoryImageView.translatesAutoresizingMaskIntoConstraints = NO;
    _directoryImageView.image = RCResourceImage(@"folder");
    [self.contentView addSubview:_directoryImageView];

    _directoryNameLabel = [UILabel new];
    _directoryNameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _directoryNameLabel.font = [[RCKitConfig defaultConfig].font fontOfSecondLevel];
    _directoryNameLabel.textColor = [RCKitUtility generateDynamicColor:HEXCOLOR(0x000000) darkColor:RCMASKCOLOR(0xffffff, 0.9)];
    [self.contentView addSubview:_directoryNameLabel];

    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_directoryImageView
                                                                 attribute:NSLayoutAttributeCenterY
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.contentView
                                                                 attribute:NSLayoutAttributeCenterY
                                                                multiplier:1.0f
                                                                  constant:0]];

    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_directoryNameLabel
                                                                 attribute:NSLayoutAttributeCenterY
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.contentView
                                                                 attribute:NSLayoutAttributeCenterY
                                                                multiplier:1.0f
                                                                  constant:0]];

    NSDictionary *views = NSDictionaryOfVariableBindings(_directoryImageView, _directoryNameLabel);

    [self
        addConstraints:[NSLayoutConstraint
                           constraintsWithVisualFormat:@"H:|-49-[_directoryImageView(36)]-9-[_directoryNameLabel]-10-|"
                                               options:kNilOptions
                                               metrics:nil
                                                 views:views]];

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_directoryImageView(36)]"
                                                                 options:kNilOptions
                                                                 metrics:nil
                                                                   views:views]];

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_directoryNameLabel(21)]"
                                                                 options:kNilOptions
                                                                 metrics:nil
                                                                   views:views]];
}
@end
