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
#import "RCIM.h"
#import "RCMessageEditUtil.h"
#define leftLine_width 2
#define name_and_leftLine_space 4
#define name_height 17
@interface RCReferencedContentView ()
@property (nonatomic, strong) RCMessageModel *referModel;
@property (nonatomic, assign) CGSize contentSize;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) RCMessageContent *referedContent;
@property (nonatomic, copy) NSString *referedSenderId;
@property (nonatomic, assign) RCReferenceMessageStatus referMsgStatus;
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
    if (![self fetchReferedContentInfo]) {
        return;
    }
    [self addNotification];
    [self setUserDisplayName];
    [self setContentInfo];
    [self setupSubviews];
}

#pragma mark - Private Methods
- (BOOL)fetchReferedContentInfo {
    if ([self.referModel.content isKindOfClass:[RCReferenceMessage class]]) {
        RCReferenceMessage *content = (RCReferenceMessage *)self.referModel.content;
        self.referedContent = content.referMsg;
        self.referedSenderId = content.referMsgUserId;
        self.referMsgStatus = content.referMsgStatus;
        return YES;
    } else if ([self.referModel.content isKindOfClass:[RCStreamMessage class]]) {
        RCStreamMessage *content = (RCStreamMessage *)self.referModel.content;
        self.referedContent = content.referMsg.content;
        self.referedSenderId = content.referMsg.senderId;
        return YES;
    }
    return NO;
}

- (void)setContentInfo {
    if (self.referMsgStatus == RCReferenceMessageStatusDeleted) {
        self.textLabel.text = RCLocalizedString(@"ReferencedMessageDeleted");
    }else if (self.referMsgStatus == RCReferenceMessageStatusRecalled) {
        self.textLabel.text = RCLocalizedString(@"ReferencedMessageRecalled");
    }
    if (self.referMsgStatus == RCReferenceMessageStatusDeleted
        || self.referMsgStatus == RCReferenceMessageStatusRecalled) {
        self.textLabel.textColor = [RCMessageEditUtil editedTextColor];
        return;
    }
    NSString *messageInfo = @"";
    if ([self.referedContent isKindOfClass:[RCFileMessage class]]) {
        RCFileMessage *msg = (RCFileMessage *)self.referedContent;
        messageInfo = [NSString
            stringWithFormat:@"%@ %@", RCLocalizedString(@"RC:FileMsg"), msg.name];
    } else if ([self.referedContent isKindOfClass:[RCRichContentMessage class]]) {
        RCRichContentMessage *msg = (RCRichContentMessage *)self.referedContent;
        messageInfo = [NSString
            stringWithFormat:@"%@ %@", RCLocalizedString(@"RC:ImgTextMsg"), msg.title];
    } else if ([self.referedContent isKindOfClass:[RCImageMessage class]]) {
        RCImageMessage *msg = (RCImageMessage *)self.referedContent;
        self.msgImageView.image = msg.thumbnailImage;
        CGSize imageSize = [RCMessageCellTool getThumbnailImageSize:msg.thumbnailImage];
        if ([RCKitUtility isRTL]) {
            self.msgImageView.frame = CGRectMake(self.frame.size.width - imageSize.width, name_and_image_view_space, imageSize.width, imageSize.height);
        } else {
            self.msgImageView.frame = CGRectMake(0, name_and_image_view_space, imageSize.width, imageSize.height);
        }
    } else if ([self.referedContent isKindOfClass:[RCTextMessage class]] ||
               [self.referedContent isKindOfClass:[RCReferenceMessage class]]) {
        // 设置 text 之前设置 textColor，textLabel 的 attributeDictionary 设置才有效
        messageInfo = [RCKitUtility formatMessage:self.referedContent
                                                 targetId:self.referModel.targetId
                                         conversationType:self.referModel.conversationType
                                             isAllMessage:YES];
    } else if ([self.referedContent isKindOfClass:[RCStreamMessage class]]) {
        RCStreamMessage *msg = (RCStreamMessage *)self.referedContent;
        messageInfo = msg.content;
    } else if ([self.referedContent isKindOfClass:[RCMessageContent class]]) {
        messageInfo = [RCKitUtility formatMessage:self.referedContent
                                                 targetId:self.referModel.targetId
                                         conversationType:self.referModel.conversationType
                                             isAllMessage:YES];
        if (messageInfo.length <= 0 ||
            [messageInfo isEqualToString:[[self.referedContent class] getObjectName]]) {
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
        self.leftLimitLine.backgroundColor = RCDynamicColor(@"text_primary_color", @"0xA0A5Ab", @"0x040a0f66");
        self.nameLabel.textColor =  RCDynamicColor(@"text_primary_color", @"0xA0A5Ab", @"0x040a0f66");
        if ([self.referedContent isKindOfClass:[RCFileMessage class]] || [self.referedContent isKindOfClass:[RCRichContentMessage class]]) {
            self.textLabel.textColor = RCDynamicColor(@"primary_color", @"0x0099ff", @"0x005F9E");
        }else{
            self.textLabel.textColor = RCDynamicColor(@"text_primary_color", @"0xa0a5ab", @"0x999999");
        }
    }else{
        self.nameLabel.textColor = RCDynamicColor(@"text_primary_color", @"0xa0a5ab", @"0x999999");
        self.leftLimitLine.backgroundColor = RCDynamicColor(@"text_primary_color", @"0xa0a5ab", @"0x999999");
        if ([self.referedContent isKindOfClass:[RCFileMessage class]] || [self.referedContent isKindOfClass:[RCRichContentMessage class]]) {
            self.textLabel.textColor = RCDynamicColor(@"primary_color", @"0x0099ff", @"0x1290e2");
        }else{
            self.textLabel.textColor = RCDynamicColor(@"text_primary_color", @"0xa0a5ab", @"0x999999");
        }
    }
    
    if (([self.referedContent isKindOfClass:[RCTextMessage class]]
         || [self.referedContent isKindOfClass:[RCReferenceMessage class]])
        && self.textLabel.text.length > 0
        && self.referMsgStatus == RCReferenceMessageStatusModified) {
        NSString *originalText = self.textLabel.text;
        UIColor *originalColor = RCDynamicColor(@"text_primary_color", @"0xa0a5ab", @"0x999999");
        UIColor *editedTextColor = [RCMessageEditUtil editedTextColor];
        UIFont *font = [[RCKitConfig defaultConfig].font fontOfFourthLevel];
        NSString *displayText = [RCMessageEditUtil displayTextForOriginalText:originalText isEdited:YES];
        
        if (displayText.length > originalText.length) {
            if (originalColor) {
                originalColor = RCDYCOLOR(0xa0a5ab, 0x999999);
            }
            NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:displayText
                                                                                               attributes:@{
                NSFontAttributeName: font,
                NSForegroundColorAttributeName: originalColor
            }];
            
            NSRange originalRange = NSMakeRange(0, originalText.length);
            NSRange editedRange = NSMakeRange(originalText.length, displayText.length - originalText.length);
            if (editedTextColor) {
                [attributedText addAttribute:NSForegroundColorAttributeName
                                           value:editedTextColor
                                           range:editedRange];
            }
           
            self.textLabel.attributedText = attributedText;
        }
    }
}

- (void)setupSubviews {
    [self addSubview:self.leftLimitLine];
    [self addSubview:self.nameLabel];
    [self addSubview:self.contentView];
    BOOL isDeletedOrRecalled = (self.referMsgStatus == RCReferenceMessageStatusRecalled
                                || self.referMsgStatus == RCReferenceMessageStatusDeleted);
    // 删除撤回的图片显示 textLabel
    if ([self.referedContent isKindOfClass:[RCImageMessage class]] && !isDeletedOrRecalled) {
        [self.contentView addSubview:self.msgImageView];
    } else if ([self.referedContent isKindOfClass:[RCRichContentMessage class]] ||
               [self.referedContent isKindOfClass:[RCFileMessage class]]) {
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
    if ([self.referedContent.senderUserInfo.userId isEqualToString:self.referedSenderId] && [RCIM sharedRCIM].currentDataSourceType == RCDataSourceTypeInfoManagement) {
        name = [RCKitUtility getDisplayName:self.referedContent.senderUserInfo];
    } else {
        NSString *referUserId = self.referedSenderId;
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
    }
    __weak typeof(self) weakSelf = self;
    dispatch_main_async_safe(^{
        if([RCKitUtility isRTL]) {
            weakSelf.nameLabel.text = [@":" stringByAppendingString:name ?: @""];
        } else {
            weakSelf.nameLabel.text = [name stringByAppendingString:@":"];
        }
        
    });
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
        if ([self.referedSenderId isEqualToString:userInfoDic[@"userId"]]) {
            //重新取一下混合的用户信息
            [self setUserDisplayName];
        }
    }
}

- (void)onGroupUserInfoUpdate:(NSNotification *)notification {
    if (self.referModel.conversationType == ConversationType_GROUP &&
        [self.referModel.content isKindOfClass:[RCReferenceMessage class]]) {
        NSDictionary *groupUserInfoDic = (NSDictionary *)notification.object;
        if ([self.referModel.targetId isEqualToString:groupUserInfoDic[@"inGroupId"]] &&
            [self.referedSenderId isEqualToString:groupUserInfoDic[@"userId"]]) {
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
        _leftLimitLine.backgroundColor = RCDynamicColor(@"text_primary_color", @"0xA0A5Ab", @"0x7C7C7C");
    }
    return _leftLimitLine;
}

- (RCBaseLabel *)nameLabel {
    if (!_nameLabel) {
        CGFloat nameX = CGRectGetMaxX(self.leftLimitLine.frame) + name_and_leftLine_space;
        if ([RCKitUtility isRTL]) {
            nameX = 0;
            _nameLabel = [[RCBaseLabel alloc] initWithFrame:CGRectMake(nameX, 0, self.contentSize.width - nameX - name_and_leftLine_space, name_height)];
        } else {
            _nameLabel = [[RCBaseLabel alloc] initWithFrame:CGRectMake(nameX, 0, self.contentSize.width - nameX, name_height)];
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

- (RCBaseLabel *)textLabel {
    if (!_textLabel) {
        _textLabel = [[RCBaseLabel alloc] initWithFrame:self.contentView.bounds];
        _textLabel.numberOfLines = 1;
        [_textLabel setLineBreakMode:NSLineBreakByTruncatingMiddle];
        _textLabel.font = [[RCKitConfig defaultConfig].font fontOfFourthLevel];
    }
    return _textLabel;
}

- (RCBaseImageView *)msgImageView {
    if (!_msgImageView) {
        _msgImageView = [[RCBaseImageView alloc] init];
        _msgImageView.layer.masksToBounds = YES;
        _msgImageView.layer.cornerRadius = 3;
    }
    return _msgImageView;
}
@end
