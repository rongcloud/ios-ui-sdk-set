//
//  RCFilePreviewViewController.h
//  RongIMKit
//
//  Created by Jue on 16/7/29.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCMessageModel.h"
#import "RCBaseViewController.h"

@interface RCFilePreviewViewController : RCBaseViewController

/*!
 当前文件消息的数据模型
 */
@property (nonatomic, strong) RCMessageModel *messageModel;

/*!
 使用别的App打开文件，App可以重写定制

 @param localPath 文件的本地路径
 */
- (void)openInOtherApp:(NSString *)localPath;

@end
