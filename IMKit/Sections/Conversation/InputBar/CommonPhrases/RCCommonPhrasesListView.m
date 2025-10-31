//
//  RCCommonPhrasesListView.m
//  RongExtensionKit
//
//  Created by liyan on 2019/7/9.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import "RCCommonPhrasesListView.h"
#import "RCCommonPhrasesCell.h"
#import "RCKitCommonDefine.h"
#import "RCBaseTableView.h"
@interface RCCommonPhrasesListView () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) RCBaseTableView *commmonPhrasesTableView;

@end

@implementation RCCommonPhrasesListView

- (instancetype)initWithFrame:(CGRect)frame dataSource:(NSArray *)dataSource {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = RCDynamicColor(@"common_background_color", @"0xF5F6F9", @"0x1c1c1c");;
        self.dataSource = dataSource;
        [self addSubview:self.commmonPhrasesTableView];
    }
    return self;
}

#pragma mark - tableViewDelegate
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.dataSource.count <= indexPath.row) {
        return nil;
    }
    static NSString *cellName = @"RCCommonPhrasesCell";
    RCCommonPhrasesCell *cell = [tableView dequeueReusableCellWithIdentifier:cellName];
    if (cell == nil) {
        cell = [[RCCommonPhrasesCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellName];
    }
    [cell setLableText:[self.dataSource objectAtIndex:indexPath.row]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.dataSource.count > indexPath.row) {
        if ([self.delegate respondsToSelector:@selector(didTouchCommonPhrasesView:)]) {
            [self.delegate didTouchCommonPhrasesView:[self.dataSource objectAtIndex:indexPath.row]];
        }
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.dataSource != nil) {
        return self.dataSource.count;
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [RCCommonPhrasesCell heightForCommonPhrasesCell:[self.dataSource objectAtIndex:indexPath.row]];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return CGFLOAT_MIN;
}

#pragma mark - Getters and Setters

- (RCBaseTableView *)commmonPhrasesTableView {
    if (!_commmonPhrasesTableView) {
        CGSize size = self.bounds.size;
        _commmonPhrasesTableView =
            [[RCBaseTableView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height) style:UITableViewStyleGrouped];
        _commmonPhrasesTableView.estimatedRowHeight = 0;
        _commmonPhrasesTableView.estimatedSectionHeaderHeight = 0;
        _commmonPhrasesTableView.estimatedSectionFooterHeight = 0;
        _commmonPhrasesTableView.backgroundColor = [UIColor clearColor];
        _commmonPhrasesTableView.delegate = self;
        _commmonPhrasesTableView.dataSource = self;
        _commmonPhrasesTableView.bounces = NO;
        if (@available(iOS 11.0, *)) {
            _commmonPhrasesTableView.insetsContentViewsToSafeArea = NO;
        }
        _commmonPhrasesTableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
        _commmonPhrasesTableView.separatorColor = RCDynamicColor(@"line_background_color", @"0xE3E5E6", @"0x272727");
        _commmonPhrasesTableView.showsVerticalScrollIndicator = NO;
    }
    return _commmonPhrasesTableView;
}

- (NSArray *)dataSource {
    if (!_dataSource) {
        _dataSource = [[NSArray alloc] init];
    }
    return _dataSource;
}

- (void)reloadCommonPhrasesList {
    [self.commmonPhrasesTableView reloadData];
}

@end
