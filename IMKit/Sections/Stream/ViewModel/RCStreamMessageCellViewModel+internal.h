//
//  RCStreamMessageCellViewModel+internal.h
//  RongIMKit
//
//  Created by zgh on 2025/3/5.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCStreamMessageCellViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface RCStreamMessageCellViewModel ()

@property (nonatomic, weak) RCMessageModel *model;

@property (nonatomic, assign) BOOL showReferMessage;

@property (nonatomic, assign) RCStreamMessageStatus status;

@property (nonatomic, assign) CGSize contentViewSize;

@property (nonatomic, assign) CGSize textViewSize;

@property (nonatomic, assign) CGSize referViewSize;

@property (nonatomic, strong) dispatch_queue_t calculateHeightQueue;

@property (nonatomic, copy) NSString *summary;

@property (nonatomic, assign) BOOL summaryComplete;

@end

NS_ASSUME_NONNULL_END
