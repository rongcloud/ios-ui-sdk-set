//
//  RCGroupProfileMembersCellViewModel.m
//  RongIMKit
//
//  Created by zgh on 2024/8/23.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCGroupProfileMembersCellViewModel.h"
#import "RCGroupProfileMembersCell.h"

@interface RCGroupProfileMembersCellViewModel ()

@property (nonatomic, strong) RCGroupMembersCollectionViewModel *collectionViewModel;

@property (nonatomic, assign) NSInteger showItemCount;

@end

@implementation RCGroupProfileMembersCellViewModel

- (instancetype)initWithItemCount:(NSInteger)showItemCount {
    self = [super init];
    if (self) {
        self.showItemCount = showItemCount;
    }
    return self;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RCGroupProfileMembersCell *cell = [tableView dequeueReusableCellWithIdentifier:RCGroupProfileMembersCellIdentifier forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    [cell.membersView configViewModel:self.collectionViewModel];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat result = (CGFloat)self.showItemCount / RCGroupMembersCollectionViewModelPortraitLineCount;
    NSInteger line = ceil(result);
    return RCGroupProfileMembersCellTextTopSpace + RCGroupProfileMembersCellTextBottomSpace + RCGroupMembersCollectionViewModelItemHeight * line + RCGroupMembersCollectionViewModelLineSpace * (line - 1);
}

- (void)configViewModel:(RCGroupMembersCollectionViewModel *)viewModel {
    self.collectionViewModel = viewModel;
}

#pragma mark -- getter & setter

- (void)setDelegate:(id<RCGroupMembersCollectionViewModelDelegate>)delegate {
    self.collectionViewModel.delegate = delegate;
}

- (id<RCGroupMembersCollectionViewModelDelegate>)delegate {
    return self.collectionViewModel.delegate;
}

@end
