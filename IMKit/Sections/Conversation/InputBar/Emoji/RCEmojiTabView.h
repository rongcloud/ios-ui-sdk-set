//
//  RCEmojiBottomTab.h
//  RongIMKit
//
//  Created by 张改红 on 2020/7/9.
//  Copyright © 2020 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@protocol RCEmojiTabViewDelegate;
@interface RCEmojiTabView : UIView

@property (nonatomic, weak) id<RCEmojiTabViewDelegate> delegate;

- (void)showAddButton:(BOOL)showAddButton showSettingButton:(BOOL)showSettingButton;

- (void)reloadTabView:(NSArray *)emotionsListData;

- (void)showEmotion:(int)index;
@end

@protocol RCEmojiTabViewDelegate <NSObject>

- (void)emojiTabView:(RCEmojiTabView *)emojiTabView didClickSendButton:(UIButton *)button;

- (void)emojiTabView:(RCEmojiTabView *)emojiTabView didClickSettingButton:(UIButton *)button;

- (void)emojiTabView:(RCEmojiTabView *)emojiTabView didClickAddButton:(UIButton *)button;

- (void)emojiTabView:(RCEmojiTabView *)emojiTabView didSelectEmotion:(int)index;
@end

NS_ASSUME_NONNULL_END
