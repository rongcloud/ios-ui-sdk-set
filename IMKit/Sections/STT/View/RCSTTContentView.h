//
//  RCSTTContentView.h
//  RongIMKit
//
//  Created by RobinCui on 2025/5/27.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCBaseView.h"
#import "RCSTTContentViewModel.h"
#import "RCMessageCellDelegate.h"
NS_ASSUME_NONNULL_BEGIN
typedef void (^RCSTTConvertSuccessBlock)(void);

@interface RCSTTContentView : RCBaseView
@property (nonatomic, copy) RCSTTConvertSuccessBlock sttFinishedBlock;
/// 绑定stt VM
/// - Parameters:
///   - viewModel: viewModel
///   - frame: Cell 中messageContent 视图的frame
///
- (void)bindViewModel:(RCSTTContentViewModel *)viewModel
            baseFrame:(CGRect)frame;

/// 绑定长按事件代理
/// - Parameter delegate: 代理
- (void)bindGestureDelegate:(id<RCMessageCellDelegate>)delegate;

- (void)bindCollectionView:(UICollectionView *)collectionView;
/// 布局STT内容视图
- (void)layoutContentView;
@end

NS_ASSUME_NONNULL_END
