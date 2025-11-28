//
//  RCUserListTableViewCell.m
//  RongExtensionKit
//
//  Created by 杜立召 on 16/7/14.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCUserListTableViewCell.h"
#import "RCKitCommonDefine.h"
#import "RCKitConfig.h"
@implementation RCUserListTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.contentView.backgroundColor = RCDynamicColor(@"common_background_color", @"0xffffff", @"0x1c1c1e66");
        //布局View
        [self setUpView];
    }
    return self;
}

#pragma mark - setUpView
- (void)setUpView {
    //头像
    [self.contentView addSubview:self.headImageView];
    //姓名
    [self.contentView addSubview:self.nameLabel];
}

- (void)setHeadImageView:(UIImageView *)headImageView {
    [_headImageView removeFromSuperview];
    _headImageView = headImageView;
    if([RCKitUtility isRTL]){
        CGRect frame = self.nameLabel.frame;
        frame.origin.x = CGRectGetMinX(_headImageView.frame) - frame.size.width - 10;
        _nameLabel.frame = frame;
    }
    [self.contentView addSubview:_headImageView];
}

#pragma mark - Getters and Setters

- (RCBaseLabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[RCBaseLabel alloc] init];
        [_nameLabel setFont:[[RCKitConfig defaultConfig].font fontOfSecondLevel]];
        _nameLabel.textAlignment = [RCKitUtility isRTL] ? NSTextAlignmentRight : NSTextAlignmentLeft;
        _nameLabel.textColor = RCDynamicColor(@"text_primary_color", @"0x000000", @"0x9f9f9f");
        CGRect frame = CGRectMake(60.0, 5.0, self.bounds.size.width - 60.0, 40.0);
        _nameLabel.frame = frame;
    }
    return _nameLabel;
}

@end
