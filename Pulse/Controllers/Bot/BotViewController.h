//
//  BotViewController.h
//
//
//  Created by Austin Valleskey on 9/19/18.
//

#import <UIKit/UIKit.h>
#import "Session.h"
#import "Bot.h"
#import "ThemedTableViewController.h"
#import "CampListStream.h"

NS_ASSUME_NONNULL_BEGIN

@interface BotViewController : ThemedTableViewController <BFComponentTableViewDelegate>

@property (strong, nonatomic) Bot *bot;

@property (nonatomic, strong) CampListStream *stream;

@property (nonatomic, strong) UIImageView *coverPhotoView;

- (void)openBotActions;

@end

NS_ASSUME_NONNULL_END
