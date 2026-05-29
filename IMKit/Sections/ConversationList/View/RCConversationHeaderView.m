//
//  RCConversationHeaderView.m
//  RongIMKit
//
//  Created by 岑裕 on 16/9/15.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCConversationHeaderView.h"
#import "RCIM.h"
#import "RCKitCommonDefine.h"
#import "RCKitUtility.h"
#import "RCKitConfig.h"

@implementation RCConversationHeaderView
#pragma mark - Life Cycle
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initSubviewsLayout];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initSubviewsLayout];
    }
    return self;
}

- (void)initSubviewsLayout {
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.backgroundColor = [UIColor clearColor];

    [self addSubview:self.backgroundView];
    [self.backgroundView addSubview:self.headerImageView];
    self.headerImageStyle = RCKitConfigCenter.ui.globalConversationAvatarStyle;

    
    if ([RCKitUtility isRTL]) {
        self.bubbleView =
        [[RCMessageBubbleTipView alloc] initWithParentView:self
                                                 alignment:RC_MESSAGE_BUBBLE_TIP_VIEW_ALIGNMENT_TOP_LEFT];
    } else {
        self.bubbleView =
        [[RCMessageBubbleTipView alloc] initWithParentView:self
                                                 alignment:RC_MESSAGE_BUBBLE_TIP_VIEW_ALIGNMENT_TOP_RIGHT];
    }
    self.bubbleView.bubbleTipBackgroundColor = HEXCOLOR(0xf43530);
    
    [self addSubviewConstraints];
}

- (void)setHeaderImageStyle:(RCUserAvatarStyle)headerImageStyle {
    _headerImageStyle = headerImageStyle;
    if (_headerImageStyle == RC_USER_AVATAR_RECTANGLE) {
        self.headerImageView.layer.cornerRadius = [RCKitConfigCenter.ui portraitImageViewCornerRadius];
    } else if (_headerImageStyle == RC_USER_AVATAR_CYCLE) {
        self.headerImageView.layer.cornerRadius = [RCKitConfigCenter.ui globalConversationPortraitSize].height / 2;
    }
}

- (void)updateBubbleUnreadNumber:(int)unreadNumber {
    [self.bubbleView setBubbleTipNumber:unreadNumber];
}

- (void)resetDefaultLayout:(RCConversationModel *)reuseModel {
    UIImage *placeholderImage = nil;
    UIImage *cachedImage = [self getCachedImage:reuseModel];
    if (cachedImage) {
        placeholderImage = cachedImage;
    } else {
        placeholderImage = [RCKitUtility defaultConversationHeaderImage:reuseModel];
    }
    [self.headerImageView setPlaceholderImage:placeholderImage];
    self.bubbleView.isShowNotificationNumber = YES;
}

- (UIImage *)getCachedImage:(RCConversationModel *)reuseModel {
    if (reuseModel.conversationModelType == RC_CONVERSATION_MODEL_TYPE_COLLECTION) {
        return nil;
    }
    //先获取头像 url，可能有，可能没有
    NSString *portraitUri = nil;
    if (reuseModel.conversationType == ConversationType_GROUP) {
        RCGroup *groupInfo = [[RCIM sharedRCIM] getGroupInfoCache:reuseModel.targetId];
        if (groupInfo) {
            portraitUri = groupInfo.portraitUri;
        }
    } else {
        RCUserInfo *userInfo = [[RCIM sharedRCIM] getUserInfoCache:reuseModel.targetId];
        if (userInfo) {
            portraitUri = userInfo.portraitUri;
        }
    }

    //检测一下 RCloudImageLoader 之前有没有加载过头像
    if (portraitUri.length > 0) {
        NSData *cachedImageData =
            [[RCloudImageLoader sharedImageLoader] getImageDataForURL:[NSURL URLWithString:portraitUri]];
        if (cachedImageData) {
            return [UIImage imageWithData:cachedImageData];
            ;
        }
    }
    return nil;
}

#pragma mark - Constraints
- (void)addSubviewConstraints {
    [self addConstraints:[NSLayoutConstraint
                             constraintsWithVisualFormat:@"V:|[_backgroundView]|"
                                                 options:0
                                                 metrics:nil
                                                   views:NSDictionaryOfVariableBindings(_backgroundView)]];
    [self addConstraints:[NSLayoutConstraint
                             constraintsWithVisualFormat:@"H:|[_backgroundView]|"
                                                 options:0
                                                 metrics:nil
                                                   views:NSDictionaryOfVariableBindings(_backgroundView)]];

    [self.backgroundView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_headerImageView]|"
                                                                                options:0
                                                                                metrics:nil
                                                                                  views:NSDictionaryOfVariableBindings(
                                                                                            _headerImageView)]];
    [self.backgroundView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_headerImageView]|"
                                                                                options:0
                                                                                metrics:nil
                                                                                  views:NSDictionaryOfVariableBindings(
                                                                                            _headerImageView)]];
}

#pragma mark - Getter & Setter
- (UIView *)backgroundView {
    if(!_backgroundView) {
        _backgroundView = [[RCloudImageView alloc] initWithFrame:self.frame];
        _backgroundView.translatesAutoresizingMaskIntoConstraints = NO;
        _backgroundView.backgroundColor = [UIColor clearColor];
    }
    return _backgroundView;
}

- (RCloudImageView *)headerImageView {
    if(!_headerImageView) {
        _headerImageView = [[RCloudImageView alloc] initWithFrame:self.frame];
        _headerImageView.translatesAutoresizingMaskIntoConstraints = NO;
        _headerImageView.layer.cornerRadius = 4;
        _headerImageView.layer.masksToBounds = YES;
        _headerImageView.image = nil;
        _headerImageView.placeholderImage = RCResourceImage(@"default_portrait");
        _headerImageView.userInteractionEnabled = YES;
    }
    return _headerImageView;
}
@end
