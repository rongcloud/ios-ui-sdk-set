//
//  RCFileSelectorViewController.m
//  RongExtensionKit
//
//  Created by Jue on 16/4/25.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCFileSelectorViewController.h"
#import "RCKitCommonDefine.h"
#import "RCSelectDirectoryTableViewCell.h"
#import "RCSelectFilesTableViewCell.h"
#import "RCKitConfig.h"
#import "RCAlertView.h"
#import "RCSemanticContext.h"
@interface RCFileSelectorViewController ()

@property (nonatomic, strong) NSString *rootPath;
@property (nonatomic, assign) int maxSelectedNumber;
@property (nonatomic, strong) NSMutableArray *dataSource;
@property (nonatomic, strong) UIBarButtonItem *rightItem;
@property (nonatomic, strong) UIButton *buttonDone;
@end

static NSString *const RCFileValue = @"File";
static NSString *const RCDirectotyValue = @"Directory";
static NSString *const RCTypeValue = @"Type";
static NSString *const RCListValue = @"List";

@implementation RCFileSelectorViewController
#pragma mark - Life Cycle
- (instancetype)initWithRootPath:(NSString *)rootPath {
    self = [super init];
    if (self) {
        self.rootPath = rootPath;
        self.maxSelectedNumber = 20;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    //去除多余的分割线
    self.tableView.tableFooterView = [[UIView alloc] init];
    //控制多选
    self.tableView.allowsMultipleSelection = YES;
    //分割线的颜色
    self.tableView.backgroundColor = RCDynamicColor(@"auxiliary_background_1_color", @"0xf5f6f9", @"0x111111");
    self.tableView.separatorColor = RCDynamicColor(@"line_background_color", @"0xE3E5E6", @"0x272727");


    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableView setSeparatorInset:UIEdgeInsetsMake(0, 45, 0, 0)];
    }
    if ([self.tableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.tableView setLayoutMargins:UIEdgeInsetsMake(0, 45, 0, 0)];
    }

    self.navigationItem.title = RCLocalizedString(@"SendFile");
    UIImage *imgMirror = RCDynamicImage(@"navigation_bar_btn_back_img", @"navigator_btn_back");
    imgMirror = [RCSemanticContext imageflippedForRTL:imgMirror];
    if (self.isSubDirectory) {
        self.navigationItem.leftBarButtonItems = [RCKitUtility getLeftNavigationItems:imgMirror title:RCLocalizedString(@"Back") target:self action:@selector(clickBackBtn:)];
    } else {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn addTarget:self
                action:@selector(clickCancelBtn:)
      forControlEvents:UIControlEventTouchUpInside];
        UIColor *color =  RCKitConfigCenter.ui.globalNavigationBarTintColor;
        btn.tintColor = color;
        [btn setTitleColor:color forState:UIControlStateNormal];
        [btn setTitle:RCLocalizedString(@"Cancel") forState:UIControlStateNormal];
        [btn sizeToFit];
        UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithCustomView:btn];

        self.navigationItem.leftBarButtonItem = leftItem;
    }
    [self getDataSourceList];
}
 
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    UIColor *color = nil;
    if ([RCKitUtility isTraditionInnerThemes]) {
        color = [RCKitUtility
                          generateDynamicColor:RCResourceColor(@"fileSelect_confirm_text", @"0x9fcdfd")
                                     darkColor:RCResourceColor(@"fileSelect_confirm_text_dark", @"0x666666")];
    } else {
        color = RCDynamicColor(@"primary_color", @"0x9fcdfd", @"0x666666");
    }

    [btn setTitleColor:color forState:UIControlStateNormal];
    [btn addTarget:self
            action:@selector(clickDoneBtn:)
  forControlEvents:UIControlEventTouchUpInside];
    [btn setTitle:RCLocalizedString(@"Confirm") forState:UIControlStateNormal];
    [btn sizeToFit];
    self.buttonDone = btn;
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithCustomView:btn];
    [self.navigationItem setRightBarButtonItem:rightItem];
    self.navigationItem.rightBarButtonItem.enabled = NO;
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.dataSource.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSDictionary *dict = self.dataSource[section];
    NSArray *list = dict[RCListValue];
    return list.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *directoryCellReuseIdentifier = @"RCFileSelectorViewControllerDirectoryCellReuseId";
    NSString *cellReuseIdentifier = @"RCFileSelectorViewControllerCellReuseId";

    NSDictionary *dict = self.dataSource[indexPath.section];
    NSArray *list = dict[RCListValue];
    NSString *type = dict[RCTypeValue];

    UITableViewCell *retCell = nil;
    if ([type isEqualToString:RCFileValue]) {
        RCSelectFilesTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellReuseIdentifier];
        if (cell == nil) {
            cell = [[RCSelectFilesTableViewCell alloc] init];
        }
        NSString *fileName = list[indexPath.row];
        cell.fileNameLabel.text = fileName;
        cell.fileIconImageView.image = [RCKitUtility imageWithFileSuffix:[fileName pathExtension]];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        retCell = cell;
    } else {
        RCSelectDirectoryTableViewCell *directoryCell =
            [tableView dequeueReusableCellWithIdentifier:directoryCellReuseIdentifier];
        if (directoryCell == nil) {
            directoryCell = [[RCSelectDirectoryTableViewCell alloc] init];
        }
        NSString *path = list[indexPath.row];
        directoryCell.directoryNameLabel.text = path;
        directoryCell.selectionStyle = UITableViewCellSelectionStyleNone;
        retCell = directoryCell;
    }
    return retCell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 51.5f;
}

- (nullable NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *indexPaths = [self.tableView indexPathsForSelectedRows];
    if (indexPaths.count >= self.maxSelectedNumber) {
        return nil;
    } else {
        return indexPath;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([[tableView cellForRowAtIndexPath:indexPath] isKindOfClass:[RCSelectDirectoryTableViewCell class]]) {
        NSString *dir = self.dataSource[indexPath.section][RCListValue][indexPath.row];
        [self selecteDirectory:dir];
    } else if ([[tableView cellForRowAtIndexPath:indexPath] isKindOfClass:[RCSelectFilesTableViewCell class]]) {
        NSDictionary *dict = self.dataSource[indexPath.section];
        NSArray *list = dict[RCListValue];
        NSString *filePath = [NSString stringWithFormat:@"%@/%@", self.rootPath, list[indexPath.row]];
        if ([self.delegate respondsToSelector:@selector(canBeSelectedAtPath:)]) {
            if (![self.delegate canBeSelectedAtPath:filePath]) {
                [tableView deselectRowAtIndexPath:indexPath animated:NO];
                return;
            }
        } else {
            if ([self isOverMaximum:filePath]) {
                [tableView deselectRowAtIndexPath:indexPath animated:NO];
                [self presentOverMaximumAlert];
            } else {
                [self selecteFile:(RCSelectFilesTableViewCell *)[tableView cellForRowAtIndexPath:indexPath]];
            }
        }
    }
    [self updateRightButtonLayout];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self updateRightButtonLayout];
}

#pragma mark - Private Methods
- (RCSelectFilesTableViewCell *)getSelectFilesTableViewCell:(RCSelectFilesTableViewCell *)cell
                                                     source:(NSArray *)source
                                                        row:(NSInteger)row {
    NSString *fileName = [source objectAtIndex:row];
    cell.fileNameLabel.text = fileName;
    cell.fileIconImageView.image = [RCKitUtility imageWithFileSuffix:[fileName pathExtension]];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (RCSelectDirectoryTableViewCell *)getSelectDirectoryTableViewCell:(RCSelectDirectoryTableViewCell *)cell
                                                             source:(NSArray *)source
                                                                row:(NSInteger)row {
    cell.directoryNameLabel.text = source[row];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (void)selecteFile:(RCSelectFilesTableViewCell *)cell {
    [cell setSelected:YES];
    [self updateRightButtonLayout];
}

- (void)selecteDirectory:(NSString *)directoryName {
    RCFileSelectorViewController *vc = [[RCFileSelectorViewController alloc]
        initWithRootPath:[NSString stringWithFormat:@"%@/%@", self.rootPath, directoryName]];
    vc.isSubDirectory = YES;
    vc.delegate = self.delegate;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)clickBackBtn:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)clickCancelBtn:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)clickDoneBtn:(id)sender {
    NSMutableArray *selectedFileList = [[NSMutableArray alloc] init];
    __block NSArray *fileList;
    [self.dataSource enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        NSDictionary *dict = (NSDictionary *)obj;
        if ([dict[RCTypeValue] isEqualToString:RCFileValue]) {
            fileList = dict[RCListValue];
            *stop = YES;
        }
    }];
    for (NSIndexPath *indexPath in [self.tableView indexPathsForSelectedRows]) {
        [selectedFileList
            addObject:[NSString stringWithFormat:@"%@/%@", self.rootPath, [fileList objectAtIndex:indexPath.row]]];
    }

    if ([self.delegate respondsToSelector:@selector(fileDidSelect:)]) {
        [self.delegate fileDidSelect:[selectedFileList copy]];
    }

    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)getDataSourceList {
    NSString *filePath = self.rootPath;
    NSMutableArray *fileList = [[NSMutableArray alloc] init];
    NSMutableArray *docList = [[NSMutableArray alloc] init];
    for (NSString *file in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:filePath error:nil]) {
        BOOL fool;
        [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@/%@", filePath, file]
                                             isDirectory:&fool];
        if (!fool) {
            [fileList addObject:file];
        } else {
            [docList addObject:file];
        }
    }
    self.dataSource = [[NSMutableArray alloc] init];
    if (docList.count > 0) {
        [self.dataSource addObject:@{RCTypeValue : RCDirectotyValue, RCListValue : docList}];
    }
    if (fileList.count > 0) {
        [self.dataSource addObject:@{RCTypeValue : RCFileValue, RCListValue : fileList}];
    }
}

- (void)updateRightButtonLayout {
    NSArray *indexPaths = [self.tableView indexPathsForSelectedRows];

    if (indexPaths.count > 0) {
        self.navigationItem.rightBarButtonItem.enabled = YES;
        NSString *title = [RCLocalizedString(@"Confirm")
            stringByAppendingString:[NSString stringWithFormat:@"(%ld/20)", (long)indexPaths.count]];
        UIColor *color = RCDynamicResourceColor(@"primary_color", @"confirm_text_enable", @"0x0099ff");
        [self.buttonDone setTitleColor:color forState:UIControlStateNormal];
        [self.buttonDone setTitle: title forState:UIControlStateNormal];
        
    } else {
        UIColor *color = nil;
        if ([RCKitUtility isTraditionInnerThemes]) {
            color = [RCKitUtility
                              generateDynamicColor:RCResourceColor(@"fileSelect_confirm_text", @"0x9fcdfd")
                                         darkColor:RCResourceColor(@"fileSelect_confirm_text_dark", @"0x666666")];
        } else {
            color = RCDynamicColor(@"primary_color", @"0x9fcdfd", @"0x666666");
        }
        self.navigationItem.rightBarButtonItem.enabled = NO;
        [self.buttonDone setTitleColor:color forState:UIControlStateNormal];
        [self.buttonDone setTitle: RCLocalizedString(@"Confirm") forState:UIControlStateNormal];
    }
    [self.buttonDone sizeToFit];
}

- (BOOL)isOverMaximum:(NSString *)filePath {
    BOOL isOverMaximum = NO;
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
    unsigned long long length = [fileAttributes fileSize];
    float ff = length / 1024.0 / 1024.0;
    if (ff > 100) {
        isOverMaximum = YES;
    }
    return isOverMaximum;
}

- (void)presentOverMaximumAlert {
    [RCAlertView showAlertController:nil message:RCLocalizedString(@"OvermMaximum") cancelTitle:RCLocalizedString(@"OK") inViewController:self];
}

@end
