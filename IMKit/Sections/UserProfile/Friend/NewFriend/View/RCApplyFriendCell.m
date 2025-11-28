//
//  RCFriendApplyCell.m
//  RongIMKit
//
//  Created by RobinCui on 2024/8/23.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCApplyFriendCell.h"
#import "RCloudImageView.h"
#import <CoreText/CoreText.h>
#import "RCKitUtility.h"
#import "RCKitCommonDefine.h"
#import "RCKitConfig.h"
NSString  * const RCFriendApplyCellIdentifier = @"RCFriendApplyCellIdentifier";
NSInteger const RCFriendApplyCellMargin = 15;
NSInteger const RCFriendApplyCellPortraitWidth = 40;
NSInteger const RCFriendApplyCellBtnExpandWidth = 28;
NSInteger const RCFriendApplyCellBtnContainerWidth = 105;

@interface RCApplyFriendCell()

@end


@implementation RCApplyFriendCell

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
    [self.contentView addSubview:self.labRemark];
    [self.contentView addSubview:self.btnExpand];
    [self.contentView addSubview:self.buttonsContainer];
    [self.contentView addSubview:self.labStatus];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat portraitWidth = RCFriendApplyCellPortraitWidth;
    CGFloat marginWidth = RCFriendApplyCellMargin;
    CGFloat width = self.contentView.bounds.size.width;
    
    self.portraitImageView.frame = CGRectMake(marginWidth, 8, portraitWidth, portraitWidth);
    
    CGFloat xCenter = width - marginWidth - CGRectGetWidth(self.buttonsContainer.bounds)/2;
    self.buttonsContainer.center =  CGPointMake(xCenter, self.portraitImageView.center.y);
    CGFloat btnExpandWidth = CGRectGetWidth(self.btnExpand.bounds);
    CGFloat xOffset = CGRectGetMinX(self.buttonsContainer.frame)-btnExpandWidth-marginWidth;
    CGFloat yOffset = CGRectGetMaxY(self.portraitImageView.frame)-14;
    self.btnExpand.frame = CGRectMake(xOffset, yOffset, btnExpandWidth, 14);
    
    [self.labStatus sizeToFit];
    xCenter = width-marginWidth-CGRectGetWidth(self.labStatus.frame)/2;
    self.labStatus.center = CGPointMake(xCenter, self.portraitImageView.center.y);
    
    xOffset = CGRectGetMaxX(self.portraitImageView.frame) + marginWidth;
    CGFloat labWidth = CGRectGetMinX(self.labStatus.frame) - marginWidth - xOffset;
    self.labName.frame = CGRectMake(xOffset, CGRectGetMinY(self.portraitImageView.frame), labWidth, 24);
    
    yOffset = CGRectGetMaxY(self.portraitImageView.frame) - 14;
    // 收起时的长度
    CGFloat labRemarkWidth = CGRectGetMinX(self.btnExpand.frame) -  CGRectGetMinX(self.labName.frame)-marginWidth;
    // 展开后的长度
    CGFloat labRemarkExpandWidth = CGRectGetMinX(self.buttonsContainer.frame) -  CGRectGetMinX(self.labName.frame)-marginWidth;
    
    if (self.viewModel.style == RCFriendApplyCellStyleNone) { // 还没计算过宽度
        self.labRemark.numberOfLines = 1;
        [self.labRemark sizeToFit];
        CGSize size = CGSizeMake(labRemarkWidth, CGRectGetHeight(self.labRemark.frame));
        // 首次计算,以确定是否显示展开
        [self.viewModel configureFolderRemarkSize:size];
        // 同时计算展开后的高度
        [self.viewModel configureExpandRemarkSize:CGSizeMake(labRemarkExpandWidth, size.height)];
    }
// 不是首次计算
    if (self.viewModel.style != RCFriendApplyCellStyleExpand) {// 非展开状态
        self.labRemark.numberOfLines = 1;
        self.labRemark.frame = CGRectMake(CGRectGetMinX(self.labName.frame),
                                           yOffset,
                                          labRemarkWidth,
                                           16);
        self.btnExpand.hidden = !(self.viewModel.style == RCFriendApplyCellStyleFolder);
    } else { // 展开状态
        self.labRemark.numberOfLines = 0;
        self.labRemark.frame = CGRectMake(CGRectGetMinX(self.labName.frame),
                                          yOffset,
                                          labRemarkExpandWidth,
                                          10000);
        [self.labRemark sizeToFit];
        self.btnExpand.hidden = YES;
    }

}

- (void)showPortrait:(NSString *)url {
    if (url) {
        [self.portraitImageView setImageURL:[NSURL URLWithString:url]];
    } else {
        [self.portraitImageView setImage:RCDynamicImage(@"conversation-list_cell_portrait_msg_img",@"default_portrait_msg")];
    }
}

- (void)updateWithViewModel:(RCApplyFriendCellViewModel *)viewModel {
    self.viewModel = viewModel;
    self.labName.text = viewModel.application.name;
    [self showPortrait:viewModel.application.portraitUri];
    self.labRemark.text = self.viewModel.application.extra;
    switch (viewModel.application.applicationStatus) {
        case RCFriendApplicationStatusAccepted:
            self.labStatus.text = RCLocalizedString(@"FriendApplicationAccepted");
            break;
        case RCFriendApplicationStatusRefused:
            self.labStatus.text = RCLocalizedString(@"FriendApplicationRefused");
            break;
        case RCFriendApplicationStatusExpired:
            self.labStatus.text = RCLocalizedString(@"FriendApplicationExpired");
            break;
        default:
            self.labStatus.text = RCLocalizedString(@"FriendApplicationUnHandled");
            break;
    }
}

- (void)btnExpandClick:(id)sender {
    [self.viewModel expandRemark];
}
#pragma mark - GETTER

- (UIImageView *)portraitImageView {
    if (!_portraitImageView) {
        _portraitImageView = [RCloudImageView new];
        if (RCKitConfigCenter.ui.globalConversationAvatarStyle == RC_USER_AVATAR_CYCLE &&
            RCKitConfigCenter.ui.globalMessageAvatarStyle == RC_USER_AVATAR_CYCLE) {
            _portraitImageView.layer.cornerRadius = 20.f;
        } else {
            _portraitImageView.layer.cornerRadius = 5.f;
        }
        _portraitImageView.bounds = CGRectMake(0, 0, RCFriendApplyCellPortraitWidth, RCFriendApplyCellPortraitWidth);
        _portraitImageView.layer.masksToBounds = YES;
        [_portraitImageView setPlaceholderImage:RCDynamicImage(@"conversation-list_cell_portrait_msg_img",@"default_portrait_msg")];

    }
    return _portraitImageView;
}

- (UILabel *)labName {
    if (!_labName) {
        UILabel *lab = [UILabel new];
        lab.font = [UIFont boldSystemFontOfSize:17];
        _labName = lab;
    }
    return _labName;
}

- (UILabel *)labRemark {
    if (!_labRemark) {
        UILabel *lab = [UILabel new];
        lab.textColor = RCDYCOLOR(0xA0A5Ab, 0x878787);
        lab.font = [UIFont systemFontOfSize:14];
        lab.numberOfLines = 0;
        lab.userInteractionEnabled = YES;
        _labRemark = lab;
    }
    return _labRemark;
}


- (UILabel *)labStatus {
    if (!_labStatus) {
        UILabel *lab = [UILabel new];
        lab.textColor = RCDYCOLOR(0xA0A5Ab, 0x878787);
        lab.font = [UIFont systemFontOfSize:13];
        _labStatus = lab;
    }
    return _labStatus;
}

- (UIButton *)btnExpand {
    if (!_btnExpand) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setTitle:RCLocalizedString(@"FriendApplicationExpand")
             forState:UIControlStateNormal];
        btn.hidden = YES;
        btn.titleLabel.font = [UIFont systemFontOfSize:14];
        btn.bounds = CGRectMake(0, 0, RCFriendApplyCellBtnExpandWidth, 14);
        [btn addTarget:self
                action:@selector(btnExpandClick:)
      forControlEvents:UIControlEventTouchUpInside];
        [btn setTitleColor:HEXCOLOR(0x0099FF) forState:UIControlStateNormal];
        [btn sizeToFit];
        _btnExpand = btn;
    }
    return _btnExpand;
}

- (UIView *)buttonsContainer {
    if (!_buttonsContainer) {
        _buttonsContainer = [UIView new];
        _buttonsContainer.bounds = CGRectMake(0, 0, RCFriendApplyCellBtnContainerWidth, 24);
    }
    return _buttonsContainer;
}
@end
