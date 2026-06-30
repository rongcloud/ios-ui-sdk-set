//
//  RCLocationKitExtensionModule.m
//  RongLocationKit
//
//  Created by zgh on 2022/2/17.
//

#import "RCLocationKitExtensionModule.h"
#import "RongLocationKit.h"
#import <RongLocation/RongLocation.h>

@implementation RCLocationKitExtensionModule
 
+ (instancetype)loadRongExtensionModule {
    return [[RCLocationKitExtensionModule alloc] init];
}

- (void)destroyModule {
}

- (NSArray<RCExtensionMessageCellInfo *> *)getMessageCellInfoList:(RCConversationType)conversationType
                                                         targetId:(NSString *)targetId {
    RCExtensionMessageCellInfo *cellInfo = [RCExtensionMessageCellInfo new];
    cellInfo.messageContentClass = [RCLocationMessage class];
    cellInfo.messageCellClass = [RCLocationMessageCell class];
    return @[ cellInfo ];
}

- (NSArray<RCExtensionPluginItemInfo *> *)getPluginBoardItemInfoList:(RCConversationType)conversationType
                                                            targetId:(NSString *)targetId {
    NSMutableArray *itemList = [[NSMutableArray alloc] init];
    RCExtensionPluginItemInfo *locationItem = [[RCExtensionPluginItemInfo alloc] init];
    locationItem.normalImage = RCDynamicImage(@"conversation_plugin_item_location_img",@"plugin_item_location");
    locationItem.highlightedImage = RCDynamicImage(@"conversation_plugin_item_location_highlighted_img",@"plugin_item_location_highlighted");
    locationItem.title = RCLocalizedString(@"Location");
    locationItem.tag = PLUGIN_BOARD_ITEM_LOCATION_TAG;
    locationItem.tapBlock = ^(RCChatSessionInputBarControl *chatSessionInputBar) {
        
    };
    [itemList addObject:locationItem];
    return itemList;
}

@end
