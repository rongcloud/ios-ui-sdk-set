//
//  RCPublicServiceProfileTelCell.m
//  HelloIos
//
//  Created by litao on 15/4/10.
//  Copyright (c) 2015年 litao. All rights reserved.
//

#import "RCPublicServiceProfileTelCell.h"
#import "RCKitCommonDefine.h"
#import "RCKitUtility.h"
#import "RCPublicServiceViewConstants.h"
#import "RCKitConfig.h"

@interface RCPublicServiceProfileTelCell ()
@property (nonatomic, strong) UILabel *title;
@property (nonatomic, strong) UILabel *content;
@end

@implementation RCPublicServiceProfileTelCell

- (instancetype)init {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"hello"];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setTitle:(NSString *)title Content:(NSString *)content {
    self.title.text = title;
    self.content.text = content;
    if (content && content.length > 0) {
        UITapGestureRecognizer *tapGesture =
            [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTel:)];
        [self addGestureRecognizer:tapGesture];
    }
    [self updateFrame];
}

#pragma mark – Private Methods
- (void)setup {
    CGRect bounds = [[UIScreen mainScreen] bounds];
    bounds.size.height = 0;

    self.frame = bounds;

    self.title = [[UILabel alloc] initWithFrame:CGRectZero];
    self.content = [[UILabel alloc] initWithFrame:CGRectZero];

    self.title.numberOfLines = 0;
    self.title.font = [[RCKitConfig defaultConfig].font fontOfFirstLevel];
    self.title.textColor = RCDYCOLOR(0x00000, 0x9f9f9f);
    self.title.textAlignment = NSTextAlignmentLeft;
    self.content.numberOfLines = 0;
    self.content.lineBreakMode = NSLineBreakByCharWrapping;
    self.content.textAlignment = NSTextAlignmentRight;
    self.content.textColor = [RCKitUtility generateDynamicColor:[UIColor grayColor] darkColor:HEXCOLOR(0x707070)];
    self.content.font = [[RCKitConfig defaultConfig].font fontOfFourthLevel];
    [self.contentView addSubview:self.title];
    [self.contentView addSubview:self.content];
}

- (void)onTel:(id)sender {
    NSMutableString *str = [[NSMutableString alloc] initWithFormat:@"telprompt://%@", self.content.text];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:str]];
}

- (void)updateFrame {
    CGRect contentViewFrame = self.frame;

    UIFont *font = [[RCKitConfig defaultConfig].font fontOfFirstLevel];
    //设置一个行高上限
    CGSize size = CGSizeMake(RCPublicServiceProfileCellTitleWidth, 2000);
    //计算实际frame大小，并将label的frame变成实际大小
    CGSize labelsize = [RCKitUtility getTextDrawingSize:self.title.text font:font constrainedSize:size];
    self.title.frame = CGRectMake(2 * RCPublicServiceProfileCellPaddingLeft, RCPublicServiceProfileCellPaddingTop,
                                  labelsize.width, labelsize.height);

    size = CGSizeMake(self.frame.size.width - RCPublicServiceProfileCellPaddingLeft -
                          RCPublicServiceProfileCellTitleWidth - RCPublicServiceProfileCellPaddingRight,
                      2000);
    font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];

    labelsize = [RCKitUtility getTextDrawingSize:self.content.text font:font constrainedSize:size];

    if (RCPublicServiceProfileCellPaddingLeft + RCPublicServiceProfileCellTitleWidth + labelsize.width <
        contentViewFrame.size.width) {
        self.content.frame =
            CGRectMake(contentViewFrame.size.width - labelsize.width - RCPublicServiceProfileCellPaddingLeft - 20,
                       RCPublicServiceProfileCellPaddingTop, labelsize.width, labelsize.height);
    } else
        self.content.frame = CGRectMake(100, 8, labelsize.width, labelsize.height);
    contentViewFrame.size.height = MAX(self.title.frame.size.height, self.content.frame.size.height) +
                                   RCPublicServiceProfileCellPaddingTop + RCPublicServiceProfileCellPaddingBottom;
    self.frame = contentViewFrame;
}

@end
