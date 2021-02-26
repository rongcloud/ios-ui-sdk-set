//
//  RCPublicServiceProfileRcvdMsgCell.m
//  HelloIos
//
//  Created by litao on 15/4/10.
//  Copyright (c) 2015年 litao. All rights reserved.
//

#import "RCPublicServiceProfileRcvdMsgCell.h"
#import "RCKitCommonDefine.h"
#import "RCKitUtility.h"
#import "RCPublicServiceViewConstants.h"
#import "RCKitConfig.h"
#import <RongPublicService/RongPublicService.h>
@interface RCPublicServiceProfileRcvdMsgCell ()
@property (nonatomic, strong) UILabel *title;
@property (nonatomic, strong) UISwitch *switcher;
@end

@implementation RCPublicServiceProfileRcvdMsgCell

- (instancetype)init {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"hello"];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setTitleText:(NSString *)title {
    self.title.text = title;
    [self updateFrame];
}

- (void)setOn:(BOOL)enableNotification {
    [self.switcher setOn:enableNotification];
}

#pragma mark – Private Methods

- (void)setup {
    CGRect bounds = [[UIScreen mainScreen] bounds];
    bounds.size.height = 0;

    self.frame = bounds;

    self.title = [[UILabel alloc] initWithFrame:CGRectZero];

    self.title.numberOfLines = 0;
    self.title.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    self.title.textAlignment = NSTextAlignmentLeft;
    self.title.font = [[RCKitConfig defaultConfig].font fontOfFirstLevel];
    self.title.textColor = RCDYCOLOR(0x00000, 0x9f9f9f);
    self.switcher = [[UISwitch alloc] init];
    self.switcher.onTintColor = HEXCOLOR(0x0099ff);
    [self.switcher addTarget:self action:@selector(switchAction:) forControlEvents:UIControlEventValueChanged];

    [self.contentView addSubview:self.title];
    [self.contentView addSubview:self.switcher];

    CGRect frame = self.contentView.frame;
    DebugLog(@"frame size is %f, %f", frame.size.width, frame.size.height);
}

- (void)switchAction:(id)sender {
    BOOL enableNotification = self.switcher.on;

    [[RCIMClient sharedRCIMClient]
        setConversationNotificationStatus:(RCConversationType)self.serviceProfile.publicServiceType
        targetId:self.serviceProfile.publicServiceId
        isBlocked:!enableNotification
        success:^(RCConversationNotificationStatus nStatus) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setOn:enableNotification];
            });
        }
        error:^(RCErrorCode status) {
            DebugLog(@"set error");
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setOn:enableNotification];
            });
        }];
}

- (void)updateFrame {
    CGRect contentViewFrame = self.frame;
    CGSize size = CGSizeMake(RCPublicServiceProfileCellTitleWidth, MAXFLOAT);
    CGSize labelsize = [RCKitUtility getTextDrawingSize:self.title.text
                                                   font:[[RCKitConfig defaultConfig].font fontOfFirstLevel]
                                        constrainedSize:size];
    CGFloat maxHeigh = MAX(labelsize.height, self.switcher.frame.size.height);
    self.title.frame = CGRectMake(2 * RCPublicServiceProfileCellPaddingLeft,
                                  RCPublicServiceProfileCellPaddingTop + (maxHeigh - labelsize.height) / 2,
                                  labelsize.width, labelsize.height);

    CGRect frame = self.switcher.frame;

    frame.origin.y = RCPublicServiceProfileCellPaddingTop + (maxHeigh - frame.size.height) / 2;
    frame.origin.x = self.frame.size.width - RCPublicServiceProfileCellPaddingRight - frame.size.width - 10;

    self.switcher.frame = frame;

    contentViewFrame.size.height = MAX(self.title.frame.size.height, self.switcher.frame.size.height) +
                                   RCPublicServiceProfileCellPaddingTop + RCPublicServiceProfileCellPaddingBottom;
    self.frame = contentViewFrame;
}
@end
