//
//  RCContactCardMessageCell.m
//  RongContactCard
//
//  Created by Sin on 16/8/19.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCContactCardMessageCell.h"
#import "RCContactCardMessage.h"
#import "UIColor+RCCCColor.h"
#import "RCCCUtilities.h"
#import "RCloudImageView.h"
#import "RCUserInfoCacheManager.h"
#define Cart_Message_Cell_Height 93
#define Cart_Portrait_View_Width 40


@interface RCContactCardMessageCell ()
@property (nonatomic, strong) NSMutableArray *messageContentConstraint;

@property (nonatomic, strong) RCBaseLabel *typeLabel;     //个人名片的字样
@property (nonatomic, strong) UIView *separationView; //分割线
@property (nonatomic, assign) BOOL isConversationAppear;
@end

@implementation RCContactCardMessageCell

+ (CGSize)sizeForMessageModel:(RCMessageModel *)model
      withCollectionViewWidth:(CGFloat)collectionViewWidth
         referenceExtraHeight:(CGFloat)extraHeight {
    CGFloat messagecontentview_height = Cart_Message_Cell_Height;
    if (messagecontentview_height < RCKitConfigCenter.ui.globalMessagePortraitSize.height) {
        messagecontentview_height = RCKitConfigCenter.ui.globalMessagePortraitSize.height;
    }
    messagecontentview_height += extraHeight;
    return CGSizeMake(collectionViewWidth, messagecontentview_height);
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    self.messageContentConstraint = [[NSMutableArray alloc] init];
    [self showBubbleBackgroundView:YES];

    //头像imageView
    self.portraitView = [[RCloudImageView alloc] initWithFrame:CGRectZero];
    [self.messageContentView addSubview:self.portraitView];
    self.portraitView.translatesAutoresizingMaskIntoConstraints = YES;
    self.portraitView.layer.masksToBounds = YES;
    if (RCKitConfigCenter.ui.globalConversationAvatarStyle == RC_USER_AVATAR_CYCLE &&
        RCKitConfigCenter.ui.globalMessageAvatarStyle == RC_USER_AVATAR_CYCLE) {
        self.portraitView.layer.cornerRadius = Cart_Portrait_View_Width/2;
    } else {
        self.portraitView.layer.cornerRadius = 5.f;
    }
    [self.portraitView
        setPlaceholderImage:[RCCCUtilities imageNamed:@"default_portrait_msg" ofBundle:@"RongCloud.bundle"]];

    //昵称label
    self.nameLabel = [[RCBaseLabel alloc] initWithFrame:CGRectZero];
    [self.nameLabel setFont:[UIFont systemFontOfSize:17.f]];
    [self.messageContentView addSubview:self.nameLabel];
    self.nameLabel.translatesAutoresizingMaskIntoConstraints = YES;
    self.nameLabel.textColor = [RCKitUtility generateDynamicColor:[UIColor colorWithHexString:@"262626" alpha:1] darkColor:[UIColor colorWithHexString:@"ffffff" alpha:0.8]];
    self.nameLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;

    //分割线
    self.separationView = [[UIView alloc] initWithFrame:CGRectZero];
    self.separationView.backgroundColor =
        [RCKitUtility generateDynamicColor:[UIColor colorWithHexString:@"ededed" alpha:1]
                                 darkColor:[UIColor colorWithHexString:@"373737" alpha:1]];
    self.separationView.translatesAutoresizingMaskIntoConstraints = YES;
    [self.messageContentView addSubview:self.separationView];

    // typeLabel
    self.typeLabel = [[RCBaseLabel alloc] initWithFrame:CGRectZero];
    self.typeLabel.text = RCLocalizedString(@"ContactCard");
    self.typeLabel.font = [UIFont systemFontOfSize:12.f];
    self.typeLabel.textColor = [RCKitUtility generateDynamicColor:[UIColor colorWithHexString:@"939393" alpha:1] darkColor:[UIColor colorWithHexString:@"ffffff" alpha:0.4]];
    [self.messageContentView addSubview:self.typeLabel];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateCell:)
                                                 name:@"RCKitDispatchUserInfoUpdateNotification"
                                               object:nil];
}

- (void)updateCell:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *userInfoDic = notification.object;
        NSString *userId = userInfoDic[@"userId"];
        RCContactCardMessage *cardMessage = (RCContactCardMessage *)self.model.content;
        if ([userId isEqualToString:cardMessage.userId]) {
            RCUserInfo *userInfo = [[RCIM sharedRCIM] getUserInfoCache:userId];
            NSString *portraitUri = userInfo.portraitUri;
            [self.portraitView setImageURL:[NSURL URLWithString:portraitUri]];
        }
    });
}

- (void)setDataModel:(RCMessageModel *)model {
    [super setDataModel:model];
    [self beginDestructing];
    [self setAutoLayout];
}

- (void)setAutoLayout {
    RCContactCardMessage *cardMessage = (RCContactCardMessage *)self.model.content;
    if (cardMessage) {
        self.nameLabel.text = cardMessage.name;
        NSString *portraitUri = cardMessage.portraitUri;
        if (portraitUri.length < 1) {
            RCUserInfo *userInfo = [[RCIM sharedRCIM] getUserInfoCache:cardMessage.userId];
            if (userInfo == nil || userInfo.portraitUri.length < 1) {
                [[RCUserInfoCacheManager sharedManager] getUserInfo:cardMessage.userId complete:^(RCUserInfo * _Nonnull userInfo) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.portraitView setImageURL:[NSURL URLWithString:userInfo.portraitUri]];
                    });
                }];
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.portraitView setImageURL:[NSURL URLWithString:userInfo.portraitUri]];
                });
            }
        } else {
            [self.portraitView setImageURL:[NSURL URLWithString:portraitUri]];
        }
    }
    CGSize size = [[self class] sizeOfMessageCell];
    self.messageContentView.contentSize = size;
    self.typeLabel.accessibilityLabel = @"typeLabel";
    self.nameLabel.accessibilityLabel  = @"nameLabel";
    self.portraitView.accessibilityLabel  = @"portraitView";
    if ([RCKitUtility isRTL]) {
        self.portraitView.frame = CGRectMake(size.width - Cart_Portrait_View_Width- 12, 10, Cart_Portrait_View_Width, Cart_Portrait_View_Width);
        self.nameLabel.frame = CGRectMake(12, 17.5,  self.portraitView.frame.origin.x - 24 , 25);
        self.separationView.frame = CGRectMake(CGRectGetMinX(self.nameLabel.frame),CGRectGetMaxY(self.portraitView.frame)+12, self.messageContentView.frame.size.width - 12 * 2, 0.5);
        self.typeLabel.frame = CGRectMake(CGRectGetMinX(self.separationView.frame),CGRectGetMaxY(self.portraitView.frame)+16.5, self.separationView.frame.size.width, 16.5);
    } else {
        self.portraitView.frame = CGRectMake(12, 10, Cart_Portrait_View_Width, Cart_Portrait_View_Width);
        self.nameLabel.frame = CGRectMake(CGRectGetMaxX(self.portraitView.frame)+12, 17.5, 100, 25);
        self.separationView.frame = CGRectMake(CGRectGetMinX(self.portraitView.frame),CGRectGetMaxY(self.portraitView.frame)+12, self.messageContentView.frame.size.width - 12 * 2, 0.5);
        self.typeLabel.frame = CGRectMake(CGRectGetMinX(self.portraitView.frame),CGRectGetMaxY(self.portraitView.frame)+16.5, self.separationView.frame.size.width, 16.5);
    }
}

- (void)beginDestructing {
    RCContactCardMessage *cardMessage = (RCContactCardMessage *)self.model.content;
    if (self.model.messageDirection == MessageDirection_RECEIVE && cardMessage.destructDuration > 0 &&
        [UIApplication sharedApplication].applicationState != UIApplicationStateBackground &&
        self.isConversationAppear) {
        [[RCCoreClient sharedCoreClient]
            messageBeginDestruct:[[RCCoreClient sharedCoreClient] getMessageByUId:self.model.messageUId]];
    }
}

+ (CGSize)sizeOfMessageCell {
    return CGSizeMake([RCMessageCellTool getMessageContentViewMaxWidth], Cart_Message_Cell_Height);
}

@end
