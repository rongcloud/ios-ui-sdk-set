//
//  RCStreamMessageCellViewModel.m
//  SealTalk
//
//  Created by zgh on 2025/2/20.
//  Copyright © 2025 RongCloud. All rights reserved.
//
#import <CoreFoundation/CoreFoundation.h>
#import <CoreText/CoreText.h>

#import "RCStreamMessageCellViewModel.h"
#import "RCKitConfig.h"
#import "RCMessageCellTool.h"
#import "RCMMMarkdown.h"
#import "RCKitCommonDefine.h"
#import "RCStreamMessageCellViewModel+internal.h"
#import "RCStreamTextContentViewModel.h"
#import "RCStreamMarkdownContentViewModel.h"
#import "NSDictionary+RCAccessor.h"
#import "RCStreamHTMLContentViewModel.h"

#import "RCStreamUtilities.h"

NSUInteger const RCStreamMessageCellDisplayTextLimit = 10000;
NSUInteger const RCStreamMessageCellLoadingLimit = 20;
CGFloat const rcUnfoldButtonHeight = 42;
CGFloat const rcContentTop = 10;
CGFloat const rcContentBottom = 10;
CGFloat const rcContentSpace = 10;
CGFloat const rcTextLeadingX = 12;

@interface RCStreamMessageCellViewModel ()<RCStreamMessageRequestEventDelegate, RCStreamContentViewModelDelegate>

@end

@implementation RCStreamMessageCellViewModel

+ (instancetype)viewModelWithModel:(RCMessageModel *)model {
    RCStreamMessageCellViewModel *cellVM = [RCStreamMessageCellViewModel new];
    [cellVM configMessage:model];
    return cellVM;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.calculateHeightQueue = dispatch_queue_create("com.rongcloud.calculateHeightQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (CGSize)getMessageContentViewSize {
    if (CGSizeEqualToSize(self.contentViewSize, CGSizeZero)) {
        [self syncRefreshViewSizes];
    }
    return self.contentViewSize;
}

- (void)initRequestStreamMessage {
    RCStreamMessage *streamMessage = (RCStreamMessage *)self.model.content;
    if (streamMessage.isSync) {
        return;
    }
    if (self.summaryComplete ||
        (self.summary && !self.summaryComplete)) {
        return;
    }
    [self requestStreamMessage];
}

- (void)requestStreamMessage {
    [[RCCoreClient sharedCoreClient] removeStreamMessageRequestEventDelegate:self];
    [[RCCoreClient sharedCoreClient] addStreamMessageRequestEventDelegate:self];
    DebugLog(@"[Stream] mUid:%@; addStreamMessageRequestEventDelegate", self.model.messageUId);
    RCStreamMessageRequestParams *params = [RCStreamMessageRequestParams new];
    params.messageUId = self.model.messageUId;
    [[RCCoreClient sharedCoreClient] requestStreamMessageWithParams:params completionHandler:^(RCErrorCode code) {
        DebugLog(@"[Stream] mUid:%@; lib requestStreamMessageWithParams, code:%@", self.model.messageUId, @(code));
        if (code != RC_SUCCESS) {
            [self requestStreamMessageResult:code];
        }
    }];
}

- (void)asyncRefreshViewSizes {
    __block CGSize referViewSize = CGSizeZero;
    __block CGSize textViewSize = CGSizeZero;
    __block CGFloat height = rcContentTop + rcContentBottom;
    dispatch_async(self.calculateHeightQueue, ^{
        // 计算高度
        if (self.showReferMessage) {
            referViewSize = [self getReferViewSize];
            height += referViewSize.height + rcContentSpace;
        }
        
        textViewSize = [self getTextViewSize];
        height += textViewSize.height;
        
        if (self.status == RCStreamMessageStatusBottomFailed ||
            self.status == RCStreamMessageStatusBottomUnfold ||
            self.status == RCStreamMessageStatusBottomLoading) {
            height += rcUnfoldButtonHeight;
        }
        // 将结果传递回主线程
        dispatch_async(dispatch_get_main_queue(), ^{
            self.textViewSize = textViewSize;
            self.referViewSize = referViewSize;
            self.contentViewSize = CGSizeMake([RCMessageCellTool getMessageContentViewMaxWidth], height);
            self.model.cellSize = CGSizeZero;
            if ([self.delegate respondsToSelector:@selector(contentLayoutDidUpdate)]) {
                [self.delegate contentLayoutDidUpdate];
            }
        });
    });
}

- (void)syncRefreshViewSizes {
    CGFloat height = rcContentTop + rcContentBottom;
    // 计算高度
    if (self.showReferMessage) {
        self.referViewSize = [self getReferViewSize];
        height += self.referViewSize.height + rcContentSpace;
    }
    
    self.textViewSize = [self getTextViewSize];
    height += self.textViewSize.height;
    
    if (self.status == RCStreamMessageStatusBottomFailed ||
        self.status == RCStreamMessageStatusBottomUnfold ||
        self.status == RCStreamMessageStatusBottomLoading) {
        height += rcUnfoldButtonHeight;
    }
    self.contentViewSize = CGSizeMake([RCMessageCellTool getMessageContentViewMaxWidth], height);
    if ([self.delegate respondsToSelector:@selector(contentLayoutDidUpdate)]) {
        [self.delegate contentLayoutDidUpdate];
    }
}

- (CGSize)getTextViewSize {
    if (self.status == RCStreamMessageStatusContentLoading) {
        return CGSizeMake([self.contentViewModel contentMaxWidth], 21);
    }
    if (self.status == RCStreamMessageStatusContentFailedWhenLoading) {
        NSDictionary *attributes = @{NSFontAttributeName : [[RCKitConfig defaultConfig].font fontOfSecondLevel]};
        CGSize size = [[self.contentViewModel.class failedInfo] boundingRectWithSize:CGSizeMake([self.contentViewModel contentMaxWidth], 200)
                                                        options:(NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                                     attributes:attributes
                                                        context:nil].size;
        return CGSizeMake([self.contentViewModel contentMaxWidth],ceilf(size.height));
    }

    return [self.contentViewModel calculateContentSize];
}

- (CGSize)getReferViewSize {
    RCStreamMessage *streamMsg = (RCStreamMessage *)self.model.content;
    RCReferenceInfo *streamReferInfo = streamMsg.referMsg;
    CGFloat height = 17;//名字显示高度
    if ([streamReferInfo.content isKindOfClass:[RCImageMessage class]]) {
        RCImageMessage *msg = (RCImageMessage *)streamReferInfo.content;
        CGFloat space = 5.0;
        height = [RCMessageCellTool getThumbnailImageSize:msg.thumbnailImage].height + height + space;
    } else {
        height = 34;//两行文本高度
    }
    return CGSizeMake([self.contentViewModel contentMaxWidth], height);
}

#pragma mark -- private

- (void)configMessage:(RCMessageModel *)model {
    self.model = model;
    RCStreamMessage *streamMsg = (RCStreamMessage *)self.model.content;
    if ([streamMsg.type.lowercaseString isEqualToString:@"markdown"]) {
        self.contentType = RCStreamContentTypeMarkdown;
    }else if([streamMsg.type.lowercaseString isEqualToString:@"html"]) {
        self.contentType = RCStreamContentTypeHTML;
    } else {
        self.contentType = RCStreamContentTypeText;
    }
    [self parserSummary];
    [self checkReferView:streamMsg];
    [self checkStreamStatus];
    [self createStreamContentModel];
    [self initRequestStreamMessage];
}

- (void)createStreamContentModel {
    if (self.contentType == RCStreamContentTypeMarkdown ) {
        self.contentViewModel = [[RCStreamMarkdownContentViewModel alloc] init];
    } else if(self.contentType == RCStreamContentTypeHTML) {
        self.contentViewModel = [[RCStreamHTMLContentViewModel alloc] init];
    } else {
        self.contentViewModel = [[RCStreamTextContentViewModel alloc] init];
    }
    self.contentViewModel.delegate = self;
    [self.contentViewModel streamContentDidUpdate:self.content];
}

- (void)checkStreamStatus {
    RCStreamMessage *streamMsg = (RCStreamMessage *)self.model.content;
    DebugLog(@"[Stream] mUid:%@; checkStreamStatus %@, %@, %@, %@",self.model.messageUId,@(streamMsg.isSync), @(self.summaryComplete), @(self.summary.length), @(streamMsg.content.length));
    if (streamMsg.isSync || self.summaryComplete) {
        self.status = RCStreamMessageStatusNormal;
    } else if (self.summary.length > 0 && !streamMsg.isSync && !self.summaryComplete) {
        self.status = RCStreamMessageStatusBottomUnfold;
    } else if (streamMsg.content.length < RCStreamMessageCellLoadingLimit) {
        self.status = RCStreamMessageStatusContentLoading;
    } else {
        self.status = RCStreamMessageStatusNormal;
    }
}

- (void)checkReferView:(RCStreamMessage *)streamMsg {
    self.showReferMessage = streamMsg.referMsg ? YES : NO;
}

- (void)reloadStreamContent:(RCStreamMessageStatus)status {
    self.status = status;
    if ([self.contentViewModel.content isEqualToString:self.content]) {
        [self asyncRefreshViewSizes];
    } else {
        [self.contentViewModel streamContentDidUpdate:self.content];
    }
}

- (void)requestStreamMessageResult:(RCErrorCode)code {
    [self resetMessage];
    RCStreamMessage *streamMsg = (RCStreamMessage *)self.model.content;
    if (streamMsg.isSync || self.summaryComplete) {
        [self reloadStreamContent:RCStreamMessageStatusNormal];
    } else if (code == STREAM_MESSAGE_REQUEST_IN_PROCESS) {
        return;
    } else {
        if (self.status == RCStreamMessageStatusBottomLoading) {
            [self reloadStreamContent:RCStreamMessageStatusBottomFailed];
        } else if (self.status == RCStreamMessageStatusContentLoading) {
            [self reloadStreamContent:RCStreamMessageStatusContentFailedWhenLoading];
        } else if (self.status == RCStreamMessageStatusNormal){
            [self reloadStreamContent:RCStreamMessageStatusContentFailedWhenNormal];
        }
    }
    [[RCCoreClient sharedCoreClient] removeStreamMessageRequestEventDelegate:self];
    DebugLog(@"[Stream] mUid:%@; removeStreamMessageRequestEventDelegate", self.model.messageUId);
}

- (void)parserSummary {
    RCStreamSummaryModel *summary = [RCStreamUtilities parserStreamSummary:self.model];
    self.summaryComplete = summary.isComplete;
    self.summary = summary.summary;
}

- (void)resetMessage {
    RCMessage *message = [[RCCoreClient sharedCoreClient] getMessageByUId:self.model.messageUId];
    self.model.content = message.content;
    self.model.expansionDic = message.expansionDic;
    [self parserSummary];
}

#pragma mark -- RCStreamMessageRequestEventDelegate
/// 请求准备完成回调，如果该消息之前是异常中止的，会清理异常数据。
- (void)didReceiveInitEventWithMessageUId:(NSString *)messageUId {
    if (![messageUId isEqualToString:self.model.messageUId]) {
        return;
    }
    DebugLog(@"[Stream] mUid:%@; didReceiveInitEventWithMessageUId", messageUId);
    [self resetMessage];
}

/// 收到流式消息请求增量数据的回调。
- (void)didReceiveDeltaEventWithMessage:(RCMessage *)message
                              chunkInfo:(RCStreamMessageChunkInfo *)chunkInfo {
    if (![message.messageUId isEqualToString:self.model.messageUId]) {
        return;
    }
    NSString *content = ((RCStreamMessage *)(self.model.content)).content;
    if (content.length >= RCStreamMessageCellDisplayTextLimit) {
        return;
    }
    self.model.content = message.content;
    self.model.expansionDic = message.expansionDic;
    if (self.status == RCStreamMessageStatusBottomLoading) {
        self.status = RCStreamMessageStatusNormal;
    } else {
        [self checkStreamStatus];
    }
    [self reloadStreamContent:self.status];
    DebugLog(@"[Stream] mUid:%@; didReceiveDeltaEventWithMessage, content:%@", message.messageUId, chunkInfo.content);
}

/// 收到流式消息请求接收完成的回调。
- (void)didReceiveCompleteEventWithMessageUId:(NSString *)messageUId
                                         code:(RCErrorCode)code {
    if (![messageUId isEqualToString:self.model.messageUId]) {
        return;
    }
    
    [self requestStreamMessageResult:code];
    DebugLog(@"[Stream] mUid:%@; didReceiveCompleteEventWithMessageUId, code:%@", messageUId, @(code));
}

#pragma mark -- RCStreamContentViewModelDelegate

- (void)streamContentLayoutWillUpdate {
    [self asyncRefreshViewSizes];
}

#pragma mark -- Getter

- (NSString *)content {
    if (self.status == RCStreamMessageStatusNone || self.status == RCStreamMessageStatusContentLoading || self.status == RCStreamMessageStatusContentFailedWhenLoading) {
        return @"";
    }
    if (self.status == RCStreamMessageStatusBottomFailed || self.status == RCStreamMessageStatusBottomUnfold  || self.status == RCStreamMessageStatusBottomLoading) {
        return self.summary;
    }
    NSString *content = ((RCStreamMessage *)(self.model.content)).content;
    if (content.length < self.summary.length) {
        content = self.summary;
    }
    if (content.length >= RCStreamMessageCellDisplayTextLimit) {
        content = [content substringWithRange:NSMakeRange(0, RCStreamMessageCellDisplayTextLimit)];
    }
    if (self.status == RCStreamMessageStatusContentFailedWhenNormal) {
        content = [content stringByAppendingFormat:@"\n\n%@",RCLocalizedString(@"StreamFailedWithRequesting")];
    }
    return content;
}

@end
