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

#define envConfig [[[NSUserDefaults standardUserDefaults] objectForKey:@"config"] objectForKey:[[NSUserDefaults standardUserDefaults] stringForKey:@"environment"]]

@interface MyRoomsViewController ()

@property (strong, nonatomic) NSMutableArray *rooms;
@property (nonatomic) BOOL loading;
@property (nonatomic) BOOL errorLoading;

@end


@implementation MyRoomsViewController

static NSString * const reuseIdentifier = @"RoomCell";
static NSString * const emptyRoomCellReuseIdentifier = @"EmptyRoomCell";
static NSString * const errorRoomCellReuseIdentifier = @"ErrorRoomCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.rooms = [[NSMutableArray alloc] init];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.loading = true;
    [self.collectionView setContentOffset:CGPointMake(-16, 0)];
    self.collectionView.scrollEnabled = false;
    self.errorLoading = false;
    
    [self setupCollectionView];
    [self setupCreateRoomButton];
    
    self.manager = [HAWebService manager];
    [self getRooms];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshMyRooms:) name:@"refreshMyRooms" object:nil];
}

- (void)refreshMyRooms:(id)sender {
    [self getRooms];
}

- (void)setupCollectionView {
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.minimumLineSpacing = 8.f;
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height * .2, self.view.frame.size.width, self.view.frame.size.height * .6) collectionViewLayout:flowLayout];
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
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    NSLog(@"scrollview");
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
}
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    NSLog(@"scrollview");
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
}

- (void)setupCreateRoomButton {
    self.createRoomButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.createRoomButton.frame = CGRectMake(0, 0, 92, 50);
    self.createRoomButton.adjustsImageWhenHighlighted = false;
    [self.createRoomButton setContentMode:UIViewContentModeBottom];
    self.createRoomButton.contentVerticalAlignment = UIControlContentVerticalAlignmentBottom;
    self.createRoomButton.titleLabel.font = [UIFont systemFontOfSize:12.f weight:UIFontWeightBold];
    [self.createRoomButton setTitleColor:[UIColor colorWithWhite:0.47 alpha:1] forState:UIControlStateNormal];
    [self.createRoomButton setTitle:[NSString stringWithFormat:@"%@ ROOM", [[Session sharedInstance].defaults.room.createVerb uppercaseString]] forState:UIControlStateNormal];
    UIImageView *createRoomPlusIcon = [[UIImageView alloc] initWithFrame:CGRectMake(self.createRoomButton.frame.size.width / 2 - (28 / 2), 0, 28, 28)];
    createRoomPlusIcon.image = [UIImage imageNamed:@"newRoomIcon"];
    [self.createRoomButton addSubview:createRoomPlusIcon];
    
    [self.createRoomButton bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.createRoomButton.alpha = 0.8;
            self.createRoomButton.transform = CGAffineTransformMakeScale(0.8, 0.8);
        } completion:nil];
    } forControlEvents:UIControlEventTouchDown];
    
    [self.createRoomButton bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.createRoomButton.alpha = 1;
            self.createRoomButton.transform = CGAffineTransformMakeScale(1, 1);
        } completion:nil];
    } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
    
    [self.createRoomButton bk_whenTapped:^{
        [(LauncherNavigationViewController *)self.navigationController openCreateRoom];
    }];
    
    [self.view addSubview:self.createRoomButton];
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
                        
                        NSString *picURL = @"";// cell.room.attributes.summaries.members[imageView.tag].attributes.details.profilePicture;
                        if (picURL.length > 0) {
                            [imageView sd_setImageWithURL:[NSURL URLWithString:picURL]];
                        }
                        else {
                            [imageView setImage:[[UIImage imageNamed:@"anonymous"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
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

- (UIColor *)colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    if (hexString != nil && hexString.length == 6) {
        NSScanner *scanner = [NSScanner scannerWithString:hexString];
        [scanner setScanLocation:0]; // bypass '#' character
        [scanner scanHexInt:&rgbValue];
        return [UIColor colorWithDisplayP3Red:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
    }
    else {
        return [UIColor colorWithWhite:0.2f alpha:1];
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    float height = self.collectionView.frame.size.height - 32;
    return CGSizeMake(self.view.frame.size.width - 32, height);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (!self.loading && !self.errorLoading && self.rooms.count > 0) {
        // animate the cell user tapped on
        Room *room = [[Room alloc] initWithDictionary:self.rooms[indexPath.row] error:nil];
        
        RoomContext *context = [[RoomContext alloc] initWithDictionary:@{@"status": STATUS_MEMBER} error:nil];
        room.attributes.context = context;
        
        [(LauncherNavigationViewController *)self.navigationController openRoom:room];
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
}

@end
