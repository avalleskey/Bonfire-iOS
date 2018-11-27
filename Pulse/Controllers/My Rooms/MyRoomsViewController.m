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
#import "LauncherNavigationViewController.h"
#import "Launcher.h"
#import "MyRoomsListCell.h"
#import "RoomSuggestionsListCell.h"
#import "TabController.h"
#import "UIColor+Palette.h"

#define envConfig [[[NSUserDefaults standardUserDefaults] objectForKey:@"config"] objectForKey:[[NSUserDefaults standardUserDefaults] stringForKey:@"environment"]]

@interface MyRoomsViewController ()

@property (strong, nonatomic) LauncherNavigationViewController *launchNavVC;
@property (strong, nonatomic) NSMutableArray *rooms;
@property (nonatomic) BOOL loading;
@property (nonatomic) BOOL errorLoading;

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
    
    self.launchNavVC = (LauncherNavigationViewController *)self.navigationController;
    
    self.rooms = [[NSMutableArray alloc] init];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.loading = true;
    self.errorLoading = false;
    
    [self setupCreateRoomButton];
    [self setupTableView];
    // [self addPill];
    
    self.manager = [HAWebService manager];
    [self getRooms];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userUpdated:) name:@"UserUpdated" object:nil];
}

- (UIColor *)headerBackgroundColor {
    static UIColor *color = nil;
    if (!color) color = [UIColor colorWithRed:0.98 green:0.98 blue:0.99 alpha:1.0];
    return color;
}

- (void)userUpdated:(NSNotification *)notification {
    self.launchNavVC.textField.tintColor = [Session sharedInstance].themeColor;
    self.launchNavVC.composePostButton.tintColor = [Session sharedInstance].themeColor;
    self.launchNavVC.inviteFriendButton.tintColor = [Session sharedInstance].themeColor;
    
    self.tabBarController.tabBar.tintColor = [Session sharedInstance].themeColor;
    self.createRoomButton.backgroundColor = [Session sharedInstance].themeColor;
    
    self.view.tintColor = [Session sharedInstance].themeColor;
    [self.tableView reloadData];
}

- (void)addPill {
    TabController *tabController = (TabController *)self.tabBarController;
    [tabController hidePill:nil];
    [tabController addPillWithTitle:@"Add Period" andImage:[UIImage imageNamed:@"pill_plus_icon"]];
    
    [tabController.currentPill bk_whenTapped:^{
        
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.launchNavVC == nil) {
        self.launchNavVC = (LauncherNavigationViewController *)self.navigationController;
    }
    
    self.launchNavVC.navigationBackgroundView.backgroundColor = [self headerBackgroundColor];
    self.launchNavVC.navigationBar.barTintColor = self.launchNavVC.navigationBackgroundView.backgroundColor;
    
    if (self.createRoomButton.alpha == 0) {
        [self.navigationController.view addSubview:self.createRoomButton];
        
        self.createRoomButton.frame = CGRectMake(self.view.frame.size.width - 50 - 12, self.tabBarController.tabBar.frame.origin.y - 50 - 12, 50, 50);
        self.createRoomButton.transform = CGAffineTransformMakeScale(0.5, 0.5);
        [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.createRoomButton.transform = CGAffineTransformMakeScale(1, 1);
            self.createRoomButton.alpha = 1;
        } completion:nil];
    }
    
    CGFloat navigationHeight = self.navigationController != nil ? self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height : 0;
    self.tableView.frame = CGRectMake(0, 0, self.view.frame.size.width, [UIScreen mainScreen].bounds.size.height - navigationHeight);
}

- (void)setupTableView {
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView setSeparatorColor:[UIColor clearColor]];
    
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 12 + 12 + self.createRoomButton.frame.size.height, 0);
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 0, 0);
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:blankReuseIdentifier];
    [self.tableView registerClass:[MyRoomsListCell class] forCellReuseIdentifier:myRoomsCellReuseIdentifier];
    [self.tableView registerClass:[RoomSuggestionsListCell class] forCellReuseIdentifier:miniRoomCellReuseIdentifier];
    
    UIView *headerHack = [[UIView alloc] initWithFrame:CGRectMake(0, -1 * self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height)];
    headerHack.backgroundColor = [self headerBackgroundColor];
    [self.tableView addSubview:headerHack];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView == self.tableView) {
        if (scrollView.contentOffset.y > 10) {
            if (self.launchNavVC.shadowView.alpha == 0) {
                [self.launchNavVC setShadowVisibility:TRUE withAnimation:TRUE];
            }
            if (self.launchNavVC.navigationBackgroundView.backgroundColor != [UIColor whiteColor]) {
                [UIView animateWithDuration:0.2f animations:^{
                    self.launchNavVC.navigationBackgroundView.backgroundColor = [UIColor whiteColor];
                }];
            }
        }
        else if (scrollView.contentOffset.y <= 10) {
            if (self.launchNavVC.shadowView.alpha == 1) {
                [self.launchNavVC setShadowVisibility:FALSE withAnimation:TRUE];
            }
            if (self.launchNavVC.navigationBackgroundView.backgroundColor != [self headerBackgroundColor]) {
                [UIView animateWithDuration:0.2f animations:^{
                    self.launchNavVC.navigationBackgroundView.backgroundColor = [self headerBackgroundColor];
                }];
            }
        }
    }
}
/*
- (void)setupCollectionView {
    self.myRoomsLayout = [[UICollectionViewFlowLayout alloc] init];
    self.myRoomsLayout.minimumLineSpacing = 10.f;
    self.myRoomsLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:self.myRoomsLayout];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.bounces = false;
    self.collectionView.contentInset = UIEdgeInsetsMake(0, 16, 0, 16);
    [self.collectionView registerClass:[ChannelCell class] forCellWithReuseIdentifier:reuseIdentifier];
    [self.collectionView registerClass:[EmptyChannelCell class] forCellWithReuseIdentifier:emptyRoomCellReuseIdentifier];
    [self.collectionView registerClass:[ErrorChannelCell class] forCellWithReuseIdentifier:errorRoomCellReuseIdentifier];
    self.collectionView.showsHorizontalScrollIndicator = false;
    self.collectionView.layer.masksToBounds = true;
    self.collectionView.backgroundColor = [UIColor whiteColor];
    
    [self.view addSubview:self.collectionView];
}*/
/*- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    UICollectionViewCell *closestCell = self.collectionView.visibleCells[0];
    for (UICollectionViewCell *cell in self.collectionView.visibleCells) {
        int closestCellDelta = fabs(closestCell.center.x - self.collectionView.bounds.size.width/2.0 - self.collectionView.contentOffset.x);
        int cellDelta = fabs(cell.center.x - self.collectionView.bounds.size.width/2.0 - self.collectionView.contentOffset.x);
        if (cellDelta < closestCellDelta) {
            closestCell = cell;
        }
    }
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:closestCell];
    [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:true];
}*/

- (void)setupCreateRoomButton {
    self.createRoomButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.createRoomButton.frame = CGRectMake(self.view.frame.size.width - 50 - 12, self.tabBarController.tabBar.frame.origin.y - 50 - 16, 50, 50);
    self.createRoomButton.layer.cornerRadius = self.createRoomButton.frame.size.height / 2;
    self.createRoomButton.layer.masksToBounds = false;
    self.createRoomButton.layer.shadowRadius = 1.f;
    self.createRoomButton.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.08f].CGColor;
    self.createRoomButton.layer.shadowOffset = CGSizeMake(0, 1);
    self.createRoomButton.layer.shadowOpacity = 1.f;
    self.createRoomButton.contentMode = UIViewContentModeCenter;
    self.createRoomButton.adjustsImageWhenHighlighted = false;
    self.createRoomButton.backgroundColor = [Session sharedInstance].themeColor;
    self.createRoomButton.alpha = 0;
    
    /*
    UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    blurView.tag = 10;
    blurView.frame = self.createRoomButton.bounds;
    blurView.userInteractionEnabled = false;
    blurView.layer.cornerRadius = self.createRoomButton.frame.size.height / 2;
    blurView.layer.masksToBounds = true;
    [self.createRoomButton insertSubview:blurView atIndex:0];
    */
     
    UIImageView *plusIcon = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    plusIcon.center = CGPointMake(self.createRoomButton.frame.size.width / 2, self.createRoomButton.frame.size.height / 2);
    plusIcon.image = [[UIImage imageNamed:@"newRoomIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    plusIcon.tintColor = [UIColor colorWithWhite:1 alpha:1];
    plusIcon.contentMode = UIViewContentModeCenter;
    plusIcon.userInteractionEnabled = false;
    [self.createRoomButton addSubview:plusIcon];
    
    [self.createRoomButton bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.createRoomButton.transform = CGAffineTransformMakeScale(0.8, 0.8);
        } completion:nil];
    } forControlEvents:UIControlEventTouchDown];
    
    [self.createRoomButton bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.createRoomButton.transform = CGAffineTransformMakeScale(1, 1);
        } completion:nil];
    } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
    
    [self.createRoomButton bk_whenTapped:^{
        [[Launcher sharedInstance] openCreateRoom];
    }];
}

- (void)getRooms {
    NSString *url;// = [NSString stringWithFormat:@"%@/%@/schools/%@/channels", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"], @"2"];
    //url = @"https://rawgit.com/avalleskey/avalleskey.github.io/master/sample_rooms2.json"; // sample data
    url = [NSString stringWithFormat:@"%@/%@/users/me/rooms", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"]];
    
    [[Session sharedInstance] authenticate:^(BOOL success, NSString *token) {
        if (success) {
            [self.manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
            
            NSLog(@"token::: %@", token);
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
                self.collectionView.scrollEnabled = true;
                self.errorLoading = false;
                [self.collectionView reloadData];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"MyRoomsViewController / getRooms() - error: %@", error);
                //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                
                self.loading = false;
                self.collectionView.scrollEnabled = true;
                self.errorLoading = true;
                [self.collectionView reloadData];
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
        cell.backgroundColor = [self headerBackgroundColor];
        
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
    return indexPath.section == 0 ? 400 : 240;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) return 80;
    
    return 64;
}
- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    //if (section > 1) return nil;
    
    if (section == 100) {
        UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 48)];
        header.backgroundColor = [self headerBackgroundColor];
        return header;
        /*UIImageView *profilePicture = [[UIImageView alloc] initWithFrame:CGRectMake(16, 32, 40, 40)];
        [self continuityRadiusForView:profilePicture withRadius:profilePicture.frame.size.height*.25];
        [profilePicture setImage:[[UIImage imageNamed:@"anonymous"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        profilePicture.tintColor = [Session sharedInstance].themeColor;
        profilePicture.layer.masksToBounds = true;
        profilePicture.backgroundColor = [UIColor whiteColor];
        profilePicture.userInteractionEnabled = true;
        [header addSubview:profilePicture];*/
        
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
        UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 64 + (section == 0 ? 16 : 0))];
        header.backgroundColor = section == 0 ? [self headerBackgroundColor] : [UIColor whiteColor];
        
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(16, header.frame.size.height - 24 - 18, self.view.frame.size.width - 32, 24)];
        if (section == 0) { title.text = @"My Rooms"; }
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
    return section == 0 ? 40 : 24;
}
- (nullable UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == 3) return nil;
    
    UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, section == 0 ? 40 : 24)];
    
    UIView *footerContent = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, section == 0 ? 32 : 24)];
    [footer addSubview:footerContent];
    
    if (section == 0) {
        footerContent.backgroundColor = [self headerBackgroundColor];
    }
    UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(16, footerContent.frame.size.height - (1 / [UIScreen mainScreen].scale), self.view.frame.size.width - 32, 1 / [UIScreen mainScreen].scale)];
    separator.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1];
    [footerContent addSubview:separator];
    
    return footer;
}

/*
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.loading) {
        return 2;
    }
    else {
        if (self.errorLoading) {
            return 1;
        }
        else {
            return self.rooms.count > 0 ? self.rooms.count : 1;
        }
    }
}
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.loading) {
        ChannelCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
        
        cell.profilePicture.backgroundColor = [UIColor whiteColor];
        cell.profilePicture.image = nil;
        cell.profilePicture.layer.shadowOpacity = 0;
        
        cell.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
        cell.title.layer.cornerRadius = 6.f;
        cell.title.layer.masksToBounds = true;
        cell.title.backgroundColor = [UIColor whiteColor];
        cell.title.text = @"Loading";
        cell.title.textColor = [UIColor clearColor];
        cell.bio.text = @"Quintessential information";
        cell.bio.textColor = [UIColor clearColor];
        cell.bio.backgroundColor = [UIColor whiteColor];
        
        cell.shimmerContainer.hidden = false;
        
        cell.ticker.hidden = true;
        cell.membersView.hidden = true;
        cell.inviteButton.hidden = true;
        
        return cell;
    }
    else {
        if (self.rooms.count == 0) {
            if (self.errorLoading) {
                ErrorChannelCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:errorRoomCellReuseIdentifier forIndexPath:indexPath];
                
                return cell;
            }
            else {
                EmptyChannelCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:emptyRoomCellReuseIdentifier forIndexPath:indexPath];
                
                cell.titleLabel.text = [Session sharedInstance].defaults.onboarding.myRooms.title;
                cell.descriptionLabel.text = [Session sharedInstance].defaults.onboarding.myRooms.theDescription;
                
                return cell;
            }
        }
        else {
            ChannelCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
            
            NSError *error;
            cell.room = [[Room alloc] initWithDictionary:self.rooms[indexPath.item] error:&error];
            
            cell.profilePicture.image = [[UIImage imageNamed:@"anonymousGroup"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.profilePicture.tintColor = [UIColor whiteColor];
            cell.profilePicture.backgroundColor = [UIColor clearColor];
            cell.profilePicture.layer.shadowOpacity = 0;
            
            cell.shimmerContainer.shimmering = false;
            cell.shimmerContainer.hidden = true;
            
            cell.title.text = cell.room.attributes.details.title;
            cell.title.textColor = [UIColor whiteColor];
            cell.title.backgroundColor = [UIColor clearColor];
            
            cell.bio.text = cell.room.attributes.details.theDescription != nil ? cell.room.attributes.details.theDescription : @"";
            cell.bio.textColor = [UIColor colorWithWhite:1 alpha:0.75f];
            cell.bio.backgroundColor = [UIColor clearColor];
            
            if (cell.room.attributes.summaries.counts.live < [Session sharedInstance].defaults.room.liveThreshold) {
                cell.ticker.hidden = true;
                cell.inviteButton.hidden = false;
            }
            else {
                cell.ticker.hidden = false;
                [cell.ticker setTitle:[NSString stringWithFormat:@"%ld live", (long)cell.room.attributes.summaries.counts.live] forState:UIControlStateNormal];
                cell.inviteButton.hidden = true;
            }
            // cell.membersView.text = @"650 members";
            
            cell.membersView.hidden = false;
            
            for (int i = 0; i < cell.membersView.subviews.count; i++) {
                if ([cell.membersView.subviews[i] isKindOfClass:[UIImageView class]]) {
                    UIImageView *imageView = cell.membersView.subviews[i];
                    
                    if (cell.room.attributes.summaries.members.count > imageView.tag) {
                        imageView.hidden = false;
                        
                        User *member = [[User alloc] initWithDictionary:cell.room.attributes.summaries.members[imageView.tag] error:nil];
                        NSString *picURL = member.attributes.details.media.profilePicture;
                        if (picURL.length > 0) {
                            [imageView sd_setImageWithURL:[NSURL URLWithString:picURL]];
                        }
                        else {
                            [imageView setImage:[[UIImage imageNamed:@"anonymous"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
                            imageView.tintColor = [self colorFromHexString:member.attributes.details.color];
                        }
                    }
                    else {
                        imageView.hidden = true;
                    }
                }
            }
            
            cell.backgroundColor = [self colorFromHexString:cell.room.attributes.details.color];
            
            [cell layoutSubviews];
            
            return cell;
        }
    }
}
 */

/*
- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionViewLayout == self.)
    float height = self.collectionView.frame.size.height - 32;
    return CGSizeMake(self.view.frame.size.width - 32, height);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (!self.loading && !self.errorLoading && self.rooms.count > 0) {
        // animate the cell user tapped on
        Room *room = [[Room alloc] initWithDictionary:self.rooms[indexPath.row] error:nil];
        
        RoomContext *context = [[RoomContext alloc] initWithDictionary:@{@"status": ROOM_STATUS_MEMBER} error:nil];
        room.attributes.context = context;
        
        [[Launcher sharedInstance] openRoom:room];
    }
    else if (self.errorLoading) {
        // tap to try loading again
        self.rooms = [[NSMutableArray alloc] init];
        
        self.loading = true;
        [self.collectionView setContentOffset:CGPointMake(-16, 0)];
        self.collectionView.scrollEnabled = false;
        self.errorLoading = false;
        
        [self getRooms];
        [self.collectionView reloadData];
    }
}*/

- (void)continuityRadiusForView:(UIView *)sender withRadius:(CGFloat)radius {
    CAShapeLayer * maskLayer = [CAShapeLayer layer];
    maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:sender.bounds
                                           byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight|UIRectCornerTopLeft|UIRectCornerTopRight
                                                 cornerRadii:CGSizeMake(radius, radius)].CGPath;
    
    sender.layer.mask = maskLayer;
}

@end
