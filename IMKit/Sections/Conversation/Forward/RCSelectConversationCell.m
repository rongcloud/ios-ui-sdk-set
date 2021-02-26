//
//  RCSelectConversationCell.m
//  RongCallKit
//
//  Created by 岑裕 on 16/3/15.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCSelectConversationCell.h"
#import "RCKitCommonDefine.h"
#import "RCKitUtility.h"
#import "RCUserInfoCacheManager.h"
#import "RCloudImageView.h"

@interface RCSelectConversationCell ()

@property (nonatomic, strong) UIImageView *selectedImageView;

@property (nonatomic, strong) RCloudImageView *headerImageView;

@property (nonatomic, strong) UILabel *nameLabel;

@end

@implementation RCSelectConversationCell
#pragma mark - Life Cycle
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.contentView.backgroundColor =
            [RCKitUtility generateDynamicColor:HEXCOLOR(0xffffff)
                                     darkColor:[HEXCOLOR(0x1c1c1e) colorWithAlphaComponent:0.4]];
        [self.contentView addSubview:self.selectedImageView];
        [self.contentView addSubview:self.headerImageView];
        [self.contentView addSubview:self.nameLabel];
    }
    return self;
}

#pragma mark - Public Methods

- (void)setConversation:(RCConversation *)conversation ifSelected:(BOOL)ifSelected {
    if (!conversation) {
        return;
    }
    if (ifSelected) {
        [self.selectedImageView setImage:RCResourceImage(@"message_cell_select")];
    } else {
        [self.selectedImageView setImage:RCResourceImage(@"message_cell_unselect")];
    }
    if (conversation.conversationType == ConversationType_GROUP) {
        RCGroup *group = [[RCUserInfoCacheManager sharedManager] getGroupInfoFromCacheOnly:conversation.targetId];
        if (group) {
            [self.headerImageView setImageURL:[NSURL URLWithString:group.portraitUri]];
            [self.nameLabel setText:group.groupName];
        } else {
            [self.headerImageView setPlaceholderImage:RCResourceImage(@"default_group_portrait")];
            [self.nameLabel setText:conversation.targetId];
        }
    } else {
        RCUserInfo *userInfo = [[RCUserInfoCacheManager sharedManager] getUserInfo:conversation.targetId];
        if (userInfo) {
            [self.headerImageView setImageURL:[NSURL URLWithString:userInfo.portraitUri]];
            [self.nameLabel setText:userInfo.name];
        } else {
            [self.headerImageView setPlaceholderImage:RCResourceImage(@"default_portrait_msg")];
            [self.nameLabel setText:conversation.targetId];
        }
    }
}

#pragma mark - Private Methods

- (void)resetSubviews {
    [self.selectedImageView setImage:RCResourceImage(@"message_cell_unselect")];
    [self.headerImageView setPlaceholderImage:RCResourceImage(@"default_portrait_msg")];
    self.nameLabel.text = nil;
}

#pragma mark - Getters and Setters

- (UIImageView *)selectedImageView {
    if (!_headerImageView) {
        _selectedImageView = [[UIImageView alloc] init];
        if ([RCKitUtility isRTL]) {
            // 神奇的地方：这里的 self.bounds = (origin = (x = 0, y = 0), size = (width = 320, height = 44))
            _selectedImageView.frame = CGRectMake(self.bounds.size.width + 20 + 5, 25, 20, 20);
        } else {
            _selectedImageView.frame = CGRectMake(10, 25, 20, 20);
        }
        [_selectedImageView setImage:RCResourceImage(@"message_cell_unselect")];
    }
    return _selectedImageView;
}

- (RCloudImageView *)headerImageView {
    if (!_headerImageView) {
        _headerImageView = [[RCloudImageView alloc] init];
        _headerImageView.contentMode = UIViewContentModeScaleAspectFill;
        [_headerImageView setPlaceholderImage:RCResourceImage(@"default_portrait_msg")];
        if ([RCKitUtility isRTL]) {
            _headerImageView.frame = CGRectMake(self.bounds.size.width - 45, 5, 60, 60);
        } else {
            _headerImageView.frame = CGRectMake(40, 5, 60, 60);
        }
        _headerImageView.layer.cornerRadius = 5;
        _headerImageView.layer.masksToBounds = YES;
    }
    return _headerImageView;
}

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] init];
        if ([RCKitUtility isRTL]) {
            _nameLabel.frame = CGRectMake(0, 5, self.bounds.size.width - 55, 60);
            _nameLabel.textAlignment = NSTextAlignmentRight;
        } else {
            _nameLabel.frame = CGRectMake(110, 5, self.bounds.size.width - 110, 60);
            _nameLabel.textAlignment = NSTextAlignmentLeft;
        }
        _nameLabel.textColor = RCDYCOLOR(0x000000, 0x9f9f9f);
    }
    return _nameLabel;
}

@end
