//
//  RCStreamMessageTextCellViewModel.h
//  RongIMKit
//
//  Created by zgh on 2025/3/5.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCStreamContentViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface RCStreamTextContentViewModel : RCStreamContentViewModel<RCStreamViewModelProtocol>

@property (nonatomic, copy, readonly)  NSAttributedString *attributedContent;

@end

NS_ASSUME_NONNULL_END
