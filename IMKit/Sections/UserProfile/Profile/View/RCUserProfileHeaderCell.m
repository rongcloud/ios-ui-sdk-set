//
//  RCUUserProfileHeaderCell.m
//  RongUserProfile
//
//  Created by zgh on 2024/8/19.
//

#import "RCUserProfileHeaderCell.h"
#import "RCKitConfig.h"
#import "RCKitCommonDefine.h"

#define RCUUserProfileHeaderCellSize 60
#define RCUUserProfileHeaderCellNameFont 11
#define RCUUserProfileHeaderCellRemarkFont 17
#define RCUUserProfileHeaderCellPortraitLeft 15
#define RCUUserProfileHeaderCellPortraitTop 11
#define RCUUserProfileHeaderCellRemarkLeadingSpace 17
#define RCUUserProfileHeaderCellRemarkTop 21

NSString  * const RCUUserProfileHeaderCellIdentifier = @"RCUUserProfileHeaderCellIdentifier";

@implementation RCUserProfileHeaderCell

- (void)setupView {
    [super setupView];
    [self.contentView addSubview:self.portraitImageView];
    [self.contentView addSubview:self.nameLabel];
    [self.contentView addSubview:self.remarkLabel];
    self.portraitImageView.frame = CGRectMake(RCUUserProfileHeaderCellPortraitLeft, RCUUserProfileHeaderCellPortraitTop, RCUUserProfileHeaderCellSize, RCUUserProfileHeaderCellSize);
}

- (void)hiddenNameLabel:(BOOL)hidden {
    self.nameLabel.hidden = hidden;
    [self.nameLabel sizeToFit];
    [self.remarkLabel sizeToFit];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat width = self.contentView.bounds.size.width - RCUUserProfileHeaderCellRemarkLeadingSpace*3- CGRectGetWidth(self.portraitImageView.frame);

    self.nameLabel.bounds = CGRectMake(0,
                                       0,
                                       width,
                                       self.nameLabel.bounds.size.height);
    self.remarkLabel.frame = CGRectMake(0,
                                        0,
                                        width,
                                        self.remarkLabel.bounds.size.height);
    if (self.nameLabel.isHidden) {
        self.remarkLabel.center = CGPointMake( CGRectGetMaxX(self.portraitImageView.frame) + RCUUserProfileHeaderCellRemarkLeadingSpace + CGRectGetWidth(self.remarkLabel.frame)/2, self.portraitImageView.center.y);
    } else {
        self.remarkLabel.center = CGPointMake(CGRectGetMaxX(self.portraitImageView.frame) + RCUUserProfileHeaderCellRemarkLeadingSpace + CGRectGetWidth(self.remarkLabel.frame)/2, CGRectGetMidY(self.portraitImageView.frame) - CGRectGetHeight(self.remarkLabel.frame)/2);
        self.nameLabel.center = CGPointMake(CGRectGetMaxX(self.portraitImageView.frame) + RCUUserProfileHeaderCellRemarkLeadingSpace + CGRectGetWidth(self.nameLabel.frame)/2, CGRectGetMidY(self.portraitImageView.frame) + CGRectGetHeight(self.nameLabel.frame)/2+5);
    }

}
#pragma mark - getter

- (UIImageView *)portraitImageView {
    if (!_portraitImageView) {
        _portraitImageView = [[RCloudImageView alloc] init];
        if (RCKitConfigCenter.ui.globalConversationAvatarStyle == RC_USER_AVATAR_CYCLE &&
            RCKitConfigCenter.ui.globalMessageAvatarStyle == RC_USER_AVATAR_CYCLE) {
            _portraitImageView.layer.cornerRadius = RCUUserProfileHeaderCellSize/2;
        }else{
            _portraitImageView.layer.cornerRadius = 5.f;
        }
        _portraitImageView.layer.masksToBounds = YES;
        [_portraitImageView setPlaceholderImage:RCResourceImage(@"default_portrait_msg")];
    }
    return _portraitImageView;
}

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.textColor = RCDYCOLOR(0xA0A5Ab, 0x878787);
        _nameLabel.font = [UIFont systemFontOfSize:RCUUserProfileHeaderCellNameFont];
    }
    return _nameLabel;
}

- (UILabel *)remarkLabel {
    if (!_remarkLabel) {
        _remarkLabel = [[UILabel alloc] init];
        _remarkLabel.textColor =RCDYCOLOR(0x11f2c, 0x9f9f9f);
        _remarkLabel.font = [UIFont systemFontOfSize:RCUUserProfileHeaderCellRemarkFont];
    }
    return _remarkLabel;
}


@end
