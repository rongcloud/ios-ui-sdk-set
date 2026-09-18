//
//  RCFriendListPermanentCell.m
//  RongIMKit
//
//  Created by RobinCui on 2024/8/20.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCFriendListPermanentCell.h"
#import "RCloudImageView.h"
#import "RCKitUtility.h"
#import "RCKitCommonDefine.h"
#import "RCKitConfig.h"
NSString  * const RCFriendListPermanentCellIdentifier = @"RCFriendListPermanentCellIdentifier";

@implementation RCFriendListPermanentCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)setupView {
    [super setupView];
   self.contentView.backgroundColor = [RCKitUtility generateDynamicColor:HEXCOLOR(0xffffff)
                                                        darkColor:[HEXCOLOR(0x1c1c1e) colorWithAlphaComponent:0.4]];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    [self.contentView addSubview:self.portraitImageView];
    [self.contentView addSubview:self.labName];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat portraitWidth = 40;
    CGFloat marginWidth = 15;
    self.portraitImageView.bounds = CGRectMake(0, 0, portraitWidth, portraitWidth);
    self.portraitImageView.center = CGPointMake(marginWidth+portraitWidth/2, self.contentView.center.y);
    
    CGFloat width = self.contentView.bounds.size.width;
    CGFloat labWidth = width - CGRectGetMaxX(self.portraitImageView.frame) -marginWidth*2;
    self.labName.bounds= CGRectMake(0, 0, labWidth, 40);
    CGFloat xCenter = CGRectGetMaxX(self.portraitImageView.frame) +marginWidth + labWidth/2;
    self.labName.center = CGPointMake(xCenter, self.contentView.center.y);
}

- (void)showPortraitByImage:(UIImage *)image {
    [self.portraitImageView setImage:image];
}

- (UIImageView *)portraitImageView {
    if (!_portraitImageView) {
        _portraitImageView = [RCloudImageView new];
        if (RCKitConfigCenter.ui.globalConversationAvatarStyle == RC_USER_AVATAR_CYCLE &&
            RCKitConfigCenter.ui.globalMessageAvatarStyle == RC_USER_AVATAR_CYCLE) {
            _portraitImageView.layer.cornerRadius = 20.f;
        } else {
            _portraitImageView.layer.cornerRadius = 5.f;
        }
        _portraitImageView.layer.masksToBounds = YES;
        [_portraitImageView setPlaceholderImage:RCResourceImage(@"default_portrait_msg")];
    }
    return _portraitImageView;
}

- (UILabel *)labName {
    if (!_labName) {
        UILabel *lab = [UILabel new];
        _labName = lab;
    }
    return _labName;
}
@end
