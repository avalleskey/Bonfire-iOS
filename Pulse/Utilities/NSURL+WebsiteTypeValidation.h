//
//  NSURL+WebsiteTypeValidation.h
//  Pulse
//
//  Created by Austin Valleskey on 8/7/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import <Foundation/Foundation.h>

// regex
#define REGEX_YOUTUBE @"^(?:https?:\\/\\/)?(?:www\\.)?(?:(?:youtube\\.com\\/watch\\?v=)|(?:youtu.be\\/))(?:[a-zA-Z0-9-_]+)"
#define REGEX_SPOTIFY_SONG @"^(https:\\/\\/open.spotify.com\\/track\\/)([a-zA-Z0-9]+)(.*)$"
#define REGEX_SPOTIFY_PLAYLIST @"^(?:https:\\/\\/open.spotify.com\\/playlist\\/)(?:[a-zA-Z0-9]+)(?:.*)$"
#define REGEX_APPLE_MUSIC_SONG @"^https:\\/\\/music.apple.com\\/([a-zA-Z]+)\\/album\\/([-_a-zA-Z0-9]+)\\/([a-zA-Z0-9]+)(.*)$"
#define REGEX_APPLE_MUSIC_ALBUM @"^https:\\/\\/music.apple.com\\/([a-zA-Z]+)\\/album\\/([-_a-zA-Z0-9]+)\\/([a-zA-Z0-9]+)(.*)$"
#define REGEX_APPLE_MUSIC_PODCAST_OR_PODCAST_EPISODE @"^(?:https?:\\/\\/)?podcasts\\.apple\\.com\\/(?:[a-zA-Z]+)\\/podcast\\/(?:[-_a-zA-Z0-9]+)\\/id(?:[a-zA-Z0-9]+)(\\?(?:[a-zA-Z0-9]+(?:=(?:[a-zA-Z0-9]*))?&?)*)?$"
#define REGEX_SOUNDCLOUD @"^(?:https?:\\/\\/)?(?:(?:www.)|(?:m.)|(?:s))?(?:soundcloud.com\\/)[a-zA-Z0-9-.]+\\/+[a-zA-Z0-9-.]+(?:#.*)?$"

NS_ASSUME_NONNULL_BEGIN

@interface NSURL (WebsiteTypeValidation)

- (BOOL)matches:(NSString *)pattern;

@end

NS_ASSUME_NONNULL_END
