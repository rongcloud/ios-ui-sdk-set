//
//  RCUUserProfileHeaderCellViewModel.h
//  RongUserProfile
//
//  Created by zgh on 2024/8/19.
//

#import "RCProfileCellViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface RCUserProfileHeaderCellViewModel : RCProfileCellViewModel

@property (nonatomic, copy) NSString *portrait;

@property (nonatomic, copy) NSString *name;

@property (nonatomic, copy) NSString *remark;

/// 是否显示在线状态
/// 默认 NO 不显示
@property (nonatomic, assign) BOOL displayOnlineStatus;

/// 默认 NO 不在线状态
@property (nonatomic, assign) BOOL isOnline;

- (instancetype)initWithPortrait:(NSString *)portrait
                            name:(NSString *)name
                          remark:(NSString *)remark;

@end

NS_ASSUME_NONNULL_END
