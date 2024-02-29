//
//  RCStickerModule.m
//  RongSticker
//
//  Created by Zhaoqianyu on 2018/8/7.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import "RCStickerModule.h"
#import "RCStickerMessage.h"
#import "RCStickerMessageCell.h"
#import "RCStickerCategoryTabSource.h"
#import "RCStickerPackageTabSource.h"
#import "RCStickerListViewController.h"

@interface RCStickerModule ()

@end

@implementation RCStickerModule

+ (instancetype)loadRongExtensionModule {
    return [self sharedModule];
}

+ (instancetype)sharedModule {
    static RCStickerModule *module = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        module = [[RCStickerModule alloc] init];
    });
    return module;
}

- (void)initWithAppKey:(NSString *)appkey {
    [[RCIM sharedRCIM] registerMessageType:[RCStickerMessage class]];
    self.appKey = appkey;
}

- (void)didConnect:(NSString *)userId {
    self.userId = userId;
    [[RCIM sharedRCIM]
            .userInfoDataSource getUserInfoWithUserId:[RCStickerModule sharedModule].userId
                                           completion:^(RCUserInfo *userInfo) {
                                               self.userInfo = userInfo;
                                           }];
    [[RCStickerDataManager sharedManager] managerInitialize];
}

- (void)didDisconnect {
}

- (void)emoticonTab:(RCEmojiBoardView *)emojiView
    didTouchEmotionIconIndex:(int)index
                  inInputBar:(RCChatSessionInputBarControl *)inputBarControl
         isBlockDefaultEvent:(void (^)(BOOL))block {
    block(NO);
}

- (void)extensionViewWillAppear:(RCConversationType)conversationType
                       targetId:(NSString *)targetId
                  extensionView:(UIView *)extensionView {
    self.conversationType = conversationType;
    self.currentTargetId = targetId;
}

- (void)extensionViewWillDisappear:(RCConversationType)conversationType targetId:(NSString *)targetId {
    self.conversationType = ConversationType_INVALID;
    self.currentTargetId = nil;
}

- (NSArray<RCExtensionMessageCellInfo *> *)getMessageCellInfoList:(RCConversationType)conversationType
                                                         targetId:(NSString *)targetId {
    RCExtensionMessageCellInfo *cellInfo = [RCExtensionMessageCellInfo new];
    cellInfo.messageContentClass = [RCStickerMessage class];
    cellInfo.messageCellClass = [RCStickerMessageCell class];
    return @[ cellInfo ];
}

- (NSArray<id<RCEmoticonTabSource>> *)getEmoticonTabList:(RCConversationType)conversationType
                                                targetId:(NSString *)targetId {

    NSMutableArray *tabSources = [[NSMutableArray alloc] init];
    int categoryCount = [[RCStickerDataManager sharedManager] getCategoryPackageCount:RCStickerCategoryTypeRecommend];
    if (categoryCount > 0) {
        RCStickerCategoryTabSource *categoryTabSource = [[RCStickerCategoryTabSource alloc] init];
        categoryTabSource.categoryType = RCStickerCategoryTypeRecommend;
        [tabSources addObject:categoryTabSource];
    }

    for (RCStickerPackage *package in [[RCStickerDataManager sharedManager] getAllPackages]) {
        RCStickerPackageTabSource *packageTabSource = [[RCStickerPackageTabSource alloc] init];
        packageTabSource.packageId = package.packageId;
        [tabSources addObject:packageTabSource];
    }

    return tabSources;
}

- (BOOL)isEmoticonSettingButtonEnabled:(RCChatSessionInputBarControl *)inputBarControl {
    return YES;
}

- (void)emoticonTab:(RCEmojiBoardView *)emojiView
    didTouchSettingButton:(UIButton *)settingButton
               inInputBar:(RCChatSessionInputBarControl *)inputBarControl {
    RCStickerListViewController *stickerList = [[RCStickerListViewController alloc] init];
    RCBaseNavigationController *nav = [[RCBaseNavigationController alloc] initWithRootViewController:stickerList];
    UIViewController *rootVC = [RCKitUtility getKeyWindow].rootViewController;
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [rootVC presentViewController:nav animated:YES completion:nil];
}

- (void)reloadEmoticonTabSource {
}

@end
