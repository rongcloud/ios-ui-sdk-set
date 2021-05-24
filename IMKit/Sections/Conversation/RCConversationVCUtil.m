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
            if (interval / 1000 <= 3 * 60) {
                if (model.isDisplayMessageTime && model.cellSize.height > 0) {
                    CGSize size = model.cellSize;
                    size.height = model.cellSize.height - 45;
                    model.cellSize = size;
                }
                model.isDisplayMessageTime = NO;
            } else if (![model.content isKindOfClass:[RCOldMessageNotificationMessage class]]) {
                if (!model.isDisplayMessageTime && model.cellSize.height > 0) {
                    CGSize size = model.cellSize;
                    size.height = model.cellSize.height + 45;
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
    if (self.chatVC.conversationDataRepository.count > 0) {

        RCMessageModel *pre_model =
            [self.chatVC.conversationDataRepository objectAtIndex:self.chatVC.conversationDataRepository.count - 1];

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
    NSString *draft = self.chatVC.chatSessionInputBarControl.draft;
    if (draft && [draft length] > 0) {
        NSString *draftInDB = [[RCIMClient sharedRCIMClient] getTextMessageDraft:self.chatVC.conversationType targetId:self.chatVC.targetId];
        if(![draft isEqualToString:draftInDB]) {
            [[RCIMClient sharedRCIMClient] saveTextMessageDraft:self.chatVC.conversationType targetId:self.chatVC.targetId content:draft];
        }
    } else {
        [[RCIMClient sharedRCIMClient] clearTextMessageDraft:self.chatVC.conversationType targetId:self.chatVC.targetId];
    }
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
    NSUInteger duration = content.destructDuration;
    if (self.chatVC.chatSessionInputBarControl.destructMessageMode) {
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
    long long ServerTime = cTime - [[RCIMClient sharedRCIMClient] getDeltaTime];
    long long interval = ServerTime - model.sentTime > 0 ? ServerTime - model.sentTime : model.sentTime - ServerTime;
    return (interval <= RCKitConfigCenter.message.maxRecallDuration * 1000 && model.messageDirection == MessageDirection_SEND &&
            RCKitConfigCenter.message.enableMessageRecall && model.sentStatus != SentStatus_SENDING &&
            model.sentStatus != SentStatus_FAILED && model.sentStatus != SentStatus_CANCELED &&
            (model.conversationType == ConversationType_PRIVATE || model.conversationType == ConversationType_GROUP ||
             model.conversationType == ConversationType_DISCUSSION) &&
            ![model.content isKindOfClass:NSClassFromString(@"JrmfRedPacketMessage")] &&
            ![model.content isKindOfClass:NSClassFromString(@"RCCallSummaryMessage")]);
}


- (BOOL)canReferenceMessage:(RCMessageModel *)message {
    if (!RCKitConfigCenter.message.enableMessageReference || !self.chatVC.chatSessionInputBarControl || self.chatVC.chatSessionInputBarControl.hidden ||
        self.chatVC.chatSessionInputBarControl.destructMessageMode || self.chatVC.conversationType == ConversationType_CUSTOMERSERVICE) {
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
    if (messageContent.destructDuration > 0) {
        pushContent = RCLocalizedString(@"BurnAfterRead");
    }
    if ([messageContent isKindOfClass:[RCMediaMessageContent class]]) {
        [[RCIM sharedRCIM] sendMediaMessage:self.chatVC.conversationType
                                   targetId:self.chatVC.targetId
                                    content:messageContent
                                pushContent:pushContent
                                   pushData:nil
                                   progress:nil
                                    success:nil
                                      error:nil
                                     cancel:nil];
    } else {
        [[RCIM sharedRCIM] sendMessage:self.chatVC.conversationType
            targetId:self.chatVC.targetId
            content:messageContent
            pushContent:pushContent
            pushData:nil
            success:^(long messageId) {
            }
            error:^(RCErrorCode nErrorCode, long messageId) {
                DebugLog(@"error");
            }];
    }
}

- (void)doSendSelectedMediaMessage:(NSArray *)selectedImages fullImageRequired:(BOOL)full {
    //耗时操作异步执行，以免阻塞主线程
    RCConversationViewController *chatVC = self.chatVC;
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
                            [chatVC sendMessage:imagemsg pushContent:nil];
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
                            [chatVC sendMessage:sightMsg pushContent:nil];
                        });
                    } else {
                        NSData *gifImageData = (NSData *)[assertInfo objectForKey:@"imageData"];
                        RCGIFImage *gifImage = [RCGIFImage animatedImageWithGIFData:gifImageData];
                        if (gifImage) {
                            RCGIFMessage *gifMsg = [RCGIFMessage messageWithGIFImageData:gifImageData
                                                                                   width:gifImage.size.width
                                                                                  height:gifImage.size.height];
                            [chatVC sendMessage:gifMsg pushContent:nil];
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
        stringByAppendingFormat:@"/%@/RCHQVoiceCache", [RCIMClient sharedRCIMClient].currentUserInfo.userId];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path] == NO) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
    }
    NSString *fileName = [NSString stringWithFormat:@"/Voice_%@.m4a", @(currentTime)];
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
        [cell stopPlayingVoice];
    }else if([model.content isMemberOfClass:[RCHQVoiceMessage class]]) {
        RCHQVoiceMessageCell *cell = (RCHQVoiceMessageCell *)[self.chatVC.conversationMessageCollectionView cellForItemAtIndexPath:indexPath];
        [cell stopPlayingVoice];
    }
}

//自动回复机器人收到信令消息也会有自动回复，针对这些会话暂时不发 RC:SRSMsg 信令
//包含融云客服/爱客服小助手/测试公众号客服
- (BOOL)isAutoResponseRobot:(RCConversationType)type targetId:(NSString *)targetId {
    if (type == ConversationType_APPSERVICE) {
        if ([targetId isEqualToString:@"aikefutest"] || [targetId isEqualToString:@"KEFU144595511648939"] ||
            [targetId isEqualToString:@"testkefu"] || [targetId isEqualToString:@"service"]) {
            return YES;
        }
    }
    return NO;
}

- (void)adaptUnreadButtonSize:(UILabel *)sender {
    UIButton * senderButton;
    if (sender.tag == 1001) {
        senderButton = self.chatVC.unReadButton;
    }else {
        senderButton = self.chatVC.unReadMentionedButton;
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
    UIImage *image = RCResourceImage(@"up");
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
    image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(image.size.width * 0.2, image.size.width * 0.8,
                                                                image.size.width * 0.2, image.size.width * 0.2)
                                  resizingMode:UIImageResizingModeStretch];
    [senderButton setBackgroundImage:image forState:UIControlStateNormal];
    CGRect imageViewFrame = CGRectMake(arrowLeft,(temBut.size.height- 9)/2, arrowWidth, 9);
    if ([RCKitUtility isRTL]) {
        imageViewFrame = CGRectMake(temBut.size.width - arrowLeft - arrowWidth, (temBut.size.height- 9)/2, arrowWidth, 9);
    }
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:imageViewFrame];
    CGPoint center = imageView.center;
    center.y = sender.center.y;
    imageView.center = center;
    imageView.image = RCResourceImage(@"arrow");
    [senderButton addSubview:imageView];
}

#pragma mark - 回执请求及响应处理， 同步阅读状态
- (void)syncReadStatus {
    if (!RCKitConfigCenter.message.enableSyncReadStatus)
        return;

    //单聊如果开启了已读回执，同步阅读状态功能可以复用已读回执，不需要发送同步命令。
    if ((self.chatVC.conversationType == ConversationType_PRIVATE &&
         ![RCKitConfigCenter.message.enabledReadReceiptConversationTypeList containsObject:@(self.chatVC.conversationType)]) ||
        self.chatVC.conversationType == ConversationType_GROUP || self.chatVC.conversationType == ConversationType_DISCUSSION || self.chatVC.conversationType == ConversationType_Encrypted || self.chatVC.conversationType == ConversationType_APPSERVICE ||
        self.chatVC.conversationType == ConversationType_PUBLICSERVICE) {
        if ([self isAutoResponseRobot:self.chatVC.conversationType targetId:self.chatVC.targetId]) {
            return;
        }
        for (long i = self.chatVC.conversationDataRepository.count - 1; i >= 0; i--) {
            RCMessageModel *model = self.chatVC.conversationDataRepository[i];
            if (model.messageDirection == MessageDirection_RECEIVE) {
                [[RCIMClient sharedRCIMClient] syncConversationReadStatus:self.chatVC.conversationType
                                                                 targetId:self.chatVC.targetId
                                                                     time:model.sentTime
                                                                  success:nil
                                                                    error:nil];
                break;
            }
        }
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
            [[RCIMClient sharedRCIMClient] sendReadReceiptMessage:self.chatVC.conversationType
                                                         targetId:self.chatVC.targetId
                                                             time:lastReceiveMessageTime
                                                          success:nil
                                                            error:nil];
        }
    }
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
            [[RCIMClient sharedRCIMClient] sendReadReceiptResponse:self.chatVC.conversationType
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
@end
