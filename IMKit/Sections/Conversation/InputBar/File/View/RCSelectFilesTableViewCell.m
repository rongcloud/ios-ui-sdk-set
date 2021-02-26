//
//  RCSelectFilesTableViewCell.m
//  RongExtensionKit
//
//  Created by Jue on 16/4/28.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCSelectFilesTableViewCell.h"
#import "RCKitCommonDefine.h"
#import "RCKitConfig.h"

@implementation RCSelectFilesTableViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupSelectFilesCellView];
        self.contentView.backgroundColor = RCDYCOLOR(0xffffff, 0x191919);
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    if (selected) {
        _selectedImageView.image = RCResourceImage(@"message_cell_select");
    } else {
        _selectedImageView.image = RCResourceImage(@"message_cell_unselect");
    }
}

- (void)setupSelectFilesCellView {
    //加载三个UI控件
    _selectedImageView = [UIImageView new];
    _selectedImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_selectedImageView];

    _fileIconImageView = [UIImageView new];
    _fileIconImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_fileIconImageView];

    _fileNameLabel = [UILabel new];
    _fileNameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _fileNameLabel.font = [[RCKitConfig defaultConfig].font fontOfSecondLevel];
    _fileNameLabel.textColor = [RCKitUtility generateDynamicColor:HEXCOLOR(0x000000) darkColor:RCMASKCOLOR(0xffffff, 0.9)];
    _fileNameLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    [self.contentView addSubview:_fileNameLabel];

    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_selectedImageView
                                                                 attribute:NSLayoutAttributeCenterY
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.contentView
                                                                 attribute:NSLayoutAttributeCenterY
                                                                multiplier:1.0f
                                                                  constant:0]];

    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_fileIconImageView
                                                                 attribute:NSLayoutAttributeCenterY
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.contentView
                                                                 attribute:NSLayoutAttributeCenterY
                                                                multiplier:1.0f
                                                                  constant:0]];

    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_fileNameLabel
                                                                 attribute:NSLayoutAttributeCenterY
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.contentView
                                                                 attribute:NSLayoutAttributeCenterY
                                                                multiplier:1.0f
                                                                  constant:0]];

    NSDictionary *views = NSDictionaryOfVariableBindings(_selectedImageView, _fileNameLabel, _fileIconImageView);

    [self addConstraints:[NSLayoutConstraint
                             constraintsWithVisualFormat:
                                 @"H:|-10-[_selectedImageView(20)]-17-[_fileIconImageView(36)]-10-[_fileNameLabel]-10-|"
                                                 options:kNilOptions
                                                 metrics:nil
                                                   views:views]];

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_selectedImageView(20)]"
                                                                 options:kNilOptions
                                                                 metrics:nil
                                                                   views:views]];

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_fileIconImageView(36)]"
                                                                 options:kNilOptions
                                                                 metrics:nil
                                                                   views:views]];

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_fileNameLabel(21)]"
                                                                 options:kNilOptions
                                                                 metrics:nil
                                                                   views:views]];
}

@end
