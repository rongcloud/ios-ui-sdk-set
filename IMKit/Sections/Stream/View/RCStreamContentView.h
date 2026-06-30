//
//  RCStreamContentView.h
//  RongIMKit
//
//  Created by zgh on 2025/2/27.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCMessageModel.h"
#import "RCStreamContentViewModel.h"
NS_ASSUME_NONNULL_BEGIN

@protocol RCStreamContentViewDelegate <NSObject>

- (void)streamContentViewDidLongPress;


- (void)streamContentViewDidClickUrl:(NSString *)urlString;

@end

@interface RCStreamContentView : UIView

@property (nonatomic, weak) id<RCStreamContentViewDelegate> delegate;

- (void)configViewModel:(RCStreamContentViewModel *)contentViewModel;

- (void)showLoading;

- (void)showFailed;

- (void)cleanView;

@end

NS_ASSUME_NONNULL_END
