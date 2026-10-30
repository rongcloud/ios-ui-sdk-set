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
#import "RCMessageCellReferenceContentViewRegistry.h"
#import <RongIMLibCore/RongIMLibCore.h>

@interface RCMessageCellReferenceContentView ()
@property (nonatomic, strong, readwrite, nullable) RCMessageModel *messageModel;
@property (nonatomic, strong, readwrite, nullable) RCMessageContent *referencedContent;
@end

#define leftLine_width 2
#define name_and_leftLine_space 4
#define name_height 18
static CGFloat const RCQuoteTextLineHeight = 18.0;
static NSInteger const RCQuoteTextMaxNumberOfLines = 2;
static CGFloat const RCQuoteInlineLeftLineWidth = 1.0;
static CGFloat const RCQuoteInlineLeftLineHeight = 9.0;
static CGFloat const RCQuoteImagePreviewSize = 50.0;
static CGFloat const RCQuoteFilePreviewTopSpacing = 6.0;
static CGFloat const RCQuoteFilePreviewHeight = 50.0;
static CGFloat const RCQuoteFilePreviewMinWidth = 156.0;
static CGFloat const RCQuoteFilePreviewHorizontalPadding = 8.0;
static CGFloat const RCQuoteFilePreviewIconSize = 32.0;
static CGFloat const RCQuoteFilePreviewIconTextSpacing = 8.0;

CGFloat const RCQuoteCardDefaultHeight = 34.0;
CGFloat const RCQuoteCardTopMargin = 10.0;

@interface RCReferencedContentView ()
@property (nonatomic, strong) RCMessageModel *referModel;
@property (nonatomic, assign) CGSize contentSize;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) RCMessageContent *referedContent;
@property (nonatomic, copy) NSString *referedSenderId;
@property (nonatomic, copy) NSString *referedObjectName;
@property (nonatomic, copy) NSString *referedDisplayName;
@property (nonatomic, copy) NSString *referedPreviewText;
@property (nonatomic, copy) NSString *quotedMessageUId;
@property (nonatomic, assign) RCReferenceMessageStatus referMsgStatus;
@property (nonatomic, assign) BOOL quoteContentUnavailable;
@property (nonatomic, strong) UIView *filePreviewCardView;
@property (nonatomic, strong) RCBaseImageView *filePreviewIconView;
@property (nonatomic, strong) UILabel *filePreviewNameLabel;
@property (nonatomic, strong) UILabel *filePreviewSizeLabel;
@property (nonatomic, strong) RCMessageCellReferenceContentView *messageCellReferenceContentView;
@property (nonatomic, strong) UITapGestureRecognizer *contentTapGestureRecognizer;
@end
@implementation RCReferencedContentView

+ (BOOL)shouldShowQuoteCardForMessageModel:(RCMessageModel *)message {
    return (message.quoteInfo.messageUId.length > 0 &&
            ![message.content isKindOfClass:[RCReferenceMessage class]]);
}

+ (BOOL)isImagePreviewObjectName:(NSString *)objectName {
    return [objectName isEqualToString:[RCImageMessage getObjectName]];
}

+ (BOOL)isFilePreviewObjectName:(NSString *)objectName {
    return [objectName isEqualToString:[RCFileMessage getObjectName]];
}

+ (BOOL)isDeletedOrRecalledStatus:(RCReferenceMessageStatus)status
          quoteContentUnavailable:(BOOL)quoteContentUnavailable {
    return (status == RCReferenceMessageStatusDeleted ||
            status == RCReferenceMessageStatusRecalled ||
            quoteContentUnavailable);
}

+ (RCReferenceMessageStatus)referenceStatusForQuoteMessageStatus:(RCQuoteMessageStatus)status {
    switch (status) {
        case RCQuoteMessageStatusDeleted:
            return RCReferenceMessageStatusDeleted;
        case RCQuoteMessageStatusRecalled:
            return RCReferenceMessageStatusRecalled;
        case RCQuoteMessageStatusDefault:
        default:
            return RCReferenceMessageStatusDefault;
    }
}

+ (RCReferenceMessageStatus)referenceStatusForQuoteReferenceLoadStatus:(RCQuoteReferenceLoadStatus)status {
    switch (status) {
        case RCQuoteReferenceLoadStatusDeleted:
            return RCReferenceMessageStatusDeleted;
        case RCQuoteReferenceLoadStatusRecalled:
            return RCReferenceMessageStatusRecalled;
        case RCQuoteReferenceLoadStatusFailed:
        case RCQuoteReferenceLoadStatusLoading:
        case RCQuoteReferenceLoadStatusUnknown:
        case RCQuoteReferenceLoadStatusLoaded:
        default:
            return RCReferenceMessageStatusDefault;
    }
}

+ (NSString *)placeholderTextForQuoteReferenceLoadStatus:(RCQuoteReferenceLoadStatus)status {
    switch (status) {
        case RCQuoteReferenceLoadStatusFailed:
            return RCLocalizedString(@"ReferencedMessageLoadFailed");
        case RCQuoteReferenceLoadStatusDeleted:
            return RCLocalizedString(@"ReferencedMessageDeleted");
        case RCQuoteReferenceLoadStatusRecalled:
            return RCLocalizedString(@"ReferencedMessageRecalled");
        case RCQuoteReferenceLoadStatusLoaded:
            return RCLocalizedString(@"ReferencedMessageDeleted");
        case RCQuoteReferenceLoadStatusLoading:
        case RCQuoteReferenceLoadStatusUnknown:
        default:
            return RCLocalizedString(@"ReferencedMessageLoading");
    }
}

+ (CGFloat)inlineTextMaxWidthForQuoteCardWidth:(CGFloat)cardWidth {
    return MAX(cardWidth - RCQuoteInlineLeftLineWidth - name_and_leftLine_space, 0);
}

+ (UIFont *)quoteTextFont {
    return [[RCKitConfig defaultConfig].font fontOfAnnotationLevel];
}

+ (NSMutableParagraphStyle *)quoteTextParagraphStyle {
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.minimumLineHeight = RCQuoteTextLineHeight;
    paragraphStyle.maximumLineHeight = RCQuoteTextLineHeight;
    paragraphStyle.lineBreakMode = NSLineBreakByCharWrapping;
    paragraphStyle.alignment = [RCKitUtility isRTL] ? NSTextAlignmentRight : NSTextAlignmentLeft;
    return paragraphStyle;
}

+ (CGFloat)quoteTextBaselineOffset {
    return (RCQuoteTextLineHeight - [self quoteTextFont].lineHeight) / 2.0;
}

+ (NSAttributedString *)quoteAttributedStringWithText:(NSString *)text color:(UIColor *)color {
    if (text.length <= 0) {
        return nil;
    }
    UIColor *textColor = color ?: RCDynamicColor(@"text_primary_color", @"0x020814", @"0xffffffcc");
    NSDictionary *attributes = @{
        NSFontAttributeName : [self quoteTextFont],
        NSForegroundColorAttributeName : textColor,
        NSParagraphStyleAttributeName : [self quoteTextParagraphStyle],
        NSBaselineOffsetAttributeName : @([self quoteTextBaselineOffset])
    };
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

+ (NSAttributedString *)quoteHeaderAttributedStringWithText:(NSString *)text color:(UIColor *)color {
    if (text.length <= 0) {
        return nil;
    }
    NSMutableParagraphStyle *paragraphStyle = [self quoteTextParagraphStyle];
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    UIColor *textColor = color ?: RCDynamicColor(@"text_primary_color", @"0x020814", @"0xffffffcc");
    NSDictionary *attributes = @{
        NSFontAttributeName : [self quoteTextFont],
        NSForegroundColorAttributeName : textColor,
        NSParagraphStyleAttributeName : paragraphStyle,
        NSBaselineOffsetAttributeName : @([self quoteTextBaselineOffset])
    };
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

+ (NSString *)sanitizedPreviewText:(NSString *)text {
    if (text.length <= 0) {
        return @"";
    }
    NSString *previewText = [text stringByReplacingOccurrencesOfString:@"\r\n" withString:@" "];
    previewText = [previewText stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    previewText = [previewText stringByReplacingOccurrencesOfString:@"\r" withString:@" "];
    return previewText;
}

+ (NSString *)fallbackPreviewTextForObjectName:(NSString *)objectName
                       quoteContentUnavailable:(BOOL)quoteContentUnavailable {
    if (quoteContentUnavailable) {
        return RCLocalizedString(@"unknown_message_cell_tip");
    }
    if (objectName.length <= 0) {
        return RCLocalizedString(@"unknown_message_cell_tip");
    }
    if ([objectName isEqualToString:@"RC:TxtMsg"]) {
        return RCLocalizedString(@"RC:TxtMsg");
    }
    if ([objectName isEqualToString:@"RC:ImgMsg"]) {
        return RCLocalizedString(@"RC:ImgMsg");
    }
    if ([objectName isEqualToString:@"RC:VcMsg"]) {
        return RCLocalizedString(@"RC:VcMsg");
    }
    if ([objectName isEqualToString:@"RC:SightMsg"]) {
        return RCLocalizedString(@"RC:SightMsg");
    }
    if ([objectName isEqualToString:@"RC:FileMsg"]) {
        return RCLocalizedString(@"RC:FileMsg");
    }
    if ([objectName isEqualToString:@"RC:LBSMsg"]) {
        return RCLocalizedString(@"RC:LBSMsg");
    }
    return RCLocalizedString(@"unknown_message_cell_tip");
}

+ (NSString *)previewTextForQuotedContent:(RCMessageContent *)quotedContent
                               objectName:(NSString *)objectName
                              messageModel:(RCMessageModel *)message
                                    status:(RCReferenceMessageStatus)status
                   quoteContentUnavailable:(BOOL)quoteContentUnavailable {
    if (status == RCReferenceMessageStatusDeleted || quoteContentUnavailable) {
        return RCLocalizedString(@"ReferencedMessageDeleted");
    }
    if (status == RCReferenceMessageStatusRecalled) {
        return RCLocalizedString(@"ReferencedMessageRecalled");
    }
    NSString *messageInfo = @"";
    if ([quotedContent isKindOfClass:[RCFileMessage class]]) {
        RCFileMessage *msg = (RCFileMessage *)quotedContent;
        messageInfo = [NSString stringWithFormat:@"%@ %@", RCLocalizedString(@"RC:FileMsg"), msg.name];
    } else if ([quotedContent isKindOfClass:[RCRichContentMessage class]]) {
        RCRichContentMessage *msg = (RCRichContentMessage *)quotedContent;
        messageInfo = [NSString stringWithFormat:@"%@ %@", RCLocalizedString(@"RC:ImgTextMsg"), msg.title];
    } else if ([quotedContent isKindOfClass:[RCImageMessage class]]) {
        messageInfo = RCLocalizedString(@"RC:ImgMsg");
    } else if ([quotedContent isKindOfClass:[RCTextMessage class]] ||
               [quotedContent isKindOfClass:[RCReferenceMessage class]]) {
        messageInfo = [RCKitUtility formatMessage:quotedContent
                                         targetId:message.targetId
                                 conversationType:message.conversationType
                                     isAllMessage:YES];
    } else if ([quotedContent isKindOfClass:[RCStreamMessage class]]) {
        RCStreamMessage *msg = (RCStreamMessage *)quotedContent;
        messageInfo = msg.content;
    } else if ([quotedContent isKindOfClass:[RCMessageContent class]]) {
        messageInfo = [RCKitUtility formatMessage:quotedContent
                                         targetId:message.targetId
                                 conversationType:message.conversationType
                                     isAllMessage:YES];
        if (messageInfo.length <= 0 ||
            [messageInfo isEqualToString:[[quotedContent class] getObjectName]]) {
            messageInfo = [self fallbackPreviewTextForObjectName:objectName quoteContentUnavailable:NO];
        }
    } else {
        messageInfo = [self fallbackPreviewTextForObjectName:objectName
                                     quoteContentUnavailable:quoteContentUnavailable];
    }
    return [self sanitizedPreviewText:messageInfo];
}

+ (NSString *)inlineDisplayTextWithSenderName:(NSString *)senderName previewText:(NSString *)previewText {
    NSString *name = senderName ?: @"";
    NSString *text = previewText ?: @"";
    if (name.length <= 0) {
        return text;
    }
    if (text.length <= 0) {
        return name;
    }
    if ([RCKitUtility isRTL]) {
        return [NSString stringWithFormat:@"%@ :%@", text, name];
    }
    return [NSString stringWithFormat:@"%@: %@", name, text];
}

+ (RCUserInfo *)userInfoForSenderId:(NSString *)senderId messageModel:(RCMessageModel *)message {
    if (senderId.length <= 0) {
        return nil;
    }
    if (ConversationType_GROUP == message.conversationType) {
        RCUserInfo *groupUserInfo = [[RCUserInfoCacheManager sharedManager] getUserInfo:senderId inGroupId:message.targetId];
        RCUserInfo *ordinaryUserInfo = [[RCUserInfoCacheManager sharedManager] getUserInfo:senderId];
        if (groupUserInfo) {
            groupUserInfo.alias = ordinaryUserInfo.alias.length > 0 ? ordinaryUserInfo.alias : groupUserInfo.alias;
            if (groupUserInfo.name.length <= 0 && ordinaryUserInfo.name.length > 0) {
                groupUserInfo.name = ordinaryUserInfo.name;
            }
            return groupUserInfo;
        }
        return ordinaryUserInfo;
    }
    return [[RCUserInfoCacheManager sharedManager] getUserInfo:senderId];
}

+ (NSString *)displayNameForSenderId:(NSString *)senderId
                        quotedContent:(RCMessageContent *)quotedContent
                         messageModel:(RCMessageModel *)message {
    NSString *name = senderId ?: @"";
    if ([quotedContent.senderUserInfo.userId isEqualToString:senderId] &&
        [RCIM sharedRCIM].currentDataSourceType == RCDataSourceTypeInfoManagement) {
        name = [RCKitUtility getDisplayName:quotedContent.senderUserInfo];
    } else if (senderId.length > 0) {
        RCUserInfo *userInfo = [self userInfoForSenderId:senderId messageModel:message];
        NSString *displayName = [RCKitUtility getDisplayName:userInfo];
        if (displayName.length > 0) {
            name = displayName;
        }
    }
    return name ?: @"";
}

+ (NSString *)senderNameForMessageModel:(RCMessageModel *)message
                           quotedContent:(RCMessageContent *)quotedContent {
    NSString *senderName = @"";
    if ([message.content isKindOfClass:[RCReferenceMessage class]]) {
        senderName = ((RCReferenceMessage *)message.content).referMsgUserId;
    } else if ([message.content isKindOfClass:[RCStreamMessage class]]) {
        senderName = ((RCStreamMessage *)message.content).referMsg.senderId;
    } else {
        senderName = message.quoteInfo.senderId;
    }
    return [self displayNameForSenderId:senderName
                          quotedContent:quotedContent
                           messageModel:message];
}

+ (CGFloat)quoteNameWidthForSenderName:(NSString *)senderName {
    if (senderName.length <= 0) {
        return 0;
    }
    NSString *nameText = [RCKitUtility isRTL] ? [@":" stringByAppendingString:senderName]
                                              : [senderName stringByAppendingString:@":"];
    CGSize nameSize =
        [RCKitUtility getTextDrawingSize:nameText
                                    font:[self quoteTextFont]
                         constrainedSize:CGSizeMake(CGFLOAT_MAX, name_height)];
    return ceilf(nameSize.width);
}

+ (UIFont *)quoteFilePreviewNameFont {
    return [[RCKitConfig defaultConfig].font fontOfAnnotationLevel];
}

+ (UIFont *)quoteFilePreviewSizeFont {
    return [[RCKitConfig defaultConfig].font fontOfAnnotationLevel];
}

+ (CGFloat)quoteFilePreviewWidthForFileMessage:(RCFileMessage *)fileMessage maxWidth:(CGFloat)maxWidth {
    if (!fileMessage || maxWidth <= 0) {
        return 0;
    }
    CGFloat textMaxWidth = MAX(maxWidth - RCQuoteFilePreviewHorizontalPadding * 2 -
                               RCQuoteFilePreviewIconSize - RCQuoteFilePreviewIconTextSpacing, 0);
    NSString *fileName = fileMessage.name ?: @"";
    NSString *fileSize = [RCKitUtility getReadableStringForFileSize:fileMessage.size] ?: @"";
    CGSize nameSize = [RCKitUtility getTextDrawingSize:fileName
                                                  font:[self quoteFilePreviewNameFont]
                                       constrainedSize:CGSizeMake(CGFLOAT_MAX, RCQuoteTextLineHeight)];
    CGSize sizeSize = [RCKitUtility getTextDrawingSize:fileSize
                                                  font:[self quoteFilePreviewSizeFont]
                                       constrainedSize:CGSizeMake(CGFLOAT_MAX, RCQuoteTextLineHeight)];
    CGFloat textWidth = MIN(MAX(ceilf(nameSize.width), ceilf(sizeSize.width)), textMaxWidth);
    CGFloat width = RCQuoteFilePreviewHorizontalPadding * 2 + RCQuoteFilePreviewIconSize +
                    RCQuoteFilePreviewIconTextSpacing + textWidth;
    return MIN(MAX(width, MIN(RCQuoteFilePreviewMinWidth, maxWidth)), maxWidth);
}

+ (BOOL)canUseMessageCellReferenceContentViewForContent:(RCMessageContent *)content
                                             objectName:(NSString *)objectName
                                                 status:(RCReferenceMessageStatus)status
                                quoteContentUnavailable:(BOOL)quoteContentUnavailable {
    if (!content) {
        return NO;
    }
    if ([self isDeletedOrRecalledStatus:status quoteContentUnavailable:quoteContentUnavailable]) {
        return NO;
    }
    return [RCMessageCellReferenceContentViewRegistry contentViewClassForMessageContent:content objectName:objectName] != nil;
}

+ (BOOL)shouldUseInlineTextLayoutForContent:(RCMessageContent *)content
                                 objectName:(NSString *)objectName
                                     status:(RCReferenceMessageStatus)status
                    quoteContentUnavailable:(BOOL)quoteContentUnavailable
                        canShowImagePreview:(BOOL)canShowImagePreview {
    if (canShowImagePreview) {
        return NO;
    }
    if ([self isDeletedOrRecalledStatus:status quoteContentUnavailable:quoteContentUnavailable]) {
        return YES;
    }
    if ([content isKindOfClass:[RCFileMessage class]] ||
        [content isKindOfClass:[RCRichContentMessage class]]) {
        return NO;
    }
    return YES;
}

+ (CGFloat)inlineTextHeightForText:(NSString *)text maxWidth:(CGFloat)maxWidth {
    if (text.length <= 0 || maxWidth <= 0) {
        return RCQuoteTextLineHeight;
    }
    NSAttributedString *attributedText = [self quoteAttributedStringWithText:text color:UIColor.clearColor];
    CGRect textRect = [attributedText boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX)
                                                   options:(NSStringDrawingUsesLineFragmentOrigin |
                                                            NSStringDrawingUsesFontLeading)
                                                   context:nil];
    CGFloat maxHeight = RCQuoteTextLineHeight * RCQuoteTextMaxNumberOfLines;
    CGFloat height = ceilf(textRect.size.height);
    NSInteger lineCount = (NSInteger)ceil((height - 0.5) / RCQuoteTextLineHeight);
    lineCount = MIN(MAX(lineCount, 1), RCQuoteTextMaxNumberOfLines);
    return MIN(lineCount * RCQuoteTextLineHeight, maxHeight);
}

+ (CGFloat)inlineTextWidthForText:(NSString *)text maxWidth:(CGFloat)maxWidth {
    if (text.length <= 0 || maxWidth <= 0) {
        return 0;
    }
    NSAttributedString *attributedText = [self quoteAttributedStringWithText:text color:UIColor.clearColor];
    CGRect textRect = [attributedText boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX)
                                                   options:(NSStringDrawingUsesLineFragmentOrigin |
                                                            NSStringDrawingUsesFontLeading)
                                                   context:nil];
    return MIN(ceilf(textRect.size.width), maxWidth);
}

+ (CGFloat)inlineQuoteCardHeightForText:(NSString *)text maxWidth:(CGFloat)maxWidth {
    return [self inlineTextHeightForText:text maxWidth:maxWidth];
}

+ (CGSize)quoteCardContentSizeForMessageModel:(RCMessageModel *)message
                                     maxWidth:(CGFloat)maxWidth {
    CGFloat contentWidth = MAX(maxWidth, 0);
    CGFloat contentHeight = RCQuoteCardDefaultHeight;

    RCReferenceMessageStatus status = RCReferenceMessageStatusDefault;
    RCMessageContent *quotedContent = nil;
    NSString *objectName = message.quoteInfo.objectName;

    if ([message.content isKindOfClass:[RCReferenceMessage class]]) {
        RCReferenceMessage *referenceMessage = (RCReferenceMessage *)message.content;
        quotedContent = referenceMessage.referMsg;
        objectName = [[quotedContent class] getObjectName];
        status = referenceMessage.referMsgStatus;
    } else {
        status = [self referenceStatusForQuoteMessageStatus:message.quoteInfo.quoteMessageStatus];
        if (![self isDeletedOrRecalledStatus:status quoteContentUnavailable:NO]) {
            status = [self referenceStatusForQuoteReferenceLoadStatus:message.quoteReferenceLoadStatus];
            RCMessage *quotedMessage = message.quoteReferencedMessage;
            if ([quotedMessage.content isKindOfClass:[RCRecallNotificationMessage class]]) {
                status = RCReferenceMessageStatusRecalled;
            } else if (quotedMessage.messageId > 0 && quotedMessage.content) {
                quotedContent = quotedMessage.content;
                status = quotedMessage.hasChanged ? RCReferenceMessageStatusModified : RCReferenceMessageStatusDefault;
                if (quotedMessage.objectName.length > 0) {
                    objectName = quotedMessage.objectName;
                } else if (quotedContent) {
                    objectName = [[quotedContent class] getObjectName];
                }
            }
        }
    }

    BOOL isDeletedOrRecalled = (status == RCReferenceMessageStatusDeleted ||
                                status == RCReferenceMessageStatusRecalled);
    BOOL shouldShowImagePreview = NO;
    UIImage *previewImage = nil;
    if (!isDeletedOrRecalled) {
        if ([quotedContent isKindOfClass:[RCImageMessage class]]) {
            shouldShowImagePreview = YES;
            previewImage = ((RCImageMessage *)quotedContent).thumbnailImage;
        } else if ([quotedContent respondsToSelector:@selector(thumbnailImage)] &&
                   [self isImagePreviewObjectName:objectName]) {
            shouldShowImagePreview = YES;
            previewImage = [quotedContent valueForKey:@"thumbnailImage"];
        } else if ([self isImagePreviewObjectName:objectName]) {
            shouldShowImagePreview = YES;
        }
    }

    if ([self canUseMessageCellReferenceContentViewForContent:quotedContent
                                                   objectName:objectName
                                                       status:status
                                      quoteContentUnavailable:NO]) {
        Class viewClass = [RCMessageCellReferenceContentViewRegistry contentViewClassForMessageContent:quotedContent
                                                                                            objectName:objectName];
        CGSize customSize = [viewClass sizeForReferencedContent:quotedContent
                                                    messageModel:message
                                                        maxWidth:contentWidth];
        if (customSize.width > 0 && customSize.height > 0) {
            contentWidth = MIN(customSize.width, contentWidth);
            contentHeight = customSize.height;
            return CGSizeMake(contentWidth, contentHeight);
        }
    }

    if (shouldShowImagePreview) {
        CGSize imageSize = CGSizeMake(RCQuoteImagePreviewSize, RCQuoteImagePreviewSize);
        NSString *senderName = [self senderNameForMessageModel:message quotedContent:quotedContent];
        CGFloat visibleContentWidth = MAX(imageSize.width, [self quoteNameWidthForSenderName:senderName]);
        contentWidth = MIN(visibleContentWidth + leftLine_width + name_and_leftLine_space, contentWidth);
        contentHeight = MAX(contentHeight, imageSize.height + name_height + name_and_image_view_space);
    } else if ([quotedContent isKindOfClass:[RCFileMessage class]] ||
               (!quotedContent &&
                [self shouldShowQuoteCardForMessageModel:message] &&
                [self isFilePreviewObjectName:objectName] &&
                (message.quoteReferenceLoadStatus == RCQuoteReferenceLoadStatusLoading ||
                 message.quoteReferenceLoadStatus == RCQuoteReferenceLoadStatusUnknown))) {
        NSString *senderName = [self senderNameForMessageModel:message quotedContent:quotedContent];
        CGFloat maxPreviewWidth = contentWidth;
        CGFloat filePreviewWidth = quotedContent
            ? [self quoteFilePreviewWidthForFileMessage:(RCFileMessage *)quotedContent maxWidth:maxPreviewWidth]
            : MIN(RCQuoteFilePreviewMinWidth, maxPreviewWidth);
        CGFloat nameWidth = [self quoteNameWidthForSenderName:senderName] + leftLine_width + name_and_leftLine_space;
        contentWidth = MIN(MAX(filePreviewWidth, nameWidth), contentWidth);
        contentHeight = name_height + RCQuoteFilePreviewTopSpacing + RCQuoteFilePreviewHeight;
    } else if ([self shouldUseInlineTextLayoutForContent:quotedContent
                                              objectName:objectName
                                                  status:status
                                 quoteContentUnavailable:NO
                                     canShowImagePreview:NO]) {
        NSString *senderName = [self senderNameForMessageModel:message quotedContent:quotedContent];
        NSString *previewText = nil;
        if ([self shouldShowQuoteCardForMessageModel:message] && !quotedContent &&
            status == RCReferenceMessageStatusDefault) {
            previewText = [self placeholderTextForQuoteReferenceLoadStatus:message.quoteReferenceLoadStatus];
        } else {
            previewText = [self previewTextForQuotedContent:quotedContent
                                                 objectName:objectName
                                               messageModel:message
                                                     status:status
                                    quoteContentUnavailable:NO];
        }
        NSString *inlineText = [self inlineDisplayTextWithSenderName:senderName previewText:previewText];
        CGFloat inlineTextWidth = [self inlineTextWidthForText:inlineText
                                                      maxWidth:[self inlineTextMaxWidthForQuoteCardWidth:contentWidth]];
        contentWidth = MIN(inlineTextWidth + RCQuoteInlineLeftLineWidth + name_and_leftLine_space, contentWidth);
        contentHeight = [self inlineQuoteCardHeightForText:inlineText
                                                  maxWidth:[self inlineTextMaxWidthForQuoteCardWidth:contentWidth]];
    }

    return CGSizeMake(contentWidth, contentHeight);
}

+ (CGFloat)quoteCardHeightForMessageModel:(RCMessageModel *)message
                                 maxWidth:(CGFloat)maxWidth {
    return [self quoteCardContentSizeForMessageModel:message maxWidth:maxWidth].height;
}

- (instancetype)init {
    if (self = [super init]) {
        self.frame = CGRectZero;
        self.userInteractionEnabled = YES;
        // 整个引用卡片添加点击手势，防止触摸事件穿透到 messageContentView 触发原始消息操作
        self.contentTapGestureRecognizer =
            [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapContentView:)];
        self.contentTapGestureRecognizer.numberOfTapsRequired = 1;
        self.contentTapGestureRecognizer.numberOfTouchesRequired = 1;
        [self addGestureRecognizer:self.contentTapGestureRecognizer];
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
        self.referedObjectName = [[content.referMsg class] getObjectName];
        self.referMsgStatus = content.referMsgStatus;
        return YES;
    } else if ([self.referModel.content isKindOfClass:[RCStreamMessage class]]) {
        RCStreamMessage *content = (RCStreamMessage *)self.referModel.content;
        self.referedContent = content.referMsg.content;
        self.referedSenderId = content.referMsg.senderId;
        self.referedObjectName = [[content.referMsg.content class] getObjectName];
        return YES;
    } else if ([[self class] shouldShowQuoteCardForMessageModel:self.referModel]) {
        self.quotedMessageUId = self.referModel.quoteInfo.messageUId;
        self.referedSenderId = self.referModel.quoteInfo.senderId;
        self.referedObjectName = self.referModel.quoteInfo.objectName;
        self.referMsgStatus = [[self class] referenceStatusForQuoteMessageStatus:self.referModel.quoteInfo.quoteMessageStatus];
        if (![[self class] isDeletedOrRecalledStatus:self.referMsgStatus quoteContentUnavailable:NO]) {
            self.referMsgStatus = [[self class] referenceStatusForQuoteReferenceLoadStatus:self.referModel.quoteReferenceLoadStatus];
            RCMessage *quotedMessage = self.referModel.quoteReferencedMessage;
            if (quotedMessage.messageId > 0 && quotedMessage.content) {
                [self updateQuotedMessageStateWithMessage:quotedMessage];
            } else {
                self.referedPreviewText = [[self class] placeholderTextForQuoteReferenceLoadStatus:self.referModel.quoteReferenceLoadStatus];
            }
        }
        return YES;
    }
    return NO;
}

- (NSString *)fallbackPreviewText {
    return [[self class] fallbackPreviewTextForObjectName:self.referedObjectName
                                  quoteContentUnavailable:self.quoteContentUnavailable];
}

- (void)reloadReferencedContentIfNeeded {
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.msgImageView = nil;
    self.textLabel = nil;
    self.filePreviewCardView = nil;
    self.filePreviewIconView = nil;
    self.filePreviewNameLabel = nil;
    self.filePreviewSizeLabel = nil;
    self.messageCellReferenceContentView = nil;
    self.nameLabel = nil;
    self.leftLimitLine = nil;
    self.contentView = nil;
    [self setUserDisplayName];
    [self setContentInfo];
    [self setupSubviews];
}

- (void)updateQuotedMessageStateWithMessage:(RCMessage *)message {
    self.quoteContentUnavailable = NO;
    self.referedSenderId = message.senderUserId.length > 0 ? message.senderUserId : self.referedSenderId;
    NSString *objectName = message.objectName.length > 0 ? message.objectName : [[message.content class] getObjectName];
    if (objectName.length > 0) {
        self.referedObjectName = objectName;
    }

    if ([message.content isKindOfClass:[RCRecallNotificationMessage class]]) {
        self.referedContent = nil;
        self.referMsgStatus = RCReferenceMessageStatusRecalled;
        return;
    }

    self.referedContent = message.content;
    self.referMsgStatus = message.hasChanged ? RCReferenceMessageStatusModified : RCReferenceMessageStatusDefault;
}

- (void)setContentInfo {
    BOOL canShowPreviewImage = [self canShowPreviewImage];
    BOOL usesFilePreviewLayout = [self usesFilePreviewLayout];
    if (self.referedPreviewText.length > 0 &&
        !self.referedContent &&
        self.referMsgStatus == RCReferenceMessageStatusDefault) {
        self.textLabel.textColor = [RCMessageEditUtil editedTextColor];
        if ([self usesInlineTextLayout]) {
            [self applyInlineTextLayoutWithTextColor:self.textLabel.textColor];
        } else {
            self.textLabel.text = self.referedPreviewText;
        }
        return;
    }
    // v2 quote 场景下 quoteContentUnavailable 表示本地+远端均无法获取原消息，视为已删除
    if (self.referMsgStatus == RCReferenceMessageStatusDeleted || self.quoteContentUnavailable) {
        self.referedPreviewText = RCLocalizedString(@"ReferencedMessageDeleted");
    }else if (self.referMsgStatus == RCReferenceMessageStatusRecalled) {
        self.referedPreviewText = RCLocalizedString(@"ReferencedMessageRecalled");
    }
    if (self.referMsgStatus == RCReferenceMessageStatusDeleted
        || self.referMsgStatus == RCReferenceMessageStatusRecalled
        || self.quoteContentUnavailable) {
        self.textLabel.textColor = [RCMessageEditUtil editedTextColor];
        if ([self usesInlineTextLayout]) {
            [self applyInlineTextLayoutWithTextColor:self.textLabel.textColor];
        } else {
            self.textLabel.text = self.referedPreviewText;
        }
        return;
    }
    NSString *messageInfo = @"";
    if ([self.referedContent isKindOfClass:[RCFileMessage class]]) {
        RCFileMessage *msg = (RCFileMessage *)self.referedContent;
        messageInfo = msg.name ?: @"";
        if (usesFilePreviewLayout) {
            [self configureFilePreviewWithMessage:msg];
        }
    } else if ([self.referedContent isKindOfClass:[RCRichContentMessage class]]) {
        RCRichContentMessage *msg = (RCRichContentMessage *)self.referedContent;
        messageInfo = [NSString
            stringWithFormat:@"%@ %@", RCLocalizedString(@"RC:ImgTextMsg"), msg.title];
    } else if ([self.referedContent isKindOfClass:[RCImageMessage class]] && canShowPreviewImage) {
        RCImageMessage *msg = (RCImageMessage *)self.referedContent;
        self.msgImageView.image = msg.thumbnailImage;
        CGSize imageSize = CGSizeMake(RCQuoteImagePreviewSize, RCQuoteImagePreviewSize);
        if ([RCKitUtility isRTL]) {
            self.msgImageView.frame = CGRectMake(self.frame.size.width - imageSize.width, name_and_image_view_space, imageSize.width, imageSize.height);
        } else {
            self.msgImageView.frame = CGRectMake(0, name_and_image_view_space, imageSize.width, imageSize.height);
        }
    } else if ([self.referedContent isKindOfClass:[RCImageMessage class]]) {
        messageInfo = RCLocalizedString(@"RC:ImgMsg");
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
    } else {
        messageInfo = [self fallbackPreviewText];
    }
    if (messageInfo.length > 0) {
        messageInfo = [[self class] sanitizedPreviewText:messageInfo];
        self.referedPreviewText = messageInfo;
        if (![self usesInlineTextLayout] && !usesFilePreviewLayout) {
            self.textLabel.text = messageInfo;
        }
    }
    
    if(self.referModel.messageDirection == MessageDirection_SEND){
        self.leftLimitLine.backgroundColor = RCDynamicColor(@"text_primary_color", @"0xA0A5Ab", @"0x040a0f66");
        self.nameLabel.textColor =  RCDynamicColor(@"text_primary_color", @"0xA0A5Ab", @"0x040a0f66");
        if (!usesFilePreviewLayout) {
            if ([self.referedContent isKindOfClass:[RCFileMessage class]] ||
                [self.referedContent isKindOfClass:[RCRichContentMessage class]]) {
                self.textLabel.textColor = RCDynamicColor(@"primary_color", @"0x0099ff", @"0x005F9E");
            }else{
                self.textLabel.textColor = RCDynamicColor(@"text_primary_color", @"0xa0a5ab", @"0x999999");
            }
        }
    }else{
        self.nameLabel.textColor = RCDynamicColor(@"text_primary_color", @"0xa0a5ab", @"0x999999");
        self.leftLimitLine.backgroundColor = RCDynamicColor(@"text_primary_color", @"0xa0a5ab", @"0x999999");
        if (!usesFilePreviewLayout) {
            if ([self.referedContent isKindOfClass:[RCFileMessage class]] ||
                [self.referedContent isKindOfClass:[RCRichContentMessage class]]) {
                self.textLabel.textColor = RCDynamicColor(@"primary_color", @"0x0099ff", @"0x1290e2");
            }else{
                self.textLabel.textColor = RCDynamicColor(@"text_primary_color", @"0xa0a5ab", @"0x999999");
            }
        }
    }

    if ([self usesImagePreviewHeaderLayout] || usesFilePreviewLayout) {
        self.nameLabel.textColor = RCDynamicColor(@"text_primary_color", @"0x020814", @"0xffffffcc");
        self.leftLimitLine.backgroundColor = self.nameLabel.textColor;
        [self applyNameLabelText];
    }

    if ([self usesInlineTextLayout]) {
        self.textLabel.textColor = RCDynamicColor(@"text_primary_color", @"0x020814", @"0xffffffcc");
        self.leftLimitLine.backgroundColor = self.textLabel.textColor;
        [self applyInlineTextLayoutWithTextColor:self.textLabel.textColor];
    }
    
    if (([self.referedContent isKindOfClass:[RCTextMessage class]]
         || [self.referedContent isKindOfClass:[RCReferenceMessage class]])
        && self.textLabel.text.length > 0
        && self.referMsgStatus == RCReferenceMessageStatusModified) {
        NSString *originalText = self.textLabel.text;
        BOOL usesInlineTextLayout = [self usesInlineTextLayout];
        UIColor *originalColor = usesInlineTextLayout ? self.textLabel.textColor : RCDynamicColor(@"text_primary_color", @"0xa0a5ab", @"0x999999");
        UIColor *editedTextColor = [RCMessageEditUtil editedTextColor];
        UIFont *font = usesInlineTextLayout ? [[self class] quoteTextFont] : [[RCKitConfig defaultConfig].font fontOfFourthLevel];
        NSString *displayText = [RCMessageEditUtil displayTextForOriginalText:originalText isEdited:YES];
        
        if (displayText.length > originalText.length) {
            if (!usesInlineTextLayout && originalColor) {
                originalColor = RCDYCOLOR(0xa0a5ab, 0x999999);
            }
            NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:displayText
                                                                                               attributes:@{
                NSFontAttributeName: font,
                NSForegroundColorAttributeName: originalColor,
                NSParagraphStyleAttributeName: [[self class] quoteTextParagraphStyle]
            }];
            
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
    if ([self usesMessageCellReferenceContentView]) {
        self.contentTapGestureRecognizer.enabled = NO;
        [self addSubview:self.contentView];
        self.contentView.frame = self.bounds;
        [self.contentView addSubview:self.messageCellReferenceContentView];
        return;
    }
    self.contentTapGestureRecognizer.enabled = YES;
    [self addSubview:self.leftLimitLine];
    self.nameLabel.hidden = [self usesInlineTextLayout];
    [self addSubview:self.nameLabel];
    [self addSubview:self.contentView];
    BOOL isDeletedOrRecalled = (self.referMsgStatus == RCReferenceMessageStatusRecalled
                                || self.referMsgStatus == RCReferenceMessageStatusDeleted
                                || self.quoteContentUnavailable);
    BOOL canShowPreviewImage = [self canShowPreviewImage];
    // 删除撤回的图片显示 textLabel
    if ([self.referedContent isKindOfClass:[RCImageMessage class]] && !isDeletedOrRecalled && canShowPreviewImage) {
        [self.contentView addSubview:self.msgImageView];
    } else if ([self usesFilePreviewLayout]) {
        [self.contentView addSubview:self.filePreviewCardView];
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
    self.filePreviewCardView = nil;
    self.filePreviewIconView = nil;
    self.filePreviewNameLabel = nil;
    self.filePreviewSizeLabel = nil;
    self.messageCellReferenceContentView = nil;
    self.nameLabel = nil;
    self.leftLimitLine = nil;
    self.contentView = nil;
    self.referedContent = nil;
    self.referedSenderId = nil;
    self.referedObjectName = nil;
    self.referedDisplayName = nil;
    self.referedPreviewText = nil;
    self.quotedMessageUId = nil;
    self.referMsgStatus = RCReferenceMessageStatusDefault;
    self.quoteContentUnavailable = NO;
}

- (BOOL)canShowPreviewImage {
    BOOL isDeletedOrRecalled = [[self class] isDeletedOrRecalledStatus:self.referMsgStatus
                                               quoteContentUnavailable:self.quoteContentUnavailable];
    return ([self.referedContent isKindOfClass:[RCImageMessage class]] &&
            !isDeletedOrRecalled &&
            self.contentSize.height > RCQuoteCardDefaultHeight);
}

- (BOOL)usesInlineTextLayout {
    return [[self class] shouldUseInlineTextLayoutForContent:self.referedContent
                                                  objectName:self.referedObjectName
                                                      status:self.referMsgStatus
                                     quoteContentUnavailable:self.quoteContentUnavailable
                                         canShowImagePreview:[self canShowPreviewImage]];
}

- (BOOL)usesImagePreviewHeaderLayout {
    return [self canShowPreviewImage];
}

- (BOOL)usesFilePreviewLayout {
    BOOL isDeletedOrRecalled = [[self class] isDeletedOrRecalledStatus:self.referMsgStatus
                                               quoteContentUnavailable:self.quoteContentUnavailable];
    return ([self.referedContent isKindOfClass:[RCFileMessage class]] && !isDeletedOrRecalled);
}

- (BOOL)usesMessageCellReferenceContentView {
    return [[self class] canUseMessageCellReferenceContentViewForContent:self.referedContent
                                                              objectName:self.referedObjectName
                                                                  status:self.referMsgStatus
                                                 quoteContentUnavailable:self.quoteContentUnavailable];
}

- (void)applyNameLabelText {
    NSString *name = self.referedDisplayName ?: @"";
    NSString *displayName = [RCKitUtility isRTL] ? [@":" stringByAppendingString:name]
                                                 : [name stringByAppendingString:@":"];
    if ([self usesImagePreviewHeaderLayout] || [self usesFilePreviewLayout]) {
        self.nameLabel.attributedText = [[self class] quoteHeaderAttributedStringWithText:displayName
                                                                                    color:self.nameLabel.textColor];
    } else {
        self.nameLabel.text = displayName;
    }
}

- (void)applyInlineTextLayoutWithTextColor:(UIColor *)textColor {
    NSString *inlineText = [[self class] inlineDisplayTextWithSenderName:self.referedDisplayName
                                                             previewText:self.referedPreviewText];
    self.textLabel.attributedText = [[self class] quoteAttributedStringWithText:inlineText color:textColor];
}

- (CGFloat)inlineTextLayoutHeight {
    CGFloat maxHeight = RCQuoteTextLineHeight * RCQuoteTextMaxNumberOfLines;
    if (self.contentSize.height <= RCQuoteCardDefaultHeight) {
        return RCQuoteTextLineHeight;
    }
    return MIN(self.contentSize.height, maxHeight);
}

- (CGFloat)inlineTextFirstLineCenterY {
    CGFloat textHeight = [self inlineTextLayoutHeight];
    CGFloat textY = MAX((self.frame.size.height - textHeight) / 2.0, 0);
    return textY + RCQuoteTextLineHeight / 2.0;
}

- (void)configureFilePreviewWithMessage:(RCFileMessage *)fileMessage {
    CGFloat cardWidth = CGRectGetWidth(self.contentView.bounds);
    CGFloat cardY = RCQuoteFilePreviewTopSpacing;
    self.filePreviewCardView.frame = CGRectMake(0, cardY, cardWidth, RCQuoteFilePreviewHeight);
    self.filePreviewIconView.image = [RCKitUtility imageWithFileSuffix:fileMessage.type];
    self.filePreviewNameLabel.text = fileMessage.name ?: @"";
    self.filePreviewSizeLabel.text = [RCKitUtility getReadableStringForFileSize:fileMessage.size];

    CGFloat iconY = (RCQuoteFilePreviewHeight - RCQuoteFilePreviewIconSize) / 2.0;
    CGFloat textX = RCQuoteFilePreviewHorizontalPadding + RCQuoteFilePreviewIconSize + RCQuoteFilePreviewIconTextSpacing;
    CGFloat textWidth = MAX(cardWidth - textX - RCQuoteFilePreviewHorizontalPadding, 0);
    self.filePreviewIconView.frame = CGRectMake(RCQuoteFilePreviewHorizontalPadding,
                                                iconY,
                                                RCQuoteFilePreviewIconSize,
                                                RCQuoteFilePreviewIconSize);
    self.filePreviewNameLabel.frame = CGRectMake(textX, 6, textWidth, RCQuoteTextLineHeight);
    self.filePreviewSizeLabel.frame = CGRectMake(textX, 27, textWidth, 15);
}

- (void)setUserDisplayName {
    NSString *name = self.referedSenderId;
    if ([self.referedContent.senderUserInfo.userId isEqualToString:self.referedSenderId] && [RCIM sharedRCIM].currentDataSourceType == RCDataSourceTypeInfoManagement) {
        name = [RCKitUtility getDisplayName:self.referedContent.senderUserInfo];
    } else {
        NSString *referUserId = self.referedSenderId;
        RCUserInfo *userInfo = [[self class] userInfoForSenderId:referUserId messageModel:self.referModel];
        self.referModel.userInfo = userInfo;
        NSString *displayName = [RCKitUtility getDisplayName:userInfo];
        if (displayName.length > 0) {
            name = displayName;
        }
    }
    self.referedDisplayName = name ?: @"";
    __weak typeof(self) weakSelf = self;
    dispatch_main_async_safe(^{
        [weakSelf applyNameLabelText];
        if ([weakSelf usesInlineTextLayout] && weakSelf.referedPreviewText.length > 0) {
            [weakSelf applyInlineTextLayoutWithTextColor:weakSelf.textLabel.textColor];
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

- (void)messageCellReferenceContentView:(RCMessageCellReferenceContentView *)referenceContentView
                       didPerformAction:(NSString *)action
                                  extra:(nullable NSDictionary *)extra {
    if ([self.delegate respondsToSelector:@selector(messageCellReferenceContentView:didPerformAction:extra:)]) {
        [self.delegate messageCellReferenceContentView:referenceContentView didPerformAction:action extra:extra];
    }
}

#pragma mark - UserInfo Update
- (void)onUserInfoUpdate:(NSNotification *)notification {
    NSDictionary *userInfoDic = notification.object;
    if ([self.referedSenderId isEqualToString:userInfoDic[@"userId"]]) {
        //重新取一下混合的用户信息
        [self setUserDisplayName];
    }
}

- (void)onGroupUserInfoUpdate:(NSNotification *)notification {
    if (self.referModel.conversationType == ConversationType_GROUP) {
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
        BOOL usesCompactQuoteLine = [self usesInlineTextLayout] || [self usesImagePreviewHeaderLayout];
        CGFloat lineWidth = usesCompactQuoteLine ? RCQuoteInlineLeftLineWidth : leftLine_width;
        CGFloat lineHeight = usesCompactQuoteLine ? RCQuoteInlineLeftLineHeight : 13.0;
        CGFloat lineY = 2.0;
        if ([self usesInlineTextLayout]) {
            lineY = MAX([self inlineTextFirstLineCenterY] - lineHeight / 2.0, 0);
        } else if ([self usesImagePreviewHeaderLayout]) {
            lineY = MAX((name_height - lineHeight) / 2.0, 0);
        }
        if ([RCKitUtility isRTL]) {
            _leftLimitLine =
                [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width - lineWidth, lineY, lineWidth, lineHeight)];
        } else {
            _leftLimitLine = [[UIView alloc] initWithFrame:CGRectMake(0, lineY, lineWidth, lineHeight)];
        }
        _leftLimitLine.backgroundColor = usesCompactQuoteLine
            ? RCDynamicColor(@"text_primary_color", @"0x020814", @"0xffffffcc")
            : RCDynamicColor(@"text_primary_color", @"0xA0A5Ab", @"0x7C7C7C");
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
        _nameLabel.font = ([self usesImagePreviewHeaderLayout] || [self usesFilePreviewLayout])
            ? [[self class] quoteTextFont]
            : [[RCKitConfig defaultConfig].font fontOfFourthLevel];
        _nameLabel.numberOfLines = 1;
        _nameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    return _nameLabel;
}

- (UIView *)contentView {
    if (!_contentView) {
        if ([self usesInlineTextLayout]) {
            CGFloat textWidth = [[self class] inlineTextMaxWidthForQuoteCardWidth:self.contentSize.width];
            CGFloat textX = [RCKitUtility isRTL] ? 0 : CGRectGetMaxX(self.leftLimitLine.frame) + name_and_leftLine_space;
            CGFloat textHeight = [self inlineTextLayoutHeight];
            CGFloat textY = MAX((self.frame.size.height - textHeight) / 2.0, 0);
            _contentView = [[UIView alloc] initWithFrame:CGRectMake(textX, textY, textWidth, textHeight)];
        } else if ([self usesImagePreviewHeaderLayout]) {
            _contentView =
            [[UIView alloc] initWithFrame:CGRectMake(0,
                                                     CGRectGetMaxY(self.nameLabel.frame),
                                                     self.contentSize.width,
                                                     self.frame.size.height - CGRectGetMaxY(self.nameLabel.frame))];
        } else if ([self usesFilePreviewLayout]) {
            _contentView =
            [[UIView alloc] initWithFrame:CGRectMake(0,
                                                     CGRectGetMaxY(self.nameLabel.frame),
                                                     self.contentSize.width,
                                                     self.frame.size.height - CGRectGetMaxY(self.nameLabel.frame))];
        } else if ([RCKitUtility isRTL]) {
            _contentView =
            [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.nameLabel.frame), CGRectGetWidth(self.nameLabel.frame), self.frame.size.height - CGRectGetMaxY(self.nameLabel.frame))];
        } else {
            _contentView =
            [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.leftLimitLine.frame) + name_and_leftLine_space,
                                                     CGRectGetMaxY(self.nameLabel.frame),
                                                     CGRectGetWidth(self.nameLabel.frame), self.frame.size.height - CGRectGetMaxY(self.nameLabel.frame))];
        }
        if (![self usesMessageCellReferenceContentView]) {
            UITapGestureRecognizer *messageTap =
            [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapContentView:)];
            messageTap.numberOfTapsRequired = 1;
            messageTap.numberOfTouchesRequired = 1;
            [_contentView addGestureRecognizer:messageTap];
            _contentView.userInteractionEnabled = YES;
        }
    }
    return _contentView;
}

- (UILabel *)textLabel {
    if (!_textLabel) {
        _textLabel = [[RCBaseLabel alloc] initWithFrame:self.contentView.bounds];
        _textLabel.numberOfLines = RCQuoteTextMaxNumberOfLines;
        [_textLabel setLineBreakMode:NSLineBreakByCharWrapping];
        _textLabel.font = [[self class] quoteTextFont];
    }
    return _textLabel;
}

- (RCBaseImageView *)msgImageView {
    if (!_msgImageView) {
        _msgImageView = [[RCBaseImageView alloc] init];
        _msgImageView.contentMode = UIViewContentModeScaleAspectFill;
        _msgImageView.clipsToBounds = YES;
        _msgImageView.layer.masksToBounds = YES;
        _msgImageView.layer.cornerRadius = 3;
    }
    return _msgImageView;
}

- (UIView *)filePreviewCardView {
    if (!_filePreviewCardView) {
        _filePreviewCardView = [[UIView alloc] initWithFrame:CGRectZero];
        _filePreviewCardView.backgroundColor = RCDynamicColor(@"file_quote_card_background", @"0xffffff", @"0x1f1f1f");
        _filePreviewCardView.layer.cornerRadius = 6;
        _filePreviewCardView.layer.masksToBounds = YES;
        _filePreviewCardView.layer.borderWidth = 0.5;
        _filePreviewCardView.layer.borderColor = RCDynamicColor(@"line_background_color", @"0xE2E4E5", @"0x3a3a3a").CGColor;
        [_filePreviewCardView addSubview:self.filePreviewIconView];
        [_filePreviewCardView addSubview:self.filePreviewNameLabel];
        [_filePreviewCardView addSubview:self.filePreviewSizeLabel];
    }
    return _filePreviewCardView;
}

- (RCBaseImageView *)filePreviewIconView {
    if (!_filePreviewIconView) {
        _filePreviewIconView = [[RCBaseImageView alloc] initWithFrame:CGRectZero];
        _filePreviewIconView.contentMode = UIViewContentModeScaleAspectFit;
        _filePreviewIconView.clipsToBounds = YES;
    }
    return _filePreviewIconView;
}

- (UILabel *)filePreviewNameLabel {
    if (!_filePreviewNameLabel) {
        _filePreviewNameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _filePreviewNameLabel.font = [[self class] quoteFilePreviewNameFont];
        _filePreviewNameLabel.textColor = RCDynamicColor(@"text_primary_color", @"0x020814", @"0xffffffcc");
        _filePreviewNameLabel.numberOfLines = 1;
        _filePreviewNameLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        _filePreviewNameLabel.textAlignment = [RCKitUtility isRTL] ? NSTextAlignmentRight : NSTextAlignmentLeft;
    }
    return _filePreviewNameLabel;
}

- (UILabel *)filePreviewSizeLabel {
    if (!_filePreviewSizeLabel) {
        _filePreviewSizeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _filePreviewSizeLabel.font = [[self class] quoteFilePreviewSizeFont];
        _filePreviewSizeLabel.textColor = RCDynamicColor(@"text_secondary_color", @"0xa0a5ab", @"0xffffff66");
        _filePreviewSizeLabel.numberOfLines = 1;
        _filePreviewSizeLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _filePreviewSizeLabel.textAlignment = [RCKitUtility isRTL] ? NSTextAlignmentRight : NSTextAlignmentLeft;
    }
    return _filePreviewSizeLabel;
}

- (RCMessageCellReferenceContentView *)messageCellReferenceContentView {
    if (!_messageCellReferenceContentView) {
        Class viewClass = [RCMessageCellReferenceContentViewRegistry contentViewClassForMessageContent:self.referedContent
                                                                                            objectName:self.referedObjectName];
        if (!viewClass) {
            return nil;
        }
        _messageCellReferenceContentView = [[viewClass alloc] initWithFrame:self.contentView.bounds];
        _messageCellReferenceContentView.referencedContent = self.referedContent;
        _messageCellReferenceContentView.messageModel = self.referModel;
        [_messageCellReferenceContentView setReferencedContent:self.referedContent
                                             messageModel:self.referModel];
    }
    return _messageCellReferenceContentView;
}
@end
