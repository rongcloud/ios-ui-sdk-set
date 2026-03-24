//
//  RCSTTContentViewModel.m
//  RongIMKit
//
//  Created by RobinCui on 2025/5/27.
//  Copyright © 2025 RongCloud. All rights reserved.
//
#import "RCSpeechToTextModel.h"
#import "RCSTTContentViewModel.h"
#import "RCMessageModel+StreamCellVM.h"
#import "RCMessageCellTool.h"
#import "RCSTTLabel.h"
#import "RCSTTObserverContext.h"
#import "RCIMThreadLock.h"
#import "RCMessageModel+STT.h"

@interface RCSTTContentViewModel()<RCSpeechToTextDelegate> {
    __weak id<RCSTTContentViewModelDelegate> _delegate;
}
@property (nonatomic, strong) UILabel *labContent;
@property (nonatomic, assign) CGSize textSize;
@property (nonatomic, strong) RCSpeechToTextModel *sttModel;
@property (nonatomic, strong) RCIMThreadLock *lock;
@end

@implementation RCSTTContentViewModel

+ (void)configureSTTIfNeeded:(RCMessageModel *)model {
    RCSpeechToTextInfo *sttInfo = [RCSTTContentViewModel sttInfoOfModel:model];
    if (sttInfo) { // 启用语音转文本
        if (!model.cellViewModel) {// 尚未配置stt vm
            RCSTTContentViewModel *vm = [[RCSTTContentViewModel alloc] initWithSTTInfo:sttInfo];
            vm.model = model;
            model.cellViewModel = vm;
        }
    }
}

        
- (instancetype)initWithSTTInfo:(RCSpeechToTextInfo *)info;
{
    self = [super init];
    if (self) {
        self.lock = [RCIMThreadLock new];
        RCSpeechToTextModel *sttModel = [[RCSpeechToTextModel alloc] initWithSTTInfo:info];
        self.sttModel = sttModel;
        [self refreshTotalHeightIfNeeded];
    }
    return self;
}

+ (RCSpeechToTextInfo *)sttInfoOfModel:(RCMessageModel *)model {
    if ([model.content isKindOfClass:[RCHQVoiceMessage class]]) {
        RCHQVoiceMessage *msg = (RCHQVoiceMessage *)model.content;
        return msg.sttInfo;
    } else if([model.content isKindOfClass:[RCVoiceMessage class]]) {
        RCVoiceMessage *msg = (RCVoiceMessage *)model.content;
        return msg.sttInfo;
    }
    return nil;
}

- (CGFloat)speedToTextContentHeight {
    if (!self.sttModel.isVisible || self.sttModel.status == RCSpeechToTextStatusNotConverted) {
        return 0;
    }
    CGFloat height = 0;
    switch (self.sttModel.status) {
        case RCSpeechToTextStatusFailed:
        case RCSpeechToTextStatusConverting:
            height = 40;
            break;
        case RCSpeechToTextStatusSuccess:{
                height = self.textSize.height;
        }
            break;
            
        default:
            break;
    }
    return height;
}

- (BOOL)shouldDisplayFullText {
    BOOL ret = self.sttModel.sttInfo.status == RCSpeechToTextStatusSuccess;
    return  ret;
}

- (void)refreshCell {
    self.model.cellSize = CGSizeMake(self.model.cellSize.width, 0);
    [self updateSTTContentViewLayout];
}

- (void)hideSpeedToText {
    self.sttModel.isVisible = NO;
    [[RCCoreClient sharedCoreClient] setMessageSpeechToTextVisible:self.model.messageId
                                                         isVisible:NO
                                                 completionHandler:nil];
    self.model.cellSize = CGSizeMake(self.model.cellSize.width, 0);
    [self changeSTTContentViewStatus:RCSTTContentStatusHide];
    [self updateSTTContentViewLayout];
}

- (void)convertAndDisplaySpeedToText:(void(^)(RCErrorCode code))completion {
    self.sttModel.isVisible = YES;
    if ([self shouldDisplayFullText]) {// 已转换完成
        [[RCCoreClient sharedCoreClient] setMessageSpeechToTextVisible:self.model.messageId
                                                             isVisible:YES
                                                     completionHandler:^(RCErrorCode code) {
            if (code == RC_SUCCESS) {
                [self displaySTTContentViewText:self.sttModel.sttInfo.text
                                           size:self.textSize
                                      animation:YES];
                [self changeStatus:RCSpeechToTextStatusSuccess];
                [self refreshCell];
            } else {
                self.sttModel.isVisible = NO;
            }
            if (completion) {
                completion(code);
            }
        }];
      
        return;
    }
    if (self.sttModel.status != RCSpeechToTextStatusSuccess) {
        RCSTTLog(@"requestSpeechToTextForMessage start: messageUid %@", self.model.messageUId);
        if (self.model.messageUId) {
            [RCSTTObserverContext registerObserver:self forMessage:self.model.messageUId];
        }
        [[RCCoreClient sharedCoreClient] requestSpeechToTextForMessage:self.model.messageUId completionHandler:^(RCErrorCode code) {
            RCSTTLog(@"requestSpeechToTextForMessage : code %ld", code);
            if (code != RC_SUCCESS) {
                if (self.model.messageUId) {
                    [RCSTTObserverContext removeObserverForMessage:self.model.messageUId];
                }
                self.sttModel.isVisible = NO;
            } else {
                [self changeStatus:RCSpeechToTextStatusConverting];
                [self refreshCell];
            }
            if (completion) {
                completion(code);
            }
        }];
    }
}

- (void)changeStatus:(RCSpeechToTextStatus)sttStatus {
    self.sttModel.status = sttStatus;
    RCSTTContentStatus status = RCSTTContentStatusHide;
    switch (sttStatus) {
        case RCSpeechToTextStatusFailed:
            status = RCSTTContentStatusFailed;
            break;
        case RCSpeechToTextStatusConverting:
            status = RCSTTContentStatusLoading;
            break;
        case RCSpeechToTextStatusSuccess:
            status = RCSTTContentStatusText;
            break;
        default:
            break;
    }
    [self changeSTTContentViewStatus:status];
}

- (void)refreshStatus {
    RCSTTContentStatus status = RCSTTContentStatusHide;
    if (self.sttModel.isVisible) {
        switch (self.sttModel.status) {
            case RCSpeechToTextStatusFailed:
                status = RCSTTContentStatusFailed;
                break;
            case RCSpeechToTextStatusConverting:
                status = RCSTTContentStatusLoading;
                break;
            case RCSpeechToTextStatusSuccess: {
                status = RCSTTContentStatusText;
                [self displaySTTContentViewText:self.sttModel.sttInfo.text
                                           size:self.textSize
                                      animation:NO];
            }
                break;
            default:
                break;
        }
    }
    [self changeSTTContentViewStatus:status];
}

- (void)refreshTotalHeightIfNeeded {
    RCSTTLog(@"refreshTotalHeightIfNeeded before: %f, %lf",self.textSize.width, self.textSize.height);
    if (self.textSize.height > 0) {
        return;
    }
    if (self.sttModel.status != RCSpeechToTextStatusSuccess) {
        return;
    }
    if (self.sttModel.sttInfo.text.length == 0) {
        self.sttModel.sttInfo.text = @" ";
    }
    self.labContent.text = self.sttModel.sttInfo.text;
    CGSize constraintSize = CGSizeMake(self.labContent.frame.size.width, CGFLOAT_MAX);
    CGSize size = [self.labContent sizeThatFits:constraintSize];
    self.textSize = size;
    RCSTTLog(@"refreshTotalHeightIfNeeded after: %f, %lf",self.textSize.width, self.textSize.height);
}

#pragma mark - Public
- (BOOL)isConverting {
    return self.sttModel.status == RCSpeechToTextStatusConverting;
}

- (BOOL)isSTTVisible {
    return self.sttModel.isVisible;
}

- (RCSpeechToTextInfo *)messageSTTInfo {
    return self.sttModel.sttInfo;
}
#pragma mark - Protocol
- (void)updateSTTContentViewLayout {
    id<RCSTTContentViewModelDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(sttViewModelUpdateSTTContentViewLayout:)]) {
        [delegate sttViewModelUpdateSTTContentViewLayout:self];
    }
}

- (void)changeSTTContentViewStatus:(RCSTTContentStatus)status {
    id<RCSTTContentViewModelDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(sttViewModel:changeStatus:)]) {
        [delegate sttViewModel:self changeStatus:status];
    }
}

- (void)displaySTTContentViewText:(NSString *)text
                             size:(CGSize)size
                        animation:(BOOL)animation {
    id<RCSTTContentViewModelDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(sttViewModel:displayText:size:animation:)]) {
        [delegate sttViewModel:self
                   displayText:text
                          size:size
                     animation:animation];;
    }
}

- (void)speechToTextFinished:(BOOL)result {
    id<RCSTTContentViewModelDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(sttViewModel:speechToTextFinished:)]) {
        [delegate sttViewModel:self speechToTextFinished:result];
    }
}
#pragma mark - RCSpeechToTextDelegate
- (void)speechToTextDidComplete:(RCSpeechToTextInfo* _Nullable)info
                     messageUId:(nonnull NSString *)messageUId
                           code:(RCErrorCode)code {
    RCSTTLog(@"speechToTextDidComplete: %@, %ld", info.text, (long)info.status);
    [self speechToTextFinished:code == RC_SUCCESS];
    if (info.text.length == 0) {
        info.text = @" ";
    }
    if (messageUId) {
        [RCSTTObserverContext removeObserverForMessage:messageUId];
    }
    info = [self.model stt_refreshSpeechToTextInfo:info];
    // 同步数据
    [self.sttModel synchronizeSTTInfo:info];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (code == RC_SUCCESS) {
            [self.model stt_markVoiceMessageListened];
            [self refreshTotalHeightIfNeeded];
            
            [self displaySTTContentViewText:self.sttModel.sttInfo.text
                                       size:self.textSize
                                  animation:YES];
            [self changeStatus:RCSpeechToTextStatusSuccess];
            self.model.cellSize = CGSizeMake(self.model.cellSize.width, 0);
            [self updateSTTContentViewLayout];
        } else {
            [self changeStatus:info.status];
        }
    });
}

#pragma mark - Property

- (UILabel *)labContent {
    if (!_labContent) {
        CGFloat width = [RCMessageCellTool getMessageContentViewMaxWidth];
        RCSTTLabel *lab = [[RCSTTLabel alloc] initWithFrame:CGRectMake(0, 0, width, 0)];
        lab.numberOfLines = 0;
        lab.font = [UIFont systemFontOfSize:16];
        lab.lineBreakMode = NSLineBreakByWordWrapping;
        lab.adjustsFontSizeToFitWidth = NO;
        _labContent = lab;
    }
    return _labContent;
}

- (void)setDelegate:(id<RCSTTContentViewModelDelegate>)delegate {
    [self.lock performWriteLockBlock:^{
            _delegate = delegate;
    }];
}

- (id<RCSTTContentViewModelDelegate>)delegate {
    __block id<RCSTTContentViewModelDelegate> d = nil;
    [self.lock performReadLockBlock:^{
            d = _delegate;
    }];
    return d;
}
@end
