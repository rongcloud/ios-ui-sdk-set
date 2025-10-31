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
#import "RCConversationModel.h"
#import "RCBaseImageView.h"
#import "RCBaseLabel.h"
@interface RCSelectConversationCell ()
/*!
 Cell的数据模型
 */
@property (nonatomic, strong) RCConversation *model;

@property (nonatomic, strong) RCBaseImageView *selectedImageView;

@property (nonatomic, strong) RCloudImageView *headerImageView;

@property (nonatomic, strong) RCBaseLabel *nameLabel;

@end

@implementation RCSelectConversationCell
#pragma mark - Life Cycle
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.contentView.backgroundColor = RCDynamicColor(@"common_background_color", @"0xffffff", @"0x1c1c1e66");
        [self.contentView addSubview:self.selectedImageView];
        [self.contentView addSubview:self.headerImageView];
        [self.contentView addSubview:self.nameLabel];
        
        [self registerObserver];
    }
    return self;
}

- (void)registerObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onUserInfoUpdate:)
                                                 name:RCKitDispatchUserInfoUpdateNotification
                                               object:nil];
   
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onGroupInfoUpdate:)
                                                 name:RCKitDispatchGroupInfoUpdateNotification
                                               object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Public Methods

- (void)setConversation:(RCConversation *)conversation ifSelected:(BOOL)ifSelected {
    if (!conversation) {
        return;
    }
    self.model = conversation;
    RCConversationModel *rcModel = [[RCConversationModel alloc] initWithConversation:conversation extend:nil];
    UIImage *defaultHeaderImg = [RCKitUtility defaultConversationHeaderImage:rcModel];
    [self.headerImageView setPlaceholderImage:defaultHeaderImg];
    
    if (ifSelected) {
        [self.selectedImageView setImage:RCDynamicImage(@"conversation_msg_cell_select_img", @"message_cell_select")];
    } else {
        [self.selectedImageView setImage:RCDynamicImage(@"conversation_msg_cell_unselect_img", @"message_cell_unselect")];
    }
    if (conversation.conversationType == ConversationType_GROUP) {
        RCGroup *group = [[RCUserInfoCacheManager sharedManager] getGroupInfo:conversation.targetId];
        if (group) {
            [self.headerImageView setImageURL:[NSURL URLWithString:group.portraitUri]];
            [self.nameLabel setText:group.groupName];
        } else {
            [self.headerImageView setPlaceholderImage:RCDynamicImage(@"conversation-list_cell_group_portrait_img", @"default_group_portrait")];
            [self.nameLabel setText:conversation.targetId];
        }
    } else {
        RCUserInfo *userInfo = [[RCUserInfoCacheManager sharedManager] getUserInfo:conversation.targetId];
        if (userInfo) {
            [self.headerImageView setImageURL:[NSURL URLWithString:userInfo.portraitUri]];
            [self.nameLabel setText:[RCKitUtility getDisplayName:userInfo]];
        } else {
            [self.headerImageView setPlaceholderImage:RCDynamicImage(@"conversation-list_cell_portrait_msg_img",@"default_portrait_msg")];
            [self.nameLabel setText:conversation.targetId];
        }
    }
}

#pragma mark - Private Methods

- (void)resetSubviews {
    [self.selectedImageView setImage:RCDynamicImage(@"conversation_msg_cell_unselect_img", @"message_cell_unselect")];
    [self.headerImageView setPlaceholderImage:RCDynamicImage(@"conversation-list_cell_portrait_msg_img",@"default_portrait_msg")];
    self.nameLabel.text = nil;
}

#pragma mark - Notification selector
- (void)onUserInfoUpdate:(NSNotification *)notification {
    NSDictionary *userInfoDic = notification.object;
    RCUserInfo *updateUserInfo = userInfoDic[@"userInfo"];
    NSString *updateUserId = userInfoDic[@"userId"];

    if (![updateUserId isEqualToString:self.model.targetId]) {
        return;
    }
    if (self.model.conversationType == ConversationType_GROUP) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (updateUserInfo) {
            [self.headerImageView setImageURL:[NSURL URLWithString:updateUserInfo.portraitUri]];
            [self.nameLabel setText:[RCKitUtility getDisplayName:updateUserInfo]];
        }
    });
}

- (void)onGroupInfoUpdate:(NSNotification *)notification {
    NSDictionary *groupInfoDic = (NSDictionary *)notification.object;
    RCGroup *groupInfo = groupInfoDic[@"groupInfo"];
    if (![self.model.targetId isEqualToString:groupInfo.groupId]) {
        return;
    }
    
    if (self.model.conversationType != ConversationType_GROUP) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (groupInfo) {
            [self.headerImageView setImageURL:[NSURL URLWithString:groupInfo.portraitUri]];
            [self.nameLabel setText:groupInfo.groupName];
        }
    });
}

#pragma mark - Getters and Setters

- (RCBaseImageView *)selectedImageView {
    if (!_headerImageView) {
        _selectedImageView = [[RCBaseImageView alloc] init];
        if ([RCKitUtility isRTL]) {
            // 神奇的地方：这里的 self.bounds = (origin = (x = 0, y = 0), size = (width = 320, height = 44))
            _selectedImageView.frame = CGRectMake(self.bounds.size.width + 20 + 5, 25, 20, 20);
        } else {
            _selectedImageView.frame = CGRectMake(10, 25, 20, 20);
        }
        [_selectedImageView setImage:RCDynamicImage(@"conversation_msg_cell_unselect_img", @"message_cell_unselect")];
    }
    return _selectedImageView;
}

- (RCloudImageView *)headerImageView {
    if (!_headerImageView) {
        _headerImageView = [[RCloudImageView alloc] init];
        _headerImageView.contentMode = UIViewContentModeScaleAspectFill;
        [_headerImageView setPlaceholderImage:RCDynamicImage(@"conversation-list_cell_portrait_msg_img",@"default_portrait_msg")];
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

- (RCBaseLabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[RCBaseLabel alloc] init];
        if ([RCKitUtility isRTL]) {
            _nameLabel.frame = CGRectMake(0, 5, self.bounds.size.width - 55, 60);
        } else {
            _nameLabel.frame = CGRectMake(110, 5, self.bounds.size.width - 110, 60);
        }
        _nameLabel.textColor = RCDynamicColor(@"text_primary_color", @"0x000000", @"0x9f9f9f");
    }
    return _nameLabel;
}

@end
