//
//  RCForwardManager.m
//  SealTalk
//
//  Created by 孙浩 on 2019/6/17.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import "RCForwardManager.h"
#import "RCUserInfoCacheManager.h"
#import "RCCombineMessageUtility.h"
#import "RCMessageModel.h"
#import "RCKitUtility.h"
#import "RCCoreClient+Destructing.h"
#import "RCKitCommonDefine.h"
#import "RCLocationMessage+imkit.h"
#import "RCForwardKeyItem.h"
#import "RCDownloadHelper.h"
#import "RCIM.h"

#define BASE_HEAD @"baseHead"
#define BASE_BOTTOM @"baseBottom"
#define BASE_TIME @"time"
#define BASE_COMBINEMSGBODY @"CombineMsgBody"
#define TAG_TEXT @"{%text%}"
#define TAG_FILEURL @"{%fileUrl%}"
#define TAG_GIFCONTENT @"{%gifContent%}"
#define TAG_GIFDISPLAY @"{%gifDisplay%}"
#define TAG_GIFCONTENTDISPLAY @"{%gifContentDisplay%}"
#define TAG_TITLE @"{%title%}"
#define TAG_FOOT @"{%foot%}"
#define TAG_COMBINEBODY @"{%combineBody%}"
#define TAG_FILETYPE @"{%fileType%}"
#define TAG_FILEICON @"{%fileIcon%}"
#define TAG_FILENAME @"{%fileName%}"
#define TAG_SIZE @"{%size%}"
#define TAG_FILESIZE @"{%fileSize%}"
#define TAG_IMGURL @"{%imgUrl%}"
#define TAG_LOCATIONNAME @"{%locationName%}"
#define TAG_LATITUDE @"{%latitude%}"
#define TAG_LONGTITUDE @"{%longitude%}"
#define TAG_PORTRAIT @"{%portrait%}"
#define TAG_SHOWUSER @"{%showUser%}"
#define TAG_USERNAME @"{%userName%}"
#define TAG_SENDTIME @"{%sendTime%}"
#define TAG_TIME @"{%time%}"
#define TAG_IMGEBASE64 @"{%imageBase64%}"
#define RCForwardReplace(a, b, ...)                                                                                    \
    [a replaceOccurrencesOfString:b withString:__VA_ARGS__ options:0 range:NSMakeRange(0, a.length)];

@interface RCForwardManager ()

@property (nonatomic, strong) NSDictionary *templateJsonDic;

@property (nonatomic, strong) dispatch_queue_t rcForwardQueue;

@property(nonatomic, strong) NSDictionary *commonMessageInfo;
@end

@implementation RCForwardManager
#pragma mark - Public Methods
+ (RCForwardManager *)sharedInstance {
    static RCForwardManager *instance = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        instance = [[[self class] alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSString *bundlePath = [RCKitUtility bundlePathWithName:@"RongCloud"];
        NSString *templateFilePath = [bundlePath stringByAppendingPathComponent:@"template.json"];
        NSData *templateJsonData = [NSData dataWithContentsOfFile:templateFilePath];
        _templateJsonDic = [NSJSONSerialization JSONObjectWithData:templateJsonData options:1 error:nil];
        _rcForwardQueue = dispatch_queue_create("com.rongcloud.forwardQueue", DISPATCH_QUEUE_SERIAL);
        self.commonMessageInfo = [self makeCommonMessageInfo];
    }
    return self;
}

- (NSDictionary *)makeCommonMessageInfo {
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    RCForwardKeyItem *txt = [[RCForwardKeyItem alloc] initWithTitle:@""
                                                                 key:RCTextMessageTypeIdentifier];
    dic[RCTextMessageTypeIdentifier] = txt;
    
    RCForwardKeyItem *vc = [[RCForwardKeyItem alloc] initWithTitle:RCLocalizedString(@"RC:VcMsg")
                                                                 key:RCVoiceMessageTypeIdentifier];
    dic[RCHQVoiceMessageTypeIdentifier] = vc;
    dic[RCVoiceMessageTypeIdentifier] = vc;
    
    RCForwardKeyItem *imgText = [[RCForwardKeyItem alloc] initWithTitle:RCLocalizedString(@"RC:ImgTextMsg")
                                                                    key:@"RC:ImgTextMsg"];
    dic[@"RC:ImgTextMsg"] = imgText;
    
    RCForwardKeyItem *summary = [[RCForwardKeyItem alloc] initWithTitle:RCLocalizedString(@"RC:VCSummary")
                                                                    key:@"RC:VCSummary"];
    dic[@"RC:VCSummary"] = summary;
    
    RCForwardKeyItem *stkMsg = [[RCForwardKeyItem alloc] initWithTitle:RCLocalizedString(@"RC:StkMsg")
                                                                    key:@"RC:StkMsg"];
    dic[@"RC:StkMsg"] = stkMsg;
    
    RCForwardKeyItem *gif = [[RCForwardKeyItem alloc] initWithTitle:RCLocalizedString(@"RC:StkMsg")
                                                                    key:RCGIFMessageTypeIdentifier];
    dic[RCGIFMessageTypeIdentifier] = gif;
    
    RCForwardKeyItem *cardMsg = [[RCForwardKeyItem alloc] initWithTitle:RCLocalizedString(@"RC:CardMsg")
                                                                    key:@"RC:CardMsg"];
    dic[@"RC:CardMsg"] = cardMsg;

    return dic;
}
- (void)doForwardMessageList:(NSArray *)messageList
            conversationList:(NSArray *)conversationList
                   isCombine:(BOOL)isCombine
     forwardConversationType:(RCConversationType)forwardConversationType
                   completed:(void (^)(BOOL success))completedBlock {
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.rcForwardQueue, ^{
        if (!messageList || conversationList.count <= 0 || !forwardConversationType) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completedBlock(NO);
            });
        }
        if (isCombine) {
            [weakSelf sendCombienMessage:messageList
                      selectConversation:conversationList
                               isCombine:isCombine
                 forwardConversationType:forwardConversationType];
        } else {
            [weakSelf sendMessageOneByone:messageList selectConversation:conversationList isCombine:isCombine];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completedBlock) {
                completedBlock(YES);
            }
        });
    });
}

#pragma mark - Private Methods

- (void)sendMessageOneByone:(NSArray *)messageList
         selectConversation:(NSArray *)conversationList
                  isCombine:(BOOL)isCombine {
    for (RCMessageModel *message in messageList) {
        message.content.mentionedInfo = nil;
        message.content.senderUserInfo = nil;
        for (RCConversation *conversation in conversationList) {
            [self forwardWithConversationType:conversation.conversationType
                                     targetId:conversation.targetId
                                      content:message.content
                                    isCombine:isCombine];
        }
    }
}

- (void)sendCombienMessage:(NSArray *)messageList
        selectConversation:(NSArray *)conversationList
                 isCombine:(BOOL)isCombine
   forwardConversationType:(RCConversationType)forwardConversationType {
    //组装消息
    NSMutableArray *nameList = [[NSMutableArray alloc] init];
    NSMutableArray *summaryList = [[NSMutableArray alloc] init];
    NSString *baseHead = [self.templateJsonDic objectForKey:BASE_HEAD];
    NSString *baseBottom = [self.templateJsonDic objectForKey:BASE_BOTTOM];
    NSMutableString *htmlContent = [[NSMutableString alloc] init];
    [htmlContent appendString:baseHead];
    NSString *timeContent = [self formatTime:messageList.firstObject endModel:messageList.lastObject];
    [htmlContent appendString:timeContent];
    NSString *beforeUserId = [[NSString alloc] init];
    for (int i = 0; i < messageList.count; i++) {
        RCMessageModel *messageModel = [messageList objectAtIndex:i];
        RCUserInfo *userInfo;
        NSString *senderUserName;
        //组装名字
        if (forwardConversationType == ConversationType_GROUP) {
            userInfo = [[RCUserInfoCacheManager sharedManager] getUserInfo:messageModel.senderUserId inGroupId:messageModel.targetId];
            if (!userInfo) {
                userInfo = [[RCUserInfo alloc] initWithUserId:messageModel.senderUserId name:nil portrait:nil];
            }
            senderUserName = userInfo.name;
            RCGroup *groupInfo =
                [[RCUserInfoCacheManager sharedManager] getGroupInfoFromCacheOnly:messageModel.targetId];
            NSString *groupName = groupInfo.groupName ?: [NSString stringWithFormat:@"group<%@>", messageModel.targetId];
            if (![nameList containsObject:groupName]) {
                [nameList addObject:groupName];
            }
        } else {
            userInfo = [[RCUserInfoCacheManager sharedManager] getUserInfo:messageModel.senderUserId];
            if (!userInfo) {
                userInfo = [[RCUserInfo alloc] initWithUserId:messageModel.senderUserId name:nil portrait:nil];
            }
            senderUserName = userInfo.name;
            if (![nameList containsObject:senderUserName]) {
                [nameList addObject:senderUserName];
            }
        }
        //组装缩略信息
        if (i < 4) {
            [summaryList addObject:[self packageSummaryList:messageModel senderUserName:senderUserName]];
        }
        //组装htmlbody
        BOOL ifSplitPortrait;
        if ([beforeUserId isEqualToString:userInfo.userId]) {
            ifSplitPortrait = NO;
        } else {
            ifSplitPortrait = YES;
        }
        beforeUserId = userInfo.userId;
        NSString *htmlBody = [self packageHTMLBody:messageModel userInfo:userInfo ifSplitPortrait:ifSplitPortrait];
        [htmlContent appendString:htmlBody];
    }

    [htmlContent appendString:baseBottom];
    for (RCConversation *conversation in conversationList) {
        RCCombineMessage *combineMessage = [RCCombineMessage messageWithSummaryList:summaryList
                                                                           nameList:nameList
                                                                   conversationType:forwardConversationType
                                                                            content:htmlContent];
        [self forwardWithConversationType:conversation.conversationType
                                 targetId:conversation.targetId
                                  content:combineMessage
                                isCombine:isCombine];
    }
}

- (NSString *)packageSummaryList:(RCMessageModel *)messageModel senderUserName:(NSString *)senderUserName {
    NSMutableString *summaryContent = [[NSMutableString alloc] init];
    [summaryContent appendString:[NSString stringWithFormat:@"%@：", senderUserName]];
    if ([messageModel.objectName isEqualToString:RCTextMessageTypeIdentifier]) {
        RCTextMessage *textMessage = (RCTextMessage *)messageModel.content;
        if (textMessage.content) {
            [summaryContent appendString:textMessage.content];
        }
    } else if ([messageModel.objectName isEqualToString:RCImageMessageTypeIdentifier]) {
        [summaryContent appendString:RCLocalizedString(RCImageMessageTypeIdentifier)];
    } else if ([messageModel.objectName isEqualToString:@"RC:ImgTextMsg"]) {
        [summaryContent appendString:RCLocalizedString(@"RC:ImgTextMsg")];
    } else if ([messageModel.objectName isEqualToString:RCHQVoiceMessageTypeIdentifier] ||
               [messageModel.objectName isEqualToString:RCVoiceMessageTypeIdentifier]) {
        [summaryContent appendString:RCLocalizedString(@"RC:VcMsg")];
    } else if ([messageModel.objectName isEqualToString:RCFileMessageTypeIdentifier]) {
        [summaryContent appendString:RCLocalizedString(RCFileMessageTypeIdentifier)];
        [summaryContent appendString:((RCFileMessage *)messageModel.content).name];
    } else if ([messageModel.objectName isEqualToString:RCCombineMessageTypeIdentifier]) {
        [summaryContent appendString:RCLocalizedString(RCCombineMessageTypeIdentifier)];
    } else if ([messageModel.objectName isEqualToString:RCSightMessageTypeIdentifier]) {
        [summaryContent appendString:RCLocalizedString(RCSightMessageTypeIdentifier)];
    } else if ([messageModel.objectName isEqualToString:@"RC:LBSMsg"]) {
        [summaryContent appendString:RCLocalizedString(@"RC:LBSMsg")];
    } else if ([messageModel.objectName isEqualToString:@"RC:CardMsg"]) {
        [summaryContent appendString:RCLocalizedString(@"RC:CardMsg")];
    } else if ([messageModel.objectName isEqualToString:@"RC:StkMsg"]) {
        [summaryContent appendString:RCLocalizedString(@"RC:StkMsg")];
    } else if ([messageModel.objectName isEqualToString:@"RC:VCSummary"]) {
        [summaryContent appendString:RCLocalizedString(@"RC:VCSummary")];
    } else if ([messageModel.objectName isEqualToString:RCGIFMessageTypeIdentifier]) {
        [summaryContent appendString:RCLocalizedString(RCGIFMessageTypeIdentifier)];
    }
    return summaryContent;
}

- (NSMutableString *)p_generateCommonStringWith:(RCMessageModel *)model
                                       userInfo:(RCUserInfo *)userInfo
                                ifSplitPortrait:(BOOL)ifSplitPortrait {
    NSMutableString *templateString = [[NSMutableString alloc] init];

    BOOL ret = model && model.objectName;
    if (!ret) {
        return [templateString mutableCopy];
    }
    if ([model.objectName isEqualToString:RCTextMessageTypeIdentifier]) {
        RCTextMessage *message = (RCTextMessage *)model.content;
        templateString = [self generateCommonString:message.content
                                           userInfo:userInfo
                                           sentTime:model.sentTime
                                    ifSplitPortrait:ifSplitPortrait
                                            htmlKey:RCTextMessageTypeIdentifier];
    } else {
        RCForwardKeyItem *item = self.commonMessageInfo[model.objectName];
        if (!item) {
            return nil;
        }
        templateString = [self generateCommonString:item.title
                                           userInfo:userInfo
                                           sentTime:model.sentTime
                                    ifSplitPortrait:ifSplitPortrait
                                            htmlKey:item.htmlKey];
        if ([model.objectName isEqualToString:RCGIFMessageTypeIdentifier]) {
            RCGIFMessage *message = (RCGIFMessage *)model.content;
            RCForwardReplace(templateString, TAG_FILEURL, message.remoteUrl ? message.remoteUrl : @"");
            if ([[RCDownloadHelper getMinioOSSAddr] length] > 0) {
                RCForwardReplace(templateString, TAG_GIFCONTENT, RCLocalizedString(RCGIFMessageTypeIdentifier));
                // gif 图展示为 [图片]
                RCForwardReplace(templateString, TAG_GIFCONTENTDISPLAY, @"inline");
                RCForwardReplace(templateString, TAG_GIFDISPLAY, @"none");
            } else {
                // 直接展示 gif 图
                RCForwardReplace(templateString, TAG_GIFCONTENTDISPLAY, @"none");
                RCForwardReplace(templateString, TAG_GIFDISPLAY, @"inline");
            }
        }
    }
    NSLog(@"[W] [%@] - 0: %@", model.objectName, templateString);
    return [templateString mutableCopy];
}

- (BOOL)p_isCommonMessage:(RCMessageModel *)model {
    NSArray *array = [self.commonMessageInfo allKeys];
    if (model.objectName) {
        return [array containsObject:model.objectName];
    }

    return NO;
}

- (long)p_getSightSize:(RCSightMessage *)message {
    long long sightSize = 0;
    if (message.size) {
        sightSize = message.size;
    } else if (message.localPath) {
        sightSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:message.localPath error:nil] fileSize];
    } else {
        NSString *localPath = [RCFileUtility getSightCachePath:message.sightUrl];
        if ([[NSFileManager defaultManager] fileExistsAtPath:localPath]) {
            sightSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:localPath error:nil] fileSize];
        }
    }
    return sightSize;
}

- (NSMutableString *)p_generalTitleStyle:(RCMessageModel *)model
                                userInfo:(RCUserInfo *)userInfo
                         ifSplitPortrait:(BOOL)ifSplitPortrait {
    NSMutableString *templateString = [[NSMutableString alloc] init];

    if ([model.objectName isEqualToString:@"RC:LBSMsg"]) {
        RCLocationMessage *message = (RCLocationMessage *)model.content;
        templateString = [[self.templateJsonDic objectForKey:@"RC:LBSMsg"] mutableCopy];
        templateString = [self generalTitleStyle:templateString
                                        userInfo:userInfo
                                        sentTime:model.sentTime
                                 ifSplitPortrait:ifSplitPortrait];
        RCForwardReplace(templateString, TAG_LOCATIONNAME, message.locationName ? message.locationName : @"");
        RCForwardReplace(templateString, TAG_LATITUDE, [NSString stringWithFormat:@"%f", message.latitude]);
        RCForwardReplace(templateString, TAG_LONGTITUDE, [NSString stringWithFormat:@"%f", message.longitude]);
    } else if ([model.objectName isEqualToString:RCSightMessageTypeIdentifier]) {
        RCSightMessage *message = (RCSightMessage *)model.content;
        templateString = [[self.templateJsonDic objectForKey:RCSightMessageTypeIdentifier] mutableCopy];
        templateString = [self generalTitleStyle:templateString
                                        userInfo:userInfo
                                        sentTime:model.sentTime
                                 ifSplitPortrait:ifSplitPortrait];
        RCForwardReplace(templateString, TAG_FILEURL, message.sightUrl ? message.sightUrl : @"");
        RCForwardReplace(templateString, TAG_FILENAME,
                         RCLocalizedString(@"RC:SightMsg"));
        long long sightSize = [self p_getSightSize:message];

        RCForwardReplace(templateString, TAG_SIZE, [RCKitUtility getReadableStringForFileSize:sightSize]);
        RCForwardReplace(templateString, TAG_IMGEBASE64, [self UIImageToBase64Str:message.thumbnailImage]);
    } else if ([model.objectName isEqualToString:RCImageMessageTypeIdentifier]) {
        RCImageMessage *message = (RCImageMessage *)model.content;
        templateString = [[self.templateJsonDic objectForKey:RCImageMessageTypeIdentifier] mutableCopy];
        templateString = [self generalTitleStyle:templateString
                                        userInfo:userInfo
                                        sentTime:model.sentTime
                                 ifSplitPortrait:ifSplitPortrait];
        RCForwardReplace(templateString, TAG_FILEURL, message.remoteUrl ? message.remoteUrl : @"");
        RCForwardReplace(templateString, TAG_IMGURL, [self UIImageToBase64Str:message.thumbnailImage]);
    } else if ([model.objectName isEqualToString:RCFileMessageTypeIdentifier]) {
        RCFileMessage *message = (RCFileMessage *)model.content;
        templateString = [[self.templateJsonDic objectForKey:RCFileMessageTypeIdentifier] mutableCopy];
        templateString = [self generalTitleStyle:templateString
                                        userInfo:userInfo
                                        sentTime:model.sentTime
                                 ifSplitPortrait:ifSplitPortrait];
        RCForwardReplace(templateString, TAG_FILEURL, message.fileUrl ? message.fileUrl : @"");
        RCForwardReplace(templateString, TAG_FILETYPE, message.type ? message.type : @"");
        NSString *fileBase64 = [self UIImageToBase64Str:[RCKitUtility imageWithFileSuffix:message.type]];
        RCForwardReplace(templateString, TAG_FILEICON, fileBase64 ? fileBase64 : @"");
        RCForwardReplace(templateString, TAG_FILENAME, message.name ? message.name : @"");
        RCForwardReplace(templateString, TAG_SIZE, [RCKitUtility getReadableStringForFileSize:message.size]);
        RCForwardReplace(templateString, TAG_FILESIZE, [NSString stringWithFormat:@"%lld", message.size]);

    } else if ([model.objectName isEqualToString:RCCombineMessageTypeIdentifier]) {
        RCCombineMessage *message = (RCCombineMessage *)model.content;
        templateString = [[self.templateJsonDic objectForKey:RCCombineMessageTypeIdentifier] mutableCopy];
        templateString = [self generalTitleStyle:templateString
                                        userInfo:userInfo
                                        sentTime:model.sentTime
                                 ifSplitPortrait:ifSplitPortrait];
        RCForwardReplace(templateString, TAG_FILEURL, message.remoteUrl ? message.remoteUrl : @"");
        RCForwardReplace(templateString, TAG_TITLE, [RCCombineMessageUtility getCombineMessageSummaryTitle:message]);
        RCForwardReplace(templateString, TAG_FOOT, RCLocalizedString(@"ChatHistory"));
        NSMutableString *summmryContent = [[NSMutableString alloc] init];
        for (NSString *summary in message.summaryList) {
            NSMutableString *combineBody = [[self.templateJsonDic objectForKey:BASE_COMBINEMSGBODY] mutableCopy];
            RCForwardReplace(combineBody, TAG_TEXT, summary);
            [summmryContent appendString:combineBody];
        }
        RCForwardReplace(templateString, TAG_COMBINEBODY, summmryContent);
    }
    return [templateString mutableCopy];
}

- (NSString *)packageHTMLBody:(RCMessageModel *)model
                     userInfo:(RCUserInfo *)userInfo
              ifSplitPortrait:(BOOL)ifSplitPortrait {
    BOOL ret = !userInfo || !model;
    if (ret) {
        return @"";
    }
    
    NSMutableString *templateString;
    if ([self p_isCommonMessage:model]) {
        templateString = [self p_generateCommonStringWith:model
                                                 userInfo:userInfo
                                          ifSplitPortrait:ifSplitPortrait];
        
    } else {
        templateString = [self p_generalTitleStyle:model
                                          userInfo:userInfo
                                   ifSplitPortrait:ifSplitPortrait];
    }

    return [templateString copy];
}

- (NSMutableString *)generateCommonString:(NSString *)replaceString
                                 userInfo:(RCUserInfo *)userInfo
                                 sentTime:(long long)sentTime
                          ifSplitPortrait:(BOOL)ifSplitPortrait
                                  htmlKey:(NSString *)htmlKey {
    if (!replaceString || !userInfo || !sentTime || !htmlKey) {
        return [@"" mutableCopy];
    }
    
    // <html lang=yyyu> 特殊字符需要转义
    NSString *encodeReplaceString = [self p_encodeTranslation:replaceString];
    NSMutableString *templateString = [[self.templateJsonDic objectForKey:htmlKey] mutableCopy];
    templateString =
        [self generalTitleStyle:templateString userInfo:userInfo sentTime:sentTime ifSplitPortrait:ifSplitPortrait];
    RCForwardReplace(templateString, TAG_TEXT, encodeReplaceString ? encodeReplaceString : @"");
    return templateString;
}

- (NSString *)p_encodeTranslation:(NSString *)sourceString {
    if (sourceString.length == 0) {
        return @"";
    }
    NSString *encode = [sourceString stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
    encode = [encode stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
    encode = [encode stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
    return encode;
}

- (NSMutableString *)generalTitleStyle:(NSMutableString *)templateString
                              userInfo:(RCUserInfo *)userInfo
                              sentTime:(long long)sentTime
                       ifSplitPortrait:(BOOL)ifSplitPortrait {
    if (!templateString || !userInfo || !sentTime) {
        return [@"" mutableCopy];
    }
    if (ifSplitPortrait) {
        NSString *portraitStr = [self getUserportrait:userInfo.portraitUri];
        RCForwardReplace(templateString, TAG_PORTRAIT, portraitStr ? portraitStr : @"");
        RCForwardReplace(templateString, TAG_SHOWUSER, @"");
    } else {
        RCForwardReplace(templateString, TAG_PORTRAIT, @"");
        RCForwardReplace(templateString, TAG_SHOWUSER, @"rong-none-user");
    }
    RCForwardReplace(templateString, TAG_USERNAME, userInfo.name ? userInfo.name : @"");
    RCForwardReplace(templateString, TAG_SENDTIME, [RCKitUtility convertMessageTime:sentTime / 1000]);
    return templateString;
}

- (NSString *)getUserportrait:(NSString *)portraitUri {
    if (!portraitUri || portraitUri.length <= 0) {
        return @"";
    }
    NSString *portrait;
    if ([RCUtilities isRemoteUrl:portraitUri]) {
        portrait = portraitUri;
    } else {
        NSData *imageData = [NSData dataWithContentsOfFile:[RCUtilities getCorrectedFilePath:portraitUri]];
        UIImage *compressedImage =
            [RCUtilities imageByScalingAndCropSize:[UIImage imageWithData:imageData] targetSize:CGSizeMake(100, 100)];
        portrait = [self UIImageToBase64Str:compressedImage];
    }
    return portrait;
}

- (NSString *)UIImageToBase64Str:(UIImage *)image {
    if (!image) {
        return @"";
    }
    NSData *data = UIImageJPEGRepresentation(image, 0.6f);
    if (!data) {
        return @"";
    }
    NSString *encodedImageStr =
        [NSString stringWithFormat:@"data:image/png;base64,%@", [data base64EncodedStringWithOptions:kNilOptions]];
    return encodedImageStr;
}

- (NSString *)formatTime:(RCMessageModel *)beginModel endModel:(RCMessageModel *)endModel {
    NSMutableString *baseTime = [[self.templateJsonDic objectForKey:BASE_TIME] mutableCopy];
    if (!beginModel || !endModel) {
        RCForwardReplace(baseTime, TAG_TIME, @"");
    } else {
        NSString *beginTime = [self formatTime:beginModel.sentTime];
        NSString *endTime = [self formatTime:endModel.sentTime];
        if ([beginTime isEqualToString:endTime]) {
            RCForwardReplace(baseTime, TAG_TIME, beginTime);
        } else {
            RCForwardReplace(baseTime, TAG_TIME, [NSString stringWithFormat:@"%@ ~ %@", beginTime, endTime]);
        }
    }
    return baseTime;
}

- (NSString *)formatTime:(long long)sendTime {
    if (!sendTime) {
        return @"";
    }
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:sendTime / 1000];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    NSTimeZone *timezone = [NSTimeZone localTimeZone];
    [formatter setTimeZone:timezone];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    return [formatter stringFromDate:date];
}

- (void)forwardWithConversationType:(RCConversationType)type
                           targetId:(NSString *)targetId
                            content:(RCMessageContent *)content
                          isCombine:(BOOL)isCombine {
    if (isCombine) {
        [[RCIM sharedRCIM] sendMediaMessage:type
            targetId:targetId
            content:content
            pushContent:nil
            pushData:nil
            progress:^(int progress, long messageId) {
            }
            success:^(long messageId) {

            }
            error:^(RCErrorCode errorCode, long messageId) {

            }
            cancel:^(long messageId){

            }];
    } else {
        [[RCIM sharedRCIM] sendMessage:type
            targetId:targetId
            content:content
            pushContent:nil
            pushData:nil
            success:^(long messageId) {

            }
            error:^(RCErrorCode nErrorCode, long messageId){

            }];
    }
    [NSThread sleepForTimeInterval:0.4];
}

@end
