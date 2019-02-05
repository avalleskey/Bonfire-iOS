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
#import "RoomCardsListCell.h"
#import "SearchResultCell.h"
#import "MiniRoomsListCell.h"
#import "TabController.h"
#import "UIColor+Palette.h"
#import <Tweaks/FBTweakInline.h>
#import "NSArray+Clean.h"

@interface MyRoomsViewController ()

@property (strong, nonatomic) SimpleNavigationController *simpleNav;
@property (strong, nonatomic) NSMutableArray *recents;

@property (strong, nonatomic) NSMutableArray *featuredRooms;
@property (nonatomic) BOOL loadingFeaturedRooms;
@property (nonatomic) BOOL errorLoadingFeaturedRooms;

@property (strong, nonatomic) NSMutableArray *rooms;
@property (nonatomic) BOOL loadingRooms;
@property (nonatomic) BOOL errorLoadingRooms;

@property (strong, nonatomic) NSMutableArray *lists;
@property (nonatomic) BOOL loadingLists;
@property (nonatomic) BOOL errorLoadingLists;

@property (nonatomic) BOOL userDidRefresh;
@property (nonatomic) BOOL showAllRooms;

@end


@implementation MyRoomsViewController

static NSString * const reuseIdentifier = @"RoomCell";
static NSString * const emptyRoomCellReuseIdentifier = @"EmptyRoomCell";
static NSString * const errorRoomCellReuseIdentifier = @"ErrorRoomCell";

static NSString * const cardsListCellReuseIdentifier = @"CardsListCell";
static NSString * const miniRoomCellReuseIdentifier = @"MiniCell";

static NSString * const myRoomsListCellReuseIdentifier = @"MyRoomsListCell";

static NSString * const blankReuseIdentifier = @"BlankCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.manager = [HAWebService manager];
    self.simpleNav = (SimpleNavigationController *)self.navigationController;
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.simpleNav.navigationBar.prefersLargeTitles = true;
    self.extendedLayoutIncludesOpaqueBars = true;
    // self.simpleNav.navigationItem.largeTitleDisplayMode = uinavigationlar
    
    [self initDefaults];
    
    [self setupTableView];
    
    [self getFeaturedRooms];
    [self getRooms];
    [self getRecents];
    [self getLists];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roomUpdated:) name:@"RoomUpdated" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recentsUpdated:) name:@"RecentsUpdated" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshMyRooms:) name:@"refreshMyRooms" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userUpdated:) name:@"UserUpdated" object:nil];
}

- (void)initDefaults {
    self.featuredRooms = [[NSMutableArray alloc] initWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:@"featured_rooms_cache"]];
    self.rooms = [[NSMutableArray alloc] initWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:@"my_rooms_cache"]];
    if (self.rooms.count > 1) [self sortRooms];
    self.recents = [[NSMutableArray alloc] init];
    self.lists = [[NSMutableArray alloc] init];
    
    self.loadingFeaturedRooms = true;
    self.loadingRooms = true;
    self.loadingLists = true;
    
    self.errorLoadingFeaturedRooms = false;
    self.errorLoadingRooms = false;
    self.errorLoadingLists = false;
}

- (void)refreshMyRooms:(NSNotification *)notification {
    [self getRooms];
}
- (void)recentsUpdated:(NSNotification *)notification {
    /*
    [self getRecents];
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    if (self.rooms.count > 0) {
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1]] withRowAnimation:UITableViewRowAnimationNone];
    }
    [self.tableView endUpdates];
    
    RoomCardsListCell *listCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [listCell.collectionView setContentOffset:CGPointMake(-16, 0) animated:false];
     */
}

- (void)userUpdated:(NSNotification *)notification {
    if ([notification.object isKindOfClass:[User class]]) {
        User *user = notification.object;
        if ([user.identifier isEqualToString:[Session sharedInstance].currentUser.identifier]) {
            [self.tableView reloadData];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.simpleNav == nil) {
        self.simpleNav = (SimpleNavigationController *)self.navigationController;
        [self.simpleNav hideBottomHairline];
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
    self.userDidRefresh = true;
    [self getFeaturedRooms];
    [self getRooms];
    [self getRecents];
    [self getLists];
}
- (void)setupTableView {
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 24, 0);
    [self.tableView setSeparatorColor:[UIColor clearColor]];
    self.tableView.refreshControl = [[UIRefreshControl alloc] init];
    [self.tableView.refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:blankReuseIdentifier];
    [self.tableView registerClass:[RoomCardsListCell class] forCellReuseIdentifier:cardsListCellReuseIdentifier];
    [self.tableView registerClass:[MiniRoomsListCell class] forCellReuseIdentifier:myRoomsListCellReuseIdentifier];
    
    UIView *headerHack = [[UIView alloc] initWithFrame:CGRectMake(0, -1 * self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height)];
    headerHack.backgroundColor = [UIColor whiteColor];
    [self.tableView insertSubview:headerHack atIndex:0];
}

- (void)sortRooms {
    NSDictionary *opens = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"room_opens"];
    
    for (int i = 0; i < self.rooms.count; i++) {
        if ([self.rooms[i] isKindOfClass:[NSDictionary class]] && [self.rooms[i] objectForKey:@"id"]) {
            NSMutableDictionary *mutableRoom = [[NSMutableDictionary alloc] initWithDictionary:self.rooms[i]];
            NSString *roomId = mutableRoom[@"id"];
            NSInteger roomOpens = [opens objectForKey:roomId] ? [opens[roomId] integerValue] : 0;
            [mutableRoom setObject:[NSNumber numberWithInteger:roomOpens] forKey:@"opens"];
            [self.rooms replaceObjectAtIndex:i withObject:mutableRoom];
        }
    }
    NSSortDescriptor *sortByName = [NSSortDescriptor sortDescriptorWithKey:@"opens"
                                                                    ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortByName];
    NSArray *sortedArray = [self.rooms sortedArrayUsingDescriptors:sortDescriptors];
    
    self.rooms = [[NSMutableArray alloc] initWithArray:sortedArray];
}

- (void)getLists {
    NSString *url = [NSString stringWithFormat:@"%@/%@/users/me/rooms/lists", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"]];
    
    [[Session sharedInstance] authenticate:^(BOOL success, NSString *token) {
        if (success) {
            [self.manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
            
            [self.manager GET:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                NSArray *responseData = responseObject[@"data"];
                
                if (responseData.count > 0) {
                    self.lists = [[NSMutableArray alloc] initWithArray:responseData];
                }
                else {
                    self.lists = [[NSMutableArray alloc] init];
                }
                
                self.loadingLists = false;
                self.errorLoadingLists = false;
                
                [self.tableView reloadData];
                
                if (!self.loadingLists && !self.loadingRooms) {
                    [[self refreshControl] performSelector:@selector(endRefreshing) withObject:nil afterDelay:0.0];
                }
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"‼️ MyRoomsViewController / getLists() - error: %@", error);
                //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                
                self.loadingLists = false;
                self.errorLoadingLists = true;
                
                [self.tableView reloadData];
                
                if (!self.loadingLists && !self.loadingRooms) {
                    [[self refreshControl] performSelector:@selector(endRefreshing) withObject:nil afterDelay:0.0];
                }
            }];
        }
    }];
}

- (void)getFeaturedRooms {
    NSString *url;
    url = [NSString stringWithFormat:@"%@/%@/users/me/rooms/lists/featured", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"]];
    
    [[Session sharedInstance] authenticate:^(BOOL success, NSString *token) {
        if (success) {
            [self.manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
            
            [self.manager GET:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                // NSLog(@"MyRoomsViewController / getRooms() success! ✅");
                
                NSArray *responseData = responseObject[@"data"];
                
                if (responseData.count > 0) {
                    self.featuredRooms = [[NSMutableArray alloc] initWithArray:responseData];
                }
                else {
                    self.featuredRooms = [[NSMutableArray alloc] init];
                }
                [[NSUserDefaults standardUserDefaults] setObject:[self.featuredRooms clean] forKey:@"featured_rooms_cache"];
                
                self.loadingFeaturedRooms = false;
                self.errorLoadingFeaturedRooms = false;
                
                [self.tableView reloadData];
                
                if (!self.loadingLists && !self.loadingFeaturedRooms && !self.loadingRooms) {
                    [[self refreshControl] performSelector:@selector(endRefreshing) withObject:nil afterDelay:0.0];
                }
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"MyRoomsViewController / getRooms() - error: %@", error);
                //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                
                self.loadingRooms = false;
                self.errorLoadingRooms = true;
                
                [self.tableView reloadData];
                
                if (!self.loadingLists && !self.loadingFeaturedRooms && !self.loadingRooms) {
                    [[self refreshControl] performSelector:@selector(endRefreshing) withObject:nil afterDelay:0.0];
                }
            }];
        }
    }];
}

- (void)getRooms {
    NSString *url;
    url = [NSString stringWithFormat:@"%@/%@/users/me/rooms", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"]];
    
    [[Session sharedInstance] authenticate:^(BOOL success, NSString *token) {
        if (success) {
            [self.manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
            
            [self.manager GET:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                // NSLog(@"MyRoomsViewController / getRooms() success! ✅");
                
                NSArray *responseData = responseObject[@"data"];
                
                if (responseData.count > 0) {
                    self.rooms = [[NSMutableArray alloc] initWithArray:responseData];
                    if (self.rooms.count > 1) [self sortRooms];
                }
                else {
                    self.rooms = [[NSMutableArray alloc] init];
                }
                [[NSUserDefaults standardUserDefaults] setObject:[self.rooms clean] forKey:@"my_rooms_cache"];
                
                self.loadingRooms = false;
                self.errorLoadingRooms = false;
                
                [self.tableView reloadData];
                
                if (!self.loadingLists && !self.loadingRooms) {
                    [[self refreshControl] performSelector:@selector(endRefreshing) withObject:nil afterDelay:0.0];
                }
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"MyRoomsViewController / getRooms() - error: %@", error);
                //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                
                self.loadingRooms = false;
                self.errorLoadingRooms = true;
                
                [self.tableView reloadData];
                
                if (!self.loadingLists && !self.loadingRooms) {
                    [[self refreshControl] performSelector:@selector(endRefreshing) withObject:nil afterDelay:0.0];
                }
            }];
        }
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2 + self.lists.count;
    // 1. Featured
    // 2. My Rooms
    // 3. Lists
    // 4. Quick Links
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return 1;
    if (section == 1) return 1;
    else if (section < (2 + self.lists.count)) {
        return 1;
    }
    else {
        // last section -- quick links
        return 0;
    }
}

- (void)getRecents {
    self.recents = [[NSMutableArray alloc] init];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults arrayForKey:@"recents_search"]) {
        NSArray *searchRecents = [defaults arrayForKey:@"recents_search"];
        
        if (searchRecents.count > 0) {
            self.recents = [[NSMutableArray alloc] initWithArray:searchRecents];
            
            // lol killList = objects to remove
            NSMutableArray *killList = [[NSMutableArray alloc] init];
            for (id object in self.recents) {
                if (![object[@"type"] isEqualToString:@"room"]) {
                    [killList addObject:object];
                }
            }
            [self.recents removeObjectsInArray:killList];
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (self.loadingFeaturedRooms || self.featuredRooms.count > 0) {
            RoomCardsListCell *cell = [tableView dequeueReusableCellWithIdentifier:cardsListCellReuseIdentifier forIndexPath:indexPath];
            
            if (cell == nil) {
                cell = [[RoomCardsListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cardsListCellReuseIdentifier];
            }
            
            cell.size = ROOM_CARD_SIZE_LARGE;
            
            if (self.loadingFeaturedRooms) {
                cell.loading = true;
            }
            else {
                cell.loading = false;
                
                if (self.featuredRooms.count > 0) {
                    cell.rooms = [[NSMutableArray alloc] initWithArray:self.featuredRooms];
                    [cell.collectionView reloadData];
                }
            }
            
            /* TODO: Use featured endpoint
             if (self.loadingRooms) {
             cell.loading = true;
             }
             else {
             cell.loading = false;
             
             cell.rooms = self.rooms;
             [cell.collectionView reloadData];
             }*/
            
            return cell;
        }
    }
    else if (indexPath.section == 1) {
        MiniRoomsListCell *cell = [tableView dequeueReusableCellWithIdentifier:myRoomsListCellReuseIdentifier forIndexPath:indexPath];
        
        if (cell == nil) {
            cell = [[MiniRoomsListCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:myRoomsListCellReuseIdentifier];
        }
        
        if (self.loadingRooms) {
            cell.loading = true;
        }
        else {
            cell.loading = false;
            cell.rooms = self.rooms;
            
            [cell.collectionView reloadData];
        }
        
        return cell;
    }
    else if (!self.loadingLists && (indexPath.section > 1 && indexPath.section <= self.lists.count + 1)) {
        RoomCardsListCell *cell = [tableView dequeueReusableCellWithIdentifier:cardsListCellReuseIdentifier forIndexPath:indexPath];
        
        if (cell == nil) {
            cell = [[RoomCardsListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cardsListCellReuseIdentifier];
        }
        
        if (indexPath.section == 2) {
            cell.size = ROOM_CARD_SIZE_SMALL;
        }
        else {
            cell.size = ROOM_CARD_SIZE_MEDIUM;
        }
        
        if (self.loadingLists) {
            cell.loading = true;
        }
        else {
            cell.loading = false;
            
            NSInteger index = indexPath.section - 2;
            if (self.lists.count > index && index >= 0) {
                NSArray *roomsList = self.lists[index][@"attributes"][@"rooms"];
                
                cell.rooms = [[NSMutableArray alloc] initWithArray:roomsList];
                [cell.collectionView reloadData];
            }
        }
        
        return cell;
    }
    
    UITableViewCell *blankCell = [tableView dequeueReusableCellWithIdentifier:blankReuseIdentifier forIndexPath:indexPath];
    
    blankCell.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1];
    
    return blankCell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        // Size: large
        return 304;
    }
    if (indexPath.section == 1) {
        // Size: mini
        return self.rooms.count > 0 ? 116 : 0;
    }
    if (!self.loadingLists && (indexPath.section > 1 && indexPath.section <= self.lists.count + 1)) {
        if (indexPath.section == 2) {
            // Size: small
            return 98;
        }
        else {
            // Size: medium
            return 226;
        }
    }
    
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 1 && self.rooms.count == 0) return 0;
    
    return 60;
}
- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 1 && self.rooms.count == 0) return nil;
    
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 8, self.view.frame.size.width, 60)];
    
    NSString *bigTitle;
    NSString *title;

    if (section == 0) {
        // bigTitle = [Session sharedInstance].defaults.home.myRoomsPageTitle;
        title = @"Featured";
    }
    else if (section == 1) {
        title = @"My Camps";
    }
    else if (section < (2 + self.lists.count)) {
        // room lists
        NSInteger index = section - 2;
        title = self.lists[index][@"attributes"][@"title"];
    }
    else {
        title = @"Quick Links";
    }
    
    UIView *bigTitleView;
    if (bigTitle) {
        bigTitleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 48)];
        
        header.frame = CGRectMake(header.frame.origin.x, header.frame.origin.y, header.frame.size.width, 104);
        UILabel *bigTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, header.frame.size.width - 32, 40)];
        bigTitleLabel.text = bigTitle;
        bigTitleLabel.textAlignment = NSTextAlignmentLeft;
        bigTitleLabel.font = [UIFont systemFontOfSize:34.f weight:UIFontWeightHeavy];
        bigTitleLabel.textColor = [UIColor colorWithWhite:0.07f alpha:1];
        [bigTitleView addSubview:bigTitleLabel];
        
        UIView *headerSeparator = [[UIView alloc] initWithFrame:CGRectMake(16, bigTitleView.frame.size.height - (1 / [UIScreen mainScreen].scale), self.view.frame.size.width - 32, 1 / [UIScreen mainScreen].scale)];
        headerSeparator.backgroundColor = [UIColor colorWithWhite:0 alpha:0.08f];
        [bigTitleView addSubview:headerSeparator];
        
        [header addSubview:bigTitleView];
    }
    
    UIView *titleLabelView = [[UIView alloc] initWithFrame:CGRectMake(0, bigTitleView.frame.size.height, self.view.frame.size.width, 56)];

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, titleLabelView.frame.size.height - 24 - 11, self.view.frame.size.width - 32, 24)];
    titleLabel.text = title;
    titleLabel.textAlignment = NSTextAlignmentLeft;
    titleLabel.font = [UIFont systemFontOfSize:22.f weight:UIFontWeightBold];
    titleLabel.textColor = section == 0 ? [UIColor colorWithRed:0.43 green:0.46 blue:0.48 alpha:1.00] : [UIColor bonfireGrayWithLevel:900];
    [titleLabelView addSubview:titleLabel];
    [header addSubview:titleLabelView];
    
    header.frame = CGRectMake(0, 0, header.frame.size.width, titleLabelView.frame.origin.y + titleLabelView.frame.size.height);
    
    return header;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 1 && self.rooms.count == 0) return 0;
    
    return section == 0 ? 24 : 16;
}
- (nullable UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == self.lists.count + 1) return nil;
    
    UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, section == 0 ? 24 : 16)];
    
    UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(16, footer.frame.size.height - (1 / [UIScreen mainScreen].scale), self.view.frame.size.width - 32, 1 / [UIScreen mainScreen].scale)];
    separator.backgroundColor = [UIColor colorWithWhite:0 alpha:0.08f];
    [footer addSubview:separator];
    
    return footer;
}

- (void)roomUpdated:(NSNotification *)notification {
    Room *room = notification.object;
    
    if (room != nil) {
        BOOL changes = false;
        
        NSArray *dataArraysToCheck = @[self.rooms, self.featuredRooms];
        
        for (NSMutableArray *array in dataArraysToCheck) {
            for (int i = 0; i < array.count; i++) {
                if ([array[i][@"id"] isEqualToString:room.identifier]) {
                    // same room -> replace it with updated object
                    if (array[i] != [room toDictionary]) {
                        changes = true;
                        NSLog(@"yo we got a change doeeee");
                        NSLog(@"new room : %@", room);
                    }
                    else {
                        NSLog(@"nah no diff");
                    }
                    [array replaceObjectAtIndex:i withObject:[room toDictionary]];
                }
            }
        }
        
        if (changes) {
            NSLog(@"reload da data mahn!");
            [self.tableView reloadData];
        }
    }
}

@end
