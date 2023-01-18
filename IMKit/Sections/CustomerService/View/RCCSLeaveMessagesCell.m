//
//  RCCSLeaveMessagesCell.m
//  RongIMKit
//
//  Created by 张改红 on 2016/12/5.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCCSLeaveMessagesCell.h"
#import "RCKitCommonDefine.h"
#import "RCKitUtility.h"
#import "RCKitConfig.h"
#import "RCAlertView.h"
#import <RongCustomerService/RongCustomerService.h>
@interface RCCSLeaveMessagesCell () <UITextFieldDelegate, UITextViewDelegate>
@property (nonatomic, strong) UILabel *textNum;
@property (nonatomic, assign) int max;
@property (nonatomic, copy) NSString *alertText;
@property (nonatomic, strong) UITextView *placeHolderText;
@property (nonatomic, strong) RCCSLeaveMessageItem *leaveMessageItem;
@end
@implementation RCCSLeaveMessagesCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupSubviews];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(textFieldTextDidChange:)
                                                     name:UITextFieldTextDidChangeNotification
                                                   object:self.infoTextField];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Public Method

- (void)setDataWithModel:(RCCSLeaveMessageItem *)model indexPath:(NSIndexPath *)indexPath {
    self.infoTextField.tag = indexPath.row;
    self.leaveMessageItem = model;
    self.titleLabel.text = model.title;
    if ([model.type isEqualToString:@"text"]) {
        [self setLayoutConstraint:NO];
        self.infoTextField.placeholder = model.defaultText;
    } else if ([model.type isEqualToString:@"textarea"]) {
        [self setLayoutConstraint:YES];
        self.placeHolderText.text = model.defaultText;
        if (model.message.count == 3) {
            self.alertText = model.message[2];
        }
    }
    self.max = model.max;
    self.textNum.text = [NSString stringWithFormat:@"0/%d", self.max];
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {

    UITextRange *selectedRange = [textView markedTextRange];
    //获取高亮部分
    UITextPosition *pos = [textView positionFromPosition:selectedRange.start offset:0];

    //如果有高亮且当前字数开始位置小于最大限制时允许输入
    if (selectedRange && pos) {
        NSInteger startOffset =
            [textView offsetFromPosition:textView.beginningOfDocument toPosition:selectedRange.start];
        NSInteger endOffset = [textView offsetFromPosition:textView.beginningOfDocument toPosition:selectedRange.end];
        NSRange offsetRange = NSMakeRange(startOffset, endOffset - startOffset);

        if (offsetRange.location <= self.max) {
            return YES;
        } else {
            return NO;
        }
    }
    if (self.max > 0 && (textView.text.length > self.max || range.location >= self.max ||
                         ((textView.text.length == self.max && text.length > 0)))) {
        [self showAlertController:self.alertText];
        self.textNum.text = [NSString stringWithFormat:@"%ld/%d", (long)textView.text.length, self.max];
        return NO;
    }
    if (![text isEqualToString:@""]) {
        self.placeHolderText.hidden = YES;
    }

    if ([text isEqualToString:@""] && range.location == 0 && range.length == 1) {
        self.placeHolderText.hidden = NO;
    }
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    if (self.leaveMessageInfomation) {
        self.leaveMessageInfomation(@{
            [NSString stringWithFormat:@"%@", self.leaveMessageItem.name] : [NSString stringWithFormat:@"%@", textView.text]
        });
    }
    
    if (![textView.text isEqualToString:@""]) {
        self.placeHolderText.hidden = YES;
    }

    UITextRange *selectedRange = [textView markedTextRange];
    //获取高亮部分
    UITextPosition *pos = [textView positionFromPosition:selectedRange.start offset:0];

    //如果在变化中是高亮部分在变，就不要计算字符了
    if (selectedRange && pos) {
        return;
    }

    if (self.max > 0 && textView.text.length > self.max) {
        textView.text = [textView.text substringToIndex:self.max];
        [self showAlertController:self.alertText];
    }
    self.textNum.text = [NSString stringWithFormat:@"%ld/%d", (long)textView.text.length, self.max];
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if (self.leaveMessageInfomation) {
        self.leaveMessageInfomation(@{
            [NSString stringWithFormat:@"%@", self.leaveMessageItem.name] : [NSString stringWithFormat:@"%@", textView.text]
        });
    }
    
    if (![textView.text isEqualToString:@""]) {
        self.placeHolderText.hidden = YES;
    }
}

#pragma mark - UITextFieldDelegate

- (void)textFieldTextDidChange:(NSNotification *)notification {
    UITextField *textField = notification.object;
    if (self.infoTextField.tag == textField.tag) {
        if (self.leaveMessageInfomation) {
            self.leaveMessageInfomation(@{
                [NSString stringWithFormat:@"%@", self.leaveMessageItem.name] :
                    [NSString stringWithFormat:@"%@", self.infoTextField.text]
            });
        }
    }
}

//点击return 按钮 去掉z
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (self.leaveMessageInfomation) {
        self.leaveMessageInfomation(@{
            [NSString stringWithFormat:@"%@", self.leaveMessageItem.name] :
                [NSString stringWithFormat:@"%@", textField.text]
        });
    }
}

#pragma mark - Private Method
- (void)showAlertController:(NSString *)message {
    [RCAlertView showAlertController:nil message:message cancelTitle:RCLocalizedString(@"OK") inViewController:nil];
}

- (void)setupSubviews {
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = [[RCKitConfig defaultConfig].font fontOfSecondLevel];

    self.infoTextField = [[UITextField alloc] init];
    self.infoTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.infoTextField.font = [[RCKitConfig defaultConfig].font fontOfSecondLevel];
    self.infoTextField.delegate = self;

    self.infoTextView = [[UITextView alloc] init];
    self.infoTextView.font = [[RCKitConfig defaultConfig].font fontOfSecondLevel];
    self.infoTextView.delegate = self;
    self.infoTextView.backgroundColor = [UIColor clearColor];
    self.placeHolderText = [[UITextView alloc] init];
    self.placeHolderText.font = [[RCKitConfig defaultConfig].font fontOfSecondLevel];
    self.placeHolderText.editable = NO;
    self.placeHolderText.textColor = RGBCOLOR(188, 188, 194);

    self.textNum = [[UILabel alloc] init];
    self.textNum.font = [[RCKitConfig defaultConfig].font fontOfAnnotationLevel];
    self.textNum.textColor = HEXCOLOR(0x999999);
    self.textNum.textAlignment = NSTextAlignmentRight;

    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.infoTextField];
    [self.contentView addSubview:self.placeHolderText];
    [self.contentView addSubview:self.infoTextView];
    [self.contentView addSubview:self.textNum];

    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.infoTextField.translatesAutoresizingMaskIntoConstraints = NO;
    self.infoTextView.translatesAutoresizingMaskIntoConstraints = NO;
    self.placeHolderText.translatesAutoresizingMaskIntoConstraints = NO;
    self.textNum.translatesAutoresizingMaskIntoConstraints = NO;
}

- (void)setLayoutConstraint:(BOOL)isMultiLine {
    if (isMultiLine) {
        NSDictionary *views = NSDictionaryOfVariableBindings(_titleLabel, _infoTextView, _placeHolderText, _textNum);
        [self.contentView
            addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
                                                   @"V:|-10-[_titleLabel(17)]-10-[_infoTextView]-7-[_textNum(13)]-10-|"
                                                                   options:0
                                                                   metrics:nil
                                                                     views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[_infoTextView]-10-|"
                                                                                 options:0
                                                                                 metrics:nil
                                                                                   views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[_titleLabel]-10-|"
                                                                                 options:0
                                                                                 metrics:nil
                                                                                   views:views]];
        [self.contentView
            addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[_placeHolderText]-10-|"
                                                                   options:0
                                                                   metrics:nil
                                                                     views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_textNum(100)]-10-|"
                                                                                 options:0
                                                                                 metrics:nil
                                                                                   views:views]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.placeHolderText
                                                                     attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.infoTextView
                                                                     attribute:NSLayoutAttributeTop
                                                                    multiplier:1
                                                                      constant:0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.placeHolderText
                                                                     attribute:NSLayoutAttributeHeight
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.infoTextView
                                                                     attribute:NSLayoutAttributeHeight
                                                                    multiplier:1
                                                                      constant:0]];
        [self.infoTextField removeFromSuperview];
    } else {
        NSDictionary *views = NSDictionaryOfVariableBindings(_titleLabel, _infoTextField);

        [self.contentView
            addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"H:|-10-[_titleLabel(35)]-5-[_infoTextField]-3.5-|"
                                                   options:0
                                                   metrics:nil
                                                     views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_infoTextField(20)]"
                                                                                 options:0
                                                                                 metrics:nil
                                                                                   views:views]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.infoTextField
                                                                     attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.titleLabel
                                                                     attribute:NSLayoutAttributeTop
                                                                    multiplier:1
                                                                      constant:0]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_titleLabel(20)]"
                                                                                 options:0
                                                                                 metrics:nil
                                                                                   views:views]];
        [self.infoTextView removeFromSuperview];
        [self.placeHolderText removeFromSuperview];
        [self.textNum removeFromSuperview];
    }

    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.titleLabel
                                                                 attribute:NSLayoutAttributeTop
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.contentView
                                                                 attribute:NSLayoutAttributeTop
                                                                multiplier:1
                                                                  constant:10]];
}


@end
