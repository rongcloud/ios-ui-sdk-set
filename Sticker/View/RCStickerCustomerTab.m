//
//  RCStickerCustomerTab.m
//  RCloudMessage
//
//  Created by 杜立召 on 16/9/19.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCStickerCustomerTab.h"
#import "RCStickerCustomModel.h"
#import "NSObject+model.h"
#import "RCStickerHelper.h"

typedef NS_ENUM(NSInteger, RCElayoutPreset) {
    RCElayoutPresetCompact,   // 紧凑布局：4×2
    RCElayoutPresetStandard,  // 标准布局：5×2
    RCElayoutPresetLarge,     // 大屏布局：6×2
    RCElayoutPresetiPad       // iPad布局：8×2
};

@interface RCStickerCustomerTab ()
@property (nonatomic, strong) NSArray *btnTitles;
@property (nonatomic, assign) NSInteger columns;
@property (nonatomic, strong) NSArray *emojiArray;
@property (nonatomic, weak) id<RCEmojiViewDelegate> delegate;
@property (nonatomic, weak) RCEmojiBoardView *emojiBoardView;

@end

@implementation RCStickerCustomerTab

- (instancetype)initWith:(RCEmojiBoardView *)emojiBoardView {
    if (self = [super init]) {
        self.emojiBoardView = emojiBoardView;
        self.delegate = emojiBoardView.delegate;
        RCElayoutPreset preset = [self getAutoLayoutPreset];
        self.pageCount = (int)[self getPageCount:self.emojiArray.count preset:preset];
    }
    return self;
}

- (UIView *)loadEmoticonView:(NSString *)identify index:(int)index {
    DebugLog(@"loadEmoticonView --- %@---%d",identify,index);
    DebugLog(@"%d",self.pageCount);
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, 186)];
    // 计算当前页的表情范围
    NSInteger itemsPerPage = self.columns * 2;
    NSInteger startIndex = index * itemsPerPage;
    NSInteger endIndex = MIN(startIndex + itemsPerPage, self.emojiArray.count);
    DebugLog(@"当前页: %ld, 表情范围: %ld - %ld", (long)index, (long)startIndex, (long)endIndex);
    // 添加当前页的所有表情按钮
    [self addEmoticonButtonsToView:view startIndex:startIndex endIndex:endIndex];
    return view;
}

- (void)addEmoticonButtonsToView:(UIView *)view startIndex:(NSInteger)startIndex endIndex:(NSInteger)endIndex {
    // 计算间距
    CGFloat itemSpacing = (UIScreen.mainScreen.bounds.size.width - 66 * self.columns) / (self.columns + 1);
    CGFloat lineSpacing = 18;
    CGFloat topMargin = 18;
    // 计算每个表情的尺寸
    CGFloat itemSize = 66;
    
    // 添加表情按钮
    for (NSInteger i = startIndex; i < endIndex; i++) {
        NSInteger positionInPage = i - startIndex; // 在当前页中的位置
        NSInteger row = positionInPage / self.columns;
        NSInteger column = positionInPage % self.columns;
        
        CGFloat x = itemSpacing + column * (itemSize + itemSpacing);
        CGFloat y = topMargin + row * (itemSize + lineSpacing);
        
        UIButton *sender = [self configStickerSenderWithDictionary:self.emojiArray[i]];
        sender.tag = i;
        sender.frame = CGRectMake(x, y, itemSize, itemSize);
        [view addSubview:sender];
    }
}

- (UIButton *)configStickerSenderWithDictionary:(RCStickerCustomModel *)model {
    UIButton *emojiBtn = [[UIButton alloc] init];
    if (model.image.length > 0) {
        UIImage *image = [RCKitUtility imageNamed:model.image ofBundle:@"RongSticker.bundle"];
        [emojiBtn setImage:image forState:UIControlStateNormal];
    }
    if (model) {
        NSString *jsonString = [[RCStickerHelper shared] transformJsonString:model];
        [emojiBtn setTitle:jsonString forState:UIControlStateNormal];
    }
    [emojiBtn setTitleColor:UIColor.clearColor forState:UIControlStateNormal];
    [emojiBtn addTarget:self action:@selector(emojiSenderHandle:) forControlEvents:UIControlEventTouchUpInside];
    return emojiBtn;
}

- (void)emojiSenderHandle:(UIButton *)sender {
    DebugLog(@"emojiSenderHandle: %@",sender.titleLabel.text);
    if (self.delegate && [self.delegate respondsToSelector:@selector(didTouchEmojiView:touchedSticker:)]) {
        [self.delegate didTouchEmojiView:self.emojiBoardView touchedSticker:sender.titleLabel.text];
    }
}

- (NSArray *)emojiArray {
    if (!_emojiArray) {
        _emojiArray = [RCStickerHelper shared].emojiArray;
    }
    return _emojiArray;
}

- (NSInteger)getPageCount:(NSInteger)emoticonCount preset:(RCElayoutPreset)preset {
    NSInteger columns = 0;
    NSInteger rows = 0;
    switch (preset) {
        case RCElayoutPresetCompact:
            columns = 4;
            rows = 2;
            break;
        case RCElayoutPresetStandard:
            columns = 5;
            rows = 2;
            break;
        case RCElayoutPresetLarge:
            columns = 6;
            rows = 2;
            break;
        case RCElayoutPresetiPad:
            columns = 8;
            rows = 2;
            break;
    }
    self.columns = columns;
    return [self calculatePageCountWithEmoticonCount:emoticonCount columns:columns rows:rows];
}

- (RCElayoutPreset)getAutoLayoutPreset {
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    if (screenWidth > 768) {
        return RCElayoutPresetiPad;
    } else if (screenWidth > 414) {
        return RCElayoutPresetLarge;
    } else if (screenWidth > 375) {
        return RCElayoutPresetStandard;
    } else {
        return RCElayoutPresetCompact;
    }
}

// MARK: - 计算页数
- (NSInteger)calculatePageCountWithEmoticonCount:(NSInteger)emoticonCount
                                   columns:(NSInteger)columns
                                      rows:(NSInteger)rows {
    if (emoticonCount <= 0) { return 0; }
    NSInteger itemsPerPage = columns * rows;
    // 核心计算公式：向上取整
    NSInteger pageCount = (emoticonCount + itemsPerPage - 1) / itemsPerPage;
    DebugLog(@"[RCCustomEmotionUtils] 页数计算:\n"
             "- 表情总数: %ld\n"
             "- 每页布局: %ld列×%ld行\n"
             "- 每页数量: %ld\n"
             "- 总页数: %ld",
             (long)emoticonCount, (long)columns, (long)rows, (long)itemsPerPage, (long)pageCount);
    return pageCount;
}

@end
