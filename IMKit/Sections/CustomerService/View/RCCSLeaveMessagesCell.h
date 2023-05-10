//
//  RCCSLeaveMessagesCell.h
//  RongIMKit
//
//  Created by 张改红 on 2016/12/5.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>
@class RCCSLeaveMessageItem;
@interface RCCSLeaveMessagesCell : UITableViewCell
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UITextField *infoTextField;
@property (nonatomic, strong) UITextView *infoTextView;
@property (nonatomic, copy) void (^leaveMessageInfomation)(NSDictionary *info);

- (void)setDataWithModel:(RCCSLeaveMessageItem *)model indexPath:(NSIndexPath *)indexPath;
@end
