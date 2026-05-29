//
//  RCGroupNoticeView.h
//  RongIMKit
//
//  Created by zgh on 2024/8/28.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCBaseView.h"
#import "RCPlaceholderTextView.h"

NS_ASSUME_NONNULL_BEGIN

@interface RCGroupNoticeView : RCBaseView

@property (nonatomic, strong) RCPlaceholderTextView *textView;

@property (nonatomic, strong) UILabel *tipLabel;

@property (nonatomic, strong) UILabel *emptyLabel;

- (void)updateTextViewHeight:(BOOL)canEdit;
- (void)showEmptylabel:(BOOL)show;
@end

NS_ASSUME_NONNULL_END
