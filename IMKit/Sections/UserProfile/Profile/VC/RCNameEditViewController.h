//
//  RCNameEditViewController.h
//  RongUserProfile
//
//  Created by zgh on 2024/8/19.
//

#import "RCBaseViewController.h"
#import "RCNameEditViewModel.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, RCNameEditViewControllerType) {
    RCNameEditViewControllerTypeRemark,
    RCNameEditViewControllerTypeName,
    RCNameEditViewControllerTypeGroupNickName
};

@interface RCNameEditViewController : RCBaseViewController

- (instancetype)initWithViewModel:(RCNameEditViewModel *)viewModel;

@end

NS_ASSUME_NONNULL_END
