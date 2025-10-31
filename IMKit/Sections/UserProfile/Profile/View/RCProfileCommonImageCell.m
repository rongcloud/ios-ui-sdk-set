//
//  RCUserProfileImageCell.m
//  RongUserProfile
//
//  Created by zgh on 2024/8/16.
//

#import "RCProfileCommonImageCell.h"
#import "RCloudImageView.h"
#import "RCProfileCommonCellViewModel.h"
#import "RCKitCommonDefine.h"
#import "RCKitConfig.h"

#define RCUProfileImageCellPortraitTrailingSpace 10
#define RCUProfileImageCellPortraitTop 5
#define RCUProfileImageCellPortraitSize 34

NSString  * const RCUProfileImageCellIdentifier = @"RCUProfileImageCellIdentifier";

@implementation RCProfileCommonImageCell

- (void)setupView {
    [super setupView];
    [self.contentView addSubview:self.portraitImageView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (self.arrowView.hidden) {
        self.portraitImageView.frame = CGRectMake(CGRectGetMaxX(self.arrowView.frame)-RCUProfileImageCellPortraitSize, RCUProfileImageCellPortraitTop, RCUProfileImageCellPortraitSize, RCUProfileImageCellPortraitSize);
    } else {
        self.portraitImageView.frame = CGRectMake(CGRectGetMinX(self.arrowView.frame)-RCUProfileImageCellPortraitSize - RCUProfileImageCellPortraitTrailingSpace, RCUProfileImageCellPortraitTop, RCUProfileImageCellPortraitSize, RCUProfileImageCellPortraitSize);
    }
}

- (void)hiddenArrow:(BOOL)hiddenArrow {
    self.arrowView.hidden = hiddenArrow;
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

#pragma mark - getter
- (UIImageView *)portraitImageView {
    if (!_portraitImageView) {
        _portraitImageView = [[RCloudImageView alloc] init];
        if (RCKitConfigCenter.ui.globalConversationAvatarStyle == RC_USER_AVATAR_CYCLE &&
            RCKitConfigCenter.ui.globalMessageAvatarStyle == RC_USER_AVATAR_CYCLE) {
            _portraitImageView.layer.cornerRadius = RCUProfileImageCellPortraitSize/2;
        }else{
            _portraitImageView.layer.cornerRadius = 5.f;
        }
        _portraitImageView.layer.masksToBounds = YES;
        [_portraitImageView setPlaceholderImage:RCDynamicImage(@"conversation-list_cell_portrait_msg_img",@"default_portrait_msg")];
    }
    return _portraitImageView;
}
@end
