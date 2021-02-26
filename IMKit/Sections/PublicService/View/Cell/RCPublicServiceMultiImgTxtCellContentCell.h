//
//  RCPublicServiceMultiImgTxtCellContentCell.h
//  RongIMKit
//
//  Created by litao on 15/4/15.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCMessageCellDelegate.h"
#import <RongIMLib/RongIMLib.h>
#import <UIKit/UIKit.h>

@protocol RCPublicServiceMultiImgTxtCellContentCellDelegate <NSObject>

- (void)longPressAction:(UITableViewCell *)cell;

@end

@interface RCPublicServiceMultiImgTxtCellContentCell : UITableViewCell
@property (nonatomic, strong) RCMessageModel *model;
@property (strong, nonatomic) RCRichContentMessage *richContent;
@property (nonatomic, weak) id<RCPublicServiceMessageCellDelegate> publicServiceDelegate;
@property (nonatomic, weak) id<RCPublicServiceMultiImgTxtCellContentCellDelegate> delegate;
- (instancetype)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier;
+ (CGFloat)getContentCellHeight:(RCRichContentMessage *)richContent;
@end
