//
//  NotificationsTableViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 12/5/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "NotificationsTableViewController.h"
#import "NotificationCell.h"
#import "NSAttributedString+NotificationConveniences.h"
#import "UIColor+Palette.h"
#import "Session.h"

@interface NotificationsTableViewController ()

@property (strong, nonatomic) NSMutableArray *notifications;

@end

@implementation NotificationsTableViewController

static NSString * const notificationCellReuseIdentifier = @"NotificationCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.notifications = [[NSMutableArray alloc] initWithArray:@[@{}, @{}, @{}, @{}, @{}, @{}]];
    [self setupTableView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userProfileUpdated:) name:@"UserUpdated" object:nil];
}

- (void)userProfileUpdated:(NSNotification *)notification {
    [self.tableView reloadData];
}

- (void)setupTableView {
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 48, 0);
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableView registerClass:[NotificationCell class] forCellReuseIdentifier:notificationCellReuseIdentifier];
}

- (NSArray *)newNotifications {
    // notifications earlier than x time interval
    
    return self.notifications;
}
- (NSArray *)oldNotifications {
    // notificationsl later than or equal to x time interval
    
    return self.notifications;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? [self newNotifications].count : [self oldNotifications].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NotificationCell *cell = [tableView dequeueReusableCellWithIdentifier:notificationCellReuseIdentifier forIndexPath:indexPath];
        
    // Configure the cell...
    switch (indexPath.row) {
        case 0:
            cell.type = NotificationTypeUserNewFollower;
            break;
        case 1:
            cell.type = NotificationTypeRoomJoinRequest;
            break;
        case 2:
            cell.type = NotificationTypeRoomNewMember;
            break;
        case 3:
            cell.type = NotificationTypeRoomApprovedRequest;
            break;
        case 4:
            cell.type = NotificationTypePostReply;
            break;
        case 5:
            cell.type = NotificationTypePostSparks;
            break;
            
        default:
            break;
    }
    cell.textLabel.attributedText = [NSAttributedString attributedStringForType:cell.type];
    
    cell.profilePicture.tintColor = [UIColor bonfireBlue];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat minHeight = 62;
    
    CGFloat topPadding = 14;
    CGFloat bottomPadding = topPadding;
    
    NotificationType type;
    switch (indexPath.row) {
        case 0:
            type = NotificationTypeUserNewFollower;
            break;
        case 1:
            type = NotificationTypeRoomJoinRequest;
            break;
        case 2:
            type = NotificationTypeRoomNewMember;
            break;
        case 3:
            type = NotificationTypeRoomApprovedRequest;
            break;
        case 4:
            type = NotificationTypePostReply;
            break;
        case 5:
            type = NotificationTypePostSparks;
            break;
            
        default:
            type = NotificationTypeUnkown;
            break;
    }
    
    CGFloat actionButtonWidth = 96;
    CGFloat textLabelWidth = self.view.frame.size.width - 70 - actionButtonWidth - 16  - 10;
    CGRect textLabelRect = [[NSAttributedString attributedStringForType:type] boundingRectWithSize:CGSizeMake(textLabelWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) context:nil];
    
    CGFloat calculatedHeight = topPadding + textLabelRect.size.height + bottomPadding;
    
    NSLog(@"calculatedHeight: %f", calculatedHeight);
    
    return calculatedHeight < minHeight ? minHeight : calculatedHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0 && [self newNotifications].count == 0) return CGFLOAT_MIN;
    if (section == 1 && [self oldNotifications].count == 0) return CGFLOAT_MIN;
    
    return 48;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0 && [self newNotifications].count == 0) return nil;
    if (section == 1 && [self oldNotifications].count == 0) return nil;
    
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 52)];
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(16, 21, self.view.frame.size.width - 32, 19)];
    title.textAlignment = NSTextAlignmentLeft;
    title.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightBold];
    title.textColor = [UIColor colorWithWhite:0.07f alpha:1];
    title.text = section == 0 ? @"New" : @"Earlier";
    [header addSubview:title];
    
    UIView *hairline = [[UIView alloc] initWithFrame:CGRectMake(0, header.frame.size.height - (1 / [UIScreen mainScreen].scale), header.frame.size.width, (1 / [UIScreen mainScreen].scale))];
    hairline.backgroundColor = [UIColor colorWithWhite:0 alpha:0.08f];
    //[header addSubview:hairline];
    
    return header;
    
    return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 0 && [self newNotifications].count == 0) return CGFLOAT_MIN;
    if (section == 1 && [self oldNotifications].count == 0) return CGFLOAT_MIN;
    
    return (1 / [UIScreen mainScreen].scale);
}
- (UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section {
    if (section == 0 && [self newNotifications].count == 0) return nil;
    if (section == 1 && [self oldNotifications].count == 0) return nil;
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, (1 / [UIScreen mainScreen].scale))];
    view.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1];
    
    return view;
}

@end
