//
//  RCActionSheetView.m
//  RongIMKit
//
//  Created by liyan on 2019/8/22.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import "RCActionSheetView.h"
#import "RCKitCommonDefine.h"
#import "RCKitUtility.h"
#import "RCKitConfig.h"

#define Space_Line 6
@interface RCActionSheetView()
@property (nonatomic, strong) UIView *maskView; //背景

@property (nonatomic, strong) UITableView *tableView; //展示表格

@property (nonatomic, strong) NSArray *cellArray; //表格数组

@property (nonatomic, copy) NSString *title; //标题设置

@property (nonatomic, copy) NSString *cancelTitle; //取消的标题设置

@property (nonatomic, strong) UIView *headView; //标题头视图

@property (nonatomic, assign) CGSize viewSize; //父view的大小

@property (nonatomic, copy) void (^selectedBlock)(NSInteger index); //选择单元格block

@property (nonatomic, copy) void (^cancelBlock)(void); //取消单元格block
@end

@implementation RCActionSheetView
+ (void)showActionSheetView:(NSString *)title
                  cellArray:(NSArray *)cellArray
                cancelTitle:(NSString *)cancelTitle
              selectedBlock:(void (^)(NSInteger index))selectedBlock
                cancelBlock:(void (^)(void))cancelBlock{
    UIWindow *keyWindow = [RCKitUtility getKeyWindow];
    [keyWindow endEditing:YES];
    RCActionSheetView *actionSheet = [[RCActionSheetView alloc] initWithTitle:title CellArray:cellArray viewSize:keyWindow.bounds.size cancelTitle:cancelTitle selectedBlock:selectedBlock cancelBlock:cancelBlock];
    [keyWindow addSubview:actionSheet];
}

- (instancetype)initWithTitle:(NSString *)title
                    CellArray:(NSArray *)cellArray
                   viewSize:(CGSize)viewSize
                  cancelTitle:(NSString *)cancelTitle
                selectedBlock:(void (^)(NSInteger index))selectedBlock
                  cancelBlock:(void (^)(void))cancelBlock{
    self = [super init];
    if (self) {
        _viewSize = viewSize;
        if (title.length > 0) {
            _title = title;
            [self addTitleView];
        }
        _cellArray = cellArray;
        _cancelTitle = cancelTitle;
        _selectedBlock = selectedBlock;
        _cancelBlock = cancelBlock;
        [self createUI];
    }
    return self;
}

#pragma mark------ 创建UI视图
- (void)addTitleView{
    CGFloat height = [RCKitUtility getTextDrawingSize:self.title font:[UIFont systemFontOfSize:15] constrainedSize:CGSizeMake(self.viewSize.width-20, MAXFLOAT)].height;
    self.headView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.viewSize.width, height + 30)];
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, self.headView.frame.size.width - 20, self.headView.frame.size.height)];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont systemFontOfSize:14];
    titleLabel.numberOfLines = 0;
    titleLabel.textColor = RCDYCOLOR(0x8b8b8b, 0x878787);
    titleLabel.text = self.title;
    [self.headView addSubview:titleLabel];
}

- (void)createUI {
    self.frame = [UIScreen mainScreen].bounds;
    [self addSubview:self.maskView];
    [self addSubview:self.tableView];
}

- (UIView *)maskView {
    if (!_maskView) {
        _maskView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _maskView.backgroundColor = [UIColor blackColor];
        _maskView.alpha = 0.4;
        _maskView.userInteractionEnabled = YES;
    }
    return _maskView;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.rowHeight = 56.0;
        _tableView.bounces = NO;
        _tableView.backgroundColor = RCDYCOLOR(0xffffff, 0x1d1d1d);
        _tableView.tableHeaderView = self.headView;
        _tableView.separatorInset = UIEdgeInsetsMake(0, -50, 0, 0);
        _tableView.separatorColor = RCDYCOLOR(0xE3E5E6, 0x2f2f2f);
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"OneCell"];
    }
    return _tableView;
}

#pragma mark <UITableViewDelegate,UITableViewDataSource>
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (section == 0) ? _cellArray.count : 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"OneCell"];
    if (indexPath.section == 0) {
        cell.textLabel.text = _cellArray[indexPath.row];
    } else {
        cell.textLabel.text = _cancelTitle;
    }
    cell.contentView.backgroundColor = RCDYCOLOR(0xffffff, 0x1d1d1d);
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.font = [[RCKitConfig defaultConfig].font fontOfSize:17];
    cell.textLabel.textColor = [RCKitUtility generateDynamicColor:HEXCOLOR(0x333333) darkColor:[HEXCOLOR(0xffffff) colorWithAlphaComponent:0.9]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (self.selectedBlock) {
            self.selectedBlock(indexPath.row);
        }
    } else {
        if (self.cancelBlock) {
            self.cancelBlock();
        }
    }
    [self dismiss];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return (section == 0) ? Space_Line : 0.01f;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == 0) {
        UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, Space_Line)];
        footerView.backgroundColor = RCDYCOLOR(0xf7f7f7, 0x111111);
        return footerView;
    } else {
        return nil;
    }
}

#pragma mark------ 绘制视图
- (void)layoutSubviews {
    [super layoutSubviews];
    [self show];
    UIBezierPath *maskPath =
        [UIBezierPath bezierPathWithRoundedRect:self.tableView.bounds
                              byRoundingCorners:UIRectCornerTopRight | UIRectCornerTopLeft
                                    cornerRadii:CGSizeMake(6, 6)];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = self.tableView.bounds;
    maskLayer.path = maskPath.CGPath;
    _tableView.layer.mask = maskLayer;
}

//滑动弹出
- (void)show {
    _tableView.frame =
        CGRectMake(0, self.viewSize.height, self.viewSize.width,
                   _tableView.rowHeight * (_cellArray.count + 1) + _headView.bounds.size.height + (Space_Line * 2) + [RCKitUtility getWindowSafeAreaInsets].bottom);
    [UIView animateWithDuration:.2
                     animations:^{
                         CGRect rect = _tableView.frame;
                         rect.origin.y -= _tableView.bounds.size.height;
                         _tableView.frame = rect;
                     }];
}

//滑动消失
- (void)dismiss {
    [UIView animateWithDuration:.2
        animations:^{
            CGRect rect = _tableView.frame;
            rect.origin.y += _tableView.bounds.size.height;
            _tableView.frame = rect;
        }
        completion:^(BOOL finished) {
            [self removeFromSuperview];
        }];
}

#pragma mark------ 触摸屏幕其他位置弹下
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self dismiss];
}

@end
