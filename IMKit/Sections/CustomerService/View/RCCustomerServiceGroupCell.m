//
//  RCCustomerServiceGroupCell.m
//  RongIMKit
//
//  Created by 张改红 on 16/7/19.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCCustomerServiceGroupCell.h"
#import "RCKitCommonDefine.h"
#import "RCKitUtility.h"
#import "RCKitConfig.h"
@interface RCCustomerServiceGroupCell ()

@property (nonatomic, strong) UIImageView *selectImageView;

@end
@implementation RCCustomerServiceGroupCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        //布局View
        [self setUpView];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    if (selected) {
        self.selectImageView.hidden = NO;
    } else {
        self.selectImageView.hidden = YES;
    }
}

#pragma mark – Private Methods

- (void)setUpView {
    self.backgroundColor = [RCKitUtility generateDynamicColor:HEXCOLOR(0xffffff)
                                                    darkColor:[HEXCOLOR(0x1c1c1e) colorWithAlphaComponent:0.4]];
    self.groupName = [[UILabel alloc] initWithFrame:CGRectMake(45, (self.contentView.frame.size.height - 20) / 2,
                                                               self.contentView.frame.size.width - 45, 20)];
    self.groupName.textColor = RCDYCOLOR(0x000000, 0x9f9f9f);
    self.groupName.font = [[RCKitConfig defaultConfig].font fontOfSecondLevel];
    [self.contentView addSubview:self.groupName];

    self.selectImageView = [[UIImageView alloc]
        initWithFrame:CGRectMake((45 - 13) / 2, (self.contentView.frame.size.height - 10) / 2, 13, 10)];
    self.selectImageView.image = RCResourceImage(@"check");
    [self.contentView addSubview:self.selectImageView];
}
@end
