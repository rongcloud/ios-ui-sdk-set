//
//  RCReferencingView.m
//  RongIMKit
//
//  Created by 张改红 on 2020/2/27.
//  Copyright © 2020 RongCloud. All rights reserved.
//

#import "RCReferencingView.h"
#import "RCKitUtility.h"
#import "RCKitCommonDefine.h"
#import "RCUserInfoCacheManager.h"
#import "RCMessageCellTool.h"
#import "RCKitConfig.h"
@interface RCReferencingView ()
@property (nonatomic, strong) UIView *inView;
@end

#define textlabel_left_space 12
#define textlabel_and_dismiss_space 8
#define dismiss_right_space 12
#define dismiss_width 16
@implementation RCReferencingView
- (instancetype)initWithModel:(RCMessageModel *)model inView:(UIView *)view {
    if (self = [super init]) {
        self.backgroundColor = [RCKitUtility generateDynamicColor:HEXCOLOR(0xffffff) darkColor:HEXCOLOR(0x1c1c1c)];
        self.inView = view;
        self.referModel = model;
        [self addNotification];
        [self setContentInfo];
        [self setupSubviews];
    }
    return self;
}

- (void)setOffsetY:(CGFloat)offsetY {
    [UIView animateWithDuration:0.25
                     animations:^{
                         CGRect rect = self.frame;
                         rect.origin.y = offsetY;
                         self.frame = rect;
                     }];
}

#pragma mark - Private Methods

- (void)setupSubviews {
    self.frame = CGRectMake(0, self.inView.frame.size.height, self.inView.frame.size.width,60);
    if ([RCKitUtility isRTL]) {
        self.dismissButton.frame = CGRectMake(dismiss_right_space, (self.frame.size.height - dismiss_width)/2, dismiss_width, dismiss_width);
        self.nameLabel.frame = CGRectMake(textlabel_left_space, 10, self.frame.size.width - self.dismissButton.frame.origin.x - textlabel_left_space - textlabel_and_dismiss_space, 20);
        self.textLabel.frame = CGRectMake(textlabel_left_space, CGRectGetMaxY(self.nameLabel.frame), self.frame.size.width - self.dismissButton.frame.origin.x - textlabel_left_space - textlabel_and_dismiss_space, 20);
    } else {
        self.dismissButton.frame = CGRectMake(self.frame.size.width - dismiss_width - dismiss_right_space, 10, dismiss_width, dismiss_width);
        self.nameLabel.frame = CGRectMake(textlabel_left_space, 10, self.dismissButton.frame.origin.x - textlabel_left_space - textlabel_and_dismiss_space, 20);
        self.textLabel.frame = CGRectMake(textlabel_left_space, CGRectGetMaxY(self.nameLabel.frame), self.dismissButton.frame.origin.x - textlabel_left_space - textlabel_and_dismiss_space, 20);
    }
    [self addSubview:self.dismissButton];
    [self addSubview:self.nameLabel];
    [self addSubview:self.textLabel];
}

- (void)setContentInfo {
    NSString *messageInfo;
    if ([self.referModel.content isKindOfClass:[RCFileMessage class]]) {
        RCFileMessage *msg = (RCFileMessage *)self.referModel.content;
        messageInfo = [NSString
            stringWithFormat:@"%@ %@", RCLocalizedString(@"RC:FileMsg"), msg.name];
    } else if ([self.referModel.content isKindOfClass:[RCRichContentMessage class]]) {
        RCRichContentMessage *msg = (RCRichContentMessage *)self.referModel.content;
        messageInfo = [NSString
            stringWithFormat:@"%@ %@", RCLocalizedString(@"RC:ImgTextMsg"), msg.title];
    } else if ([self.referModel.content isKindOfClass:[RCTextMessage class]] ||
               [self.referModel.content isKindOfClass:[RCReferenceMessage class]]) {
        messageInfo = [RCKitUtility formatMessage:self.referModel.content
                                                 targetId:self.referModel.targetId
                                         conversationType:self.referModel.conversationType
                                             isAllMessage:YES];
    } else if ([self.referModel.content isKindOfClass:[RCMessageContent class]]) {
        messageInfo = [RCKitUtility formatMessage:self.referModel.content
                                                 targetId:self.referModel.targetId
                                         conversationType:self.referModel.conversationType
                                             isAllMessage:YES];
        if (messageInfo <= 0 ||
            [messageInfo isEqualToString:[[self.referModel.content class] getObjectName]]) {
            messageInfo = RCLocalizedString(@"unknown_message_cell_tip");
        }
    }
    self.nameLabel.text = [NSString stringWithFormat:@"%@：",[self getUserDisplayName]];
    //替换换行符为空格
    messageInfo = [messageInfo stringByReplacingOccurrencesOfString:@"\r\n" withString:@" "];
    messageInfo = [messageInfo stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    messageInfo = [messageInfo stringByReplacingOccurrencesOfString:@"\r" withString:@" "];
    self.textLabel.text = [NSString stringWithFormat:@"%@",messageInfo];
}

- (void)didClickDismissButton:(UIButton *)button {
    if (self.delegate && [self.delegate respondsToSelector:@selector(dismissReferencingView:)]) {
        [self.delegate dismissReferencingView:self];
    }
}

- (NSString *)getUserDisplayName {
    NSString *name;
    if (ConversationType_GROUP == self.referModel.conversationType) {
        RCUserInfo *userInfo = [[RCUserInfoCacheManager sharedManager] getUserInfo:self.referModel.senderUserId
                                                                         inGroupId:self.referModel.targetId];
        self.referModel.userInfo = userInfo;
        if (userInfo) {
            name = userInfo.name;
        }
    } else {
        RCUserInfo *userInfo = [[RCUserInfoCacheManager sharedManager] getUserInfo:self.referModel.senderUserId];
        self.referModel.userInfo = userInfo;
        if (userInfo) {
            name = userInfo.name;
        }
    }
    return name;
}

- (void)addNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onUserInfoUpdate:)
                                                 name:RCKitDispatchUserInfoUpdateNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onGroupUserInfoUpdate:)
                                                 name:RCKitDispatchGroupUserInfoUpdateNotification
                                               object:nil];
}

- (void)didTapContentView:(id)sender {
    if ([self.delegate respondsToSelector:@selector(didTapReferencingView:)]) {
        [self.delegate didTapReferencingView:self.referModel];
    }
}


#pragma mark - UserInfo Update
- (void)onUserInfoUpdate:(NSNotification *)notification {
    NSDictionary *userInfoDic = notification.object;
    if ([self.referModel.senderUserId isEqualToString:userInfoDic[@"userId"]]) {
        //重新取一下混合的用户信息
        [self setContentInfo];
    }
}

- (void)onGroupUserInfoUpdate:(NSNotification *)notification {
    if (self.referModel.conversationType == ConversationType_GROUP) {
        NSDictionary *groupUserInfoDic = (NSDictionary *)notification.object;
        if ([self.referModel.targetId isEqualToString:groupUserInfoDic[@"inGroupId"]] &&
            [self.referModel.senderUserId isEqualToString:groupUserInfoDic[@"userId"]]) {
            //重新取一下混合的用户信息
            [self setContentInfo];
        }
    }
}

#pragma mark - Getters and Setters
- (UIButton *)dismissButton {
    if (!_dismissButton) {
        _dismissButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_dismissButton setImage:RCResourceImage(@"referencing_view_dismiss_icon") forState:UIControlStateNormal];
        [_dismissButton addTarget:self
                           action:@selector(didClickDismissButton:)
                 forControlEvents:UIControlEventTouchUpInside];
    }
    return _dismissButton;
}

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.textColor = [RCKitUtility generateDynamicColor:HEXCOLOR(0x111f2c) darkColor:RCMASKCOLOR(0xffffff, 0.4)];
        _nameLabel.font = [[RCKitConfig defaultConfig].font fontOfGuideLevel];
    }
    return _nameLabel;
}

- (UILabel *)textLabel {
    if (!_textLabel) {
        _textLabel = [[UILabel alloc] init];
        _textLabel.numberOfLines = 1;
        [_textLabel setLineBreakMode:NSLineBreakByTruncatingTail];
        _textLabel.font = [[RCKitConfig defaultConfig].font fontOfGuideLevel];
        _textLabel.textColor = [RCKitUtility generateDynamicColor:HEXCOLOR(0x111f2c) darkColor:RCMASKCOLOR(0xffffff, 0.4)];
        UITapGestureRecognizer *messageTap =
            [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapContentView:)];
        messageTap.numberOfTapsRequired = 1;
        messageTap.numberOfTouchesRequired = 1;
        [_textLabel addGestureRecognizer:messageTap];
    }
    return _textLabel;
}
@end
