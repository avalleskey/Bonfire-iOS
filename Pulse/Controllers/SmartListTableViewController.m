//
//  SmartListTableViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 12/20/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "SmartListTableViewController.h"
#import "UIColor+Palette.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "Session.h"
#import "ButtonCell.h"
#import "NSString+Validation.h"
#import "ToggleCell.h"
#import "BFHeaderView.h"

#define section(section) self.list.sections[section]
#define row(indexPath) section(indexPath.section).rows[indexPath.row]

#define DEFAULT_ROW_HEIGHT 52
#define RADIO_ROW_HEIGHT 64
#define INPUT_ROW_HEIGHT 52
#define TOGGLE_ROW_HEIGHT 52

@implementation SmartListTableViewController

static NSString * const inputReuseIdentifier = @"InputCell";
static NSString * const buttonReuseIdentifier = @"ButtonCell";
static NSString * const toggleReuseIdentifier = @"ToggleCell";
static NSString * const blankReuseIdentifier = @"BlankCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initDefaults];
}

- (void)initDefaults {
    self.view.tintColor = [UIColor bonfireBrand];
    //self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    
    [self setupTableView];
}

- (void)setupTableView {
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor headerBackgroundColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 16, 0, 0);
    self.tableView.separatorColor = [UIColor separatorColor];
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 48, 0);
    
    // register classes
    [self.tableView registerClass:[InputCell class] forCellReuseIdentifier:inputReuseIdentifier];
    [self.tableView registerClass:[ButtonCell class] forCellReuseIdentifier:buttonReuseIdentifier];
    [self.tableView registerClass:[ToggleCell class] forCellReuseIdentifier:toggleReuseIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:blankReuseIdentifier];
}

- (void)setJsonFile:(NSString *)jsonFile {
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:jsonFile ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:bundlePath];
    if (data == nil) return;

    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];

    if (json == nil) return;
    
    NSError *listError;
    self.list = [[SmartList alloc] initWithDictionary:json error:&listError];
    
    if (listError) {
        NSLog(@"listError: %@", listError);
    }
    
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.list.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.list.sections[section].rows.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SmartListSectionRow *row = row(indexPath);
    
    if (row.input) {
        InputCell *cell = [tableView dequeueReusableCellWithIdentifier:inputReuseIdentifier forIndexPath:indexPath];
        
        if (row.input.keyboard == SmartListInputEmailKeyboard) {
            cell.input.keyboardType = UIKeyboardTypeEmailAddress;
        }
        else {
            cell.input.keyboardType = UIKeyboardTypeDefault;
        }
        
        cell.input.secureTextEntry = row.input.sensitive;
        cell.inputLabel.hidden = !row.title;
        if (row.title) {
            cell.inputLabel.text = [self parse:row.title];
        }
        if (row.input && row.input.text) {
            cell.input.text = [self parse:row.input.text];
        }
        if (row.input && row.input.placeholder) {
            cell.input.placeholder = [self parse:row.input.placeholder];
        }
        
        cell.input.delegate = self;
        [cell.input addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
        
        return cell;
    }
    
    if (row.toggle) {
        ToggleCell *cell = [tableView dequeueReusableCellWithIdentifier:toggleReuseIdentifier forIndexPath:indexPath];
        
        if (row.title) {
            cell.textLabel.text = row.title;
        }
        
        [cell.toggle addTarget:self action:@selector(toggleValueDidChange:) forControlEvents:UIControlEventValueChanged];
        
        return cell;
    }
    
    if (row.title) {
        ButtonCell *cell = [tableView dequeueReusableCellWithIdentifier:buttonReuseIdentifier forIndexPath:indexPath];
        
        if (cell == nil) {
            cell = [[ButtonCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:buttonReuseIdentifier];
        }
        
        // Configure the cell...
        if (row.title) {
            cell.buttonLabel.text = [self parse:row.title];
        }
        
        if (row.push || row.present) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        
        if (row.push || row.present || row.radio || row.detail) {
            cell.buttonLabel.textColor = cell.kButtonColorDefault;
        }
        else if (row.destructive) {
            cell.buttonLabel.textColor = cell.kButtonColorDestructive;
        }
        else {
            // cell.buttonLabel.textColor = cell.kButtonColorBonfire;
            cell.buttonLabel.textColor = cell.kButtonColorDefault;
        }
        
        if (row.radio) {
            cell.checkIcon.hidden = (indexPath.row != 0);
        }
        
        if (row.detail) {
            cell.detailTextLabel.text = [self parse:row.detail];
        }
        
        return cell;
    }
    
    UITableViewCell *blankCell = [tableView dequeueReusableCellWithIdentifier:blankReuseIdentifier forIndexPath:indexPath];
    return blankCell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    SmartListSectionRow *row = row(indexPath);
    if (row.input) {
        // input cell
        return INPUT_ROW_HEIGHT;
    }
    if (row.radio) {
        return RADIO_ROW_HEIGHT;
    }
    if (row.title) {
        return DEFAULT_ROW_HEIGHT;
    }
    if (row.toggle) {
        return TOGGLE_ROW_HEIGHT;
    }
    
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    SmartListSection *s = section(section);
    
    CGFloat headerHeight = [BFHeaderView height];
    
    if (s.title) return headerHeight;
    
    return section == 0 ? 0 : 16;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    SmartListSection *s = section(section);
    
    if (!s.title) return nil;
    
    BFHeaderView *header = [[BFHeaderView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, [BFHeaderView height])];
    header.title = [self parse:s.title];
    header.separator = false;

    return header;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    SmartListSection *s = section(section);
    
    if (s.footer) {
        CGSize labelSize = [[self parse:s.footer] boundingRectWithSize:CGSizeMake(self.view.frame.size.width - 32, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:12.f weight:UIFontWeightRegular]} context:nil].size;
        
        return labelSize.height + (12 * 2); // 24 padding on top and bottom
    }
    
    return CGFLOAT_MIN;
}
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    SmartListSection *s = section(section);
    
    if (s.footer) {
        UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 90)];
        
        UILabel *descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 12, footer.frame.size.width - 24, 42)];
        descriptionLabel.text = [self parse:s.footer];
        descriptionLabel.textColor = [UIColor bonfireGray];
        descriptionLabel.font = [UIFont systemFontOfSize:13.f weight:UIFontWeightRegular];
        descriptionLabel.textAlignment = NSTextAlignmentLeft;
        descriptionLabel.numberOfLines = 0;
        descriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;
        
        CGSize labelSize = [descriptionLabel.text boundingRectWithSize:CGSizeMake(descriptionLabel.frame.size.width, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:descriptionLabel.font} context:nil].size;
        descriptionLabel.frame = CGRectMake(descriptionLabel.frame.origin.x, descriptionLabel.frame.origin.y, descriptionLabel.frame.size.width, labelSize.height);
        [footer addSubview:descriptionLabel];
        
        footer.frame = CGRectMake(0, 0, footer.frame.size.width, descriptionLabel.frame.size.height + (descriptionLabel.frame.origin.y*2));
        
        return footer;
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    SmartListSectionRow *row = row(indexPath);
    [self.smartListDelegate tableView:tableView didSelectRowWithId:row.identifier];
}

- (nullable InputCell *)inputCellForRowId:(NSString *)rowId {
    for (NSInteger i = 0; i < self.list.sections.count; i++) {
        SmartListSection *s = self.list.sections[i];
        for (int x = 0; x < s.rows.count; x++) {
            SmartListSectionRow *r = s.rows[x];
            if ([r.identifier isEqualToString:rowId]) {
                // match!
                InputCell *cell = (InputCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:x inSection:i]];
                
                return cell;
            }
        }
    }
    
    return nil;
}

- (void)textFieldDidChange:(UITextField *)textField {
    CGPoint textFieldPosition = [textField convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:textFieldPosition];
    SmartListSectionRow *r = row(indexPath);
    
    [self.smartListDelegate textFieldDidChange:textField withRowId:r.identifier];
}

- (void)toggleValueDidChange:(UISwitch *)toggle {
    CGPoint switchPosition = [toggle convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:switchPosition];
    SmartListSectionRow *r = row(indexPath);
    
    //[self.smartListDelegate toggleValueDidChange:toggle withRowId:r.identifier];
}

#pragma mark - UITextField Delegate Methods
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    CGPoint textFieldPosition = [textField convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:textFieldPosition];
    SmartListSectionRow *r = row(indexPath);
    
    NSString *newStr = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    if (r.input.validation == SmartListInputEmailValidation) {
        return newStr.length <= MAX_EMAIL_LENGTH ? YES : NO;
    }
    if (r.input.validation == SmartListInputPasswordValidation) {
        return newStr.length <= MAX_PASSWORD_LENGTH ? YES : NO;
    }
    if (r.input.validation == SmartListInputDisplayNameValidation) {
        return newStr.length <= MAX_USER_DISPLAY_NAME_LENGTH ? YES : NO;
    }
    if (r.input.validation == SmartListInputUsernameValidation) {
        if (newStr.length == 0) return NO;
        
        return newStr.length <= MAX_USER_USERNAME_LENGTH ? YES : NO;
    }
    
    return YES;
}

#pragma mark - Data Helper Functions
- (NSString *)parse:(NSString *)string {
    if ([string containsString:@"{username}"]) {
        string = [string stringByReplacingOccurrencesOfString:@"{username}" withString:[Session sharedInstance].currentUser.attributes.details.identifier];
    }
    if ([string containsString:@"{app_version}"]) {
        NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
        string = [string stringByReplacingOccurrencesOfString:@"{app_version}" withString:version];
    }
    if ([string containsString:@"{build_version}"]) {
        NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
        NSString *buildNumber = [infoDict objectForKey:@"CFBundleVersion"];
        
        string = [string stringByReplacingOccurrencesOfString:@"{build_version}" withString:buildNumber];
    }
    
    return string;
}

@end
