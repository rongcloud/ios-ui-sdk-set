//
//  RCStreamMessageCellViewModel.h
//  SealTalk
//
//  Created by zgh on 2025/2/20.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCBaseCellViewModel.h"
#import "RCMessageModel.h"
#import "RCStreamContentViewModel.h"

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    RCStreamMessageStatusNone,
    RCStreamMessageStatusNormal,
    RCStreamMessageStatusContentLoading,
    RCStreamMessageStatusContentFailedWhenLoading,
    RCStreamMessageStatusContentFailedWhenNormal,
    RCStreamMessageStatusBottomUnfold,
    RCStreamMessageStatusBottomLoading,
    RCStreamMessageStatusBottomFailed,
} RCStreamMessageStatus;

typedef enum : NSUInteger {
    RCStreamContentTypeText,
    RCStreamContentTypeMarkdown,
    RCStreamContentTypeHTML,
} RCStreamContentType;

extern CGFloat const rcUnfoldButtonHeight;
extern CGFloat const rcContentTop;
extern CGFloat const rcContentSpace;
extern CGFloat const rcTextLeadingX;
@protocol RCStreamMessageCellViewModelDelegate <NSObject>

- (void)contentLayoutDidUpdate;

@end

@interface RCStreamMessageCellViewModel : NSObject

@property (nonatomic, copy, readonly)  NSString *content;

@property (nonatomic, weak) id<RCStreamMessageCellViewModelDelegate> delegate;

@property (nonatomic, assign, readonly) BOOL showReferMessage;

@property (nonatomic, assign) RCStreamContentType contentType;

@property (nonatomic, assign, readonly) RCStreamMessageStatus status;

@property (nonatomic, assign, readonly) CGSize contentViewSize;

@property (nonatomic, assign, readonly) CGSize textViewSize;

@property (nonatomic, assign, readonly) CGSize referViewSize;

@property (nonatomic, strong) RCStreamContentViewModel *contentViewModel;

+ (instancetype)viewModelWithModel:(RCMessageModel *)model;

- (CGSize)getMessageContentViewSize;

- (void)requestStreamMessage;

- (void)reloadStreamContent:(RCStreamMessageStatus)status;
@end

NS_ASSUME_NONNULL_END
