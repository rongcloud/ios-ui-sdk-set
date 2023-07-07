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

@end

@implementation RCCCContactTableViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
        self.backgroundColor = [RCKitUtility generateDynamicColor:[UIColor colorWithHexString:@"ffffff" alpha:1] darkColor:[UIColor colorWithHexString:@"191919" alpha:1]];
    }
    return self;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self initialize];
        self.backgroundColor = [RCKitUtility generateDynamicColor:[UIColor colorWithHexString:@"ffffff" alpha:1] darkColor:[UIColor colorWithHexString:@"191919" alpha:1]];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
        self.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (void)initialize {
    _portraitView = [[RCloudImageView alloc] init];
    if (RCKitConfigCenter.ui.globalConversationAvatarStyle == RC_USER_AVATAR_CYCLE &&
        RCKitConfigCenter.ui.globalMessageAvatarStyle == RC_USER_AVATAR_CYCLE) {
        _portraitView.layer.cornerRadius = 20.f;
    }else{
        _portraitView.layer.cornerRadius = 5.f;
    }
    _portraitView.layer.masksToBounds = YES;

    _portraitView.translatesAutoresizingMaskIntoConstraints = NO;
    [_portraitView setPlaceholderImage:[RCCCUtilities imageNamed:@"default_portrait_msg" ofBundle:@"RongCloud.bundle"]];
    [self.contentView addSubview:_portraitView];

    _nicknameLabel = [[UILabel alloc] init];
    _nicknameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_nicknameLabel setFont:[UIFont fontWithName:@"Heiti SC" size:17.0]];
    _nicknameLabel.textColor = [RCKitUtility generateDynamicColor:[UIColor colorWithHexString:@"000000" alpha:1] darkColor:[UIColor colorWithHexString:@"ffffff" alpha:0.9]];
    [self.contentView addSubview:_nicknameLabel];

    _userIdLabel = [[UILabel alloc] init];
    _userIdLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_userIdLabel setFont:[UIFont fontWithName:@"Heiti SC" size:15.0]];
    _userIdLabel.textColor = [RCKitUtility generateDynamicColor:[UIColor colorWithHexString:@"000000" alpha:1]
                                                      darkColor:[UIColor colorWithHexString:@"ffffff" alpha:1]];
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

    BOOL isDisplayID = [[NSUserDefaults standardUserDefaults] boolForKey:@"isDisplayID"];

    if (isDisplayID == YES) {
        [self.contentView addConstraints:[NSLayoutConstraint
                                             constraintsWithVisualFormat:
                                                 @"H:|-12-[_portraitView(40)]-12-[_nicknameLabel][_userIdLabel(90)]-40-|"
                                                                 options:kNilOptions
                                                                 metrics:nil
                                                                   views:views]];

        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_userIdLabel
                                                                     attribute:NSLayoutAttributeCenterY
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.contentView
                                                                     attribute:NSLayoutAttributeCenterY
                                                                    multiplier:1.0f
                                                                      constant:0]];
    } else {
        [self.contentView
            addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"H:|-10-[_portraitView(40)]-12-[_nicknameLabel]-40-|"
                                                   options:kNilOptions
                                                   metrics:nil
                                                     views:views]];
    }

    self.selectedBackgroundView = [[UIView alloc] initWithFrame:self.frame];
    self.selectedBackgroundView.backgroundColor = [UIColor colorWithHexString:@"f5f5f5" alpha:1.0];
}

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
@end
