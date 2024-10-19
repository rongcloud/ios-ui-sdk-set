//
//  RCGroupCreateView.h
//  RongIMKit
//
//  Created by zgh on 2024/8/22.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCBaseView.h"
#import "RCloudImageView.h"
#import "RCNameEditView.h"
#import "RCBaseButton.h"
NS_ASSUME_NONNULL_BEGIN

@protocol RCGroupCreateViewDelegate <NSObject>

- (void)portaitImageViewDidClick;

@end

@interface RCGroupCreateView : RCBaseView

@property (nonatomic, weak) id<RCGroupCreateViewDelegate> delegate;

@property (nonatomic, strong) RCloudImageView *portraitImageView;

@property (nonatomic, strong) RCNameEditView *nameEditView;

@property (nonatomic, strong) RCBaseButton *createButton;

@end

NS_ASSUME_NONNULL_END
