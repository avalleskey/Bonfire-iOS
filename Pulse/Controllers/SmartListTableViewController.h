//
//  SmartListTableViewController.h
//  Pulse
//
//  Created by Austin Valleskey on 12/28/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Launcher.h"
#import "Session.h"
#import "UIColor+Palette.h"
#import "InputCell.h"
#import "SmartList.h"

NS_ASSUME_NONNULL_BEGIN

@protocol SmartListDelegate <NSObject>

@optional

- (void)tableView:(UITableView *)tableView didSelectRowWithId:(NSString *)rowId;
- (void)textFieldDidChange:(UITextField *)textField withRowId:(NSString *)rowId;
- (void)toggleValueDidChange:(UISwitch *)toggle withRowId:(NSString *)rowId;

- (UIView * _Nullable)alternativeViewForHeaderInSection:(NSInteger)section;
- (CGFloat)alternativeHeightForHeaderInSection:(NSInteger)section;

- (UIView * _Nullable)alternativeViewForFooterInSection:(NSInteger)section;
- (CGFloat)alternativeHeightForFooterInSection:(NSInteger)section;

@end

@interface SmartListTableViewController : UITableViewController <UITextFieldDelegate>

@property (nonatomic, strong) NSString *jsonFile;

@property (nonatomic, strong) SmartList *list;
@property (weak, nonatomic) id <SmartListDelegate> smartListDelegate;

- (nullable InputCell *)inputCellForRowId:(NSString *)rowId;

@end

NS_ASSUME_NONNULL_END
