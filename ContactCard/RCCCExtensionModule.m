//
//  RCCCExtensionModule.m
//  RongContactCard
//
//  Created by Jue on 2017/1/11.
//  Copyright © 2017年 ios-rongContactCard. All rights reserved.
//

#import "RCCCExtensionModule.h"

@implementation RCCCExtensionModule
+ (instancetype)loadRongExtensionModule {
    return [self sharedRCCCitExtensionModule];
}

+ (instancetype)sharedRCCCitExtensionModule {
    static RCCCExtensionModule *module = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        module = [[self alloc] init];
    });
    return module;
}

- (void)initWithAppKey:(NSString *)appkey {
    [[RCIM sharedRCIM] registerMessageType:[RCContactCardMessage class]];
}

- (NSArray<RCExtensionMessageCellInfo *> *)getMessageCellInfoList:(RCConversationType)conversationType
                                                         targetId:(NSString *)targetId {
    if (conversationType == ConversationType_PRIVATE || conversationType == ConversationType_GROUP ||
        conversationType == ConversationType_Encrypted) {
        RCExtensionMessageCellInfo *cellInfo = [RCExtensionMessageCellInfo new];
        cellInfo.messageContentClass = [RCContactCardMessage class];
        cellInfo.messageCellClass = [RCContactCardMessageCell class];
        return @[ cellInfo ];
    }
    return nil;
}

- (NSArray<RCExtensionPluginItemInfo *> *)getPluginBoardItemInfoList:(RCConversationType)conversationType
                                                            targetId:(NSString *)targetId {
    NSMutableArray *itemList = [[NSMutableArray alloc] init];

    if (conversationType == ConversationType_PRIVATE || conversationType == ConversationType_GROUP ||
        conversationType == ConversationType_Encrypted) {
        RCExtensionPluginItemInfo *cardItem = [[RCExtensionPluginItemInfo alloc] init];
        cardItem.normalImage = RCResourceImage(@"plugin_item_card");
        cardItem.highlightedImage = RCResourceImage(@"plugin_item_card_highlighted");
        cardItem.title = RCLocalizedString(@"ContactCard");
        cardItem.tag = PLUGIN_BOARD_ITEM_CARD_TAG;
        cardItem.tapBlock = ^(RCChatSessionInputBarControl *chatSessionInputBar) {

            if ([[RCContactCardKit shareInstance]
                        .contactVCDelegate respondsToSelector:@selector(needDisplayContactViewController:targetId:)]) {
                [[RCContactCardKit shareInstance]
                        .contactVCDelegate needDisplayContactViewController:conversationType
                                                                   targetId:targetId];
            } else {
                RCCCUserListViewController *vc = [[RCCCUserListViewController alloc] init];
                vc.conversationType = conversationType;
                vc.targetId = targetId;
                vc.modalPresentationStyle = UIModalPresentationFullScreen;
                RCBaseNavigationController *nav = [[RCBaseNavigationController alloc] initWithRootViewController:vc];
                nav.modalPresentationStyle = UIModalPresentationFullScreen;
                [[RCKitUtility getKeyWindow].rootViewController presentViewController:nav
                                                                         animated:YES
                                                                       completion:nil];
            }
        };
        [itemList addObject:cardItem];
        return itemList;
    }
    return nil;
}

@end
