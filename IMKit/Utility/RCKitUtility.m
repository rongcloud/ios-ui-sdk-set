//
//  RCKitUtility.m
//  iOS-IMKit
//
//  Created by xugang on 7/7/14.
//  Copyright (c) 2014 Heq.Shinoda. All rights reserved.
//

#import "RCKitUtility.h"
#import "RCConversationModel.h"
#import "RCIM.h"
#import "RCKitCommonDefine.h"
#import "RCUserInfoCacheManager.h"
#import <SafariServices/SafariServices.h>
#import "RCForwardManager.h"
#import "RCloudImageLoader.h"
#import "RCKitConfig.h"
#import "UIImage+RCDynamicImage.h"
#import "RCPinYin.h"
#import "RCMBProgressHUD.h"
#import "RCButton.h"
#import "RCExtensionService.h"
#import <RongDiscussion/RongDiscussion.h>
#import <RongPublicService/RongPublicService.h>
#import <UIKit/UIKit.h>
@interface RCKitWeakRefObject : NSObject
@property (nonatomic, weak) id weakRefObj;
+ (instancetype)refWithObject:(id)obj;
@end

@implementation RCKitWeakRefObject
+ (instancetype)refWithObject:(id)obj {
    RCKitWeakRefObject *ref = [[RCKitWeakRefObject alloc] init];
    ref.weakRefObj = obj;
    return ref;
}
@end

@implementation RCKitUtility
#pragma mark - Public Method

+ (NSString *)convertConversationTime:(long long)secs {
    NSString *timeText = nil;
    NSDate *messageDate = [NSDate dateWithTimeIntervalSince1970:secs];
    NSDateFormatter *formatter = [self getDateFormatter];
    NSString *locale = RCLocalizedString(@"locale");
    [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:locale]];
    if ([self isSameYear:messageDate]) {
        if ([self isSameMonth:messageDate]) {
            NSInteger intervalDays = [self getIntervalDays:messageDate];
            if (intervalDays == 0) {
                NSString *formatStr = [self getDateFormatterString:messageDate];
                [formatter setDateFormat:formatStr];
                return timeText = [formatter stringFromDate:messageDate];
            } else if (intervalDays == 1) {
                return timeText = RCLocalizedString(@"Yesterday");
            } else if (intervalDays < 7 && [self isCurrentWeek:messageDate]) {
                [formatter setDateFormat:@"eeee"];
                return timeText = [formatter stringFromDate:messageDate];
            } else {
                [formatter setDateFormat:RCLocalizedString(@"SameYearDate")];
                return timeText = [formatter stringFromDate:messageDate];
            }
        }
        [formatter setDateFormat:RCLocalizedString(@"SameYearDate")];
        return timeText = [formatter stringFromDate:messageDate];
    }
    [formatter setDateFormat:RCLocalizedString(@"chatListDate")];
    return timeText = [formatter stringFromDate:messageDate];
}

+ (NSString *)convertMessageTime:(long long)secs {
    NSString *timeText = nil;
    NSDate *messageDate = [NSDate dateWithTimeIntervalSince1970:secs];
    NSDateFormatter *formatter = [self getDateFormatter];
    [formatter setLocale:[[NSLocale alloc]
                             initWithLocaleIdentifier:RCLocalizedString(@"locale")]];
    if ([self isSameYear:messageDate]) {
        if ([self isSameMonth:messageDate]) {
            NSInteger intervalDays = [self getIntervalDays:messageDate];
            NSString *formatStr = [self getDateFormatterString:messageDate];
            [formatter setDateFormat:formatStr];
            if (intervalDays == 0) {
                return timeText = [formatter stringFromDate:messageDate];
            } else if (intervalDays == 1) {
                return timeText = [NSString stringWithFormat:@"%@ %@", RCLocalizedString(@"Yesterday"), [formatter stringFromDate:messageDate]];
            } else if (intervalDays < 7 && [self isCurrentWeek:messageDate]) {
                [formatter setDateFormat:[NSString stringWithFormat:@"eeee %@", formatStr]];
                return timeText = [formatter stringFromDate:messageDate];
            } else {
                [formatter setDateFormat:[NSString stringWithFormat:@"%@ %@", RCLocalizedString(@"SameYearDate"), [self getDateFormatterString:messageDate]]];
                return [formatter stringFromDate:messageDate];
            }
        }
        [formatter setDateFormat:[NSString stringWithFormat:@"%@ %@", RCLocalizedString(@"SameYearDate"), [self getDateFormatterString:messageDate]]];
        return [formatter stringFromDate:messageDate];
    }
    return [self getMessageDate:messageDate dateFormat:formatter];
}

+ (UIImage *)imageNamed:(NSString *)name ofBundle:(NSString *)bundleName {
    static NSMutableDictionary *loadedObjectDict = nil;
    if (!loadedObjectDict) {
        loadedObjectDict = [[NSMutableDictionary alloc] init];
    }
    NSString *keyString = [NSString stringWithFormat:@"%@%@", bundleName, name];
    if (@available(iOS 13.0, *)) {
        NSNumber *currentUserInterfaceStyle =
            [[NSUserDefaults standardUserDefaults] objectForKey:@"RCCurrentUserInterfaceStyle"];
        keyString = [NSString stringWithFormat:@"%@%@%@", bundleName, name, currentUserInterfaceStyle];
    }
    RCKitWeakRefObject *ref = loadedObjectDict[keyString];
    if (ref.weakRefObj) {
        return ref.weakRefObj;
    }

    UIImage *image = nil;
    NSString *image_name = name;
    if (![image_name hasSuffix:@".png"]) {
        image_name = [NSString stringWithFormat:@"%@.png", name];
    }
    NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
    NSString *bundlePath = [resourcePath stringByAppendingPathComponent:bundleName];
    NSString *image_path = [bundlePath stringByAppendingPathComponent:image_name];

    image = [UIImage rc_imageWithLocalPath:image_path];

    [loadedObjectDict setObject:[RCKitWeakRefObject refWithObject:image] forKey:keyString];
    return image;
}

+ (CGSize)getTextDrawingSize:(NSString *)text font:(UIFont *)font constrainedSize:(CGSize)constrainedSize {
    if (text.length <= 0) {
        return CGSizeZero;
    }

    if ([text respondsToSelector:@selector(boundingRectWithSize:options:attributes:context:)]) {
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
        NSDictionary *attributes = @{NSFontAttributeName : font, NSParagraphStyleAttributeName : paragraphStyle};

        return [text boundingRectWithSize:constrainedSize
                                  options:(NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                               attributes:attributes
                                  context:nil].size;
    }
    return CGSizeZero;
}

+ (NSString *)formatLocalNotification:(RCMessage *)message {
    RCMessageContent *messageContent = message.content;
    NSString *targetId = message.targetId;
    RCConversationType conversationType = message.conversationType;
    
    if ([messageContent isMemberOfClass:RCDiscussionNotificationMessage.class]) {
        RCDiscussionNotificationMessage *notification = (RCDiscussionNotificationMessage *)messageContent;
        return [RCKitUtility __formatDiscussionNotificationMessageContent:notification];
    } else if ([messageContent isMemberOfClass:RCGroupNotificationMessage.class]) {
        RCGroupNotificationMessage *notification = (RCGroupNotificationMessage *)messageContent;
        return [RCKitUtility __formatGroupNotificationMessageContent:notification];
    } else if ([messageContent isMemberOfClass:RCRecallNotificationMessage.class]) {
        RCRecallNotificationMessage *notification = (RCRecallNotificationMessage *)messageContent;
        return [RCKitUtility __formatRecallLocalNotificationMessageContent:notification
                                                                  targetId:targetId
                                                          conversationType:conversationType];
    } else if ([messageContent isMemberOfClass:[RCContactNotificationMessage class]]) {
        RCContactNotificationMessage *notification = (RCContactNotificationMessage *)messageContent;
        return [RCKitUtility __formatContactNotificationMessageContent:notification];
    } else if ([messageContent isMemberOfClass:[RCPublicServiceMultiRichContentMessage class]]) {
        RCPublicServiceMultiRichContentMessage *notification = (RCPublicServiceMultiRichContentMessage *)messageContent;
        RCRichContentItem *item = notification.richContents.firstObject;
        return item.title;
    } else if ([messageContent isMemberOfClass:[RCPublicServiceRichContentMessage class]]) {
        RCPublicServiceRichContentMessage *notification = (RCPublicServiceRichContentMessage *)messageContent;
        return notification.richContent.title;
    } else if ([messageContent respondsToSelector:@selector(conversationDigest)]) {
        NSString *formatedMsg = [messageContent performSelector:@selector(conversationDigest)];
        //当会话最后一条消息是文本且长度超过1W时，滑动会话列表卡顿,所以这里做截取
        if (formatedMsg.length > 500) {
            formatedMsg = [formatedMsg substringToIndex:500];
            formatedMsg = [formatedMsg stringByAppendingString:@"..."];
        }else if(formatedMsg.length == 0){
            formatedMsg = [RCKitUtility localizedDescription:messageContent];
        }
        return formatedMsg;
    } else {
        return [RCKitUtility localizedDescription:messageContent];
    }
}

+ (NSString *)formatMessage:(RCMessageContent *)messageContent
                   targetId:(NSString *)targetId
           conversationType:(RCConversationType)conversationType
               isAllMessage:(BOOL)isAllMessage {
    if (messageContent.destructDuration > 0) {
        return NSLocalizedStringFromTable(@"BurnAfterRead", @"RongCloudKit", nil);
    }
    if ([messageContent isMemberOfClass:RCDiscussionNotificationMessage.class]) {
        RCDiscussionNotificationMessage *notification = (RCDiscussionNotificationMessage *)messageContent;
        return [RCKitUtility __formatDiscussionNotificationMessageContent:notification];
    } else if ([messageContent isMemberOfClass:RCGroupNotificationMessage.class]) {
        RCGroupNotificationMessage *notification = (RCGroupNotificationMessage *)messageContent;
        return [RCKitUtility __formatGroupNotificationMessageContent:notification];
    } else if ([messageContent isMemberOfClass:RCRecallNotificationMessage.class]) {
        RCRecallNotificationMessage *notification = (RCRecallNotificationMessage *)messageContent;
        return [RCKitUtility __formatRCRecallNotificationMessageContent:notification
                                                               targetId:targetId
                                                       conversationType:conversationType];
    } else if ([messageContent isMemberOfClass:[RCContactNotificationMessage class]]) {
        RCContactNotificationMessage *notification = (RCContactNotificationMessage *)messageContent;
        return [RCKitUtility __formatContactNotificationMessageContent:notification];
    } else if ([messageContent isMemberOfClass:[RCPublicServiceMultiRichContentMessage class]]) {
        RCPublicServiceMultiRichContentMessage *notification = (RCPublicServiceMultiRichContentMessage *)messageContent;
        RCRichContentItem *item = notification.richContents.firstObject;
        return item.title;
    } else if ([messageContent isMemberOfClass:[RCPublicServiceRichContentMessage class]]) {
        RCPublicServiceRichContentMessage *notification = (RCPublicServiceRichContentMessage *)messageContent;
        return notification.richContent.title;
    } else if ([messageContent respondsToSelector:@selector(conversationDigest)]) {
        NSString *formatedMsg = [messageContent performSelector:@selector(conversationDigest)];
        //父类conversationDigest return objName
        if ([formatedMsg isEqualToString:[[messageContent class] getObjectName]]) {
            formatedMsg = [RCKitUtility localizedDescription:messageContent];
        }
        if ([formatedMsg isEqualToString:[[messageContent class] getObjectName]]) {
            formatedMsg = @"";
        }
        //当会话最后一条消息是文本且长度超过1W时，滑动会话列表卡顿,所以这里做截取
        if (!isAllMessage && formatedMsg.length > 500) {
            formatedMsg = [formatedMsg substringToIndex:500];
            formatedMsg = [formatedMsg stringByAppendingString:@"..."];
        }else if(formatedMsg.length == 0){
            formatedMsg = @"";
        }
        return formatedMsg;
    } else {
        return [RCKitUtility localizedDescription:messageContent];
    }
}

+ (NSString *)formatMessage:(RCMessageContent *)messageContent
                   targetId:(NSString *)targetId
           conversationType:(RCConversationType)conversationType {
    return [self formatMessage:messageContent targetId:targetId conversationType:conversationType isAllMessage:NO];
}

+ (NSString *)formatMessage:(RCMessageContent *)messageContent {
    return [self formatMessage:messageContent targetId:nil conversationType:ConversationType_INVALID isAllMessage:NO];
}

+ (BOOL)isVisibleMessage:(RCMessage *)message {
    if ([[message.content class] persistentFlag] & MessagePersistent_ISPERSISTED) {
        return YES;
    } else if (!message.content && message.messageId > 0 && RCKitConfigCenter.message.showUnkownMessage) {
        return YES;
    }
    return NO;
}

+ (BOOL)isUnkownMessage:(long)messageId content:(RCMessageContent *)content {
    if (!content && messageId > 0 && RCKitConfigCenter.message.showUnkownMessage) {
        return YES;
    }
    return NO;
}

+ (NSDictionary *)getNotificationUserInfoDictionary:(RCMessage *)message {
    return [RCKitUtility getNotificationUserInfoDictionary:message.conversationType
                                                fromUserId:message.senderUserId
                                                  targetId:message.targetId
                                                objectName:message.objectName
                                                 messageId:message.messageId
                                                messageUId:message.messageUId];
}

+ (NSDictionary *)getNotificationUserInfoDictionary:(RCConversationType)conversationType
                                         fromUserId:(NSString *)fromUserId
                                           targetId:(NSString *)targetId
                                         objectName:(NSString *)objectName {

    return [RCKitUtility getNotificationUserInfoDictionary:conversationType
                                                fromUserId:fromUserId
                                                  targetId:targetId
                                                objectName:objectName
                                                 messageId:0
                                                messageUId:@""];
}

+ (NSDictionary *)getNotificationUserInfoDictionary:(RCConversationType)conversationType
                                         fromUserId:(NSString *)fromUserId
                                           targetId:(NSString *)targetId
                                         objectName:(NSString *)objectName
                                          messageId:(long)messageId
                                         messageUId:(NSString *)messageUId {
    NSString *type = @"PR";
    switch (conversationType) {
    case ConversationType_PRIVATE:
        type = @"PR";
        break;
    case ConversationType_GROUP:
        type = @"GRP";
        break;
    case ConversationType_DISCUSSION:
        type = @"DS";
        break;
    case ConversationType_CUSTOMERSERVICE:
        type = @"CS";
        break;
    case ConversationType_SYSTEM:
        type = @"SYS";
        break;
    case ConversationType_APPSERVICE:
        type = @"MC";
        break;
    case ConversationType_PUBLICSERVICE:
        type = @"MP";
        break;
    case ConversationType_PUSHSERVICE:
        type = @"PH";
        break;
    default:
        return nil;
    }
    return @{
        @"rc" : @{
            @"cType" : type ?: @"",
            @"fId" : fromUserId ?: @"",
            @"oName" : objectName ?: @"",
            @"tId" : targetId ?: @"",
            @"mId" : [NSString stringWithFormat:@"%ld", messageId],
            @"id" : messageUId ?: @""
        }
    };
}

+ (NSString *)getFileTypeIcon:(NSString *)fileType {
    //把后缀名强制改为小写
    fileType = [fileType lowercaseString];
    if ([fileType isEqualToString:@"png"] || [fileType isEqualToString:@"jpg"] || [fileType isEqualToString:@"bmp"] ||
        [fileType isEqualToString:@"cod"] || [fileType isEqualToString:@"gif"] || [fileType isEqualToString:@"jpe"] ||
        [fileType isEqualToString:@"jpeg"] || [fileType isEqualToString:@"jfif"] || [fileType isEqualToString:@"svg"] ||
        [fileType isEqualToString:@"tif"] || [fileType isEqualToString:@"tiff"] || [fileType isEqualToString:@"ras"] ||
        [fileType isEqualToString:@"ico"] || ([fileType isEqualToString:@"pbm"] && RC_IOS_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.0")) ||
        [fileType isEqualToString:@"pgm"] || [fileType isEqualToString:@"pnm"] || [fileType isEqualToString:@"ppm"] ||
        [fileType isEqualToString:@"xbm"] || [fileType isEqualToString:@"xpm"] || [fileType isEqualToString:@"xwd"] ||
        [fileType isEqualToString:@"rgb"]) {
        return @"PictureFile";
    } else if ([fileType isEqualToString:@"log"] || [fileType isEqualToString:@"txt"] ||
               [fileType isEqualToString:@"html"] || [fileType isEqualToString:@"stm"] ||
               [fileType isEqualToString:@"uls"] || [fileType isEqualToString:@"bas"] ||
               [fileType isEqualToString:@"c"] || [fileType isEqualToString:@"h"] ||
               [fileType isEqualToString:@"rtf"] || [fileType isEqualToString:@"sct"] ||
               [fileType isEqualToString:@"tsv"] || [fileType isEqualToString:@"htt"] ||
               [fileType isEqualToString:@"htc"] || [fileType isEqualToString:@"etx"] ||
               [fileType isEqualToString:@"vcf"]) {
        return @"TextFile";
    } else if ([fileType isEqualToString:@"mp3"] || [fileType isEqualToString:@"au"] ||
               [fileType isEqualToString:@"snd"] || [fileType isEqualToString:@"mid"] ||
               [fileType isEqualToString:@"rmi"] || [fileType isEqualToString:@"aif"] ||
               [fileType isEqualToString:@"aifc"] || [fileType isEqualToString:@"m3u"] ||
               [fileType isEqualToString:@"ra"] || [fileType isEqualToString:@"ram"] ||
               [fileType isEqualToString:@"wav"] || [fileType isEqualToString:@"wma"]) {
        return @"Mp3File";
    } else if ([fileType isEqualToString:@"pdf"]) {
        return @"PdfFile";
    } else if ([fileType isEqualToString:@"doc"] || [fileType isEqualToString:@"docx"] ||
               [fileType isEqualToString:@"dot"] || [fileType isEqualToString:@"dotx"]) {
        return @"WordFile";
    } else if ([fileType isEqualToString:@"xls"] || [fileType isEqualToString:@"xlsx"] ||
               [fileType isEqualToString:@"xlc"] || [fileType isEqualToString:@"xlm"] ||
               [fileType isEqualToString:@"xla"] || [fileType isEqualToString:@"xlt"] ||
               [fileType isEqualToString:@"xlw"]) {
        return @"ExcelFile";
    } else if ([fileType isEqualToString:@"mp4"] || [fileType isEqualToString:@"mov"] ||
               [fileType isEqualToString:@"rmvb"] || [fileType isEqualToString:@"avi"] ||
               [fileType isEqualToString:@"mp2"] || [fileType isEqualToString:@"xpa"] ||
               [fileType isEqualToString:@"xpe"] || [fileType isEqualToString:@"mpeg"] ||
               [fileType isEqualToString:@"mpg"] || [fileType isEqualToString:@"mpv2"] ||
               [fileType isEqualToString:@"qt"] || [fileType isEqualToString:@"lsf"] ||
               [fileType isEqualToString:@"lsx"] || [fileType isEqualToString:@"asf"] ||
               [fileType isEqualToString:@"asr"] || [fileType isEqualToString:@"asx"] ||
               [fileType isEqualToString:@"wmv"] || [fileType isEqualToString:@"movie"]) {
        return @"VideoFile";
    } else if ([fileType isEqualToString:@"ppt"] || [fileType isEqualToString:@"pptx"]) {
        return @"pptFile";
    } else if ([fileType isEqualToString:@"pages"]) {
        return @"Pages";
    } else if ([fileType isEqualToString:@"numbers"]) {
        return @"Numbers";
    } else if ([fileType isEqualToString:@"key"]) {
        return @"Keynote";
    } else {
        return @"OtherFile";
    }
}

+ (NSString *)getReadableStringForFileSize:(long long)byteSize {
    if (byteSize < 0) {
        return @"0 B";
    } else if (byteSize < 1024) {
        return [NSString stringWithFormat:@"%lld B", byteSize];
    } else if (byteSize < 1024 * 1024) {
        double kSize = (double)byteSize / 1024;
        return [NSString stringWithFormat:@"%.2f KB", kSize];
    } else if (byteSize < 1024 * 1024 * 1024) {
        double kSize = (double)byteSize / (1024 * 1024);
        return [NSString stringWithFormat:@"%.2f MB", kSize];
    } else {
        double kSize = (double)byteSize / (1024 * 1024 * 1024);
        return [NSString stringWithFormat:@"%.2f GB", kSize];
    }
}

+ (UIImage *)defaultConversationHeaderImage:(RCConversationModel *)model {
    if (model.conversationModelType == RC_CONVERSATION_MODEL_TYPE_NORMAL) {
        if (model.conversationType == ConversationType_SYSTEM || model.conversationType == ConversationType_PRIVATE ||
            model.conversationType == ConversationType_CUSTOMERSERVICE) {
            return RCResourceImage(@"default_portrait_msg");
        } else if (model.conversationType == ConversationType_GROUP) {
            return RCResourceImage(@"default_group_portrait");
        } else if (model.conversationType == ConversationType_DISCUSSION) {
            return RCResourceImage(@"default_discussion_portrait");
        }
    } else if (model.conversationModelType == RC_CONVERSATION_MODEL_TYPE_COLLECTION) {
        if (model.conversationType == ConversationType_PRIVATE || model.conversationType == ConversationType_SYSTEM) {
            return RCResourceImage(@"default_portrait");
        } else if (model.conversationType == ConversationType_CUSTOMERSERVICE) {
            return RCResourceImage(@"portrait_kefu");
        } else if (model.conversationType == ConversationType_DISCUSSION) {
            return RCResourceImage(@"default_discussion_collection_portrait");
        } else if (model.conversationType == ConversationType_GROUP) {
            return RCResourceImage(@"default_collection_portrait");
        }
    } else if (model.conversationModelType == RC_CONVERSATION_MODEL_TYPE_PUBLIC_SERVICE) {
        return RCResourceImage(@"default_portrait");
    }
    return RCResourceImage(@"default_portrait");
}

+ (NSString *)defaultTitleForCollectionConversation:(RCConversationType)conversationType {
    if (conversationType == ConversationType_PRIVATE) {
        return RCLocalizedString(@"conversation_private_collection_title");
    } else if (conversationType == ConversationType_DISCUSSION) {
        return RCLocalizedString(@"conversation_discussion_collection_title");
    } else if (conversationType == ConversationType_GROUP) {
        return RCLocalizedString(@"conversation_group_collection_title");
    } else if (conversationType == ConversationType_CUSTOMERSERVICE) {
        return RCLocalizedString(@"conversation_customer_collection_title");
    } else if (conversationType == ConversationType_SYSTEM) {
        return RCLocalizedString(@"conversation_systemMessage_collection_title");
    }
    return nil;
}

+ (int)getConversationUnreadCount:(RCConversationModel *)model {
    if (model.conversationModelType == RC_CONVERSATION_MODEL_TYPE_COLLECTION) {
        return [[RCIMClient sharedRCIMClient] getUnreadCount:@[ @(model.conversationType) ]];
    } else {
        return [[RCIMClient sharedRCIMClient] getUnreadCount:model.conversationType targetId:model.targetId];
    }
}

+ (BOOL)getConversationUnreadMentionedStatus:(RCConversationModel *)model {
    if (model.conversationModelType == RC_CONVERSATION_MODEL_TYPE_COLLECTION) {
        return [[RCIMClient sharedRCIMClient] getUnreadMentionedCount:@[ @(model.conversationType) ]] != 0;
    } else {
        return [[RCIMClient sharedRCIMClient] getConversation:model.conversationType targetId:model.targetId]
            .hasUnreadMentioned;
    }
}

+ (void)syncConversationReadStatusIfEnabled:(RCConversationModel *)conversation {
    if (!RCKitConfigCenter.message.enableSyncReadStatus){
        return;
    }
    if (conversation.conversationType == ConversationType_PRIVATE && [RCKitConfigCenter.message.enabledReadReceiptConversationTypeList containsObject:@(conversation.conversationType)]) {
        [[RCIMClient sharedRCIMClient] sendReadReceiptMessage:conversation.conversationType
                                                     targetId:conversation.targetId
                                                         time:conversation.sentTime
                                                      success:nil
                                                        error:nil];
    } else if ((conversation.conversationType == ConversationType_PRIVATE &&
                ![RCKitConfigCenter.message.enabledReadReceiptConversationTypeList containsObject:@(conversation.conversationType)]) ||
               conversation.conversationType == ConversationType_GROUP ||
               conversation.conversationType == ConversationType_DISCUSSION ||
               conversation.conversationType == ConversationType_APPSERVICE ||
               conversation.conversationType == ConversationType_PUBLICSERVICE ||
               conversation.conversationType == ConversationType_Encrypted) {
        [[RCIMClient sharedRCIMClient] syncConversationReadStatus:conversation.conversationType
                                                         targetId:conversation.targetId
                                                             time:conversation.sentTime
                                                          success:nil
                                                            error:nil];
    }
}

+ (NSString *)getPinYinUpperFirstLetters:(NSString *)hanZi {
    if (hanZi.length == 0) {
        return nil;
    } else {
        NSMutableString *pinYinResult = [[NSMutableString alloc] init];
        for (int i = 0; i < hanZi.length; i++) {
            [pinYinResult appendFormat:@"%c", rcpinyinFirstLetter([hanZi characterAtIndex:i])];
        }
        return [[pinYinResult copy] uppercaseString];
    }
}

+ (void)openURLInSafariViewOrWebView:(NSString *)url base:(UIViewController *)viewController {
    if (!url || url.length == 0) {
        DebugLog(@"[RongIMKit] : Push to web Page url is nil");
        return;
    }
    url = [url stringByReplacingOccurrencesOfString:@" " withString:@""];
    url = [self checkOrAppendHttpForUrl:url];
    if (![RCIM sharedRCIM].embeddedWebViewPreferred && RC_IOS_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0")) {
        NSURL *targetUrl = [NSURL URLWithString:url];
        if (targetUrl) {
            SFSafariViewController *safari = [[SFSafariViewController alloc] initWithURL:targetUrl];
            safari.modalPresentationStyle = UIModalPresentationFullScreen;
            [viewController presentViewController:safari animated:YES completion:nil];
        } else {
            RCLogI(@"Push to web Page url is Invalid");
        }
    } else {
        UIViewController *webview = [[RCPublicServiceClient sharedPublicServiceClient] getPublicServiceWebViewController:url];
        [viewController.navigationController pushViewController:webview animated:YES];
    }
}

+ (NSString *)checkOrAppendHttpForUrl:(NSString *)url {
    if (![[url lowercaseString] hasPrefix:@"http://"] && ![[url lowercaseString] hasPrefix:@"https://"]) {
        url = [NSString stringWithFormat:@"http://%@", url];
    }
    return url;
}

+ (UIWindow *)getKeyWindow {
    UIWindow *keyWindow;
    for (UIWindow *window in [UIApplication sharedApplication].windows) {
        if ([window isKeyWindow]) {
            keyWindow = window;
        }
    }
    return keyWindow;
}

+ (UIEdgeInsets)getWindowSafeAreaInsets {
    UIEdgeInsets result = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) {
        UIWindow *window = [self getKeyWindow];
        if (window) {
            result = window.safeAreaInsets;
        }
    }else{
        result.top = [[UIApplication sharedApplication] statusBarFrame].size.height;
    }
    return result;
}

/*
 参考文档:
 https://blog.csdn.net/weixin_39339407/article/details/81162726
 https://www.jianshu.com/p/df094c044096
 https://www.jianshu.com/p/326ed98d92bb
 */
+ (UIImage *)fixOrientation:(UIImage *)image {

    // No-op if the orientation is already correct
    if (image.imageOrientation == UIImageOrientationUp)
        return image;

    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;

    switch (image.imageOrientation) {
    case UIImageOrientationDown:
    case UIImageOrientationDownMirrored:
        transform = CGAffineTransformTranslate(transform, image.size.width, image.size.height);
        transform = CGAffineTransformRotate(transform, M_PI);
        break;

    case UIImageOrientationLeft:
    case UIImageOrientationLeftMirrored:
        transform = CGAffineTransformTranslate(transform, image.size.width, 0);
        transform = CGAffineTransformRotate(transform, M_PI_2);
        break;

    case UIImageOrientationRight:
    case UIImageOrientationRightMirrored:
        transform = CGAffineTransformTranslate(transform, 0, image.size.height);
        transform = CGAffineTransformRotate(transform, -M_PI_2);
        break;
    default:
        break;
    }

    switch (image.imageOrientation) {
    case UIImageOrientationUpMirrored:
    case UIImageOrientationDownMirrored:
        transform = CGAffineTransformTranslate(transform, image.size.width, 0);
        transform = CGAffineTransformScale(transform, -1, 1);
        break;

    case UIImageOrientationLeftMirrored:
    case UIImageOrientationRightMirrored:
        transform = CGAffineTransformTranslate(transform, image.size.height, 0);
        transform = CGAffineTransformScale(transform, -1, 1);
        break;
    default:
        break;
    }

    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx =
        CGBitmapContextCreate(NULL, image.size.width, image.size.height, CGImageGetBitsPerComponent(image.CGImage), 0,
                              CGImageGetColorSpace(image.CGImage), CGImageGetBitmapInfo(image.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (image.imageOrientation) {
    case UIImageOrientationLeft:
    case UIImageOrientationLeftMirrored:
    case UIImageOrientationRight:
    case UIImageOrientationRightMirrored:
        // Grr...
        CGContextDrawImage(ctx, CGRectMake(0, 0, image.size.height, image.size.width), image.CGImage);
        break;

    default:
        CGContextDrawImage(ctx, CGRectMake(0, 0, image.size.width, image.size.height), image.CGImage);
        break;
    }

    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}

+ (BOOL)currentDeviceIsIPad {
    return [[UIDevice currentDevice].model containsString:@"iPad"];
}

+ (UIColor *)generateDynamicColor:(UIColor *)lightColor darkColor:(UIColor *)darkColor {
    if (!RCKitConfigCenter.ui.enableDarkMode) {
        return lightColor;
    }

    if (@available(iOS 13.0, *)) {
        UIColor *dyColor =
            [UIColor colorWithDynamicProvider:^UIColor *_Nonnull(UITraitCollection *_Nonnull traitCollection) {
                if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                    return darkColor;
                } else {
                    return lightColor;
                }
            }];
        return dyColor;
    } else {
        return lightColor;
    }
}

+ (BOOL)hasLoadedImage:(NSString *)imageUrl {
    return [[RCloudImageLoader sharedImageLoader] hasLoadedImageURL:[NSURL URLWithString:imageUrl]];
}

+ (NSData *)getImageDataForURLString:(NSString *)imageUrl {
    return [[RCloudImageLoader sharedImageLoader] getImageDataForURL:[NSURL URLWithString:imageUrl]];
}

+ (BOOL)showProgressViewFor:(UIView *)view text:(NSString *)text animated:(BOOL)animated {
    RCMBProgressHUD *hud = [RCMBProgressHUD showHUDAddedTo:view animated:YES];
    if (hud || text.length > 0) {
        hud.label.text = text;
    }
    return hud != nil;
}

+ (BOOL)hideProgressViewFor:(UIView *)view animated:(BOOL)animated {
    return [RCMBProgressHUD hideHUDForView:view animated:animated];
}

+ (UIColor *)color:(NSString *)key originalColor:(NSString *)colorStr {

    UIColor *originalColor = [self transformColor:colorStr];

    if (key.length == 0) {
        return originalColor;
    }

    NSArray *pathArr = [key componentsSeparatedByString:@"_"];
    NSMutableArray *keyArr = [NSMutableArray arrayWithArray:pathArr];
    [keyArr removeObjectAtIndex:0];
    UIColor *currentColor = [self getColor:[keyArr componentsJoinedByString:@"_"] file:pathArr[0]];
    if (currentColor) {
        return currentColor;
    } else {
        return originalColor;
    }
}

+ (UIColor *)getColor:(NSString *)key file:(NSString *)group {
    NSString *matchValue = [self getColorDic][group][key];
    if (matchValue.length > 0) {
        return [self transformColor:matchValue];
    } else {
        return nil;
    }
}

+ (NSArray <UIBarButtonItem *> *)getLeftNavigationItems:(UIImage *)image title:(NSString *)title target:(id)target action:(SEL)action{
    CGFloat width = image.size.width;
    RCButton *backBtn = [RCButton buttonWithType:UIButtonTypeCustom];
    backBtn.frame = CGRectMake(0, 0, width, image.size.height);
    [backBtn setImage:image forState:UIControlStateNormal];
    [backBtn setTitle:title forState:UIControlStateNormal];
    [backBtn setTitleColor:RCKitConfigCenter.ui.globalNavigationBarTintColor forState:UIControlStateNormal];
    [backBtn addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithCustomView:backBtn];
    return @[leftButton];
}

+ (BOOL)isRTL {
    if (@available(iOS 9.0, *)) {
        UIWindow *window = [self getKeyWindow];
        UISemanticContentAttribute attr = window.semanticContentAttribute;
        UIUserInterfaceLayoutDirection _layoutDirection = [UIView userInterfaceLayoutDirectionForSemanticContentAttribute:attr];
        return _layoutDirection == UIUserInterfaceLayoutDirectionRightToLeft;
    }
    return NO;
}

+ (BOOL)isAudioHolding {
    if([[RCCoreClient sharedCoreClient] isAudioHolding] ||
       [[RCExtensionService sharedService] isAudioHolding]) {
        return YES;
    }
    return NO;
}

+ (BOOL)isCameraHolding {
    if([[RCCoreClient sharedCoreClient] isCameraHolding] ||
       [[RCExtensionService sharedService] isCameraHolding]) {
        return YES;
    }
    return NO;
}

#pragma mark - Privite Methods
+ (NSString *)localizedDescription:(RCMessageContent *)messageContent {
    NSString *objectName = [[messageContent class] getObjectName];
    return RCLocalizedString(objectName);
}

+ (NSDateFormatter *)getDateFormatter {
    static NSDateFormatter *dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
    });
    return dateFormatter;
}

+ (NSString *)getMessageDate:(NSDate *)messageDate dateFormat:(NSDateFormatter *)formatter {
    [formatter setDateFormat:[NSString stringWithFormat:@"%@ %@",
                                                        RCLocalizedString(@"chatDate"),
                                                        [self getDateFormatterString:messageDate]]];
    return [formatter stringFromDate:messageDate];
}

+ (NSString *)getDateFormatterString:(NSDate *)messageDate {
    NSString *formatStringForHours =
        [NSDateFormatter dateFormatFromTemplate:@"j" options:0 locale:[NSLocale currentLocale]];
    NSRange containsA = [formatStringForHours rangeOfString:@"a"];
    BOOL hasAMPM = containsA.location != NSNotFound;
    NSString *formatStr = nil;
    if (hasAMPM) {
        formatStr = [self getFormatStringByMessageDate:messageDate];
    } else {
        formatStr = @"HH:mm";
    }
    return formatStr;
}

+ (BOOL)isSameYear:(NSDate *)messageDate{
    NSDate *now = [NSDate date];
    NSDateFormatter *formatter = [self getDateFormatter];
    [formatter setDateFormat:@"yyyy"];
    NSInteger currentYear = [[formatter stringFromDate:now] integerValue];
    NSInteger msgYear = [[formatter stringFromDate:messageDate] integerValue];
    if (currentYear == msgYear) {
        return YES;
    }
    return NO;
}

+ (BOOL)isSameMonth:(NSDate *)messageDate{
    NSDate *now = [NSDate date];
    NSDateFormatter *formatter = [self getDateFormatter];
    [formatter setDateFormat:@"MM"];
    NSInteger currentMonth = [[formatter stringFromDate:now] integerValue];
    NSInteger msgMonth = [[formatter stringFromDate:messageDate] integerValue];
    if (currentMonth == msgMonth) {
        return YES;
    }
    return NO;
}

+ (BOOL)isCurrentWeek:(NSDate *)messageDate {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    int unit = NSCalendarUnitWeekOfMonth | NSCalendarUnitMonth | NSCalendarUnitYear;
    NSDateComponents *nowCmps = [calendar components:unit fromDate:[NSDate date]];
    NSDateComponents *messageCmps = [calendar components:unit fromDate:messageDate];
    BOOL isCurrentWeek = (messageCmps.year == nowCmps.year) && (messageCmps.month == nowCmps.month) &&
                         (messageCmps.weekOfMonth == nowCmps.weekOfMonth);
    return isCurrentWeek;
}

+ (NSInteger)getIntervalDays:(NSDate *)messageDate{
    NSDate *now = [NSDate date];
    NSDateFormatter *formatter = [self getDateFormatter];
    [formatter setDateFormat:@"dd"];
    NSInteger currentDay = [[formatter stringFromDate:now] integerValue];
    NSInteger msgDay = [[formatter stringFromDate:messageDate] integerValue];
    return currentDay - msgDay;
}

+ (NSString *)getFormatStringByMessageDate:(NSDate *)messageDate {
    NSString *formatStr = nil;
    if ([[self class] isBetweenFromHour:0 toHour:6 currentDate:messageDate]) {
        formatStr = RCLocalizedString(@"Dawn");
    } else if ([[self class] isBetweenFromHour:6 toHour:12 currentDate:messageDate]) {
        formatStr = RCLocalizedString(@"Forenoon");
    } else if ([[self class] isBetweenFromHour:12 toHour:13 currentDate:messageDate]) {
        formatStr = RCLocalizedString(@"Noon");
    } else if ([[self class] isBetweenFromHour:13 toHour:18 currentDate:messageDate]) {
        formatStr = RCLocalizedString(@"Afternoon");
    } else {
        formatStr = RCLocalizedString(@"Evening");
    }
    return formatStr;
}

+ (BOOL)isBetweenFromHour:(NSInteger)fromHour toHour:(NSInteger)toHour currentDate:(NSDate *)currentDate {
    NSDate *date1 = [self getCustomDateWithHour:fromHour currentDate:currentDate];
    NSDate *date2 = [self getCustomDateWithHour:toHour currentDate:currentDate];
    if (([currentDate compare:date1] == NSOrderedDescending || [currentDate compare:date1] == NSOrderedSame) &&
        ([currentDate compare:date2] == NSOrderedAscending))
        return YES;
    return NO;
}

+ (NSDate *)getCustomDateWithHour:(NSInteger)hour currentDate:(NSDate *)currentDate {
    NSCalendar *currentCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *currentComps;
    NSInteger unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitWeekday |
                          NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    currentComps = [currentCalendar components:unitFlags fromDate:currentDate];
    //设置当天的某个点
    NSDateComponents *resultComps = [[NSDateComponents alloc] init];
    [resultComps setYear:[currentComps year]];
    [resultComps setMonth:[currentComps month]];
    [resultComps setDay:[currentComps day]];
    [resultComps setHour:hour];
    NSCalendar *resultCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    return [resultCalendar dateFromComponents:resultComps];
}

+ (NSString *)__formatContactNotificationMessageContent:(RCContactNotificationMessage *)contactNotification {
    RCUserInfo *userInfo = [[RCUserInfoCacheManager sharedManager] getUserInfo:contactNotification.sourceUserId];
    NSString *displayName = [self getDisplayName:userInfo];
    if (displayName.length) {
        if ([contactNotification.operation isEqualToString:ContactNotificationMessage_ContactOperationRequest]) {
            return [NSString stringWithFormat:RCLocalizedString(@"FromFriendInvitation"), displayName];
        }
        if ([contactNotification.operation isEqualToString:ContactNotificationMessage_ContactOperationAcceptResponse]) {
            return [NSString stringWithFormat:RCLocalizedString(@"AcceptFriendRequest")];
        }
        if ([contactNotification.operation isEqualToString:ContactNotificationMessage_ContactOperationRejectResponse]) {
            return [NSString stringWithFormat:RCLocalizedString(@"RejectFriendRequest"), displayName];
        }
    } else {
        return RCLocalizedString(@"AddFriendInvitation");
    }
    return nil;
}

+ (NSString *)__formatGroupNotificationMessageContent:(RCGroupNotificationMessage *)groupNotification {
    NSString *message = nil;

    NSData *jsonData = [groupNotification.data dataUsingEncoding:NSUTF8StringEncoding];
    if (jsonData == nil) {
        return nil;
    }
    NSDictionary *dictionary =
        [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
    NSString *operatorUserId = groupNotification.operatorUserId;
    NSString *nickName =
        [dictionary[@"operatorNickname"] isKindOfClass:[NSString class]] ? dictionary[@"operatorNickname"] : nil;
    NSArray *targetUserNickName = [dictionary[@"targetUserDisplayNames"] isKindOfClass:[NSArray class]]
                                      ? dictionary[@"targetUserDisplayNames"]
                                      : nil;
    NSArray *targetUserIds =
        [dictionary[@"targetUserIds"] isKindOfClass:[NSArray class]] ? dictionary[@"targetUserIds"] : nil;
    BOOL isMeOperate = NO;
    if ([groupNotification.operatorUserId isEqualToString:[RCIM sharedRCIM].currentUserInfo.userId]) {
        isMeOperate = YES;
        nickName = RCLocalizedString(@"You");
    }
    if ([groupNotification.operation isEqualToString:@"Create"]) {
        message =
            [NSString stringWithFormat:RCLocalizedString(isMeOperate ? @"GroupHaveCreated" : @"GroupCreated"),
                                       nickName];
    } else if ([groupNotification.operation isEqualToString:@"Add"]) {
        if (targetUserNickName.count == 0) {
            message =
                [NSString stringWithFormat:RCLocalizedString(@"GroupJoin"), nickName];
        } else {
            NSMutableString *names = [[NSMutableString alloc] init];
            NSMutableString *userIdStr = [[NSMutableString alloc] init];
            for (NSUInteger index = 0; index < targetUserNickName.count; index++) {
                if ([targetUserNickName[index] isKindOfClass:[NSString class]]) {
                    [names appendString:targetUserNickName[index]];
                    if (index != targetUserNickName.count - 1) {
                        [names appendString:RCLocalizedString(@"punctuation")];
                    }
                }
            }
            for (NSUInteger index = 0; index < targetUserIds.count; index++) {
                if ([targetUserIds[index] isKindOfClass:[NSString class]]) {
                    [userIdStr appendString:targetUserIds[index]];
                    if (index != targetUserNickName.count - 1) {
                        [userIdStr appendString:RCLocalizedString(@"punctuation")];
                    }
                }
            }
            if ([operatorUserId isEqualToString:userIdStr]) {
                message = [NSString
                    stringWithFormat:RCLocalizedString(@"GroupJoin"), nickName];
            } else {
                if (targetUserIds.count > targetUserNickName.count) {
                    names = [NSMutableString
                        stringWithFormat:@"%@%@", names, RCLocalizedString(@"GroupEtc")];
                }
                message = [NSString
                    stringWithFormat:RCLocalizedString(isMeOperate ? @"GroupHaveInvited" : @"GroupInvited"),
                                     nickName, names];
            }
        }
    } else if ([groupNotification.operation isEqualToString:@"Quit"]) {
        message = [NSString stringWithFormat:RCLocalizedString(isMeOperate ? @"GroupHaveQuit" : @"GroupQuit"),
                                             nickName];
    } else if ([groupNotification.operation isEqualToString:@"Kicked"]) {
        NSMutableString *names = [[NSMutableString alloc] init];
        for (NSUInteger index = 0; index < targetUserNickName.count; index++) {
            if ([targetUserNickName[index] isKindOfClass:[NSString class]]) {
                [names appendString:targetUserNickName[index]];
                if (index != targetUserNickName.count - 1) {
                    [names appendString:RCLocalizedString(@"punctuation")];
                }
            }
        }
        if (targetUserIds.count > targetUserNickName.count) {
            names = [NSMutableString
                stringWithFormat:@"%@%@", names, NSLocalizedStringFromTable(@"GroupEtc", @"RongCloudKit", nil)];
        }
        message =
            [NSString stringWithFormat:NSLocalizedStringFromTable(isMeOperate ? @"GroupHaveRemoved" : @"GroupRemoved",
                                                                  @"RongCloudKit", nil),
                                       nickName, names];
    } else if ([groupNotification.operation isEqualToString:@"Rename"]) {
        NSString *groupName =
            [dictionary[@"targetGroupName"] isKindOfClass:[NSString class]] ? dictionary[@"targetGroupName"] : nil;
        message = [NSString
            stringWithFormat:RCLocalizedString(@"GroupChanged"), nickName, groupName];
    } else if ([groupNotification.operation isEqualToString:@"Dismiss"]) {
        message =
            [NSString stringWithFormat:RCLocalizedString(isMeOperate ? @"GroupHaveDismiss" : @"GroupDismiss"),
                                       nickName];
    } else {
        message = groupNotification.message;
    }
    return message;
}

+ (NSString *)__formatDiscussionNotificationMessageContent:(RCDiscussionNotificationMessage *)discussionNotification {
    if (nil == discussionNotification) {
        DebugLog(@"[RongIMKit] : No userInfo in cache & db");
        return nil;
    }
    NSArray *operatedIds = nil;
    NSString *operationInfo = nil;

    //[RCKitUtility sharedInstance].discussionNotificationOperatorName = userInfo.name;
    switch (discussionNotification.type) {
    case RCInviteDiscussionNotification:
    case RCRemoveDiscussionMemberNotification: {
        NSString *trimedExtension = [discussionNotification.extension
            stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSArray *ids = [trimedExtension componentsSeparatedByString:@","];
        if (ids.count <= 0 && trimedExtension) {
            ids = [NSArray arrayWithObject:trimedExtension];
        }
        operatedIds = ids;
    } break;
    case RCQuitDiscussionNotification:
        break;

    case RCRenameDiscussionTitleNotification:
    case RCSwichInvitationAccessNotification:
        operationInfo = discussionNotification.extension;
        break;

    default:
        break;
    }

    // NSString *format = nil;
    NSString *message = nil;
    NSString *target = nil;
    NSString *userId = [RCIMClient sharedRCIMClient].currentUserInfo.userId;
    if (operatedIds) {
        if (operatedIds.count == 1) {
            if ([operatedIds[0] isEqualToString:userId]) {
                target = RCLocalizedString(@"You");
            } else {
                RCUserInfo *userInfo = [[RCUserInfoCacheManager sharedManager] getUserInfo:operatedIds[0]];
                NSString *displayName = [self getDisplayName:userInfo];
                if ([displayName length]) {
                    target = displayName;
                } else {
                    target = [[NSString alloc] initWithFormat:@"user<%@>", operatedIds[0]];
                }
            }
        } else {
            NSString *_members = RCLocalizedString(@"MemberNumber");
            target = [NSString stringWithFormat:@"%lu %@", (unsigned long)operatedIds.count, _members, nil];
            // target = [NSString stringWithFormat:NSLocalizedString(@"%d位成员", nil), operatedIds.count, nil];
        }
    }

    NSString *operator= discussionNotification.operatorId;
    if ([operator isEqualToString:userId]) {
        operator= RCLocalizedString(@"You");
    } else {
        RCUserInfo *userInfo = [[RCUserInfoCacheManager sharedManager] getUserInfo:operator];
        NSString *displayName = [self getDisplayName:userInfo];
        if ([displayName length]) {
            operator = displayName;
        } else {
            operator = [[NSString alloc] initWithFormat:@"user<%@>", operator];
        }
    }
    switch (discussionNotification.type) {
    case RCInviteDiscussionNotification: {
        NSString *_invite = RCLocalizedString(@"Invite");
        NSString *_joinDiscussion = RCLocalizedString(@"JoinDiscussion");
            message = [NSString stringWithFormat:@"%@ %@ %@ %@",operator, _invite,target,_joinDiscussion, nil];
            //            format = NSLocalizedString(@"%@邀请%@加入了讨论组", nil);
            //            message = [NSString stringWithFormat:format, operator, target, nil];
    } break;
    case RCQuitDiscussionNotification: {
        NSString *_quitDiscussion = RCLocalizedString(@"QuitDiscussion");

        // format = NSLocalizedString(@"%@退出了讨论组", nil);
            message = [NSString stringWithFormat:@"%@ %@", operator,_quitDiscussion, nil];
    } break;

    case RCRemoveDiscussionMemberNotification: {
        // format = NSLocalizedString(@"%@被%@移出了讨论组", nil);
        NSString *_by = RCLocalizedString(@"By");
        NSString *_removeDiscussion = RCLocalizedString(@"RemoveDiscussion");
            message = [NSString stringWithFormat:@"%@ %@ %@ %@", operator,_by, target,_removeDiscussion,nil];
    } break;
    case RCRenameDiscussionTitleNotification: {
        // format = NSLocalizedString(@"%@修改讨论组为\"%@\"", nil);
        NSString *_modifyDiscussion = RCLocalizedString(@"ModifyDiscussion");
        target = operationInfo;
            message = [NSString stringWithFormat:@"%@ %@ \"%@\"", operator,_modifyDiscussion, target, nil];
    } break;
    case RCSwichInvitationAccessNotification: {
        // 1 for off, 0 for on
        BOOL canInvite = ![operationInfo isEqualToString:@"1"];
        target = canInvite ? RCLocalizedString(@"Open")
                           : RCLocalizedString(@"Close");

        NSString *_inviteStatus = RCLocalizedString(@"InviteStatus");

        // format = NSLocalizedString(@"%@%@了成员邀请", nil);
        message =
            [NSString stringWithFormat:@"%@ %@ %@", operator, target, _inviteStatus, nil];
    } break;
    default:
        break;
    }
    return message;
}

+ (NSString *)__formatRCRecallNotificationMessageContent:
                  (RCRecallNotificationMessage *)recallNotificationMessageNotification
                                                targetId:(NSString *)targetId
                                        conversationType:(RCConversationType)conversationType {
    if (!recallNotificationMessageNotification || !recallNotificationMessageNotification.operatorId) {
        return nil;
    }

    NSString *currentUserId = [RCIMClient sharedRCIMClient].currentUserInfo.userId;
    NSString *operator= recallNotificationMessageNotification.operatorId;
    if (recallNotificationMessageNotification.isAdmin) {
        return
            [NSString stringWithFormat:RCLocalizedString(@"OtherHasRecalled"),
                                       RCLocalizedString(@"AdminWithMessageRecalled")];
    }else if ([operator isEqualToString:currentUserId]) {
        return [NSString stringWithFormat:@"%@", RCLocalizedString(@"SelfHaveRecalled")];
    } else {
        RCUserInfo *userInfo = [[RCUserInfoCacheManager sharedManager] getUserInfo:operator];
        NSString *operatorName = userInfo.name;
        if (userInfo.alias.length > 0) {
            operatorName = userInfo.alias;
        } else {
            if (conversationType == ConversationType_GROUP && targetId.length > 0) {
                RCUserInfo *groupMemberInfo = [[RCUserInfoCacheManager sharedManager] getUserInfo:operator inGroupId:targetId];
                if (groupMemberInfo.name.length > 0) {
                    operatorName = groupMemberInfo.name;
                }
            }
        }
        if (operatorName.length == 0) {
            operatorName= [[NSString alloc] initWithFormat:@"user<%@>", operator];
        }
        return [NSString
            stringWithFormat:RCLocalizedString(@"OtherHasRecalled"), operatorName];
    }
}

+ (NSString *)__formatRecallLocalNotificationMessageContent:(RCRecallNotificationMessage *)recallNotificationMessageNotification
                                                   targetId:(NSString *)targetId
                                           conversationType:(RCConversationType)conversationType {
    if (!recallNotificationMessageNotification || !recallNotificationMessageNotification.operatorId) {
        return nil;
    }

    NSString *currentUserId = [RCIMClient sharedRCIMClient].currentUserInfo.userId;
    NSString *operator= recallNotificationMessageNotification.operatorId;
    if (recallNotificationMessageNotification.isAdmin) {
        return
            [NSString stringWithFormat:NSLocalizedStringFromTable(@"OtherHasRecalled", @"RongCloudKit", nil),
                                       NSLocalizedStringFromTable(@"AdminWithMessageRecalled", @"RongCloudKit", nil)];
    }else if ([operator isEqualToString:currentUserId]) {
        return [NSString stringWithFormat:@"%@", NSLocalizedStringFromTable(@"SelfHaveRecalled", @"RongCloudKit", nil)];
    } else {
        RCUserInfo *userInfo = [[RCUserInfoCacheManager sharedManager] getUserInfo:operator];
        NSString *operatorName = userInfo.name;
        if (userInfo.alias.length > 0) {
            operatorName = userInfo.alias;
        } else {
            if (conversationType == ConversationType_GROUP && targetId.length > 0) {
                RCUserInfo *groupMemberInfo = [[RCUserInfoCacheManager sharedManager] getUserInfo:operator inGroupId:targetId];
                if (groupMemberInfo.name.length > 0) {
                    operatorName = groupMemberInfo.name;
                }
            }
        }
        
        if (operatorName.length == 0) {
            operatorName= [[NSString alloc] initWithFormat:@"user<%@>", operator];
        }
        if (conversationType == ConversationType_GROUP) {
            return [NSString
                stringWithFormat:NSLocalizedStringFromTable(@"OtherHasRecalled", @"RongCloudKit", nil), operatorName];
        } else {
            return [NSString
                stringWithFormat:NSLocalizedStringFromTable(@"MessageHasRecalled", @"RongCloudKit", nil)];
        }
    }
}

+ (UIColor *)transformColor:(NSString *)colorString {

    NSArray *colorStrings =
        [[colorString stringByReplacingOccurrencesOfString:@" " withString:@""] componentsSeparatedByString:@"#"];

    NSString *rgbString = nil;
    NSString *alphaString = nil;

    if (colorStrings.count > 0) {
        rgbString = colorStrings[0];
    }
    if (colorStrings.count > 1) {
        alphaString = colorStrings[1];
    }

    unsigned long rgbValue = 0;
    if ([rgbString hasPrefix:@"0x"] || [rgbString hasPrefix:@"0X"]) {
        rgbValue = strtoul([rgbString UTF8String], NULL, 16);
    } else {
        rgbValue = strtoul([rgbString UTF8String], NULL, 10);
    }

    float alphaValue = 1.0f;
    if (alphaString.length > 0) {
        alphaValue = [alphaString floatValue];
        if ([alphaString hasSuffix:@"%"]) {
            alphaValue /= 100.0;
        }
    }

    return [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16)) / 255.0
                           green:((float)((rgbValue & 0xFF00) >> 8)) / 255.0
                            blue:((float)(rgbValue & 0xFF)) / 255.0
                           alpha:alphaValue];
}

+ (NSDictionary *)getColorDic {
    static NSDictionary *colorDic = nil;
    if (!colorDic) {
        colorDic = [[NSDictionary alloc] initWithContentsOfFile:[[[NSBundle mainBundle] resourcePath]
                                                                    stringByAppendingPathComponent:@"RCColor.plist"]];
    }
    return colorDic;
}

+ (NSString *)getDisplayName:(RCUserInfo *)userInfo {
    if (userInfo.alias.length > 0) {
        return userInfo.alias;
    }
    return userInfo.name;
}
@end
