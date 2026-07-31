//
//  RCStreamContentViewModel.h
//  RongIMKit
//
//  Created by zgh on 2025/3/5.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCStreamViewModelProtocol.h"
@class RCStreamContentView;
NS_ASSUME_NONNULL_BEGIN

@protocol RCStreamContentViewModelDelegate <NSObject>

- (void)streamContentLayoutWillUpdate;

@end

@interface RCStreamContentViewModel : NSObject<RCStreamViewModelProtocol>

@property (nonatomic, copy) NSString *content;

@property (nonatomic, weak) id<RCStreamContentViewModelDelegate> delegate;

@property (nonatomic, assign) CGSize contentSize;

+ (NSString *)failedInfo;

- (RCStreamContentView *)streamContentView;

- (CGFloat)contentMaxWidth;

@end

NS_ASSUME_NONNULL_END
