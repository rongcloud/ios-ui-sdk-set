//
//  RCGroupListCell.m
//  RongIMKit
//
//  Created by RobinCui on 2024/11/28.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCGroupListCell.h"
#import "RCloudImageView.h"
#import "RCKitCommonDefine.h"
NSString  * const RCGroupListCellIdentifier = @"RCGroupListCellIdentifier";

@implementation RCGroupListCell

- (void)showPortrait:(NSString *)url {
    if (url.length) {
        [self.portraitImageView setImageURL:[NSURL URLWithString:url]];
    } else {
        [self.portraitImageView setImage:RCDynamicImage(@"conversation-list_cell_group_portrait_img", @"default_group_portrait")];
    }
}
@end
