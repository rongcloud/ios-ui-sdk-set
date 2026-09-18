//
//  RCSendCardMessageView.m
//  RongContactCard
//
//  Created by Jue on 2016/12/19.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCSendCardMessageView.h"
#import "UIColor+RCCCColor.h"
#import "RCCCUtilities.h"
#import "RCContactCardMessage.h"
#import "RCCCExtensionModule.h"
#import "RCloudImageView.h"
#import "RongContactCardAdaptiveHeader.h"
NSString *const RCCC_CardMessageSend = @"RCCC_CardMessageSend";

@interface RCSendCardMessageView ()

@property (nonatomic, strong) RCBaseView *contentView;
@property (nonatomic, strong) RCBaseLabel *sendToLabel;
@property (nonatomic, strong) RCloudImageView *portraitView;
@property (nonatomic, strong) RCBaseLabel *nicknameLabel;
@property (nonatomic, strong) UIView *separationView1;
@property (nonatomic, strong) RCBaseLabel *cardLabel;
@property (nonatomic, strong) UITextField *messageTextField;
@property (nonatomic, strong) UIView *separationView2;
@property (nonatomic, strong) UIView *separationView3;
@property (nonatomic, strong) RCBaseButton *cancleButton;
@property (nonatomic, strong) RCBaseButton *sendButton;
@property (nonatomic, strong) NSDictionary *subViewsDic;
@property (nonatomic) RCConversationType conversationType;
@property (nonatomic, strong) NSString *targetId;

@property (nonatomic, strong) RCCCGroupInfo *groupInfo;

@property (nonatomic, assign) NSInteger destructDuration;
@property (nonatomic, strong) RCBaseImageView *arrow;
@end

@implementation RCSendCardMessageView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (id)initWithFrame:(CGRect)frame ConversationType:(RCConversationType)conversationType targetId:(NSString *)targetId {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithHexString:@"000000" alpha:0.4];

        [self setSubViews];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillShow:)
                                                     name:UIKeyboardWillShowNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillHide:)
                                                     name:UIKeyboardWillHideNotification
                                                   object:nil];
        [self setConversationType:conversationType targetId:targetId];
    }
    return self;
}

- (void)setSubViews {
    _contentView = [[RCBaseView alloc] initWithFrame:CGRectMake(0, 0, 280, 280)];
    _contentView.center = self.center;
    _contentView.backgroundColor = [RCKitUtility generateDynamicColor:[UIColor colorWithHexString:@"ffffff" alpha:1] darkColor:HEXCOLOR(0x2c2c2c)];
    _contentView.layer.masksToBounds = YES;
    _contentView.layer.cornerRadius = 8;
    [self addSubview:_contentView];

    //发送给：
    _sendToLabel = [[RCBaseLabel alloc] initWithFrame:CGRectZero];
    _sendToLabel.font = [UIFont systemFontOfSize:18.f];
    _sendToLabel.textColor = [RCKitUtility generateDynamicColor:[UIColor colorWithHexString:@"000000" alpha:1]
                                                      darkColor:[UIColor colorWithHexString:@"ffffff" alpha:0.9]];
    _sendToLabel.text = RCLocalizedString(@"SendTo");
    //[_sendToLabel sizeToFit];
    _sendToLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_contentView addSubview:_sendToLabel];

    //头像
    _portraitView = [[RCloudImageView alloc] initWithFrame:CGRectZero];
    if (RCKitConfigCenter.ui.globalConversationAvatarStyle == RC_USER_AVATAR_CYCLE &&
        RCKitConfigCenter.ui.globalMessageAvatarStyle == RC_USER_AVATAR_CYCLE) {
        _portraitView.layer.cornerRadius = 20.f;
    } else {
        _portraitView.layer.cornerRadius = 5.f;
    }
    _portraitView.layer.masksToBounds = YES;
    _portraitView.translatesAutoresizingMaskIntoConstraints = NO;
    [_contentView addSubview:_portraitView];
    [_portraitView setPlaceholderImage:[RCCCUtilities imageNamed:@"default_portrait_msg" ofBundle:@"RongCloud.bundle"]];

    //昵称
    _nicknameLabel = [[RCBaseLabel alloc] initWithFrame:CGRectZero];
    _nicknameLabel.font = [UIFont systemFontOfSize:17.f];
    _nicknameLabel.textColor = [RCKitUtility generateDynamicColor:[UIColor colorWithHexString:@"000000" alpha:1] darkColor:[UIColor colorWithHexString:@"ffffff" alpha:0.9]];
    _nicknameLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    _nicknameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_contentView addSubview:_nicknameLabel];

    //分割线1
    _separationView1 = [[UIView alloc] initWithFrame:CGRectZero];
    _separationView1.backgroundColor =
        [RCKitUtility generateDynamicColor:[UIColor colorWithHexString:@"dfdfdf" alpha:1]
                                 darkColor:[UIColor colorWithHexString:@"373737" alpha:1]];
    _separationView1.translatesAutoresizingMaskIntoConstraints = NO;
    [_contentView addSubview:_separationView1];

    //个人名片
    _cardLabel = [[RCBaseLabel alloc] initWithFrame:CGRectZero];
    _cardLabel.font = [UIFont systemFontOfSize:14.f];
    _cardLabel.textColor = [RCKitUtility generateDynamicColor:[UIColor colorWithHexString:@"999999" alpha:1] darkColor:[UIColor colorWithHexString:@"ffffff" alpha:0.6]];
    _cardLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_contentView addSubview:_cardLabel];

    //留言
    _messageTextField = [[UITextField alloc] initWithFrame:CGRectZero];
    _messageTextField.font = [UIFont systemFontOfSize:13.f];
    _messageTextField.backgroundColor = RCDYCOLOR(0xf3f3f3, 0x363636);
    _messageTextField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 36)];
    _messageTextField.leftViewMode = UITextFieldViewModeAlways;
    _messageTextField.textColor = [RCKitUtility generateDynamicColor:[UIColor colorWithHexString:@"000000" alpha:1] darkColor:[UIColor colorWithHexString:@"ffffff" alpha:0.4]];
    NSAttributedString *attrString = [[NSAttributedString alloc]
        initWithString:RCLocalizedString(@"LeaveAMessage")
            attributes:@{
                NSForegroundColorAttributeName :RCDYCOLOR(0xa0a5ab, 0x666666),
                NSFontAttributeName : _messageTextField.font
            }];
    _messageTextField.attributedPlaceholder = attrString;
    _messageTextField.translatesAutoresizingMaskIntoConstraints = NO;
    [_contentView addSubview:_messageTextField];

    //分割线2
    _separationView2 = [[UIView alloc] initWithFrame:CGRectZero];
    _separationView2.backgroundColor =
        [RCKitUtility generateDynamicColor:[UIColor colorWithHexString:@"dfdfdf" alpha:1]
                                 darkColor:[UIColor colorWithHexString:@"373737" alpha:1]];
    _separationView2.translatesAutoresizingMaskIntoConstraints = NO;
    [_contentView addSubview:_separationView2];

    //分割线3
    _separationView3 = [[UIView alloc] initWithFrame:CGRectZero];
    _separationView3.backgroundColor =
        [RCKitUtility generateDynamicColor:[UIColor colorWithHexString:@"dfdfdf" alpha:1]
                                 darkColor:[UIColor colorWithHexString:@"323232" alpha:1]];
    _separationView3.translatesAutoresizingMaskIntoConstraints = NO;
    [_contentView addSubview:_separationView3];

    //取消按钮
    _cancleButton = [[RCBaseButton alloc] initWithFrame:CGRectZero];
    _cancleButton.titleLabel.font = [UIFont systemFontOfSize:18.f];
    [_cancleButton setTitleColor:[RCKitUtility generateDynamicColor:[UIColor colorWithHexString:@"000000" alpha:1]
                                                          darkColor:[UIColor colorWithHexString:@"aaaaaa" alpha:1]]
                        forState:UIControlStateNormal];
    [_cancleButton setTitle:RCLocalizedString(@"Cancel") forState:UIControlStateNormal];
    [_cancleButton addTarget:self action:@selector(clickCancleBtn) forControlEvents:UIControlEventTouchUpInside];
    _cancleButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_contentView addSubview:_cancleButton];

    //发送按钮
    _sendButton = [[RCBaseButton alloc] initWithFrame:CGRectZero];
    _sendButton.titleLabel.font = [UIFont systemFontOfSize:18.f];
    [_sendButton setTitleColor:[UIColor colorWithHexString:@"0099ff" alpha:1.f] forState:UIControlStateNormal];
    [_sendButton setTitle:RCLocalizedString(@"Send") forState:UIControlStateNormal];
    [_sendButton addTarget:self action:@selector(clickSendBtn) forControlEvents:UIControlEventTouchUpInside];
    _sendButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_contentView addSubview:_sendButton];
    
    _arrow = [RCBaseImageView new];
    _arrow.translatesAutoresizingMaskIntoConstraints = NO;
    [_contentView addSubview:_arrow];

    _subViewsDic = NSDictionaryOfVariableBindings(_contentView, _sendToLabel, _portraitView, _nicknameLabel,
                                                  _separationView1, _cardLabel, _messageTextField, _separationView2,
                                                  _separationView3, _cancleButton, _sendButton, _arrow);

    //设置自动布局
    [self setAutoLayout];
}

- (void)setAutoLayout {
    [_contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-20-[_sendToLabel]"
                                                                         options:0
                                                                         metrics:nil
                                                                           views:_subViewsDic]];

    [_contentView addConstraints:[NSLayoutConstraint
                                     constraintsWithVisualFormat:@"H:|-20-[_portraitView(40)]-10-[_nicknameLabel]-(>=10)-[_arrow(8)]-24-|"
                                                         options:0
                                                         metrics:nil
                                                           views:_subViewsDic]];

    [_contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-20-[_separationView1]-20-|"
                                                                         options:0
                                                                         metrics:nil
                                                                           views:_subViewsDic]];

    [_contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-20-[_cardLabel]-20-|"
                                                                         options:0
                                                                         metrics:nil
                                                                           views:_subViewsDic]];

    [_contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-20-[_messageTextField]-20-|"
                                                                         options:0
                                                                         metrics:nil
                                                                           views:_subViewsDic]];

    [_contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_separationView2]|"
                                                                         options:0
                                                                         metrics:nil
                                                                           views:_subViewsDic]];

    CGFloat buttonWidth = 280 / 2.f - 0.25;
    [_contentView addConstraints:[NSLayoutConstraint
                                     constraintsWithVisualFormat:
                                         @"H:|[_cancleButton(width)]-0-[_separationView3(0.5)]-0-[_sendButton(width)]"
                                                         options:0
                                                         metrics:@{
                                                             @"width" : @(buttonWidth)
                                                         }
                                                           views:_subViewsDic]];

    [_contentView
        addConstraints:[NSLayoutConstraint
                           constraintsWithVisualFormat:@"V:|-20-[_sendToLabel]-12-[_portraitView(40)]-14-[_"
                                                       @"separationView1(0.5)]-14-[_cardLabel]-14-[_messageTextField("
                                                       @"36)]-29.5-[_separationView2(0.5)]-0-[_cancleButton(56)]|"
                                               options:0
                                               metrics:nil
                                                 views:_subViewsDic]];

    [_contentView addConstraint:[NSLayoutConstraint constraintWithItem:_nicknameLabel
                                                             attribute:NSLayoutAttributeCenterY
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:_portraitView
                                                             attribute:NSLayoutAttributeCenterY
                                                            multiplier:1
                                                              constant:0]];
    [_contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_nicknameLabel(20)]"
                                                                         options:0
                                                                         metrics:nil
                                                                           views:_subViewsDic]];
    [_contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_arrow(15)]"
                                                                         options:0
                                                                         metrics:nil
                                                                           views:_subViewsDic]];
    [_contentView addConstraint:[NSLayoutConstraint constraintWithItem:_arrow
                                                             attribute:NSLayoutAttributeCenterY
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:_nicknameLabel
                                                             attribute:NSLayoutAttributeCenterY
                                                            multiplier:1
                                                              constant:0]];
    [_contentView addConstraint:[NSLayoutConstraint constraintWithItem:_separationView3
                                                             attribute:NSLayoutAttributeTop
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:_cancleButton
                                                             attribute:NSLayoutAttributeTop
                                                            multiplier:1
                                                              constant:0]];
    [_contentView addConstraint:[NSLayoutConstraint constraintWithItem:_separationView3
                                                             attribute:NSLayoutAttributeBottom
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:_cancleButton
                                                             attribute:NSLayoutAttributeBottom
                                                            multiplier:1
                                                              constant:0]];

    [_contentView addConstraint:[NSLayoutConstraint constraintWithItem:_sendButton
                                                             attribute:NSLayoutAttributeTop
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:_cancleButton
                                                             attribute:NSLayoutAttributeTop
                                                            multiplier:1
                                                              constant:0]];
    [_contentView addConstraint:[NSLayoutConstraint constraintWithItem:_sendButton
                                                             attribute:NSLayoutAttributeBottom
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:_cancleButton
                                                             attribute:NSLayoutAttributeBottom
                                                            multiplier:1
                                                              constant:0]];
}

- (void)clickCancleBtn {
    [self removeFromSuperview];
}

- (void)clickSendBtn {
    self.sendButton.userInteractionEnabled = NO;
    RCContactCardMessage *cardMessage = [RCContactCardMessage messageWithUserInfo:_cardUserInfo];
    RCUserInfo *currentUserInfo = [RCIM sharedRCIM].currentUserInfo;
    cardMessage.sendUserId = currentUserInfo.userId;
    cardMessage.sendUserName = currentUserInfo.name;
    RCMessage *message = [[RCMessage alloc] initWithType:_conversationType targetId:_targetId direction:MessageDirection_SEND content:cardMessage];
    NSString *tail = [NSString stringWithFormat:RCLocalizedString(@"RecommendedToYou"), _cardUserInfo.name];
    NSString *pushTitle = @"";
    NSString *pushContent = nil;
    if (_conversationType == ConversationType_GROUP) {
        pushTitle = _groupInfo.groupName;
        pushContent = [NSString stringWithFormat:@"%@%@", cardMessage.sendUserName, tail];
    } else {
        pushTitle = cardMessage.sendUserName;
        pushContent = [NSString stringWithFormat:@"%@", tail];
    }
    message.messagePushConfig.pushTitle = pushTitle;
    message.messagePushConfig.pushContent = pushContent;
    message.needReceipt = YES;
    if (self.destructDuration > 0) {
        cardMessage.destructDuration = self.destructDuration;
    }
    __weak typeof(self) ws = self;
    [[RCIM sharedRCIM] sendMessage:message pushContent:nil pushData:nil successBlock:^(RCMessage *successMessage) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [ws performSelector:@selector(sendTextMessageIfNeed) withObject:nil afterDelay:0.2];
        });
        [ws dealWithWhenSendComplete];
    } errorBlock:^(RCErrorCode nErrorCode, RCMessage *errorMessage) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [ws performSelector:@selector(sendTextMessageIfNeed) withObject:nil afterDelay:0.2];
        });
        [ws gotoConversationVC];
        [ws dealWithWhenSendComplete];
    }];
}

- (void)dealWithWhenSendComplete {
    if ([[RCContactCardKit shareInstance].contactVCDelegate respondsToSelector:@selector(clickSendContactCardButton)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[RCContactCardKit shareInstance].contactVCDelegate clickSendContactCardButton];
            [self removeFromSuperview];
        });
    } else {
        [self gotoConversationVC];
    }
}

- (void)gotoConversationVC {

    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:RCCC_CardMessageSend object:nil];
        [self removeFromSuperview];
    });
}

- (void)sendTextMessageIfNeed {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_messageTextField.text.length > 0) {
            RCTextMessage *textMessage = [RCTextMessage messageWithContent:_messageTextField.text];
            if (self.destructDuration > 0) {
                textMessage.destructDuration = self.destructDuration;
            }
            [[RCIM sharedRCIM] sendMessage:_conversationType
                targetId:_targetId
                content:textMessage
                pushContent:nil
                pushData:nil
                success:^(long messageId) {

                }
                error:^(RCErrorCode nErrorCode, long messageId){

                }];
        }
    });
}

- (void)setConversationType:(RCConversationType)conversationType targetId:(NSString *)targetId {
    if (conversationType > 0 && targetId.length > 0) {
        _conversationType = conversationType;
        _targetId = targetId;
        if (conversationType == ConversationType_PRIVATE) {
            RCUserInfo *userInfo = [[RCIM sharedRCIM] getUserInfoCache:_targetId];
            _nicknameLabel.text = userInfo.name;
            [_portraitView setImageURL:[NSURL URLWithString:userInfo.portraitUri]];
        }
        if (conversationType == ConversationType_GROUP) {
            __weak typeof(self) ws = self;
            if ([self canSendContactCardMessageInGroup]) {
                [[RCContactCardKit shareInstance]
                        .groupDataSource getGroupInfoByGroupId:_targetId
                                                        result:^(RCCCGroupInfo *groupInfo) {
                                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                                [ws updateGroupInfo:groupInfo];
                                                            });
                                                        }];
            }
        }
    }
    if (_conversationType == ConversationType_PRIVATE) {
        self.arrow.hidden = YES;
    }
}
- (void)updateGroupInfo:(RCCCGroupInfo *)groupInfo {
    self.groupInfo = groupInfo;
    [self.portraitView setImageURL:[NSURL URLWithString:groupInfo.portraitUri]];
    self.nicknameLabel.text = [NSString stringWithFormat:@"%@ (%@%@)", groupInfo.groupName, groupInfo.number,
                                                         RCLocalizedString(@"Person")];
}

- (BOOL)canSendContactCardMessageInGroup {
    BOOL result =
        [RCContactCardKit shareInstance].groupDataSource &&
        [[RCContactCardKit shareInstance].groupDataSource respondsToSelector:@selector(getGroupInfoByGroupId:result:)];
    if (!result) {
        NSLog(@"Error:Send contact card message in group, must be implemented  RCCCGroupDataSource of RCContactCardKit");
    }
    return result;
}

- (void)setCardUserInfo:(RCUserInfo *)cardUserInfo {
    _cardUserInfo = cardUserInfo;
    _cardLabel.text =
        [NSString stringWithFormat:@"[%@]%@", RCLocalizedString(@"ContactCard"),
                                   cardUserInfo.name];
    _cardUserInfo.name = cardUserInfo.name;
}

- (void)setTargetUserInfo:(RCCCUserInfo *)targetUserInfo {
    _targetUserInfo = targetUserInfo;
    if (targetUserInfo.displayName.length > 0) {
        _nicknameLabel.text = targetUserInfo.displayName;
    } else {
        _nicknameLabel.text = targetUserInfo.name;
    }
    [_portraitView setImageURL:[NSURL URLWithString:targetUserInfo.portraitUri]];
    self.conversationType = ConversationType_PRIVATE;
    self.targetId = targetUserInfo.userId;
}

- (void)setTargetgroupInfo:(RCCCGroupInfo *)targetgroupInfo {
    self.groupInfo = targetgroupInfo;
    self.nicknameLabel.text =
        [NSString stringWithFormat:@"%@ (%@%@)", targetgroupInfo.groupName, targetgroupInfo.number,
                                   RCLocalizedString(@"Person")];
    [_portraitView setImageURL:[NSURL URLWithString:targetgroupInfo.portraitUri]];
    self.conversationType = ConversationType_GROUP;
    self.targetId = targetgroupInfo.groupId;
}

- (void)addTapGestureForSelf {
    self.userInteractionEnabled = YES;
    UITapGestureRecognizer *clickSelf =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickSelf)];
    [self addGestureRecognizer:clickSelf];
}

- (void)clickSelf {
    if ([_messageTextField isFirstResponder]) {
        [_messageTextField resignFirstResponder];
    }
}

//键盘将要弹起时，修改subviews的坐标
- (void)keyboardWillShow:(NSNotification *)notif {
    if (self.hidden == YES) {
        return;
    }

    CGRect rect = [[notif.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat y = rect.origin.y;
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.25];
    NSArray *subviews = [self subviews];
    for (UIView *sub in subviews) {

        CGFloat maxY = CGRectGetMaxY(sub.frame);
        if (maxY > y - 2) {
            sub.center = CGPointMake(CGRectGetWidth(self.frame) / 2.0, sub.center.y - maxY + y - 2);
        }
    }
    [UIView commitAnimations];

    //为黑色背景添加点击收起键盘的手势
    [self addTapGestureForSelf];
}

//键盘将要收起时，修改subviews的坐标
- (void)keyboardWillHide:(NSNotification *)notif {
    if (self.hidden == YES) {
        return;
    }
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.25];
    NSArray *subviews = [self subviews];
    for (UIView *sub in subviews) {
        if (sub.center.y < CGRectGetHeight(self.frame) / 2.0) {
            sub.center = CGPointMake(CGRectGetWidth(self.frame) / 2.0, CGRectGetHeight(self.frame) / 2.0);
        }
    }
    [UIView commitAnimations];
}

- (UIImage *)imageflippedForRTL:(UIImage *)image{
    if (@available(iOS 9.0, *)) {
        if ([RCKitUtility isRTL]) {
            return [UIImage imageWithCGImage:image.CGImage
                                       scale:image.scale
                                 orientation:UIImageOrientationUpMirrored];
        }
    }
    return image;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
