//
//  MyRoomsViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 9/29/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "MyRoomsViewController.h"
#import "Session.h"
#import "ChannelCell.h"
#import "EmptyChannelCell.h"
#import "ErrorChannelCell.h"
#import "SimpleNavigationController.h"
#import "Launcher.h"
#import "MyRoomsListCell.h"
#import "RoomSuggestionsListCell.h"
#import "TabController.h"
#import "UIColor+Palette.h"
#import <Tweaks/FBTweakInline.h>

#define envConfig [[[NSUserDefaults standardUserDefaults] objectForKey:@"config"] objectForKey:[[NSUserDefaults standardUserDefaults] stringForKey:@"environment"]]

@interface MyRoomsViewController ()

@property (strong, nonatomic) SimpleNavigationController *simpleNav;
@property (strong, nonatomic) NSMutableArray *rooms;
@property (nonatomic) BOOL loading;
@property (nonatomic) BOOL errorLoading;
@property (nonatomic) BOOL userDidRefresh;

@end


@implementation MyRoomsViewController

static NSString * const reuseIdentifier = @"RoomCell";
static NSString * const emptyRoomCellReuseIdentifier = @"EmptyRoomCell";
static NSString * const errorRoomCellReuseIdentifier = @"ErrorRoomCell";

static NSString * const miniRoomCellReuseIdentifier = @"MiniCell";
static NSString * const myRoomsCellReuseIdentifier = @"MyRoomsCell";

static NSString * const blankReuseIdentifier = @"BlankCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.simpleNav = (SimpleNavigationController *)self.navigationController;
    
    self.rooms = [[NSMutableArray alloc] init];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.loading = true;
    self.errorLoading = false;
    
    //[self setupCreateRoomButton];
    [self setupTableView];
    
    self.manager = [HAWebService manager];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userProfileUpdated:) name:@"UserUpdated" object:nil];
}

- (void)userProfileUpdated:(NSNotification *)notification {
    self.navigationController.navigationBar.tintColor = [Session sharedInstance].themeColor;
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.simpleNav == nil) {
        self.simpleNav = (SimpleNavigationController *)self.navigationController;
        self.simpleNav.titleLabel.alpha = 0;
        self.simpleNav.hairline.alpha = 0;
        self.simpleNav.blurView.alpha = 0;
    }
    
    if (self.createRoomButton.alpha == 0) {
        [self.navigationController.view addSubview:self.createRoomButton];
        
        self.createRoomButton.frame = CGRectMake((self.view.frame.size.width / 2)  - (self.createRoomButton.frame.size.width / 2), self.tabBarController.tabBar.frame.origin.y - self.createRoomButton.frame.size.height - 12, self.createRoomButton.frame.size.width, self.createRoomButton.frame.size.height);
        self.createRoomButton.transform = CGAffineTransformMakeScale(0.5, 0.5);
        [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.createRoomButton.transform = CGAffineTransformMakeScale(1, 1);
            self.createRoomButton.alpha = 1;
        } completion:nil];
    }
    
    CGFloat navigationHeight = self.navigationController != nil ? self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height : 0;
    self.tableView.frame = CGRectMake(0, 0, self.view.frame.size.width, [UIScreen mainScreen].bounds.size.height - navigationHeight);
}
- (void)refresh {
    NSLog(@"refresh yo");
    
    self.userDidRefresh = true;
}
- (void)setupTableView {
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView setSeparatorColor:[UIColor clearColor]];
    self.tableView.refreshControl = [[UIRefreshControl alloc] init];
    [self.tableView.refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 12 + 12 + self.createRoomButton.frame.size.height, 0);
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 0, 0);
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:blankReuseIdentifier];
    [self.tableView registerClass:[MyRoomsListCell class] forCellReuseIdentifier:myRoomsCellReuseIdentifier];
    [self.tableView registerClass:[RoomSuggestionsListCell class] forCellReuseIdentifier:miniRoomCellReuseIdentifier];
    
    UIView *headerHack = [[UIView alloc] initWithFrame:CGRectMake(0, -1 * self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height)];
    headerHack.backgroundColor = [UIColor headerBackgroundColor];
    [self.tableView insertSubview:headerHack atIndex:0];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView == self.tableView) {
        CGFloat baseline = -1 * (self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height);
        
        if (scrollView.contentOffset.y > baseline + 56) {
            if (self.simpleNav.hairline.alpha == 0) {
                [UIView animateWithDuration:0.1f animations:^{
                    self.simpleNav.hairline.alpha = 1;
                }];
            }
        }
        else {
            if (self.simpleNav.hairline.alpha == 1) {
                [UIView animateWithDuration:0.1f animations:^{
                    self.simpleNav.hairline.alpha = 0;
                }];
            }
        }
        
        if (scrollView.contentOffset.y > baseline + 20) {
            if (self.simpleNav.titleLabel.alpha == 0) {
                [UIView animateWithDuration:0.1f animations:^{
                    self.simpleNav.titleLabel.alpha = 1;
                    self.simpleNav.blurView.alpha = 1;
                }];
            }
        }
        else {
            if (self.simpleNav.titleLabel.alpha == 1) {
                [UIView animateWithDuration:0.1f animations:^{
                    self.simpleNav.titleLabel.alpha = 0;
                    self.simpleNav.blurView.alpha = 0;
                }];
            }
            
            CGFloat headerOpacity = 1 - ((scrollView.contentOffset.y - baseline) / 20);
            MyRoomsListCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            [UIView animateWithDuration:0.1f animations:^{
                cell.bigTitle.alpha = headerOpacity;
            }];
        }
    }
}

- (void)getRooms {
    NSString *url;// = [NSString stringWithFormat:@"%@/%@/schools/%@/channels", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"], @"2"];
    //url = @"https://rawgit.com/avalleskey/avalleskey.github.io/master/sample_rooms2.json"; // sample data
    url = [NSString stringWithFormat:@"%@/%@/users/me/rooms", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"]];
    
    [[Session sharedInstance] authenticate:^(BOOL success, NSString *token) {
        if (success) {
            [self.manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
            
            [self.manager GET:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                // NSLog(@"MyRoomsViewController / getRooms() success! ✅");
                
                NSArray *responseData = responseObject[@"data"];
                
                // NSLog(@"responseData: %@", responseData);
                
                if (responseData.count > 0) {
                    self.rooms = [[NSMutableArray alloc] initWithArray:responseData];
                }
                else {
                    self.rooms = [[NSMutableArray alloc] init];
                }
                
                self.loading = false;
                self.errorLoading = false;
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"MyRoomsViewController / getRooms() - error: %@", error);
                //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                
                self.loading = false;
                self.errorLoading = true;
            }];
        }
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        MyRoomsListCell *cell = [tableView dequeueReusableCellWithIdentifier:myRoomsCellReuseIdentifier forIndexPath:indexPath];
        
        if (cell == nil) {
            cell = [[MyRoomsListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:myRoomsCellReuseIdentifier];
        }
        
        cell.collectionView.frame = CGRectMake(0, 0, cell.frame.size.width, cell.frame.size.height);
        cell.backgroundColor = [UIColor headerBackgroundColor];
        
        return cell;
    }
    else {
        RoomSuggestionsListCell *cell = [tableView dequeueReusableCellWithIdentifier:miniRoomCellReuseIdentifier forIndexPath:indexPath];
        
        if (cell == nil) {
            cell = [[RoomSuggestionsListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:miniRoomCellReuseIdentifier];
        }
        
        cell.collectionView.frame = CGRectMake(0, 0, cell.frame.size.width, cell.frame.size.height);
        cell.lineSeparator.hidden = true;
        
        return cell;
    }
    
    /*
    UITableViewCell *blankCell = [tableView dequeueReusableCellWithIdentifier:blankReuseIdentifier forIndexPath:indexPath];
    
    blankCell.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1];
    
    return blankCell;*/
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat roomHeaderHeight = FBTweakValue(@"Rooms", @"My Rooms", @"Room Height", 400);
    
    return indexPath.section == 0 ? (8 + 108) + roomHeaderHeight + 40 : 240;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) return 0;
    
    return 64;
}
- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    //if (section > 1) return nil;
    
    if (section == 100) {
        UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 48)];
        header.backgroundColor = [UIColor headerBackgroundColor];
        return header;
        
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(16, 26, self.view.frame.size.width - 16 - 56 - 16, 32)];
        title.text = @"Rooms";
        title.textAlignment = NSTextAlignmentLeft;
        title.font = [UIFont systemFontOfSize:26.f weight:UIFontWeightHeavy];
        title.textColor = [UIColor bonfireGrayWithLevel:900];
        
        [header addSubview:title];
        
        UILabel *subtitle = [[UILabel alloc] initWithFrame:CGRectMake(16, 59, self.view.frame.size.width - 16 - 56 - 16, 26)];
        subtitle.text = @"My Rooms";
        subtitle.textAlignment = NSTextAlignmentLeft;
        subtitle.font = [UIFont systemFontOfSize:22 weight:UIFontWeightBold];
        subtitle.textColor = [UIColor bonfireGrayWithLevel:600];
        
        [header addSubview:subtitle];
        
        UIButton *newRoomButton = [UIButton buttonWithType:UIButtonTypeCustom];
        newRoomButton.frame = CGRectMake(header.frame.size.width - 40 - 16, 44, 40, 40);
        newRoomButton.adjustsImageWhenHighlighted = false;
        [newRoomButton setImage:[UIImage imageNamed:@"headerNewRoomIcon"] forState:UIControlStateNormal];
        [newRoomButton bk_addEventHandler:^(id sender) {
            [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                newRoomButton.alpha = 0.8;
                newRoomButton.transform = CGAffineTransformMakeScale(0.8, 0.8);
            } completion:nil];
        } forControlEvents:UIControlEventTouchDown];
        
        [newRoomButton bk_addEventHandler:^(id sender) {
            [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                newRoomButton.alpha = 1;
                newRoomButton.transform = CGAffineTransformMakeScale(1, 1);
            } completion:nil];
        } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
        
        [newRoomButton bk_whenTapped:^{
            [[Launcher sharedInstance] openCreateRoom];
        }];
        [header addSubview:newRoomButton];
        
        return header;
    }
    else {
        UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 64)];
        header.backgroundColor = [UIColor whiteColor];
        
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(16, header.frame.size.height - 24 - 18, self.view.frame.size.width - 32, 24)];
        if (section == 1) { title.text = @"Popular Now"; }
        if (section == 2) { title.text = @"New Rooms We Love"; }
        if (section == 3) { title.text = @"Share Your Best Recipes 🦃"; }
        if (section == 4) { title.text = @"Categories"; }
        title.textAlignment = NSTextAlignmentLeft;
        title.font = [UIFont systemFontOfSize:22.f weight:UIFontWeightBold];
        title.textColor = [UIColor bonfireGrayWithLevel:900];
        
        [header addSubview:title];
        
        return header;
    }
    
    // return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {    
    return section == 0 ? 8 : 24;
}
- (nullable UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == 0) {
        UIView *view = [[UIView alloc] init];
        view.backgroundColor = [UIColor whiteColor];
        return view;
    }
    if (section == 3) return nil;
    
    UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, section == 0 ? 40 : 24)];
    
    UIView *footerContent = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, section == 0 ? 32 : 24)];
    [footer addSubview:footerContent];
    
    if (section == 0) {
        footerContent.backgroundColor = [UIColor clearColor];
    }
    UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(16, footerContent.frame.size.height - (1 / [UIScreen mainScreen].scale), self.view.frame.size.width - 32, 1 / [UIScreen mainScreen].scale)];
    separator.backgroundColor = [UIColor colorWithWhite:0 alpha:0.08f];
    [footerContent addSubview:separator];
    
    return footer;
}

- (void)continuityRadiusForView:(UIView *)sender withRadius:(CGFloat)radius {
    CAShapeLayer * maskLayer = [CAShapeLayer layer];
    maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:sender.bounds
                                           byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight|UIRectCornerTopLeft|UIRectCornerTopRight
                                                 cornerRadii:CGSizeMake(radius, radius)].CGPath;
    
    sender.layer.mask = maskLayer;
}

@end
