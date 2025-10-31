//
//  RCMessageReadDetailCell.m
//  RongIMKit
//
//  Created by Lang on 10/15/25.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCMessageReadDetailCell.h"
#import "RCKitUtility.h"
#import "RCKitCommonDefine.h"
#import "RCloudImageView.h"

@interface RCMessageReadDetailCell ()

/// 头像
@property (nonatomic, strong) RCloudImageView *portraitImageView;

/// 昵称
@property (nonatomic, strong) UILabel *nameLabel;

/// 时间
@property (nonatomic, strong) UILabel *timeLabel;

@end

@implementation RCMessageReadDetailCell

+ (NSString *)reuseIdentifier {
    return NSStringFromClass([self class]);
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.portraitImageView.image = nil;
    self.nameLabel.text = nil;
    self.timeLabel.text = nil;
    self.timeLabel.hidden = YES;
}

- (void)setupView {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    // 头像
    self.portraitImageView = [[RCloudImageView alloc] initWithPlaceholderImage:RCDynamicImage(@"conversation-list_cell_portrait_msg_img",@"default_portrait_msg")];
    [self.contentView addSubview:self.portraitImageView];
    
    // 用户名
    [self.contentView addSubview:self.nameLabel];
    // 时间
    [self.contentView addSubview:self.timeLabel];
    
    [self setupConstraints];
}

- (void)setupConstraints {
    self.portraitImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.timeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    CGFloat padding = 16;
    CGFloat avatarSize = 40;
    CGFloat spacing = 12;
    
    self.portraitImageView.layer.cornerRadius = avatarSize/2.0;
    self.portraitImageView.clipsToBounds = YES;
    
    [NSLayoutConstraint activateConstraints:@[
        [self.portraitImageView.widthAnchor constraintEqualToConstant:avatarSize],
        [self.portraitImageView.heightAnchor constraintEqualToConstant:avatarSize],
        [self.portraitImageView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:padding],
        [self.portraitImageView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor]
    ]];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.nameLabel.leadingAnchor constraintEqualToAnchor:self.portraitImageView.trailingAnchor constant:spacing],
        [self.nameLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor]
    ]];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.timeLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.nameLabel.trailingAnchor constant:spacing],
        [self.timeLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-padding],
        [self.timeLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor]
    ]];
}

- (void)bindViewModel:(RCMessageReadDetailCellViewModel *)viewModel {
    // 设置用户名
    self.nameLabel.text = viewModel.userInfo.name ?: viewModel.userInfo.userId;
    
    // 设置头像
    if (viewModel.userInfo.portraitUri.length > 0) {
        self.portraitImageView.imageURL = [NSURL URLWithString:viewModel.userInfo.portraitUri];
    } else {
        self.portraitImageView.image = RCDynamicImage(@"conversation-list_cell_portrait_msg_img",@"default_portrait_msg");
    }
    
    // 设置时间
    if (viewModel.displayReadTime.length > 0) {
        self.timeLabel.hidden = NO;
        self.timeLabel.text = viewModel.displayReadTime;
    } else {
        self.timeLabel.hidden = YES;
    }
}

#pragma mark - Getter

- (UILabel *)timeLabel {
    if (!_timeLabel) {
        _timeLabel = [[UILabel alloc] init];
        _timeLabel.font = [UIFont systemFontOfSize:12];
        _timeLabel.textColor = RCDynamicColor(@"text_secondary_color", @"0x7C838E", @"0x7C838E");
        // 设置更高的内容压缩抵抗优先级，确保时间标签始终完整显示
        [_timeLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [_timeLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    }
    return _timeLabel;
}

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.font = [UIFont systemFontOfSize:14];
        _nameLabel.textColor = RCDynamicColor(@"text_primary_color", @"0x020814", @"0xFFFFFF");
		[_nameLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        [_nameLabel setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    }
    return _nameLabel;
}

- (RCloudImageView *)portraitImageView{
    if (!_portraitImageView) {
        _portraitImageView = [[RCloudImageView alloc] initWithPlaceholderImage:RCDynamicImage(@"conversation-list_cell_portrait_msg_img",@"default_portrait_msg")];
     }
    return _portraitImageView;
}

@end


