//
//  RCPublicServiceListViewCell.m
//  HelloIos
//
//  Created by litao on 15/4/9.
//  Copyright (c) 2015年 litao. All rights reserved.
//

#import "RCPublicServiceListViewCell.h"
#import "RCKitCommonDefine.h"
#import "RCKitUtility.h"
#import "RCPublicServiceViewConstants.h"
#import "RCKitConfig.h"
@interface RCPublicServiceListViewCell ()
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *describeLabel;
@end

@implementation RCPublicServiceListViewCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setRestorationIdentifier:reuseIdentifier];
        [self setup];
    }
    return self;
}

- (void)setName:(NSString *)name {
    if (name)
        self.nameLabel.attributedText = [self getAttributedStringWith:name];
}

- (void)setDescription:(NSString *)description {
    if (description)
        self.describeLabel.attributedText = [self getAttributedStringWith:description];
}

#pragma mark – Private Methods

- (NSAttributedString *)getAttributedStringWith:(NSString *)str {
    NSMutableAttributedString *attributedStr = [[NSMutableAttributedString alloc] initWithString:str];

    if (!self.searchKey) {
        return attributedStr;
    }
    NSRange range = [str rangeOfString:self.searchKey];

    while (range.location != NSNotFound) {

        NSMutableDictionary *dict = [[attributedStr attributesAtIndex:range.location effectiveRange:NULL] mutableCopy];
        [dict setValue:RGBCOLOR(83, 213, 105) forKey:NSForegroundColorAttributeName];
        [attributedStr addAttributes:dict range:range];

        range.location++;
        range.length = str.length - range.location;
        range = [str rangeOfString:self.searchKey options:0 range:range];
    }

    return attributedStr;
}

- (void)setup {
    self.backgroundColor = [RCKitUtility generateDynamicColor:HEXCOLOR(0xffffff)
                                                    darkColor:[HEXCOLOR(0x1c1c1e) colorWithAlphaComponent:0.4]];
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
    self.headerImageView = [[RCloudImageView alloc]
        initWithFrame:CGRectMake(RCPublicServiceProfileCellPaddingLeft, RCPublicServiceProfileCellPaddingTop,
                                 RCPublicServiceProfileHeaderImageWidth - 10,
                                 RCPublicServiceProfileHeaderImageHeigh - 10)];
    self.nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.describeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.nameLabel.font = [[RCKitConfig defaultConfig].font fontOfFirstLevel];
    self.nameLabel.textColor = RCDYCOLOR(0x000000, 0x9f9f9f);
    self.nameLabel.numberOfLines = 1;
    [self.nameLabel setTranslatesAutoresizingMaskIntoConstraints:NO];

    self.describeLabel.numberOfLines = 2;
    [self.describeLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    self.describeLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.describeLabel.font = [[RCKitConfig defaultConfig].font fontOfFourthLevel];
    self.describeLabel.textColor = [RCKitUtility generateDynamicColor:[UIColor grayColor] darkColor:HEXCOLOR(0x666666)];
    self.headerImageView.placeholderImage = RCResourceImage(@"default_portrait");

    //[self.headerImageView setTranslatesAutoresizingMaskIntoConstraints:NO];
    self.headerImageView.layer.masksToBounds = YES;
    if (!self.portraitStyle) {
        self.headerImageView.layer.cornerRadius = 4;
    } else {
        if (_portraitStyle == RC_USER_AVATAR_RECTANGLE) {
            self.headerImageView.layer.cornerRadius = 4;
        } else if (_portraitStyle == RC_USER_AVATAR_CYCLE) {
            self.headerImageView.layer.cornerRadius = 25.0f;
        }
    }

    [self.contentView addSubview:self.headerImageView];
    [self.contentView addSubview:self.nameLabel];
    [self.contentView addSubview:self.describeLabel];

    [self updateConstraints];

    //
}

- (void)updateConstraints {
    [super updateConstraints];

    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.headerImageView
                                                                 attribute:NSLayoutAttributeLeft
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.contentView
                                                                 attribute:NSLayoutAttributeLeft
                                                                multiplier:1.0
                                                                  constant:4]];

    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.headerImageView
                                                                 attribute:NSLayoutAttributeTop
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.contentView
                                                                 attribute:NSLayoutAttributeTop
                                                                multiplier:1.0
                                                                  constant:4]];

    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.headerImageView
                                                                 attribute:NSLayoutAttributeBottom
                                                                 relatedBy:NSLayoutRelationLessThanOrEqual
                                                                    toItem:self.contentView
                                                                 attribute:NSLayoutAttributeBottom
                                                                multiplier:1.0
                                                                  constant:4]];

    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.nameLabel
                                                                 attribute:NSLayoutAttributeLeft
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.headerImageView
                                                                 attribute:NSLayoutAttributeRight
                                                                multiplier:1.0
                                                                  constant:8]];

    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.nameLabel
                                                                 attribute:NSLayoutAttributeTop
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.contentView
                                                                 attribute:NSLayoutAttributeTop
                                                                multiplier:1.0
                                                                  constant:10]];

    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.describeLabel
                                                                 attribute:NSLayoutAttributeLeft
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.headerImageView
                                                                 attribute:NSLayoutAttributeRight
                                                                multiplier:1.0
                                                                  constant:8]];

    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.describeLabel
                                                                 attribute:NSLayoutAttributeRight
                                                                 relatedBy:NSLayoutRelationLessThanOrEqual
                                                                    toItem:self.contentView
                                                                 attribute:NSLayoutAttributeRight
                                                                multiplier:1.0
                                                                  constant:8]];

    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.describeLabel
                                                                 attribute:NSLayoutAttributeTop
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.nameLabel
                                                                 attribute:NSLayoutAttributeBottom
                                                                multiplier:1.0
                                                                  constant:4]];

    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.describeLabel
                                                                 attribute:NSLayoutAttributeBottom
                                                                 relatedBy:NSLayoutRelationLessThanOrEqual
                                                                    toItem:self.contentView
                                                                 attribute:NSLayoutAttributeBottom
                                                                multiplier:1.0
                                                                  constant:4]];
}
@end
