//
//  RCConversationCSUtil.m
//  RongIMKit
//
//  Created by Sin on 2020/6/16.
//  Copyright © 2020 RongCloud. All rights reserved.
//

#import "RCConversationCSUtil.h"
#import <RongIMLib/RongIMLib.h>
#import "RCCSAlertView.h"
#import "RCCSEvaluateView.h"
#import "RCAdminEvaluationView.h"
#import "RCKitCommonDefine.h"
#import "RCCustomerServiceMessageModel.h"
#import "RCRobotEvaluationView.h"
#import "RCCustomerServiceGroupListController.h"
#import "RCCSLeaveMessageController.h"
#import "RCKitUtility.h"
#import <RongCustomerService/RongCustomerService.h>
#import "RCSemanticContext.h"
@interface RCConversationCSUtil ()<RCCSAlertViewDelegate, RCAdminEvaluationViewDelegate, RCRobotEvaluationViewDelegate>
@property (nonatomic, weak) RCConversationViewController *chatVC;
@property (nonatomic, strong) RCCustomerServiceConfig *csConfig;
@property (nonatomic, strong) RCCSAlertView *csAlertView;
@property (nonatomic, strong) NSDate *csEnterDate;
@property (nonatomic, assign) BOOL humanEvaluated;

/*!
 是否开启客服超时提醒

 @discussion 默认值为NO。
 开启该提示功能之后，在客服会话页面长时间没有说话或者收到对方的消息，会插入一条提醒消息
 */
@property (nonatomic, assign) BOOL enableCustomerServiceOverTimeRemind;

/*!
 客服长时间没有收到消息超时提醒时长

 @discussion 默认值60秒。
 开启enableCustomerServiceOverTimeRemind之后，在客服会话页面，时长 customerServiceReciveMessageOverTimeRemindTimer
 没有收到对方的消息，会插入一条提醒消息
 */
@property (nonatomic, assign) int customerServiceReciveMessageOverTimeRemindTimer;

/*!
 客服长时间没有收到消息超时提醒内容

 开启enableCustomerServiceOverTimeRemind之后，在客服会话页面，时长 customerServiceSendMessageOverTimeRemindTimer
 没有说话，会插入一条提醒消息
 */
@property (nonatomic, copy) NSString *customerServiceReciveMessageOverTimeRemindContent;

/*!
 客服长时间没有发送消息超时提醒时长

 @discussion 默认值60秒。
 开启enableCustomerServiceOverTimeRemind之后，在客服会话页面，时长 customerServiceSendMessageOverTimeRemindTimer
 没有说话，会插入一条提醒消息
 */
@property (nonatomic, assign) int customerServiceSendMessageOverTimeRemindTimer;

/*!
 客服长时间没有发送消息超时提醒内容

 开启enableCustomerServiceOverTimeRemind之后，在客服会话页面，时长 customerServiceSendMessageOverTimeRemindTimer
 没有说话，会插入一条提醒消息
 */
@property (nonatomic, copy) NSString *customerServiceSendMessageOverTimeRemindContent;

/*!
 客服结束会话提示信息
 */
@property (nonatomic, copy) NSString *customerServiceQuitMsg;

@property (nonatomic, strong) RCCSEvaluateView *evaluateView;

#pragma mark timer
//@property(nonatomic, strong) NSTimer *hideReceiptButtonTimer;//群回执定时消失timer
@property (nonatomic, strong) NSTimer *notReciveMessageAlertTimer; //长时间没有收到消息的计时器
@property (nonatomic, strong) NSTimer *notSendMessageAlertTimer;   //长时间没有发送消息的计时器
@end

@implementation RCConversationCSUtil
- (instancetype)init:(RCConversationViewController *)chatVC {
    self = [super init];
    if(self) {
        self.chatVC = chatVC;
        self.customerServiceReciveMessageOverTimeRemindTimer = 20;
        self.customerServiceSendMessageOverTimeRemindTimer = 10;
    }
    return self;
}
- (void)startCustomerService {
    [self.chatVC.chatSessionInputBarControl setInputBarType:RCChatSessionInputBarControlDefaultType
                                               style:RC_CHAT_INPUT_BAR_STYLE_CONTAINER];

    if (!self.csInfo) {
        self.csInfo = [RCCustomerServiceInfo new];
        self.csInfo.userId = [RCIMClient sharedRCIMClient].currentUserInfo.userId;
        self.csInfo.nickName = [RCIMClient sharedRCIMClient].currentUserInfo.name;
        self.csInfo.portraitUrl = [RCIMClient sharedRCIMClient].currentUserInfo.portraitUri;
    }
    
    __weak typeof(self) weakSelf = self;
    [[RCCustomerServiceClient sharedCustomerServiceClient] startCustomerService:self.chatVC.targetId
        info:self.csInfo
        onSuccess:^(RCCustomerServiceConfig *config) {
            weakSelf.csConfig = config;
            weakSelf.csEnterDate = [[NSDate alloc] init];
            [weakSelf startNotSendMessageAlertTimer];
            [weakSelf startNotReciveMessageAlertTimer];
            if (config.disableLocation) {
                [weakSelf.chatVC.chatSessionInputBarControl.pluginBoardView
                    removeItemWithTag:PLUGIN_BOARD_ITEM_LOCATION_TAG];
            }
            if (config.evaEntryPoint == RCCSEvaExtention) {
                [weakSelf.chatVC.chatSessionInputBarControl.pluginBoardView insertItem:RCResourceImage(@"Comment") highlightedImage:RCResourceImage(@"Comment_highlighted") title:@"评价" tag:PLUGIN_BOARD_ITEM_EVA_TAG];
            }
            [weakSelf announceViewWillShow];
        }
        onError:^(int errorCode, NSString *errMsg) {
            [weakSelf customerServiceWarning:errMsg.length ? errMsg : @"连接客服失败!"
                            quitAfterWarning:YES
                                needEvaluate:NO
                                 needSuspend:NO];
        }
        onModeType:^(RCCSModeType mode) {
            weakSelf.currentServiceStatus = RCCustomerService_NoService;
            [weakSelf onCustomerServiceModeChanged:mode];
            switch (mode) {
            case RC_CS_RobotOnly:
                [weakSelf.chatVC.chatSessionInputBarControl setInputBarType:RCChatSessionInputBarControlDefaultType
                                                               style:RC_CHAT_INPUT_BAR_STYLE_CONTAINER];
                weakSelf.currentServiceStatus = RCCustomerService_RobotService;
                break;
            case RC_CS_HumanOnly: {
                weakSelf.currentServiceStatus = RCCustomerService_HumanService;
                RCChatSessionInputBarControlStyle style = RC_CHAT_INPUT_BAR_STYLE_SWITCH_CONTAINER_EXTENTION;
                [weakSelf.chatVC.chatSessionInputBarControl setInputBarType:RCChatSessionInputBarControlDefaultType
                                                               style:style];
            } break;
            case RC_CS_RobotFirst:
                [weakSelf.chatVC.chatSessionInputBarControl setInputBarType:RCChatSessionInputBarControlCSRobotType
                                                               style:RC_CHAT_INPUT_BAR_STYLE_CONTAINER];
                weakSelf.currentServiceStatus = RCCustomerService_RobotService;
                break;
            case RC_CS_NoService: {
                RCChatSessionInputBarControlStyle style = RC_CHAT_INPUT_BAR_STYLE_SWITCH_CONTAINER_EXTENTION;
                [weakSelf.chatVC.chatSessionInputBarControl setInputBarType:RCChatSessionInputBarControlDefaultType
                                                               style:style];
                weakSelf.currentServiceStatus = RCCustomerService_NoService;
            } break;
            default:
                break;
            }
            [weakSelf resetBottomBarStatus];
        }
        onPullEvaluation:^(NSString *dialogId) {
            //          if ([weakSelf.csEnterDate timeIntervalSinceNow] < -60 && !weakSelf.humanEvaluated &&
            //          weakSelf.csConfig.evaEntryPoint == RCCSEvaLeave) {
            //              weakSelf.humanEvaluated = YES;
            [weakSelf commentCustomerServiceWithStatus:weakSelf.currentServiceStatus
                                             commentId:dialogId
                                      quitAfterComment:NO];
            //          }
            //        [weakSelf showEvaView];
        }
        onSelectGroup:^(NSArray<RCCustomerServiceGroupItem *> *groupList) {
            [weakSelf onSelectCustomerServiceGroup:groupList
                                            result:^(NSString *groupId) {
                                                [[RCCustomerServiceClient sharedCustomerServiceClient]
                                                    selectCustomerServiceGroup:weakSelf.chatVC.targetId
                                                                   withGroupId:groupId];
                                            }];
        }
        onQuit:^(NSString *quitMsg) {
            weakSelf.customerServiceQuitMsg = quitMsg;
            if (weakSelf.csConfig.evaEntryPoint == RCCSEvaCSEnd &&
                weakSelf.currentServiceStatus == RCCustomerService_HumanService) {
                [weakSelf commentCustomerServiceWithStatus:weakSelf.currentServiceStatus
                                                 commentId:nil
                                          quitAfterComment:NO];
            } else {
                [weakSelf showCustomerServiceEndAlert];
            }
        }];
}
- (void)stopCSTimer {
    [self stopNotReciveMessageAlertTimer];
    [self stopNotSendMessageAlertTimer];
}
- (void)didTapCSPullLeaveMessage:(RCMessageModel *)model {
    if (self.csConfig.leaveMessageType == RCCSLMNative && self.csConfig.leaveMessageNativeInfo.count > 0) {
        RCCSLeaveMessageController *leaveMsgVC = [[RCCSLeaveMessageController alloc] init];
        leaveMsgVC.leaveMessageConfig = self.csConfig.leaveMessageNativeInfo;
        leaveMsgVC.targetId = self.chatVC.targetId;
        leaveMsgVC.conversationType = self.chatVC.conversationType;
        __weak typeof(self) weakSelf = self;
        [leaveMsgVC setLeaveMessageSuccess:^{
            RCInformationNotificationMessage *warningMsg =
                [RCInformationNotificationMessage notificationWithMessage:@"您已提交留言。" extra:nil];
            RCMessage *savedMsg = [[RCIMClient sharedRCIMClient] insertOutgoingMessage:weakSelf.chatVC.conversationType
                                                                              targetId:weakSelf.chatVC.targetId
                                                                            sentStatus:SentStatus_SENT
                                                                               content:warningMsg];
            [weakSelf.chatVC appendAndDisplayMessage:savedMsg];
        }];
        [self.chatVC.navigationController pushViewController:leaveMsgVC animated:YES];
    } else if (self.csConfig.leaveMessageType == RCCSLMWeb) {
        [RCKitUtility openURLInSafariViewOrWebView:self.csConfig.leaveMessageWebUrl base:self.chatVC];
    }
}
#pragma mark - CustomerService
/****************** Custom Service Code Begin ******************/
- (void)robotSwitchButtonDidTouch {
    if (self.chatVC.conversationType == ConversationType_CUSTOMERSERVICE) {
        [[RCCustomerServiceClient sharedCustomerServiceClient] switchToHumanMode:self.chatVC.targetId];
        [self startNotSendMessageAlertTimer];
        [self startNotReciveMessageAlertTimer];
    }
}

- (void)didTapCustomerService:(RCMessageModel *)model RobotResoluved:(BOOL)isResolved {
    RCCustomerServiceMessageModel *csModel = (RCCustomerServiceMessageModel *)model;
    csModel.alreadyEvaluated = YES;
    [[RCCustomerServiceClient sharedCustomerServiceClient] evaluateCustomerService:model.targetId
                                              knownledgeId:csModel.evaluateId
                                                robotValue:YES
                                                   suggest:nil];
    NSUInteger index = [self.chatVC.conversationDataRepository indexOfObject:model];
    NSIndexPath *path = [NSIndexPath indexPathForRow:index inSection:0];
    [self.chatVC.conversationMessageCollectionView reloadItemsAtIndexPaths:@[ path ]];
}

- (void)suspendCustomerService {
    [[RCCustomerServiceClient sharedCustomerServiceClient] stopCustomerService:self.chatVC.targetId];
}

- (void)leftCustomerServiceWithEvaluate:(BOOL)needEvaluate {
    if (needEvaluate) {
        if ([self.csEnterDate timeIntervalSinceNow] >= -(self.chatVC.csEvaInterval)) {
            needEvaluate = NO;
        }
        if (self.currentServiceStatus == RCCustomerService_RobotService && self.csConfig.robotSessionNoEva) {
            needEvaluate = NO;
        } else if (self.currentServiceStatus == RCCustomerService_HumanService && self.csConfig.humanSessionNoEva) {
            needEvaluate = NO;
        }

        if (self.humanEvaluated) {
            needEvaluate = NO;
        }
    }

    if (needEvaluate && self.currentServiceStatus != RCCustomerService_NoService &&
        self.csConfig.evaEntryPoint == RCCSEvaLeave) {
        [self resetBottomBarStatus];
        if (self.currentServiceStatus == RCCustomerService_HumanService) {
            self.humanEvaluated = YES;
        }
        [self commentCustomerServiceWithStatus:self.currentServiceStatus commentId:nil quitAfterComment:YES];
    } else {
        [self.chatVC leftBarButtonItemPressed:nil];
    }
}

- (void)commentCustomerServiceWithStatus:(RCCustomerServiceStatus)serviceStatus
                               commentId:(NSString *)commentId
                        quitAfterComment:(BOOL)isQuit {
    if (serviceStatus != RCCustomerService_NoService && self.csConfig.evaType == EVA_UNIFIED) {
        [self showEvaView];
    }
    if (serviceStatus == RCCustomerService_HumanService) {
        RCChatSessionInputBarControlStyle style = RC_CHAT_INPUT_BAR_STYLE_SWITCH_CONTAINER_EXTENTION;
        [self.chatVC.chatSessionInputBarControl setInputBarType:RCChatSessionInputBarControlDefaultType style:style];
        RCAdminEvaluationView *eva = [[RCAdminEvaluationView alloc] initWithDelegate:self];
        eva.quitAfterEvaluation = isQuit;
        eva.dialogId = commentId;
        [eva show];
    } else if (serviceStatus == RCCustomerService_RobotService) {
        [self.chatVC.chatSessionInputBarControl setInputBarType:RCChatSessionInputBarControlDefaultType
                                                   style:RC_CHAT_INPUT_BAR_STYLE_CONTAINER];
        RCRobotEvaluationView *eva = [[RCRobotEvaluationView alloc] initWithDelegate:self];
        eva.quitAfterEvaluation = isQuit;
        eva.knownledgeId = commentId;
        [eva show];
    }
}

- (void)customerServiceLeftCurrentViewController {
    if (self.chatVC.conversationType == ConversationType_CUSTOMERSERVICE) {
        [self suspendCustomerService];
        [self leftCustomerServiceWithEvaluate:YES];
    } else {
        [self.chatVC leftBarButtonItemPressed:nil];
    }
}

- (void)customerServiceWarning:(NSString *)warning
              quitAfterWarning:(BOOL)quit
                  needEvaluate:(BOOL)needEvaluate
                   needSuspend:(BOOL)needSuspend {
    [self.evaluateView hide];
    if (self.csAlertView) {
        [self.csAlertView dismissWithClickedButtonIndex:0];
        self.csAlertView = nil;
    }

    [self resetBottomBarStatus];

    RCCSAlertView *alert = [[RCCSAlertView alloc] initWithTitle:nil warning:warning delegate:self];
    int tag = 0;
    if (quit) {
        tag = 1;
    }
    if (needEvaluate) {
        tag = tag | (1 << 1);
    }
    if (needSuspend) {
        tag = tag | (1 << 2);
    }
    alert.tag = tag;
    self.csAlertView = alert;
    [alert show];
}

- (void)onCustomerServiceModeChanged:(RCCSModeType)newMode {
}

- (void)showEvaView {
    [self resetBottomBarStatus];
    self.evaluateView =
        [[RCCSEvaluateView alloc] initWithFrame:CGRectZero showSolveView:self.csConfig.reportResolveStatus];
    __weak typeof(self) weakSelf = self;
    [self.evaluateView setEvaluateResult:^(int source, int solveStatus, NSString *suggest) {
        [[RCCustomerServiceClient sharedCustomerServiceClient] evaluateCustomerService:weakSelf.chatVC.targetId
                                                      dialogId:nil
                                                     starValue:source
                                                       suggest:suggest
                                                 resolveStatus:solveStatus];
    }];
    [self.evaluateView show];
}

- (void)showCustomerServiceEndAlert {
    [self customerServiceWarning:self.customerServiceQuitMsg.length ? self.customerServiceQuitMsg
                                                                    : @"客服会话已结束!"
                quitAfterWarning:YES
                    needEvaluate:YES
                     needSuspend:YES];
}

- (void)announceViewWillShow {
    if (self.csConfig.announceMsg.length > 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self announceViewWillShow:self.csConfig.announceMsg announceClickUrl:self.csConfig.announceClickUrl];
        });
    }
}

- (void)announceViewWillShow:(NSString *)announceMsg announceClickUrl:(NSString *)announceClickUrl {
}
- (void)onSelectCustomerServiceGroup:(NSArray *)groupList result:(void (^)(NSString *groupId))resultBlock {
    NSMutableArray *__groupList = [NSMutableArray array];
    for (RCCustomerServiceGroupItem *item in groupList) {
        if (item.online) {
            [__groupList addObject:item];
        }
    }
    if (__groupList && __groupList.count > 0) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            RCCustomerServiceGroupListController *customerGroupListController =
                [[RCCustomerServiceGroupListController alloc] init];
            UINavigationController *rootVC =
                [[UINavigationController alloc] initWithRootViewController:customerGroupListController];
            if ([RCSemanticContext isRTL]) {
                rootVC.view.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
            }
            customerGroupListController.groupList = __groupList;
            [customerGroupListController setSelectGroupBlock:^(NSString *groupId) {
                if (resultBlock) {
                    resultBlock(groupId);
                }
            }];
            rootVC.modalPresentationStyle = UIModalPresentationFullScreen;
            [weakSelf.chatVC presentViewController:rootVC animated:YES completion:nil];
        });
    } else {
        if (resultBlock) {
            resultBlock(nil);
        }
    }
}

#pragma mark RCCSAlertViewDelegate
- (void)willCSAlertViewDismiss:(RCCSAlertView *)view {
    if (view.tag & (1 << 2)) {
        [self suspendCustomerService];
    }
    if (view.tag & 0x001) {
        [self leftCustomerServiceWithEvaluate:((view.tag & (1 << 1)) > 0)];
    }
}

#pragma mark RCAdminEvaluationViewDelegate
- (void)adminEvaluateViewCancel:(RCAdminEvaluationView *)view {
    if (view.quitAfterEvaluation) {
        [self.chatVC leftBarButtonItemPressed:nil];
    }
    if (self.csConfig.evaEntryPoint == RCCSEvaCSEnd) {
        [self showCustomerServiceEndAlert];
    }
}

- (void)adminEvaluateView:(RCAdminEvaluationView *)view didEvaluateValue:(int)starValues {
    if (starValues >= 0) {
        [[RCCustomerServiceClient sharedCustomerServiceClient] evaluateCustomerService:self.chatVC.targetId
                                                      dialogId:view.dialogId
                                                     starValue:starValues + 1
                                                       suggest:nil
                                                 resolveStatus:(RCCSResolved)
                                                       tagText:nil
                                                         extra:nil];
    }
    if (view.quitAfterEvaluation) {
        [self.chatVC leftBarButtonItemPressed:nil];
    }
    if (self.csConfig.evaEntryPoint == RCCSEvaCSEnd) {
        [self showCustomerServiceEndAlert];
    }
}

#pragma mark RCRobotEvaluationViewDelegate
- (void)robotEvaluateViewCancel:(RCRobotEvaluationView *)view {
    if (view.quitAfterEvaluation) {
        [self.chatVC leftBarButtonItemPressed:nil];
    }
}

- (void)robotEvaluateView:(RCRobotEvaluationView *)view didEvaluateValue:(BOOL)isResolved {
    [[RCCustomerServiceClient sharedCustomerServiceClient] evaluateCustomerService:self.chatVC.targetId
                                              knownledgeId:view.knownledgeId
                                                robotValue:isResolved
                                                   suggest:nil];
    if (view.quitAfterEvaluation) {
        [self.chatVC leftBarButtonItemPressed:nil];
    }
}

/****************** Custom Service Code End   ******************/

#pragma mark - CustomerService Timer

/**
 *  长时间没有收到消息的超时提醒
 *
 */
- (void)longTimeNotReciveMessageAlert {
    if (self.currentServiceStatus == RCCustomerService_HumanService) {
        RCInformationNotificationMessage *informationNotifiMsg = [RCInformationNotificationMessage
            notificationWithMessage:self.customerServiceReciveMessageOverTimeRemindContent
                              extra:nil];

        __block RCMessage *tempMessage = [[RCIMClient sharedRCIMClient] insertIncomingMessage:self.chatVC.conversationType
                                                                                     targetId:self.chatVC.targetId
                                                                                 senderUserId:self.chatVC.targetId
                                                                               receivedStatus:(ReceivedStatus_READ)
                                                                                      content:informationNotifiMsg];
        dispatch_async(dispatch_get_main_queue(), ^{
            tempMessage = [self.chatVC willAppendAndDisplayMessage:tempMessage];
            if (tempMessage) {
                [self.chatVC appendAndDisplayMessage:tempMessage];
            }
            [self stopNotReciveMessageAlertTimer];
        });
    } else {
        [self stopNotReciveMessageAlertTimer];
    }
}

/**
 *  长时间没有发送消息的超时提醒
 *
 */
- (void)longTimeNotSendMessageAlert {
    if (self.currentServiceStatus == RCCustomerService_HumanService) {
        RCInformationNotificationMessage *informationNotifiMsg = [RCInformationNotificationMessage
            notificationWithMessage:self.customerServiceSendMessageOverTimeRemindContent
                              extra:nil];
        __block RCMessage *tempMessage = [[RCIMClient sharedRCIMClient] insertIncomingMessage:self.chatVC.conversationType
                                                                                     targetId:self.chatVC.targetId
                                                                                 senderUserId:self.chatVC.targetId
                                                                               receivedStatus:(ReceivedStatus_READ)
                                                                                      content:informationNotifiMsg];
        dispatch_async(dispatch_get_main_queue(), ^{
            tempMessage = [self.chatVC willAppendAndDisplayMessage:tempMessage];
            if (tempMessage) {
                [self.chatVC appendAndDisplayMessage:tempMessage];
            }

            [self stopNotSendMessageAlertTimer];
        });
    } else {
        [self stopNotReciveMessageAlertTimer];
    }
}

//客服开始长时间没有发送消息的timer监听
- (void)startNotSendMessageAlertTimer {
    if (self.chatVC.conversationType != ConversationType_CUSTOMERSERVICE) {
        return;
    }
    if (self.csConfig.userTipTime > 0 && self.csConfig.userTipWord.length > 0) {
        self.customerServiceSendMessageOverTimeRemindTimer = self.csConfig.userTipTime * 60;
        self.customerServiceSendMessageOverTimeRemindContent = self.csConfig.userTipWord;

        __weak typeof(self) ws = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [ws stopNotSendMessageAlertTimer];
            ws.notSendMessageAlertTimer =
                [NSTimer scheduledTimerWithTimeInterval:self.customerServiceSendMessageOverTimeRemindTimer
                                                 target:self
                                               selector:@selector(longTimeNotSendMessageAlert)
                                               userInfo:nil
                                                repeats:YES];
        });
    }
}
- (void)stopNotSendMessageAlertTimer {
    if (self.notSendMessageAlertTimer) {
        if (self.notSendMessageAlertTimer.valid) {
            [self.notSendMessageAlertTimer invalidate];
        }
        self.notSendMessageAlertTimer = nil;
    }
}

//客服开始长时间没有收到消息的timer监听
- (void)startNotReciveMessageAlertTimer {
    if (self.chatVC.conversationType != ConversationType_CUSTOMERSERVICE) {
        return;
    }
    if (self.csConfig.adminTipTime > 0 && self.csConfig.adminTipWord.length > 0) {
        self.customerServiceReciveMessageOverTimeRemindTimer = self.csConfig.adminTipTime * 60;
        self.customerServiceReciveMessageOverTimeRemindContent = self.csConfig.adminTipWord;
        __weak typeof(self) ws = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [ws stopNotReciveMessageAlertTimer];
            ws.notReciveMessageAlertTimer =
                [NSTimer scheduledTimerWithTimeInterval:self.customerServiceReciveMessageOverTimeRemindTimer
                                                 target:self
                                               selector:@selector(longTimeNotReciveMessageAlert)
                                               userInfo:nil
                                                repeats:YES];

        });
    }
}

- (void)stopNotReciveMessageAlertTimer {
    if (self.notReciveMessageAlertTimer) {
        if (self.notReciveMessageAlertTimer.valid) {
            [self.notReciveMessageAlertTimer invalidate];
        }
        self.notReciveMessageAlertTimer = nil;
    }
}

- (void)resetBottomBarStatus {
    [self.chatVC.chatSessionInputBarControl resetToDefaultStatus];
}

@end
