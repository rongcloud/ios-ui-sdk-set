//
//  RCPublicServiceMultiImgTxtCell.m
//  RongIMKit
//
//  Created by litao on 15/4/14.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCPublicServiceMultiImgTxtCell.h"
#import "RCPublicServiceMultiImgTxtCellContentCell.h"
#import "RCPublicServiceMultiImgTxtCellHeaderCell.h"
#import "RCPublicServiceViewConstants.h"
#import <RongPublicService/RongPublicService.h>
@interface RCPublicServiceMultiImgTxtCell () <UITableViewDataSource, UITableViewDelegate,
                                              RCPublicServiceMultiImgTxtCellContentCellDelegate,
                                              RCPublicServiceMultiImgTxtCellHeaderCellDelegate>
@property (nonatomic, strong) UITableView *tableView;
@end

@implementation RCPublicServiceMultiImgTxtCell
+ (CGSize)sizeForMessageModel:(RCMessageModel *)model
      withCollectionViewWidth:(CGFloat)collectionViewWidth
         referenceExtraHeight:(CGFloat)extraHeight {

    CGFloat height =
        [self getCellHeight:(RCPublicServiceMultiRichContentMessage *)model.content withWidth:collectionViewWidth];
    // ypf update (-5)
    height = height + extraHeight;

    return CGSizeMake(collectionViewWidth, height);
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setup];
        self.allowsSelection = YES;
    }
    return self;
}

- (void)setDataModel:(RCMessageModel *)model {
    [super setDataModel:model];
    CGRect rect =
        CGRectMake(RCPublicServiceCellPaddingLeft, RCPublicServiceCellPaddingTop,
                   self.frame.size.width - RCPublicServiceCellPaddingLeft - RCPublicServiceCellPaddingRight,
                   [RCPublicServiceMultiImgTxtCell getCellHeight:(RCPublicServiceMultiRichContentMessage *)model.content
                                                       withWidth:self.frame.size.width]);
    self.tableView.frame = rect;
    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableView setSeparatorInset:UIEdgeInsetsMake(0, RCPublicServiceCellContentPaddingLeft, 0,
                                                           RCPublicServiceCellContentPaddingRight +
                                                               RCPublicServiceCellContentPadding +
                                                               RCPublicServiceCellContentCellImageWidth)];
    }
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return ((RCPublicServiceMultiRichContentMessage *)self.model.content).richContents.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RCPublicServiceMultiRichContentMessage *content = (RCPublicServiceMultiRichContentMessage *)self.model.content;
    if (indexPath.row == 0) {
        RCPublicServiceMultiImgTxtCellHeaderCell *cell =
            [tableView dequeueReusableCellWithIdentifier:@"mpnewscellheadercell"];
        if (!cell) {
            cell = [[RCPublicServiceMultiImgTxtCellHeaderCell alloc] initWithFrame:tableView.frame
                                                                   reuseIdentifier:@"mpnewscellheadercell"];
        }
        cell.publicServiceDelegate = self.publicServiceDelegate;
        cell.delegate = self;
        cell.richContent = content.richContents[indexPath.row];
        cell.separatorInset = UIEdgeInsetsMake(0, cell.bounds.size.width, 0, 0);
        return cell;
    } else {
        RCPublicServiceMultiImgTxtCellContentCell *cell =
            [tableView dequeueReusableCellWithIdentifier:@"mpnewscellcontentcell"];
        if (!cell) {
            cell = [[RCPublicServiceMultiImgTxtCellContentCell alloc] initWithFrame:tableView.frame
                                                                    reuseIdentifier:@"mpnewscellcontentcell"];
        }
        cell.publicServiceDelegate = self.publicServiceDelegate;
        cell.delegate = self;
        if (indexPath.row == content.richContents.count - 1) {
            cell.separatorInset = UIEdgeInsetsMake(0, self.bounds.size.width, 0, 0);
        } else {
            cell.separatorInset =
                UIEdgeInsetsMake(0, RCPublicServiceCellContentPaddingLeft, 0,
                                 RCPublicServiceCellContentPaddingRight + RCPublicServiceCellContentPadding +
                                     RCPublicServiceCellContentCellImageWidth);
        }
        cell.richContent = content.richContents[indexPath.row];
        return cell;
    }
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        return ceilf(
            [RCPublicServiceMultiImgTxtCellHeaderCell getHeaderCellHeightWithWidth:tableView.frame.size.width]);
    } else {
        RCPublicServiceMultiRichContentMessage *content = (RCPublicServiceMultiRichContentMessage *)self.model.content;
        return ceilf(
            [RCPublicServiceMultiImgTxtCellContentCell getContentCellHeight:content.richContents[indexPath.row]]);
    }
}

#pragma mark – Private Methods

- (void)longPressAction:(UITableViewCell *)cell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    RCPublicServiceMultiRichContentMessage *content = (RCPublicServiceMultiRichContentMessage *)self.model.content;
    [content setValue:@(indexPath.row) forKey:@"selectedItemIndex"];
    [self.publicServiceDelegate didLongTouchPublicServiceMessageCell:self.model inView:cell];
}

- (void)setup {
    [self.baseContentView addSubview:self.tableView];
}

+ (CGFloat)getCellHeight:(RCPublicServiceMultiRichContentMessage *)mpMsg withWidth:(CGFloat)width {
    width = width - RCPublicServiceCellPaddingLeft - RCPublicServiceCellPaddingRight;
    CGFloat height = 0;
    for (int i = 0; i < mpMsg.richContents.count; i++) {
        if (i == 0) {
            height += [RCPublicServiceMultiImgTxtCellHeaderCell getHeaderCellHeightWithWidth:width];
        } else {
            RCRichContentMessage *richContentMsg = mpMsg.richContents[i];
            height += [RCPublicServiceMultiImgTxtCellContentCell getContentCellHeight:richContentMsg];
        }
    }
    return height;
}
#pragma mark – Getters and Setters

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.layer.cornerRadius = 4;
        _tableView.layer.masksToBounds = YES;
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.scrollEnabled = NO;
        _tableView.separatorColor = [UIColor colorWithRed:229 / 255.0 green:229 / 255.0 blue:229 / 255.0 alpha:1];
        _tableView.tableFooterView = [UIView new];
    }
    return _tableView;
}

@end
