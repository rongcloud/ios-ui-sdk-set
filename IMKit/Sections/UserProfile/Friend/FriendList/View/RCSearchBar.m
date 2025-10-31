//
//  RCSearchBar.m
//  RongIMKit
//
//  Created by RobinCui on 2024/8/21.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCSearchBar.h"
#import "RCKitUtility.h"
#import "RCKitCommonDefine.h"

@interface RCSearchBar ()<UITextFieldDelegate>
// placeholder 和icon 和 间隙的整体宽度
@property (nonatomic, assign) CGFloat placeholderWidth;
@property (nonatomic, strong) UITextField *textField;
@end


// icon宽度
static CGFloat const RC_SEARCHAR_ICON_WIDTH = 20.0;
// icon与placeholder间距
static CGFloat const RC_SEARCHAR_ICON_SPACE = 10.0;
// 占位文字的字体大小
static CGFloat const RC_SEARCHAR_FONT_SIZE = 15.0;

@implementation RCSearchBar

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.placeholder =@"search";
        self.keyboardType = UIKeyboardTypeDefault;
        if (@available(iOS 13.0, *)) {
            self.textField = self.searchTextField;
        }else{
            self.textField = [self valueForKey:@"searchField"];
        }
        self.textField.backgroundColor = [RCKitUtility generateDynamicColor:HEXCOLOR(0xf9f9f9)
                                                             darkColor:HEXCOLOR(0x202020)];
        self.textField.delegate = self;
        
        //设置顶部搜索栏的背景色
        self.barTintColor = RCDYCOLOR(0xffffff, 0x191919);
        self.layer.borderColor = RCDYCOLOR(0xffffff, 0x191919).CGColor;
        self.layer.borderWidth = 1;
    }
    return self;
}

- (void)setFrame:(CGRect)frame{
    [super setFrame:frame];
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    self.layer.borderColor = RCDYCOLOR(0xffffff, 0x191919).CGColor;
}

- (void)setText:(NSString *)text{
    [super setText:text];
    if (text.length == 0) {
        [self makeTextFieldCenter:YES];
    }else{
        [self makeTextFieldCenter:NO];
    }
}

#pragma mark - 文本居中
- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    //不能在 init 之后立即计算偏移量，因为 init 时的 placeholder 是默认值
    [self makeTextFieldCenter:YES];
}

// 1.默认居中placeholder
- (void)makeTextFieldCenter:(BOOL)isCenter {
    UIOffset offset = UIOffsetZero;
    if(isCenter && self.textField.text.length == 0) {
        // 8 为左右边距
        offset = UIOffsetMake((self.frame.size.width - 8 * 2 - self.placeholderWidth) / 2, 0);
    }
    // iOS 11 之前就是居中的，所以只有 iOS 11 及其以后需要代码进行居中
    if (@available(iOS 11.0, *)) {
        [self setPositionAdjustment:offset forSearchBarIcon:UISearchBarIconSearch];
    }
}

// 2.开始编辑的时候重置为靠左
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    BOOL retValue = YES;
    if ([self.delegate respondsToSelector:@selector(searchBarShouldBeginEditing:)]) {
        retValue = [self.delegate searchBarShouldBeginEditing:self];
    }
    if (retValue) {
        [self makeTextFieldCenter:NO];
    }
    return retValue;
}
// 3.结束编辑的时候设置为居中
- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    BOOL retValue = YES;
    if ([self.delegate respondsToSelector:@selector(searchBarShouldEndEditing:)]) {
        retValue = [self.delegate searchBarShouldEndEditing:self];
    }
    [self makeTextFieldCenter:YES];
    return retValue;
}

- (void)setPlaceholder:(NSString *)placeholder{
    [super setPlaceholder:placeholder];
}

// 计算placeholder、icon、icon和placeholder间距的总宽度
- (CGFloat)placeholderWidth {
    if (!_placeholderWidth && self.placeholder) {
        CGSize size = [self.placeholder boundingRectWithSize:CGSizeMake(MAXFLOAT, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:RC_SEARCHAR_FONT_SIZE]} context:nil].size;
        _placeholderWidth = size.width + RC_SEARCHAR_ICON_SPACE + RC_SEARCHAR_ICON_WIDTH;
    }
    return _placeholderWidth;
}


@end
