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

NS_ASSUME_NONNULL_BEGIN

@protocol SmartListDelegate <NSObject>

@optional
- (void)tableView:(UITableView *)tableView didSelectRowWithId:(NSString *)rowId;
- (void)textFieldDidChange:(UITextField *)textField withRowId:(NSString *)rowId;

@end

@interface SmartListTableViewController : UITableViewController <UITextFieldDelegate>

@property (strong, nonatomic) NSString *jsonFile;

@property (weak, nonatomic) id <SmartListDelegate> smartListDelegate;

- (nullable InputCell *)inputCellForRowId:(NSString *)rowId;

@end

NS_ASSUME_NONNULL_END
