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

#define RCUProfileImageCellPortraitSize 32

NSString  * const RCUProfileImageCellIdentifier = @"RCUProfileImageCellIdentifier";
@interface RCProfileCommonImageCell ()

@property (nonatomic, strong) NSLayoutConstraint *portraitTrailingToArrowConstraint;
@property (nonatomic, strong) NSLayoutConstraint *portraitTrailingToContentViewConstraint;

@end

@implementation RCProfileCommonImageCell

- (void)setupView {
    [super setupView];
    [self.contentStackView addArrangedSubview:self.titleLabel];
    [self.contentStackView addArrangedSubview:self.portraitImageView];
    [self.contentStackView addArrangedSubview:self.arrowView];
}

- (void)hiddenArrow:(BOOL)hiddenArrow {
    self.arrowView.hidden = hiddenArrow;
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
        _portraitImageView.translatesAutoresizingMaskIntoConstraints = NO;
        [_portraitImageView setPlaceholderImage:RCDynamicImage(@"conversation-list_cell_portrait_msg_img",@"default_portrait_msg")];
        [NSLayoutConstraint activateConstraints:@[
            [_portraitImageView.widthAnchor constraintEqualToConstant:RCUProfileImageCellPortraitSize],
            [_portraitImageView.heightAnchor constraintEqualToConstant:RCUProfileImageCellPortraitSize]
        ]];
    }
    return _portraitImageView;
}
@end
