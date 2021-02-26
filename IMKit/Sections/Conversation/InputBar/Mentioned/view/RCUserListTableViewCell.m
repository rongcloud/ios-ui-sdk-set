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
        self.contentView.backgroundColor =
            [RCKitUtility generateDynamicColor:HEXCOLOR(0xffffff)
                                           darkColor:[HEXCOLOR(0x1c1c1e) colorWithAlphaComponent:0.4]];
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
    [self.contentView addSubview:_headImageView];
}

#pragma mark - Getters and Setters

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(60.0, 5.0, self.bounds.size.width - 60.0, 40.0)];
        [_nameLabel setFont:[[RCKitConfig defaultConfig].font fontOfSecondLevel]];
        _nameLabel.textColor = RCDYCOLOR(0x000000, 0x9f9f9f);
    }
    return _nameLabel;
}

@end
