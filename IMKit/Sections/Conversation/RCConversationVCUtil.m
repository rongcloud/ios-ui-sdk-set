//
//  RCConversationVCUtil.m
//  RongIMKit
//
//  Created by Sin on 2020/6/8.
//  Copyright © 2020 RongCloud. All rights reserved.
//

#import "RCConversationVCUtil.h"
#import "RCKitCommonDefine.h"
#import "RCMessageBaseCell.h"
#import "RCConversationViewController.h"
#import "RCOldMessageNotificationMessage.h"
#import "RCMessageCell.h"
#import "RCIM.h"
#import "RCloudMediaManager.h"
#import "RCKitUtility.h"
#import "RCGIFImage.h"
#import <AVFoundation/AVFoundation.h>
#import "RCVoiceMessageCell.h"
#import "RCHQVoiceMessageCell.h"
#import "RCKitConfig.h"
#import "RCSightMessage+imkit.h"
#import "RCConversationDataSource.h"
#import "NSMutableDictionary+RCOperation.h"
#import "RCRRSUtil.h"

NSInteger const RCMessageCellDisplayTimeHeightForCommon = 45;
NSInteger const RCMessageCellDisplayTimeHeightForHQVoice = 36;

@interface RCConversationViewController ()
@property (nonatomic, strong, readonly) RCConversationDataSource *dataSource;

// 私有方法
- (void)onlySendMessage:(RCMessageContent *)messageContent pushContent:(NSString *)pushContent;
@end

@interface RCConversationVCUtil ()
@property (nonatomic, weak) RCConversationViewController *chatVC;
/*!
 开启已读回执功能的消息类型 objectName list, 默认为 @[@"RC:TxtMsg"],只支持文本消息

 @discussion 这些会话类型的消息在会话页面显示了之后会发送已读回执。目前仅支持单聊、群聊。
 */
@property (nonatomic, copy) NSArray<NSString *> *enabledReadReceiptMessageTypeList;
@property (nonatomic, assign) long long lastReadReceiptTime;//上次的已读回执时间戳
@end

@implementation RCConversationVCUtil
- (instancetype)init:(RCConversationViewController *)chatVC {
    self = [super init];
    if(self) {
        self.chatVC = chatVC;
        self.enabledReadReceiptMessageTypeList = @[ [RCTextMessage getObjectName] ];
        self.lastReadReceiptTime = 0;
    }
    return self;
}
- (void)sendMessageStatusNotification:(NSString *)actionNametatus messageId:(long)messageId progress:(NSInteger)progress {
    RCMessageCellNotificationModel *notifyModel = [[RCMessageCellNotificationModel alloc] init];
    notifyModel.actionName = actionNametatus;
    notifyModel.messageId = messageId;
    notifyModel.progress = progress;
    dispatch_main_async_safe(^{
       [[NSNotificationCenter defaultCenter]
           postNotificationName:KNotificationMessageBaseCellUpdateSendingStatus
                         object:notifyModel];
    });
}

- (void)sendMessageReadReceiptV5Notification:(RCMessageModel *)model {
    RCMessageCellNotificationModel *notifyModel = [[RCMessageCellNotificationModel alloc] init];
    notifyModel.actionName = CONVERSATION_CELL_STATUS_SEND_READ_RECEIPT_INFO_V5;
    notifyModel.messageId = model.messageId;
    notifyModel.readReceiptInfoV5 = model.readReceiptInfoV5;
    dispatch_main_async_safe(^{
        [[NSNotificationCenter defaultCenter] postNotificationName:KNotificationMessageBaseCellUpdateSendingStatus object:notifyModel];
    });
}
- (RCInformationNotificationMessage *)getInfoNotificationMessageByErrorCode:(RCErrorCode)nErrorCode {
    RCInformationNotificationMessage *informationNotifiMsg = nil;
    if (NOT_IN_DISCUSSION == nErrorCode) {
        informationNotifiMsg = [RCInformationNotificationMessage
            notificationWithMessage:RCLocalizedString(@"NOT_IN_DISCUSSION")
                              extra:nil];
    } else if (NOT_IN_GROUP == nErrorCode) {
        informationNotifiMsg = [RCInformationNotificationMessage
            notificationWithMessage:RCLocalizedString(@"NOT_IN_GROUP")
                              extra:nil];
    } else if (NOT_IN_CHATROOM == nErrorCode) {
        informationNotifiMsg = [RCInformationNotificationMessage
            notificationWithMessage:RCLocalizedString(@"NOT_IN_CHATROOM")
                              extra:nil];
    } else if (REJECTED_BY_BLACKLIST == nErrorCode) {
        informationNotifiMsg = [RCInformationNotificationMessage
            notificationWithMessage:RCLocalizedString(@"Message rejected")
                              extra:nil];
    } else if (FORBIDDEN_IN_GROUP == nErrorCode) {
        informationNotifiMsg = [RCInformationNotificationMessage
            notificationWithMessage:RCLocalizedString(@"FORBIDDEN_IN_GROUP")
                              extra:nil];
    } else if (FORBIDDEN_IN_CHATROOM == nErrorCode) {
        informationNotifiMsg = [RCInformationNotificationMessage
            notificationWithMessage:RCLocalizedString(@"ForbiddenInChatRoom")
                              extra:nil];
    } else if (KICKED_FROM_CHATROOM == nErrorCode) {
        informationNotifiMsg = [RCInformationNotificationMessage
            notificationWithMessage:RCLocalizedString(@"KickedFromChatRoom")
                              extra:nil];
    }
    return informationNotifiMsg;
}

+ (CGFloat)incrementOfTimeLabelBy:(RCMessageModel *)model {
    if ([model.content isKindOfClass:[RCHQVoiceMessage class]]) {
        return RCMessageCellDisplayTimeHeightForHQVoice;
    } else {
        return RCMessageCellDisplayTimeHeightForCommon;
    }
}

- (void)figureOutAllConversationDataRepository {
    for (int i = 0; i < self.chatVC.conversationDataRepository.count; i++) {
        RCMessageModel *model = [self.chatVC.conversationDataRepository objectAtIndex:i];
        if (0 == i) {
            model.isDisplayMessageTime = YES;
        } else if (i > 0) {
            RCMessageModel *pre_model = [self.chatVC.conversationDataRepository objectAtIndex:i - 1];

            long long previous_time = pre_model.sentTime;

            long long current_time = model.sentTime;

            long long interval =
                current_time - previous_time > 0 ? current_time - previous_time : previous_time - current_time;
            CGFloat increment = [[self class] incrementOfTimeLabelBy:model];
            if (interval / 1000 <= 3 * 60) {
                if (model.isDisplayMessageTime && model.cellSize.height > 0) {
                    CGSize size = model.cellSize;
                    size.height = model.cellSize.height - increment;
                    model.cellSize = size;
                }
                model.isDisplayMessageTime = NO;
            } else if (![model.content isKindOfClass:[RCOldMessageNotificationMessage class]]) {
                if (!model.isDisplayMessageTime && model.cellSize.height > 0) {
                    CGSize size = model.cellSize;
                    size.height = model.cellSize.height + increment;
                    model.cellSize = size;
                }
                model.isDisplayMessageTime = YES;
            }
        }
        if ([model.content isKindOfClass:[RCOldMessageNotificationMessage class]]) {
            model.isDisplayMessageTime = NO;
        }
    }
}

- (void)figureOutLatestModel:(RCMessageModel *)model {
    if ([model.content isKindOfClass:RCOldMessageNotificationMessage.class]) {
        model.isDisplayMessageTime = NO;
        return;
    }
    NSMutableArray *messageArr = [NSMutableArray new];
    if(self.chatVC.conversationDataRepository.count > 0) {
        [messageArr addObjectsFromArray:self.chatVC.conversationDataRepository];
    }
    if (self.chatVC.dataSource.cachedReloadMessages.count > 0) {
        [messageArr addObjectsFromArray:self.chatVC.dataSource.cachedReloadMessages];
    }
    if (messageArr.count > 0) {

        RCMessageModel *pre_model = messageArr.lastObject;
        if ([pre_model.content isKindOfClass:RCOldMessageNotificationMessage.class]) {
            model.isDisplayMessageTime = YES;
            return;
        }
        long long previous_time = pre_model.sentTime;

        long long current_time = model.sentTime;

        long long interval =
            current_time - previous_time > 0 ? current_time - previous_time : previous_time - current_time;
        if (interval / 1000 <= 3 * 60) {
            model.isDisplayMessageTime = NO;
        } else {
            model.isDisplayMessageTime = YES;
        }
    } else {
        model.isDisplayMessageTime = YES;
    }
}

- (void)saveDraftIfNeed {
    RCConversationType type = self.chatVC.conversationType;
    NSString *targetId = self.chatVC.targetId?:@"";
    NSString *channelId = self.chatVC.channelId?:@"";
    NSString *draft = self.chatVC.chatSessionInputBarControl.draft?:@"";
    NSDictionary *userInfo = @{
        @"conversationType": @(type),
        @"targetId": targetId,
        @"channelId": channelId,
        @"draft": draft,
    };
    [[RCChannelClient sharedChannelManager] getTextMessageDraft:type targetId:targetId channelId:channelId completion:^(NSString * _Nullable draftInDB) {
        if (draft && [draft length] > 0) {
            if(![draft isEqualToString:draftInDB]) {
                [[RCChannelClient sharedChannelManager] saveTextMessageDraft:type targetId:targetId channelId:channelId content:draft completion:^(BOOL result) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:RCKitDispatchConversationDraftUpdateNotification
                                                                        object:nil userInfo:userInfo];
                }];
            }
        } else if (draftInDB.length > 0){
            [[RCChannelClient sharedChannelManager] clearTextMessageDraft:self.chatVC.conversationType targetId:self.chatVC.targetId channelId:self.chatVC.channelId completion:^(BOOL result) {
                [[NSNotificationCenter defaultCenter] postNotificationName:RCKitDispatchConversationDraftUpdateNotification
                                                                    object:nil userInfo:userInfo];
            }];
        }
    }];
}


- (CGFloat)referenceExtraHeight:(Class)cellClass messageModel:(RCMessageModel *)model {
    CGFloat extraHeight = BASE_CONTENT_VIEW_BOTTOM;
    if ([cellClass isSubclassOfClass:RCMessageBaseCell.class]) {
        if (model.isDisplayMessageTime) {
            extraHeight += TIME_LABEL_TOP + TIME_LABEL_HEIGHT + TIME_LABEL_AND_BASE_CONTENT_VIEW_SPACE;
        }
    }
    if ([cellClass isSubclassOfClass:RCMessageCell.class]) {
        // name label height
        if (model.isDisplayNickname && model.messageDirection == MessageDirection_RECEIVE) {
            extraHeight += NameHeight + NameAndContentSpace;
        }
    }
    return extraHeight;
}

- (NSIndexPath *)findDataIndexFromMessageList:(RCMessageModel *)model {
    NSIndexPath *indexPath;
    for (int i = 0; i < self.chatVC.conversationDataRepository.count; i++) {
        RCMessageModel *msg = (self.chatVC.conversationDataRepository)[i];
        if (msg.messageId == model.messageId && ![msg.content isKindOfClass:[RCOldMessageNotificationMessage class]]) {
            indexPath = [NSIndexPath indexPathForItem:i inSection:0];
            break;
        }
    }
    return indexPath;
}

- (RCMessageModel *)modelByMessageID:(NSInteger)messageID {
    for (int i = 0; i < self.chatVC.conversationDataRepository.count; i++) {
        RCMessageModel *msg = (self.chatVC.conversationDataRepository)[i];
        if (msg.messageId == messageID && ![msg.content isKindOfClass:[RCOldMessageNotificationMessage class]]) {
            return msg;
        }
    }
    return nil;
}

- (RCMessageModel *)modelByMessageUId:(NSString *)messageUId {
    for (int i = 0; i < self.chatVC.conversationDataRepository.count; i++) {
        RCMessageModel *msg = (self.chatVC.conversationDataRepository)[i];
        if ([msg.messageUId isEqualToString:messageUId] && ![msg.content isKindOfClass:[RCOldMessageNotificationMessage class]]) {
            return msg;
        }
    }
    return nil;
}

- (BOOL)alertDestructMessageRemind {
    if (![[NSUserDefaults standardUserDefaults] valueForKey:@"FirstTimeBeginBurnMode"]) {
        [[NSUserDefaults standardUserDefaults] setValue:@"YES" forKey:@"FirstTimeBeginBurnMode"];
        [RCAlertView showAlertController:RCLocalizedString(@"BurnAfterReadTitle") message:RCLocalizedString(@"BurnAfterReadMsg") cancelTitle:RCLocalizedString(@"Know") inViewController:self.chatVC];
        return YES;
    }
    return NO;
}

//获取具体消息的阅后即焚倒计时时长
- (NSUInteger)getMessageDestructDuration:(RCMessageContent *)content {
    return [self getMessageDestructDuration:content destructMessageMode:self.chatVC.chatSessionInputBarControl.destructMessageMode];
}

- (NSUInteger)getMessageDestructDuration:(RCMessageContent *)content destructMessageMode:(BOOL)destructMessageMode {
    NSUInteger duration = content.destructDuration;
    if (destructMessageMode) {
        if ([content isKindOfClass:[RCTextMessage class]]) {
            RCTextMessage *msg = (RCTextMessage *)content;
            if (msg.content.length <= 20) {
                duration = 10;
            } else {
                duration = 10 + (int)(msg.content.length - 20) / 2;
            }
        } else if ([content isKindOfClass:[RCVoiceMessage class]] || [content isKindOfClass:[RCHQVoiceMessage class]] ||
                   [content isKindOfClass:[RCSightMessage class]]) {
            duration = 10;
        } else if ([content isKindOfClass:[RCImageMessage class]] || [content isKindOfClass:[RCGIFMessage class]]) {
            duration = 30;
        }
    }
    return duration;
}

- (BOOL)canRecallMessageOfModel:(RCMessageModel *)model {
    long long cTime = [[NSDate date] timeIntervalSince1970] * 1000;
    long long ServerTime = cTime - [[RCCoreClient sharedCoreClient] getDeltaTime];
    long long interval = ServerTime - model.sentTime > 0 ? ServerTime - model.sentTime : model.sentTime - ServerTime;
    return (interval <= RCKitConfigCenter.message.maxRecallDuration * 1000 && model.messageDirection == MessageDirection_SEND &&
            RCKitConfigCenter.message.enableMessageRecall && model.sentStatus != SentStatus_SENDING &&
            model.sentStatus != SentStatus_FAILED && model.sentStatus != SentStatus_CANCELED &&
            (model.conversationType == ConversationType_PRIVATE || model.conversationType == ConversationType_GROUP ||
             model.conversationType == ConversationType_DISCUSSION || model.conversationType == ConversationType_ULTRAGROUP) &&
            ![model.content isKindOfClass:NSClassFromString(@"JrmfRedPacketMessage")] &&
            ![model.content isKindOfClass:NSClassFromString(@"RCCallSummaryMessage")]
            &&
            ![model.content isKindOfClass:NSClassFromString(@"RCRealTimeLocationStartMessage")]);
}


- (BOOL)canReferenceMessage:(RCMessageModel *)message {
    BOOL inputHidden = self.chatVC.chatSessionInputBarControl.hidden;
    if (self.chatVC.editInputBarControl.isVisible) {
        inputHidden = self.chatVC.editInputBarControl.hidden;
    }
    
    if (!RCKitConfigCenter.message.enableMessageReference || !self.chatVC.chatSessionInputBarControl || inputHidden ||
        self.chatVC.chatSessionInputBarControl.destructMessageMode) {
        return NO;
    }
    
    // 客服、系统会话不支持引用
    if (self.chatVC.conversationType == ConversationType_CUSTOMERSERVICE || self.chatVC.conversationType == ConversationType_SYSTEM) {
        return NO;
    }

    //发送失败的消息不允许引用
    if ((message.sentStatus != SentStatus_SENDING && message.sentStatus != SentStatus_FAILED &&
         message.sentStatus != SentStatus_CANCELED) &&
        ([message.content isKindOfClass:RCTextMessage.class] || [message.content isKindOfClass:RCFileMessage.class] ||
         [message.content isKindOfClass:RCRichContentMessage.class] ||
         [message.content isKindOfClass:RCImageMessage.class] ||
         [message.content isKindOfClass:RCReferenceMessage.class])) {
        return YES;
    }
    return NO;
}
- (void)doSendMessage:(RCMessageContent *)messageContent pushContent:(NSString *)pushContent {
    messageContent.destructDuration = [self getMessageDestructDuration:messageContent];
    [self doOnlySendMessage:messageContent pushContent:pushContent];
}

// 专属发送, 内部无焚毁逻辑
- (void)doOnlySendMessage:(RCMessageContent *)messageContent pushContent:(NSString *)pushContent {
    if (messageContent.destructDuration > 0) {
        pushContent = RCLocalizedString(@"BurnAfterRead");
    }
    RCMessage *message = [[RCMessage alloc] initWithType:self.chatVC.conversationType targetId:self.chatVC.targetId channelId:self.chatVC.channelId direction:MessageDirection_SEND content:messageContent];
    
    if ([messageContent isKindOfClass:[RCMediaMessageContent class]]) {
        [[RCIM sharedRCIM] sendMediaMessage:message
                                pushContent:pushContent
                                   pushData:nil
                                   progress:nil
                               successBlock:nil
                                 errorBlock:nil
                                     cancel:nil];
    } else {
        [[RCIM sharedRCIM] sendMessage:message
                           pushContent:pushContent
                              pushData:nil
                          successBlock:^(RCMessage *successMessage) {
            
        } errorBlock:^(RCErrorCode nErrorCode, RCMessage *errorMessage) {
            DebugLog(@"error: %@", @(nErrorCode));
        }];
    }
}

- (void)doSendSelectedMediaMessage:(NSArray *)selectedImages fullImageRequired:(BOOL)full {
    //耗时操作异步执行，以免阻塞主线程
    RCConversationViewController *chatVC = self.chatVC;
    BOOL destructMessageMode = self.chatVC.chatSessionInputBarControl.destructMessageMode;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (int i = 0; i < selectedImages.count; i++) {
            @autoreleasepool {
                id item = [selectedImages objectAtIndex:i];
                if ([item isKindOfClass:NSData.class]) {
                    NSData *imageData = (NSData *)item;
                    UIImage *image = [UIImage imageWithData:imageData];
                    image = [RCKitUtility fixOrientation:image];
                    // 保留原有逻辑并添加大图缩小的功能
                    [[RCloudMediaManager sharedManager] downsizeImage:image
                        completionBlock:^(UIImage *outimage, BOOL doNothing) {
                            RCImageMessage *imagemsg;
                            if (doNothing || !outimage) {
                                imagemsg = [RCImageMessage messageWithImage:image];
                                imagemsg.full = full;
                            } else if (outimage) {
                                NSData *newImageData = UIImageJPEGRepresentation(outimage, 1);
                                imagemsg = [RCImageMessage messageWithImageData:newImageData];
                                imagemsg.full = full;
                            }
                            imagemsg.destructDuration = [self getMessageDestructDuration:imagemsg destructMessageMode:destructMessageMode];
                            [chatVC onlySendMessage:imagemsg pushContent:nil];
                        }
                        progressBlock:^(UIImage *outimage, BOOL doNothing){

                        }];
                } else if ([item isKindOfClass:NSDictionary.class]) {
                    NSDictionary *assertInfo = item;
                    if ([assertInfo objectForKey:@"avAsset"]) {
                        AVAsset *model = assertInfo[@"avAsset"];
                        UIImage *image = assertInfo[@"thumbnail"];
                        NSString *localPath = assertInfo[@"localPath"];
                        dispatch_sync(dispatch_get_main_queue(), ^{
                            NSUInteger duration = round(CMTimeGetSeconds(model.duration));
                            RCSightMessage *sightMsg =
                                [RCSightMessage messageWithAsset:model thumbnail:image duration:duration];
                            sightMsg.localPath = localPath;
                            sightMsg.destructDuration = [self getMessageDestructDuration:sightMsg destructMessageMode:destructMessageMode];
                            [chatVC onlySendMessage:sightMsg pushContent:nil];
                        });
                    } else {
                        NSData *gifImageData = (NSData *)[assertInfo objectForKey:@"imageData"];
                        RCGIFImage *gifImage = [RCGIFImage animatedImageWithGIFData:gifImageData];
                        if (gifImage) {
                            RCGIFMessage *gifMsg = [RCGIFMessage messageWithGIFImageData:gifImageData
                                                                                   width:gifImage.size.width
                                                                                  height:gifImage.size.height];
                            gifMsg.destructDuration = [self getMessageDestructDuration:gifMsg destructMessageMode:destructMessageMode];
                            [chatVC onlySendMessage:gifMsg pushContent:nil];
                        }
                    }
                }
                [NSThread sleepForTimeInterval:0.5];
            }
        }
    });
}

- (NSString *)getHQVoiceMessageCachePath {
    long long currentTime = [[NSDate date] timeIntervalSince1970] * 1000;
    NSString *path = [RCUtilities rongImageCacheDirectory];
    path = [path
        stringByAppendingFormat:@"/%@/RCHQVoiceCache", [RCCoreClient sharedCoreClient].currentUserInfo.userId];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path] == NO) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
    }
    NSString *fileName = [NSString stringWithFormat:@"/Voice_%@.aac", @(currentTime)];
    path = [path stringByAppendingPathComponent:fileName];
    return path;
}
- (void)stopVoiceMessageIfNeed:(RCMessageModel *)model {
    NSIndexPath *indexPath = [self findDataIndexFromMessageList:model];
    if (!indexPath) {
        return;
    }
    //如果是语音消息则停止播放
    if ([model.content isMemberOfClass:[RCVoiceMessage class]]) {
        RCVoiceMessageCell *cell =
            (RCVoiceMessageCell *)[self.chatVC.conversationMessageCollectionView cellForItemAtIndexPath:indexPath];
        if ([cell respondsToSelector:@selector(stopPlayingVoice)]) {
            [cell stopPlayingVoice];
        }
    }else if([model.content isMemberOfClass:[RCHQVoiceMessage class]]) {
        RCHQVoiceMessageCell *cell = (RCHQVoiceMessageCell *)[self.chatVC.conversationMessageCollectionView cellForItemAtIndexPath:indexPath];
        if ([cell respondsToSelector:@selector(stopPlayingVoice)]) {
            [cell stopPlayingVoice];
        }
    }
}

//自动回复机器人收到信令消息也会有自动回复，针对这些会话暂时不发 RC:SRSMsg 信令
//包含融云客服/爱客服小助手/测试公众号客服
- (BOOL)isAutoResponseRobot{
    NSString *targetId = self.chatVC.targetId;
    if (self.chatVC.conversationType == ConversationType_APPSERVICE) {
        if ([targetId isEqualToString:@"aikefutest"] || [targetId isEqualToString:@"KEFU144595511648939"] ||
            [targetId isEqualToString:@"testkefu"] || [targetId isEqualToString:@"service"]) {
            return YES;
        }
    }
    return NO;
}

- (void)adaptUnreadButtonSize:(UILabel *)sender {
    UIButton * senderButton;
    NSString *imageNameKey = nil;
    if (sender.tag == 1001) {
        imageNameKey = @"conversation_unread_button_arrow_img";
        senderButton = self.chatVC.unReadButton;
    }else {
        senderButton = self.chatVC.unReadMentionedButton;
        imageNameKey = @"conversation_mention_button_arrow_img";
    }
    CGRect temBut = senderButton.frame;

    CGRect rect = [sender.text boundingRectWithSize:CGSizeMake(2000, senderButton.frame.size.height)
                                            options:(NSStringDrawingUsesLineFragmentOrigin)
                                         attributes:@{
                                             NSFontAttributeName : [[RCKitConfig defaultConfig].font fontOfFourthLevel]
                                         }
                                            context:nil];
    CGFloat arrowLeft = 19;
    CGFloat arrowWidth = 10;
    CGFloat arrowAndTextSpace = 5;
    CGFloat textRight = 4;
    temBut.size.width = arrowLeft + arrowWidth + arrowAndTextSpace + rect.size.width + textRight;
    temBut.origin.x = self.chatVC.view.frame.size.width - temBut.size.width;
    senderButton.frame = temBut;
    sender.frame = CGRectMake(temBut.size.width - textRight - rect.size.width, 0, rect.size.width, temBut.size.height);
    UIImage *image = [senderButton currentBackgroundImage]; 
    if ([RCKitUtility isRTL]) {
        temBut.origin.x = 0;
        senderButton.frame = temBut;
        sender.frame = CGRectMake(4, 0, rect.size.width, temBut.size.height);
        image = [image imageFlippedForRightToLeftLayoutDirection];
    } else {
        temBut.origin.x = self.chatVC.view.frame.size.width - temBut.size.width;
        senderButton.frame = temBut;
        sender.frame = CGRectMake(temBut.size.width - 4 - rect.size.width, 0, rect.size.width, temBut.size.height);
    }
    if ([RCKitUtility isTraditionInnerThemes]) {
        image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(image.size.width * 0.2, image.size.width * 0.8,
                                                                    image.size.width * 0.2, image.size.width * 0.2)
                                      resizingMode:UIImageResizingModeStretch];
    } else {
        // 处理动态图片的resizable操作
        if (image.imageAsset) {
            // 对于动态图片，需要先获取当前trait对应的图片再应用resizable
            UIImage *currentTraitImage = [image.imageAsset imageWithTraitCollection:self.chatVC.traitCollection];
            image = [self applyResizableCapInsets:currentTraitImage];
        } else {
            // 对于静态图片，直接应用resizable
            image = [self applyResizableCapInsets:image];
        }
    }
    
    [senderButton setBackgroundImage:image forState:UIControlStateNormal];
    CGRect imageViewFrame = CGRectMake(arrowLeft,(temBut.size.height- 9)/2, arrowWidth, 9);
    if ([RCKitUtility isRTL]) {
        imageViewFrame = CGRectMake(temBut.size.width - arrowLeft - arrowWidth, (temBut.size.height- 9)/2, arrowWidth, 9);
    }

    UIView *view = [senderButton viewWithTag:1010];
    if (view) {
        view.frame = imageViewFrame;
        CGPoint center = view.center;
        center.y = sender.center.y;
        view.center = center;
    }else{
        RCBaseImageView *imageView = [[RCBaseImageView alloc] initWithFrame:imageViewFrame];
        CGPoint center = imageView.center;
        center.y = sender.center.y;
        imageView.center = center;
        imageView.image = RCDynamicImage(imageNameKey, @"arrow");
        imageView.tag = 1010;
        [senderButton addSubview:imageView];
    }
}

- (UIImage *)applyResizableCapInsets:(UIImage *)image {
    if (!image) return nil;
    CGFloat halfWidth = image.size.width * 0.5;
    CGFloat halfHeight = image.size.height * 0.5;
    UIEdgeInsets capInsets = UIEdgeInsetsMake(halfHeight, halfWidth, halfHeight, halfWidth);
    
    return [image resizableImageWithCapInsets:capInsets];
}

#pragma mark - 回执请求及响应处理， 同步阅读状态
- (void)syncReadStatus {
    [self syncReadStatus:0 needDelay:NO];
}

- (void)syncReadStatus:(long long)sentTime needDelay:(BOOL)needDelay{
    if (!RCKitConfigCenter.message.enableSyncReadStatus)
        return;
    if ([self isAutoResponseRobot]) {
        return;
    }
    
    void (^syncBlock)(void) = ^{
        if (0 == sentTime){
            for (long i = self.chatVC.conversationDataRepository.count - 1; i >= 0; i--) {
                RCMessageModel *model = self.chatVC.conversationDataRepository[i];
                if (model.messageDirection == MessageDirection_RECEIVE) {
                    [self startSyncConversationReadStatus:model.sentTime needDelay:needDelay];
                    break;
                }
            }
        }else{
            [self startSyncConversationReadStatus:sentTime needDelay:needDelay];
        }
    };
        
    // 如果开启已读 v5，单聊不能复用已读回执同步多端阅读状态
    if ([RCRRSUtil isSupportReadReceiptV5]
        && self.chatVC.conversationType == ConversationType_PRIVATE
        && [RCKitConfigCenter.message.enabledReadReceiptConversationTypeList containsObject:@(self.chatVC.conversationType)]) {
        syncBlock();
    }
    
    //单聊如果开启了已读回执，同步阅读状态功能可以复用已读回执，不需要发送同步命令。
    if ((self.chatVC.conversationType == ConversationType_PRIVATE &&
         ![RCKitConfigCenter.message.enabledReadReceiptConversationTypeList containsObject:@(self.chatVC.conversationType)]) ||
        self.chatVC.conversationType == ConversationType_GROUP || self.chatVC.conversationType == ConversationType_DISCUSSION || self.chatVC.conversationType == ConversationType_Encrypted || self.chatVC.conversationType == ConversationType_APPSERVICE ||
        self.chatVC.conversationType == ConversationType_PUBLICSERVICE ||
        self.chatVC.conversationType == ConversationType_SYSTEM) {
        
        syncBlock();
    }
}

- (void)startSyncConversationReadStatus:(long long)sentTime needDelay:(BOOL)needDelay{
    if (needDelay) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[RCCoreClient sharedCoreClient] syncConversationReadStatus:self.chatVC.conversationType
                                                             targetId:self.chatVC.targetId
                                                                 time:sentTime
                                                              success:nil
                                                                error:nil];
        });
    }else{
        [[RCCoreClient sharedCoreClient] syncConversationReadStatus:self.chatVC.conversationType
                                                         targetId:self.chatVC.targetId
                                                             time:sentTime
                                                          success:nil
                                                            error:nil];
    }
}

- (void)sendReadReceipt {
    if ([self canSendReadReceipt]) {
        long long lastReceiveMessageTime = -1;
        for (long i = self.chatVC.conversationDataRepository.count - 1; i >= 0; i--) {
            RCMessageModel *model = self.chatVC.conversationDataRepository[i];
            if (model.messageDirection == MessageDirection_RECEIVE) {
                lastReceiveMessageTime = model.sentTime;
                break;
            }
        }
        //如果最后一条消息的时间和上次已读回执时间不一样，再进行新的已读回执请求
        //避免没有新接收的消息，但是仍旧不停的用同一个时间戳来做已读回执
        if(self.lastReadReceiptTime != lastReceiveMessageTime) {
            self.lastReadReceiptTime = lastReceiveMessageTime;
            // -1 无需发送已读回执
            if (self.lastReadReceiptTime == -1) {
                return;
            }
            [self sendReadReceiptWithTime:self.lastReadReceiptTime];
        }
    }
}

- (void)sendReadReceiptWithTime:(long long)time {
    if ([RCRRSUtil isSupportReadReceiptV5]) {
        return;
    }
    [[RCCoreClient sharedCoreClient] sendReadReceiptMessage:self.chatVC.conversationType
                                                 targetId:self.chatVC.targetId
                                                     time:time
                                                  success:nil
                                                    error:nil];
}

- (BOOL)canSendReadReceipt {
    if((self.chatVC.conversationType == ConversationType_PRIVATE || self.chatVC.conversationType == ConversationType_Encrypted) &&
       [RCKitConfigCenter.message.enabledReadReceiptConversationTypeList containsObject:@(self.chatVC.conversationType)]) {
        return YES;
    }
    return NO;
}

/**
 *  需要发送回执响应
 *
 *  @param array 需要回执响应的消息的列表
 */
- (void)sendReadReceiptResponseForMessages:(NSArray *)array {
    if ([RCKitConfigCenter.message.enabledReadReceiptConversationTypeList containsObject:@(self.chatVC.conversationType)]) {
        NSMutableArray *readReceiptarray = [NSMutableArray array];
        for (int i = 0; i < array.count; i++) {
            RCMessage *rcMsg = [array objectAtIndex:i];
            if (rcMsg.readReceiptInfo && rcMsg.readReceiptInfo.isReceiptRequestMessage &&
                !rcMsg.readReceiptInfo.hasRespond && rcMsg.messageDirection == MessageDirection_RECEIVE) {
                [readReceiptarray addObject:rcMsg];
            }
        }

        if (readReceiptarray && readReceiptarray.count > 0) {
            [[RCCoreClient sharedCoreClient] sendReadReceiptResponse:self.chatVC.conversationType
                                                          targetId:self.chatVC.targetId
                                                       messageList:readReceiptarray
                                                           success:nil
                                                             error:nil];
        }
    }
}

- (BOOL)enabledReadReceiptMessage:(RCMessageModel *)model {
    if ([self.enabledReadReceiptMessageTypeList containsObject:model.objectName]) {
        return YES;
    }
    return NO;
}

- (RCMessageModel *)messageModelByUId:(NSString *)messageUId {
    for (int i = 0; i < self.chatVC.conversationDataRepository.count; i++) {
        RCMessageModel *msg = (self.chatVC.conversationDataRepository)[i];
        if (msg.messageUId == messageUId && ![msg.content isKindOfClass:[RCOldMessageNotificationMessage class]]) {
            return msg;
        }
    }
    return nil;
}

#pragma mark - 编辑状态管理

- (RCEditInputBarConfig *)getCacheEditConfig {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *stateData = [userDefaults objectForKey:[self editingStateDataKey]];
    if (stateData && stateData.count > 0) {
        NSData *data = [NSJSONSerialization dataWithJSONObject:stateData options:kNilOptions error:nil];
        NSString *jsonStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        RCEditInputBarConfig *editConfig = [[RCEditInputBarConfig alloc] initWithData:jsonStr];
        return editConfig;
    }
    return nil;
}

- (void)clearEditingState {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObjectForKey:[self editingStateDataKey]];
    [userDefaults synchronize];
}

- (NSString *)editingStateDataKey {
    return [NSString stringWithFormat:@"rc_editing_state_%@_%@_%@",
            @(self.chatVC.conversationType), self.chatVC.targetId, self.chatVC.channelId];
}

@end
