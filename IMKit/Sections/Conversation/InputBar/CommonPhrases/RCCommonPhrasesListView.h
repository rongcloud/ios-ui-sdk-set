//
//  RCCommonPhrasesListView.h
//  RongExtensionKit
//
//  Created by liyan on 2019/7/9.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol RCCommonPhrasesListViewDelegate <NSObject>
@optional

/*!
 点击常用语的回调

 @param commonPhrase 点击的常用语
 */
- (void)didTouchCommonPhrasesView:(NSString *)commonPhrase;

@end

@interface RCCommonPhrasesListView : UIView

/*!
 点击常用语的回调
 */
@property (nonatomic, weak) id<RCCommonPhrasesListViewDelegate> delegate;

- (instancetype)initWithFrame:(CGRect)frame dataSource:(NSArray *)dataSource;

/*!
常用语的数据源
*/
@property (nonatomic, strong) NSArray *dataSource;

/*!
刷新常用语
*/
- (void)reloadCommonPhrasesList;

@end

NS_ASSUME_NONNULL_END
