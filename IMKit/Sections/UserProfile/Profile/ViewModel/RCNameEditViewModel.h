//
//  RCNameEditViewModel.h
//  RongIMKit
//
//  Created by zgh on 2024/8/21.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCBaseViewModel.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, RCNameEditType) {
    RCNameEditTypeName,
    RCNameEditTypeRemark,
    RCNameEditTypeGroupName,
    RCNameEditTypeGroupMemberNickname,
    RCNameEditTypeGroupRemark,
};

@protocol RCNameEditViewModelDelegate <NSObject>
- (UIViewController *)currentViewController;

- (void)nameUpdateDidSuccess;

- (void)nameUpdateDidError:(NSString *)errorInfo;

@end

@interface RCNameEditViewModel : RCBaseViewModel

@property (nonatomic, weak) id<RCNameEditViewModelDelegate> delegate;

@property (nonatomic, copy) NSString *title;

@property (nonatomic, copy) NSString *content;

@property (nonatomic, copy) NSString *placeHolder;

@property (nonatomic, copy) NSString *tip;

@property (nonatomic, assign, readonly) NSInteger limit;

+ (instancetype)viewModelWithUserId:(NSString *)userId
                            groupId:(nullable NSString *)groupId
                               type:(RCNameEditType)type;

- (void)updateName:(NSString *)name;

- (void)getCurrentName:(void(^)(NSString *))block;
@end

NS_ASSUME_NONNULL_END
