//
//  RCMessageSelectionUtility.h
//  RongIMKit
//
//  Created by 张改红 on 2018/3/29.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCMessageModel.h"

typedef enum : NSUInteger {
    RCMessageMultiSelectStatusSelected = 0,
    RCMessageMultiSelectStatusCancelSelected,
} RCMessageMultiSelectStatus;
/*!
 message cell 选择状态发生变化
 */
UIKIT_EXTERN NSString *const RCMessageMultiSelectStatusChanged;

/*!
message cell 选择数量发生变化的代理
*/
@protocol RCMessagesMultiSelectedProtocol <NSObject>
@optional
/*!
message cell 消息选择数量即将发生变化的回调

@param status 消息 Cell 的选择状态
@param model 消息 Cell 的数据模型
*/
- (BOOL)onMessagesMultiSelectedCountWillChanged:(RCMessageMultiSelectStatus)status model:(RCMessageModel *)model;

/*!
message cell 消息选择数量发生变化的回调

@param status 消息 Cell 的选择状态
@param model 消息 Cell 的数据模型
*/
- (void)onMessagesMultiSelectedCountDidChanged:(RCMessageMultiSelectStatus)status model:(RCMessageModel *)model;

@end

@interface RCMessageSelectionUtility : NSObject
// Forward
@property (nonatomic, assign) BOOL multiSelect;
@property (nonatomic, weak) id<RCMessagesMultiSelectedProtocol> delegate;

+ (instancetype)sharedManager;
- (void)addMessageModel:(RCMessageModel *)model;
- (void)removeMessageModel:(RCMessageModel *)model;
- (BOOL)isContainMessage:(RCMessageModel *)model;
- (NSArray<RCMessageModel *> *)selectedMessages;
- (void)removeAllMessages;
- (void)clear;
@end
