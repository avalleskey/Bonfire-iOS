//
//  BotViewController.h
//
//
//  Created by Austin Valleskey on 9/19/18.
//

#import <UIKit/UIKit.h>
#import "Session.h"
#import "Bot.h"
#import "ThemedViewController.h"
#import "CampListStream.h"

NS_ASSUME_NONNULL_BEGIN

@interface BotViewController : ThemedViewController <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) Bot *bot;

@property (nonatomic, strong) CampListStream *stream;

@property (strong, nonatomic) UITableView *tableView;
@property (nonatomic, strong) UIImageView *coverPhotoView;

@property (nonatomic) BOOL isPreview;

- (void)openBotActions;

@end

NS_ASSUME_NONNULL_END
