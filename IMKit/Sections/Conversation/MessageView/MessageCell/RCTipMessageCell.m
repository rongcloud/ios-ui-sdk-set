//
//  RCTipMessageCell.m
//  RongIMKit
//
//  Created by xugang on 15/1/29.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCTipMessageCell.h"
#import "RCKitUtility.h"
#import "RCUserInfoCacheManager.h"
#import "RCKitCommonDefine.h"
#import "RCReeditMessageManager.h"
#import "RCKitConfig.h"
#import <RongDiscussion/RongDiscussion.h>
@interface RCTipMessageCell () <RCAttributedLabelDelegate>

@property (nonatomic, strong) NSMutableSet *relatedUserIdList;

@property (nonatomic, strong) UILabel *reeditLabel;

@end

@implementation RCTipMessageCell
#pragma mark - Life Cycle
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self.baseContentView addSubview:self.tipMessageLabel];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Super Methods
+ (CGSize)sizeForMessageModel:(RCMessageModel *)model
      withCollectionViewWidth:(CGFloat)collectionViewWidth
         referenceExtraHeight:(CGFloat)extraHeight {
    CGFloat height = [self getTipLabelSize:model].height;
    height += extraHeight;
    return CGSizeMake(collectionViewWidth, height);
}

- (void)setDataModel:(RCMessageModel *)model {
    [super setDataModel:model];
    
    [self.reeditLabel removeFromSuperview];
    RCMessageContent *content = model.content;
    self.relatedUserIdList = [self getRelatedUserIdList:content];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:RCKitDispatchUserInfoUpdateNotification object:nil];
    
    self.tipMessageLabel.text = [RCKitUtility formatMessage:content
                                                   targetId:model.targetId
                                           conversationType:model.conversationType
                                               isAllMessage:YES];
    CGSize labelSize = [RCTipMessageCell getTipLabelSize:model];
    
    if ([content isMemberOfClass:[RCRecallNotificationMessage class]] && [self canReeditMessage]) {
        CGSize buttonTitleSize = [RCKitUtility getTextDrawingSize:RCLocalizedString(@"RecallEdit")
                                    font:[[RCKitConfig defaultConfig].font fontOfFourthLevel]
                         constrainedSize:CGSizeMake([RCTipMessageCell getMaxLabelWidth], MAXFLOAT)];
        CGRect frame = CGRectMake((self.baseContentView.bounds.size.width - labelSize.width - buttonTitleSize.width) / 2.0f - 5, 0, labelSize.width + 10 + buttonTitleSize.width, labelSize.height);
        self.reeditLabel.frame = CGRectMake(frame.size.width - buttonTitleSize.width - 7, 1, buttonTitleSize.width, 22);
        self.tipMessageLabel.frame = frame;
        self.tipMessageLabel.textAlignment = NSTextAlignmentLeft;
        self.tipMessageLabel.text = [NSString stringWithFormat:@"  %@", self.tipMessageLabel.text];
        [self.tipMessageLabel addSubview:self.reeditLabel];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateRecallStatus:)
                                                     name:RCKitNeedUpdateRecallStatusNotification
                                                   object:nil];
    } else {
        self.tipMessageLabel.textAlignment = NSTextAlignmentCenter;
        self.tipMessageLabel.frame = CGRectMake((self.baseContentView.bounds.size.width - labelSize.width) / 2.0f - 5, 0, labelSize.width + 10, labelSize.height);
    }
}

#pragma mark - RCAttributedLabelDelegate

- (void)attributedLabel:(RCAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    NSString *urlString = [url absoluteString];
    urlString = [RCKitUtility checkOrAppendHttpForUrl:urlString];
    if ([self.delegate respondsToSelector:@selector(didTapUrlInMessageCell:model:)]) {
        [self.delegate didTapUrlInMessageCell:urlString model:self.model];
        return;
    }
}

- (void)attributedLabel:(RCAttributedLabel *)label didSelectLinkWithAddress:(NSDictionary *)addressComponents {
}

- (void)attributedLabel:(RCAttributedLabel *)label didSelectLinkWithPhoneNumber:(NSString *)phoneNumber {
    if (!phoneNumber) {
        DebugLog(@"didSelectLinkWithPhoneNumber phoneNumber is nil");
        return;
    }
    NSString *number = [@"tel://" stringByAppendingString:phoneNumber];
    if ([self.delegate respondsToSelector:@selector(didTapPhoneNumberInMessageCell:model:)]) {
        [self.delegate didTapPhoneNumberInMessageCell:number model:self.model];
        return;
    }
}

- (void)attributedLabel:(RCAttributedLabel *)label didTapLabel:(NSString *)content {
    if ([self.delegate respondsToSelector:@selector(didTapMessageCell:)]) {
        [self.delegate didTapMessageCell:self.model];
    }
}

#pragma mark - Private Methods
+ (CGSize)getTipLabelSize:(RCMessageModel *)model{
    RCMessageContent *notification = model.content;
    NSString *localizedMessage = [RCKitUtility formatMessage:notification
                                                    targetId:model.targetId
                                            conversationType:model.conversationType
                                                isAllMessage:YES];
    CGSize textSize = [RCKitUtility getTextDrawingSize:localizedMessage
                                                    font:[[RCKitConfig defaultConfig].font fontOfFourthLevel]
                                         constrainedSize:CGSizeMake([self getMaxLabelWidth], MAXFLOAT)];
    textSize = CGSizeMake(ceilf(textSize.width), ceilf(textSize.height));
    CGSize labelSize = CGSizeMake(textSize.width + 10, textSize.height + 6);
    return labelSize;
}

+ (CGFloat)getMaxLabelWidth{
    return SCREEN_WIDTH - 30 * 2;
}

- (void)reeditAction:(UITapGestureRecognizer *)gestureRecognizer {
    if ([gestureRecognizer state] != UIGestureRecognizerStateEnded) {
        return;
    }
    if ([self.delegate respondsToSelector:@selector(didTapReedit:)]) {
        [self.delegate didTapReedit:self.model];
    }
}

- (NSMutableSet *)getRelatedUserIdList:(RCMessageContent *)content {
    if ([content isKindOfClass:[RCDiscussionNotificationMessage class]]) {
        RCDiscussionNotificationMessage *messageContent = (RCDiscussionNotificationMessage *)content;
        NSMutableSet *relatedUserIdList = [[NSMutableSet alloc] init];
        if (messageContent.operatorId) {
            [relatedUserIdList addObject:messageContent.operatorId];
        }

        if (messageContent.type == RCInviteDiscussionNotification ||
            messageContent.type == RCRemoveDiscussionMemberNotification) {
            NSArray *targetUserList = [[messageContent.extension
                stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
                componentsSeparatedByString:@","];
            if (targetUserList && targetUserList.count > 0) {
                [relatedUserIdList addObjectsFromArray:targetUserList];
            }
        }
        return relatedUserIdList;
    } else if ([content isKindOfClass:[RCRecallNotificationMessage class]]) {
        RCRecallNotificationMessage *messageContent = (RCRecallNotificationMessage *)content;
        NSMutableSet *relatedUserIdList = [[NSMutableSet alloc] init];
        if (messageContent.operatorId) {
            [relatedUserIdList addObject:messageContent.operatorId];
        }
        return relatedUserIdList;
    } else {
        return nil;
    }
}

- (void)onUserInfoUpdate:(NSNotification *)notification {
    NSDictionary *userInfoDic = notification.object;

    //    RCUserInfo *userInfo = userInfoDic[@"userInfo"];
    if ([self.relatedUserIdList containsObject:userInfoDic[@"userId"]]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setDataModel:self.model];
        });
    }
}

- (void)updateRecallStatus:(NSNotification *)notification {
    NSDictionary *dict = notification.object;
    long messageId = [dict[@"messageId"] longValue];
    if (messageId == self.model.messageId) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] removeObserver:self
                                                            name:RCKitNeedUpdateRecallStatusNotification
                                                          object:nil];
            [self setDataModel:self.model];
        });
    }
}

// 判断是否可以重新编辑，可编辑时间从 RCIM 中的 reeditDuration 获取
- (BOOL)canReeditMessage {
    RCRecallNotificationMessage *recallMessage = (RCRecallNotificationMessage *)self.model.content;
    long long cTime = [[NSDate date] timeIntervalSince1970] * 1000;
    long long interval = cTime - recallMessage.recallActionTime;
    BOOL canReedit = NO;
    NSUInteger reeditDuration = RCKitConfigCenter.message.reeditDuration * 1000;
    if (reeditDuration > 0 && interval > 0 && interval <= reeditDuration &&
        (self.messageDirection == MessageDirection_SEND)) {
        canReedit = YES;
        [[RCReeditMessageManager defaultManager] addReeditDuration:interval messageId:self.model.messageId];
    }
    return canReedit;
}

#pragma mark - Getter
- (RCTipLabel *)tipMessageLabel{
    if (!_tipMessageLabel) {
        _tipMessageLabel = [RCTipLabel greyTipLabel];
        _tipMessageLabel.backgroundColor =
            [RCKitUtility generateDynamicColor:HEXCOLOR(0xc9c9c9) darkColor:HEXCOLOR(0x232323)];
        _tipMessageLabel.textColor = RCDYCOLOR(0xffffff, 0x707070);
        _tipMessageLabel.delegate = self;
        _tipMessageLabel.userInteractionEnabled = YES;
        _tipMessageLabel.marginInsets = UIEdgeInsetsMake(0.5f, 0.5f, 0.5f, 0.5f);
    }
    return _tipMessageLabel;
}

- (UILabel *)reeditLabel{
    if (!_reeditLabel) {
        _reeditLabel = [[UILabel alloc] init];
        _reeditLabel.text = RCLocalizedString(@"RecallEdit");
        _reeditLabel.userInteractionEnabled = YES;
        _reeditLabel.textColor = RCDYCOLOR(0x0099ff, 0x0099ff);
        _reeditLabel.font = [[RCKitConfig defaultConfig].font fontOfFourthLevel];
        UITapGestureRecognizer *tapGestureRecognizer =
            [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(reeditAction:)];
        [_reeditLabel addGestureRecognizer:tapGestureRecognizer];
    }
    return _reeditLabel;
}

@end
