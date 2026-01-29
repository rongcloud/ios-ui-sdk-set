//
//  RCUnknownMessageCell.m
//  RongIMKit
//
//  Created by xugang on 3/31/15.
//  Copyright (c) 2015 RongCloud. All rights reserved.
//

#import "RCUnknownMessageCell.h"
#import "RCKitUtility.h"
#import "RCKitCommonDefine.h"
#import "RCKitConfig.h"
@implementation RCUnknownMessageCell

#pragma mark - Life Cycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

#pragma mark - Super Methods

- (void)setDataModel:(RCMessageModel *)model {
    [super setDataModel:model];

    CGFloat maxMessageLabelWidth = self.baseContentView.bounds.size.width - 30 * 2;

    [self.messageLabel setText:RCLocalizedString(@"unknown_message_cell_tip")
           dataDetectorEnabled:NO];

    NSString *__text = self.messageLabel.text;
    CGSize __textSize = [RCKitUtility getTextDrawingSize:__text
                                                    font:[[RCKitConfig defaultConfig].font fontOfFourthLevel]
                                         constrainedSize:CGSizeMake(maxMessageLabelWidth, MAXFLOAT)];
    __textSize = CGSizeMake(ceilf(__textSize.width), ceilf(__textSize.height));
    CGSize __labelSize = CGSizeMake(__textSize.width + 5, __textSize.height + 6);

    self.messageLabel.frame = CGRectMake((self.baseContentView.bounds.size.width - __labelSize.width) / 2.0f, 0,
                                         __labelSize.width, __labelSize.height);
}

#pragma mark - Private Methods

- (void)initialize {
    self.messageLabel = [RCTipLabel greyTipLabel];
    self.messageLabel.backgroundColor =
        [RCKitUtility generateDynamicColor:HEXCOLOR(0xc9c9c9) darkColor:HEXCOLOR(0x232323)];
    self.messageLabel.textColor = RCDYCOLOR(0xffffff, 0x707070);
    [self.baseContentView addSubview:self.messageLabel];
    self.messageLabel.marginInsets = UIEdgeInsetsMake(0.5f, 0.5f, 0.5f, 0.5f);
}
@end
