//
//  RCGroupInfoCellViewModel.m
//  RongIMKit
//
//  Created by RobinCui on 2024/11/20.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCGroupInfoCellViewModel.h"
#import "RCGroupListCell.h"
#import "RCConversationViewController.h"
#import "RCKitCommonDefine.h"

@interface RCGroupInfoCellViewModel()
@property (nonatomic, copy) NSString *keyword;
@end

@implementation RCGroupInfoCellViewModel

- (instancetype)initWithGroupInfo:(RCGroupInfo *)groupInfo
                          keyword:(NSString *)keyword
{
    self = [super init];
    if (self) {
        self.groupInfo = groupInfo;
        self.keyword = keyword;
    }
    return self;
}

/// 注册 cell
+ (void)registerCellForTableView:(UITableView *)tableView {
    [tableView registerClass:[RCGroupListCell class] forCellReuseIdentifier:RCGroupListCellIdentifier];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RCGroupListCell *cell = [tableView dequeueReusableCellWithIdentifier:RCGroupListCellIdentifier
                                                                      forIndexPath:indexPath];
    if (self.groupInfo) {
        [cell showPortrait:self.groupInfo.portraitUri];
        cell.labName.attributedText =  [self attributedString:self.groupInfo.groupName withKeyword:self.keyword];;
    }
    
    return cell;
}

- (void)itemDidSelectedByViewController:(UIViewController *)vc {
    RCConversationViewController *conversationVC = [[RCConversationViewController alloc] initWithConversationType:ConversationType_GROUP targetId:self.groupInfo.groupId];
    [vc.navigationController pushViewController:conversationVC animated:YES];
}

-(NSMutableAttributedString*)attributedString:(NSString *)string
                                  withKeyword:(NSString *)keyword
{
    // 创建对象.
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:string];
   
    if (keyword.length > 0) {
        UIColor *color = HEXCOLOR(0x5a9cea);
        NSRange range = [[string uppercaseString] rangeOfString:[keyword uppercaseString]];
        [attributedString addAttribute:NSForegroundColorAttributeName value:color range:range];
    }
  
    return attributedString;
}
@end
