//
//  RCPublicServiceProfilePlainCell.m
//  HelloIos
//
//  Created by litao on 15/4/10.
//  Copyright (c) 2015年 litao. All rights reserved.
//

#import "RCPublicServiceProfilePlainCell.h"
#import "RCKitCommonDefine.h"
#import "RCKitUtility.h"
#import "RCPublicServiceViewConstants.h"
#import "RCKitConfig.h"

@interface RCPublicServiceProfilePlainCell ()
@property (nonatomic, strong) UILabel *title;
@property (nonatomic, strong) UILabel *content;
@end

@implementation RCPublicServiceProfilePlainCell

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
    self.title.textColor = RCDynamicColor(@"text_primary_color", @"0x000000", @"0x9f9f9f");
    self.title.textAlignment = NSTextAlignmentLeft;
    self.content.numberOfLines = 0;
    self.content.lineBreakMode = NSLineBreakByCharWrapping;
    self.content.textColor = RCDynamicColor(@"text_secondary_color", @"0xd9d9d9", @"0x707070");
    self.content.font = [[RCKitConfig defaultConfig].font fontOfFourthLevel];
    [self.contentView addSubview:self.title];
    [self.contentView addSubview:self.content];
}

- (void)updateFrame {
    CGRect contentViewFrame = self.frame;
    UIFont *font1 = [[RCKitConfig defaultConfig].font fontOfFirstLevel];
    //设置一个行高上限
    CGSize size = CGSizeMake(RCPublicServiceProfileCellTitleWidth, 2000);
    CGSize labelsize1 = [RCKitUtility getTextDrawingSize:self.title.text
                                                    font:[[RCKitConfig defaultConfig].font fontOfFirstLevel]
                                         constrainedSize:size];
    self.title.frame = CGRectMake(2 * RCPublicServiceProfileCellPaddingLeft, RCPublicServiceProfileCellPaddingTop,
                                  labelsize1.width, labelsize1.height);

    size = CGSizeMake(self.frame.size.width - RCPublicServiceProfileCellPaddingLeft -
                          RCPublicServiceProfileCellTitleWidth - RCPublicServiceProfileCellPaddingRight - 20,
                      2000);
    UIFont *font2 = [[RCKitConfig defaultConfig].font fontOfFourthLevel];
    CGSize labelsize2 = [RCKitUtility getTextDrawingSize:self.content.text font:font2 constrainedSize:size];
    self.content.numberOfLines = 0;
    [self.content setContentMode:UIViewContentModeTop];
    float offset = 0;
    if (labelsize2.height < labelsize1.height) {
        offset = (labelsize1.height - labelsize2.height) / 2;
        offset += (font1.xHeight - font2.xHeight) / 2;
    }
    self.content.frame = CGRectMake(RCPublicServiceProfileCellPaddingLeft + RCPublicServiceProfileCellTitleWidth,
                                    RCPublicServiceProfileCellPaddingTop + offset, labelsize2.width, labelsize2.height);
    contentViewFrame.size.height = MAX(self.title.frame.size.height, self.content.frame.size.height) +
                                   RCPublicServiceProfileCellPaddingTop + RCPublicServiceProfileCellPaddingBottom;
    [self.content sizeToFit];
    self.frame = contentViewFrame;
}
@end
