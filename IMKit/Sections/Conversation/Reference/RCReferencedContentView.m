//
//  RCReferencedContentView.m
//  RongIMKit
//
//  Created by 张改红 on 2020/2/27.
//  Copyright © 2020 RongCloud. All rights reserved.
//

#import "RCReferencedContentView.h"
#import "RCKitUtility.h"
#import "RCKitCommonDefine.h"
#import "RCUserInfoCacheManager.h"
#import "RCMessageCellTool.h"
#import "RCKitConfig.h"
#define leftLine_width 2
#define name_and_leftLine_space 4
#define name_height 17
@interface RCReferencedContentView ()
@property (nonatomic, strong) RCMessageModel *referModel;
@property (nonatomic, assign) CGSize contentSize;
@property (nonatomic, strong) UIView *contentView;
@end
@implementation RCReferencedContentView
- (instancetype)init {
    if (self = [super init]) {
        self.frame = CGRectZero;
    }
    return self;
}

- (void)setMessage:(RCMessageModel *)message contentSize:(CGSize)contentSize {
    [self resetReferencedContentView];
    self.frame = CGRectMake(0, 0, contentSize.width, contentSize.height);
    self.referModel = message;
    self.contentSize = contentSize;
    [self addNotification];
    [self setUserDisplayName];
    [self setContentInfo];
    [self setupSubviews];
}

#pragma mark - Private Methods
- (void)setContentInfo {
    RCReferenceMessage *content = (RCReferenceMessage *)self.referModel.content;
    NSString *messageInfo = @"";
    if ([content.referMsg isKindOfClass:[RCFileMessage class]]) {
        RCFileMessage *msg = (RCFileMessage *)content.referMsg;
        messageInfo = [NSString
            stringWithFormat:@"%@ %@", RCLocalizedString(@"RC:FileMsg"), msg.name];
    } else if ([content.referMsg isKindOfClass:[RCRichContentMessage class]]) {
        RCRichContentMessage *msg = (RCRichContentMessage *)content.referMsg;
        messageInfo = [NSString
            stringWithFormat:@"%@ %@", RCLocalizedString(@"RC:ImgTextMsg"), msg.title];
    } else if ([content.referMsg isKindOfClass:[RCImageMessage class]]) {
        RCImageMessage *msg = (RCImageMessage *)content.referMsg;
        self.msgImageView.image = msg.thumbnailImage;
        CGSize imageSize = [RCMessageCellTool getThumbnailImageSize:msg.thumbnailImage];
        if ([RCKitUtility isRTL]) {
            self.msgImageView.frame = CGRectMake(self.frame.size.width - imageSize.width, name_and_image_view_space, imageSize.width, imageSize.height);
        } else {
            self.msgImageView.frame = CGRectMake(0, name_and_image_view_space, imageSize.width, imageSize.height);
        }
    } else if ([content.referMsg isKindOfClass:[RCTextMessage class]] ||
               [content.referMsg isKindOfClass:[RCReferenceMessage class]]) {
        // 设置 text 之前设置 textColor，textLabel 的 attributeDictionary 设置才有效
        messageInfo = [RCKitUtility formatMessage:content.referMsg
                                                 targetId:self.referModel.targetId
                                         conversationType:self.referModel.conversationType
                                             isAllMessage:YES];
    } else if ([content.referMsg isKindOfClass:[RCMessageContent class]]) {
        messageInfo = [RCKitUtility formatMessage:content.referMsg
                                                 targetId:self.referModel.targetId
                                         conversationType:self.referModel.conversationType
                                             isAllMessage:YES];
        if (messageInfo.length <= 0 ||
            [messageInfo isEqualToString:[[content.referMsg class] getObjectName]]) {
            messageInfo = RCLocalizedString(@"unknown_message_cell_tip");
        }
    }
    if (messageInfo.length > 0) {
        messageInfo = [messageInfo stringByReplacingOccurrencesOfString:@"\r\n" withString:@" "];
        messageInfo = [messageInfo stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
        messageInfo = [messageInfo stringByReplacingOccurrencesOfString:@"\r" withString:@" "];
        self.textLabel.text = messageInfo;
    }
    
    if(self.referModel.messageDirection == MessageDirection_SEND){
        self.leftLimitLine.backgroundColor = [RCKitUtility generateDynamicColor:HEXCOLOR(0xA0A5Ab) darkColor:RCMASKCOLOR(0x040a0f, 0.4)];
        self.nameLabel.textColor = [RCKitUtility generateDynamicColor:HEXCOLOR(0xA0A5Ab) darkColor:RCMASKCOLOR(0x040a0f, 0.4)];
        if ([content.referMsg isKindOfClass:[RCFileMessage class]] || [content.referMsg isKindOfClass:[RCRichContentMessage class]]) {
            self.textLabel.textColor = RCDYCOLOR(0x0099ff, 0x005F9E);
        }else{
            self.textLabel.textColor = [RCKitUtility generateDynamicColor:HEXCOLOR(0xa0a5ab) darkColor:RCMASKCOLOR(0x040a0f, 0.4)];
        }
    }else{
        self.nameLabel.textColor = [RCKitUtility generateDynamicColor:HEXCOLOR(0xA0A5Ab) darkColor:HEXCOLOR(0x999999)];
        self.leftLimitLine.backgroundColor = [RCKitUtility generateDynamicColor:HEXCOLOR(0xA0A5Ab) darkColor:HEXCOLOR(0x999999)];
        if ([content.referMsg isKindOfClass:[RCFileMessage class]] || [content.referMsg isKindOfClass:[RCRichContentMessage class]]) {
            self.textLabel.textColor = RCDYCOLOR(0x0099ff, 0x1290e2);
        }else{
            self.textLabel.textColor = [RCKitUtility generateDynamicColor:HEXCOLOR(0xa0a5ab) darkColor:HEXCOLOR(0x999999)];
        }
    }
    
}

- (void)setupSubviews {
    [self addSubview:self.leftLimitLine];
    [self addSubview:self.nameLabel];
    [self addSubview:self.contentView];
    RCReferenceMessage *content = (RCReferenceMessage *)self.referModel.content;
    if ([content.referMsg isKindOfClass:[RCImageMessage class]]) {
        [self.contentView addSubview:self.msgImageView];
    } else if ([content.referMsg isKindOfClass:[RCRichContentMessage class]] ||
               [content.referMsg isKindOfClass:[RCFileMessage class]]) {
        [self.contentView addSubview:self.textLabel];
    } else {
        [self.contentView addSubview:self.textLabel];
    }
}

- (void)resetReferencedContentView {
    // 移除自身加载的全部view.
    for (UIView *v in self.subviews) {
        [v removeFromSuperview];
    }
    self.msgImageView = nil;
    self.textLabel = nil;
    self.nameLabel = nil;
    self.leftLimitLine = nil;
    self.contentView = nil;
}

- (void)setUserDisplayName {
    NSString *name;
    if ([self.referModel.content isKindOfClass:[RCReferenceMessage class]]) {
        RCReferenceMessage *content = (RCReferenceMessage *)self.referModel.content;
        NSString *referUserId = content.referMsgUserId;
        if (ConversationType_GROUP == self.referModel.conversationType) {
            RCUserInfo *userInfo =
                [[RCUserInfoCacheManager sharedManager] getUserInfo:referUserId inGroupId:self.referModel.targetId];
            self.referModel.userInfo = userInfo;
            if (userInfo) {
                name = userInfo.name;
            }
        } else {
            RCUserInfo *userInfo = [[RCUserInfoCacheManager sharedManager] getUserInfo:referUserId];
            self.referModel.userInfo = userInfo;
            if (userInfo) {
                name = userInfo.name;
            }
        }
        __weak typeof(self) weakSelf = self;
        dispatch_main_async_safe(^{
            weakSelf.nameLabel.text = [name stringByAppendingString:@":"];
        });
    }
}

- (NSDictionary *)attributeDictionary {
    return [RCMessageCellTool getTextLinkOrPhoneNumberAttributeDictionary:self.referModel.messageDirection];
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
    if ([self.delegate respondsToSelector:@selector(didTapReferencedContentView:)]) {
        [self.delegate didTapReferencedContentView:self.referModel];
    }
}

#pragma mark - UserInfo Update
- (void)onUserInfoUpdate:(NSNotification *)notification {
    NSDictionary *userInfoDic = notification.object;
    if ([self.referModel.content isKindOfClass:[RCReferenceMessage class]]) {
        RCReferenceMessage *content = (RCReferenceMessage *)self.referModel.content;
        if ([content.referMsgUserId isEqualToString:userInfoDic[@"userId"]]) {
            //重新取一下混合的用户信息
            [self setUserDisplayName];
        }
    }
}

- (void)onGroupUserInfoUpdate:(NSNotification *)notification {
    if (self.referModel.conversationType == ConversationType_GROUP &&
        [self.referModel.content isKindOfClass:[RCReferenceMessage class]]) {
        RCReferenceMessage *content = (RCReferenceMessage *)self.referModel.content;
        NSDictionary *groupUserInfoDic = (NSDictionary *)notification.object;
        if ([self.referModel.targetId isEqualToString:groupUserInfoDic[@"inGroupId"]] &&
            [content.referMsgUserId isEqualToString:groupUserInfoDic[@"userId"]]) {
            //重新取一下混合的用户信息
            [self setUserDisplayName];
        }
    }
}

#pragma mark - Getters and Setters
- (UIView *)leftLimitLine {
    if (!_leftLimitLine) {
        if ([RCKitUtility isRTL]) {
            _leftLimitLine = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width - leftLine_width, 2, leftLine_width, 13)];
        } else {
            _leftLimitLine = [[UIView alloc] initWithFrame:CGRectMake(0, 2, leftLine_width, 13)];
        }
        _leftLimitLine.backgroundColor =
        [RCKitUtility generateDynamicColor:HEXCOLOR(0xA0A5Ab) darkColor:HEXCOLOR(0x7C7C7C)];
    }
    return _leftLimitLine;
}

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        CGFloat nameX = CGRectGetMaxX(self.leftLimitLine.frame) + name_and_leftLine_space;
        if ([RCKitUtility isRTL]) {
            nameX = 0;
            _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(nameX, 0, self.contentSize.width - nameX - name_and_leftLine_space, name_height)];
        } else {
            _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(nameX, 0, self.contentSize.width - nameX, name_height)];
        }
        _nameLabel.font = [[RCKitConfig defaultConfig].font fontOfFourthLevel];
    }
    return _nameLabel;
}

- (UIView *)contentView {
    if (!_contentView) {
        if ([RCKitUtility isRTL]) {
            _contentView =
            [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.nameLabel.frame), CGRectGetWidth(self.nameLabel.frame), self.frame.size.height - CGRectGetMaxY(self.nameLabel.frame))];
        } else {
            _contentView =
            [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.leftLimitLine.frame) + name_and_leftLine_space,
                                                     CGRectGetMaxY(self.nameLabel.frame),
                                                     CGRectGetWidth(self.nameLabel.frame), self.frame.size.height - CGRectGetMaxY(self.nameLabel.frame))];
        }
        UITapGestureRecognizer *messageTap =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapContentView:)];
        messageTap.numberOfTapsRequired = 1;
        messageTap.numberOfTouchesRequired = 1;
        [_contentView addGestureRecognizer:messageTap];
        _contentView.userInteractionEnabled = YES;
    }
    return _contentView;
}

- (UILabel *)textLabel {
    if (!_textLabel) {
        _textLabel = [[UILabel alloc] initWithFrame:self.contentView.bounds];
        _textLabel.numberOfLines = 1;
        [_textLabel setLineBreakMode:NSLineBreakByTruncatingTail];
        _textLabel.font = [[RCKitConfig defaultConfig].font fontOfFourthLevel];
    }
    return _textLabel;
}

- (UIImageView *)msgImageView {
    if (!_msgImageView) {
        _msgImageView = [[UIImageView alloc] init];
        _msgImageView.layer.masksToBounds = YES;
        _msgImageView.layer.cornerRadius = 3;
    }
    return _msgImageView;
}
@end
