//
//  RCCCContactTableViewCell.m
//  RongContactCard
//
//  Created by Jue on 16/3/16.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCCCContactTableViewCell.h"
#import "UIColor+RCCCColor.h"
#import "RCCCUtilities.h"
#import "RongContactCardAdaptiveHeader.h"
@interface RCCCContactTableViewCell ()
@property (nonatomic, strong) UIView *paddingContainerView;
@end

@implementation RCCCContactTableViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
//        self.backgroundColor = RCDynamicColor(@"common_background_color", @"0xffffff", @"191919");
    }
    return self;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self initialize];
//        self.backgroundColor = RCDynamicColor(@"common_background_color", @"0xffffff", @"191919");
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
//        self.backgroundColor = RCDynamicColor(@"common_background_color", @"0xffffff", @"191919");
    }
    return self;
}

- (void)initialize {
    [self.contentView addSubview:self.paddingContainerView];
    [self.paddingContainerView addSubview:self.lineView];
    self.contentView.backgroundColor = [UIColor clearColor];
    self.backgroundColor = [UIColor clearColor];

     // contentView 缩小，左右各留 16px 透明间隙
     [NSLayoutConstraint activateConstraints:@[
        [self.paddingContainerView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:RCUserManagementPadding],
        [self.paddingContainerView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-5],
         [self.paddingContainerView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
         [self.paddingContainerView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
        [self.lineView.leadingAnchor constraintEqualToAnchor:self.paddingContainerView.leadingAnchor constant:63],
        [self.lineView.trailingAnchor constraintEqualToAnchor:self.paddingContainerView.trailingAnchor],
        [self.lineView.heightAnchor constraintEqualToConstant:1],
        [self.lineView.bottomAnchor constraintEqualToAnchor:self.paddingContainerView.bottomAnchor]
     ]];
    _portraitView = [[RCloudImageView alloc] init];
    if (RCKitConfigCenter.ui.globalConversationAvatarStyle == RC_USER_AVATAR_CYCLE &&
        RCKitConfigCenter.ui.globalMessageAvatarStyle == RC_USER_AVATAR_CYCLE) {
        _portraitView.layer.cornerRadius = 20.f;
    }else{
        _portraitView.layer.cornerRadius = 5.f;
    }
    _portraitView.layer.masksToBounds = YES;

    _portraitView.translatesAutoresizingMaskIntoConstraints = NO;
    [_portraitView setPlaceholderImage:RCDynamicImage(@"conversation-list_cell_portrait_msg_img",@"default_portrait_msg")];
    [self.contentView addSubview:_portraitView];

    _nicknameLabel = [[RCBaseLabel alloc] init];
    _nicknameLabel.textAlignment = [RCKitUtility isRTL] ? NSTextAlignmentRight : NSTextAlignmentLeft;
    _nicknameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_nicknameLabel setFont:[UIFont fontWithName:@"Heiti SC" size:17.0]];
    _nicknameLabel.textColor = RCDynamicColor(@"text_primary_color", @"0x000000", @"0xffffffe5");
    [self.contentView addSubview:_nicknameLabel];

    _userIdLabel = [[RCBaseLabel alloc] init];
    _userIdLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_userIdLabel setFont:[UIFont fontWithName:@"Heiti SC" size:15.0]];
    _userIdLabel.textColor = RCDynamicColor(@"text_primary_color", @"0x000000", @"0xffffff");
    [self.contentView addSubview:_userIdLabel];

    NSDictionary *views = NSDictionaryOfVariableBindings(_portraitView, _nicknameLabel, _userIdLabel);

    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_portraitView
                                                                 attribute:NSLayoutAttributeCenterY
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.contentView
                                                                 attribute:NSLayoutAttributeCenterY
                                                                multiplier:1.0f
                                                                  constant:0]];

    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_nicknameLabel
                                                                 attribute:NSLayoutAttributeCenterY
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.contentView
                                                                 attribute:NSLayoutAttributeCenterY
                                                                multiplier:1.0f
                                                                  constant:0]];

    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_portraitView(40)]"
                                                                             options:kNilOptions
                                                                             metrics:nil
                                                                               views:views]];
    [self.contentView
     addConstraints:[NSLayoutConstraint
                     constraintsWithVisualFormat:@"H:|-26-[_portraitView(40)]-12-[_nicknameLabel]-40-|"
                     options:kNilOptions
                     metrics:nil
                     views:views]];
    
    self.selectedBackgroundView = [[UIView alloc] initWithFrame:self.frame];
    self.selectedBackgroundView.backgroundColor = RCDynamicColor(@"selected_background_color", @"0xf5f5f5", @"0xf5f5f5");
}

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (UIView *)paddingContainerView {
    if (!_paddingContainerView) {
        _paddingContainerView = [UIView new];
        _paddingContainerView.backgroundColor = RCDynamicColor(@"common_background_color", @"0xffffff", @"0x1c1c1e");
        _paddingContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _paddingContainerView;
}
- (UIView *)lineView {
    if (!_lineView) {
        _lineView = [UIView new];
        _lineView.backgroundColor = RCDynamicColor(@"line_background_color", @"0xE3E5E6", @"0x272727");
        _lineView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _lineView;
}
@end
