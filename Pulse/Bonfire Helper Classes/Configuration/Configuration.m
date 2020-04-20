//
//  Configuration.m
//  Pulse
//
//  Created by Austin Valleskey on 4/11/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "Configuration.h"
#import "HAWebService.h"

#import "User.h"
#import "Camp.h"
#import "Post.h"
#import "BFLink.h"
#import "NSURL+WebsiteTypeValidation.h"
#import "NSString+Validation.h"
#import "Session.h"

#define ConfigurationDEVELOPMENT @"development"
#define ConfigurationPRODUCTION @"production"

#define ConfigurationAPI_BASE_URI @"API_BASE_URI"
#define ConfigurationAPI_CURRENT_VERSION @"API_CURRENT_VERSION"
#define ConfigurationAPI_KEY @"API_KEY"

#define ConfigurationPLIST @"Configurations"
#define ConfigurationPLIST_DEBUG ConfigurationPLIST@"-debug"

@interface Configuration ()

@property (copy, nonatomic) NSString *configuration;
@property (nonatomic) BOOL development;
@property (nonatomic, strong) NSDictionary *variables;

@end

@implementation Configuration

#ifdef DEBUG
NSString * const LOCAL_APP_URI = @"bonfireapp.debug";
#else
NSString * const LOCAL_APP_URI = @"bonfireapp";
#endif

#pragma mark -
#pragma mark Shared Configuration
+ (Configuration *)sharedConfiguration {
    static Configuration *_sharedConfiguration = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedConfiguration = [[self alloc] init];
    });
    
    return _sharedConfiguration;
}

#pragma mark -
#pragma mark Private Initialization
- (id)init {
    self = [super init];
    
    if (self) {
        // Fetch Current Configuration
        NSBundle *mainBundle = [NSBundle mainBundle];
        self.configuration = [[mainBundle infoDictionary] objectForKey:@"Configuration"];
        
        // Load Configurations
        NSString *path = [mainBundle pathForResource:ConfigurationPLIST ofType:@"plist"];
        NSDictionary *configurations = [NSDictionary dictionaryWithContentsOfFile:path];
        
        #ifdef DEBUG
        NSString *localPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:ConfigurationPLIST_DEBUG@".plist"];
        if (![NSDictionary dictionaryWithContentsOfFile:localPath]) {
            // create local config file
            [configurations writeToFile:localPath atomically:YES];
        }
        // update config variable with the debug config
        configurations = [NSDictionary dictionaryWithContentsOfFile:localPath];
        
        self.development = [[configurations objectForKey:self.configuration] isEqualToString:ConfigurationDEVELOPMENT];
        #else
        // only allow development if in debug mode
        self.development = false;
        #endif
        
        self.variables = configurations[@"environments"][self.development?ConfigurationDEVELOPMENT:ConfigurationPRODUCTION];
        
        // NSLog(@"self.variables: %@", self.variables);
    }
    
    return self;
}
- (void)saveDebugConfigFile {
    
}

#pragma mark -
+ (NSString *)configuration {
    return [[Configuration sharedConfiguration] configuration];
}
+ (BOOL)isDevelopment {
    return [[Configuration sharedConfiguration] development];
}

#pragma mark -
+ (NSString *)API_BASE_URI {
    Configuration *sharedConfiguration = [Configuration sharedConfiguration];
    
    if (sharedConfiguration.variables) {
        return [sharedConfiguration.variables objectForKey:ConfigurationAPI_BASE_URI];
    }
    
    return @"";
}

+ (NSString *)API_CURRENT_VERSION {
    Configuration *sharedConfiguration = [Configuration sharedConfiguration];
    
    if (sharedConfiguration.variables) {
        return [sharedConfiguration.variables objectForKey:ConfigurationAPI_CURRENT_VERSION];
    }
    
    return @"";
}

+ (NSString *)API_KEY {
    Configuration *sharedConfiguration = [Configuration sharedConfiguration];
    
    if (sharedConfiguration.variables) {
        return [sharedConfiguration.variables objectForKey:ConfigurationAPI_KEY];
    }
    
    return @"";
}

#pragma mark - Internal URL Helpers
+ (BOOL)isInternalURL:(NSURL *)url {
    if (!url) return false;
    
    if ([url.scheme isEqualToString:LOCAL_APP_URI]) {
        return true;
    }
    
    return false;
}
+ (BOOL)isExternalBonfireURL:(NSURL *)url {
    if (!url) return false;
    
//    if ([url matches:@"^(?:https?:\\/\\/)?(?:www\\.)?bonfire\\.camp\\b\\/((?:invite\\?friend_code=(?:[a-zA-Z0-9\\_]{1,30}|-[a-zA-Z0-9]{12,}))|(?:u\\/(?:[a-zA-Z0-9\\_]{1,30}|-[a-zA-Z0-9]{12,}))|(?:c\\/(?:[a-zA-Z0-9\\_]{1,30}|-[a-zA-Z0-9]{12,}))|(?:p\\/(?:[0-9]{1,})))$"]) {
//        return true;
//    }
    
    return ([url.host isEqualToString:@"www.bonfire.camp"] ||
            [url.host isEqualToString:@"bonfire.camp"]);
}
+ (NSString *)pathStringFromBonfireURL:(NSURL *)url {
    NSString *path = url.path;
    
    // clip leading "/" character if needed
    if (path.length > 0 && [[path substringToIndex:1] isEqualToString:@"/"]) {
        path = [path substringFromIndex:1];
    }
    // clip trailing "/" character if needed
    if (path.length > 0 && [[path substringToIndex:path.length-1] isEqualToString:@"/"]) {
        path = [path substringToIndex:path.length-1];
    }
    
    NSString *host = url.host;
    if ([self isInternalURL:url] && host && host.length > 0) {
        // prepend the host as a path component
        if (path.length == 0) {
            path = host;
        }
        else {
            path = [NSString stringWithFormat:@"%@/%@", host, path];
        }
    }
    
    return path;
}
+ (NSArray<NSString *> *)pathPartsFromBonfireURL:(NSURL *)url {
    return [[Configuration pathStringFromBonfireURL:url] componentsSeparatedByString:@"/"];
}
+ (id)objectFromBonfireURL:(NSURL *)url {
    if (![self isBonfireURL:url]) return false;
    
    DSpacer();
    DLog(@"objectFromBonfireURL(URL=%@)", url.absoluteString);
    
    NSString *path = [self pathStringFromBonfireURL:url];
    if (path.length == 0) return nil;
    NSArray<NSString *> *pathParts = [Configuration pathPartsFromBonfireURL:url];
    
    // Get parameters
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:true];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    for(NSURLQueryItem *item in components.queryItems)
    {
        [params setObject:item.value forKey:item.name];
    }
    
    DLog(@"pathParts:");
    DLog(@"%@", pathParts);
    DSpacer();
    
    BOOL isCamp = [pathParts[0] isEqualToString:@"c"];
    BOOL isUser = [pathParts[0] isEqualToString:@"u"];
    BOOL isPost = [pathParts[0] isEqualToString:@"p"];
    BOOL isLink = [pathParts[0] isEqualToString:@"l"];
    
    if (isCamp) {
        if (pathParts.count > 1 && pathParts[1].length > 0) {
            Camp *camp = [[Camp alloc] init];
            
            if ([pathParts[1] validateBonfireCampTag] == BFValidationErrorNone) {
                // camp/{camptag}
                NSString *camptag = pathParts[1];
                
                CampAttributes *attributes = [[CampAttributes alloc] init];
                attributes.identifier = camptag;
                
                camp.attributes = attributes;
            }
            else {
                // camp/{id}
                NSString *campId = pathParts[1];
                
                camp.identifier = campId;
            }
            
            return camp;
        }
    }
    else if (isUser) {
        if (pathParts.count > 1 && pathParts[1].length > 0) {
            User *user = [[User alloc] init];
            
            if ([pathParts[1] validateBonfireUsername] == BFValidationErrorNone) {
                // user/{username}
                NSString *username = pathParts[1];
                
                IdentityAttributes *attributes = [[IdentityAttributes alloc] init];
                attributes.identifier = username;
                
                user.attributes = attributes;
            }
            else {
                // user/{id}
                NSString *userId = pathParts[1];
                
                if ([userId isEqualToString:@"me"]) {
                    user = [[Session sharedInstance] currentUser];
                }
                else {
                    user.identifier = userId;
                }
            }
            
            return user;
        }
    }
    else if (isPost) {
        if (pathParts.count > 1 && pathParts[1].length > 0) {
            Post *post = [[Post alloc] init];
            
            // post/{id}
            NSString *postId = pathParts[1];
            post.identifier = postId;
            
            return post;
        }
    }
    else if (isLink) {
        if (pathParts.count > 1 && pathParts[1].length > 0) {
            BFLink *link = [[BFLink alloc] init];
            
            // post/{id}
            NSString *linkId = pathParts[1];
            link.identifier = linkId;
            
            return link;
        }
    }
    
    // No known object for URL
    return nil;
}

+ (NSDictionary *)parametersFromExternalBonfireURL:(NSURL *)url {
    // Get parameters
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:true];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    for(NSURLQueryItem *item in components.queryItems)
    {
        [params setObject:item.value forKey:item.name];
    }
    
    return params;
}
+ (BOOL)isBonfireURL:(NSURL *)url {
    if (!url) return false;
    
    return [self isInternalURL:url] || [self isExternalBonfireURL:url];
}

#pragma mark -
+ (void)switchToDevelopment {
    #ifdef DEBUG
    Configuration *sharedConfiguration = [Configuration sharedConfiguration];
    
    NSString *localPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:ConfigurationPLIST_DEBUG@".plist"];
    NSMutableDictionary *configurations = [[NSMutableDictionary alloc] initWithDictionary:[NSDictionary dictionaryWithContentsOfFile:localPath]];
    [configurations setObject:ConfigurationDEVELOPMENT forKey:sharedConfiguration.configuration];
    
    NSError *error = nil;
    NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:configurations format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
    
    if (plistData) {
        [plistData writeToFile:localPath atomically:YES];
        sharedConfiguration.development = YES;
        sharedConfiguration.variables = configurations[@"environments"][ConfigurationDEVELOPMENT];
    }
    
    [HAWebService reset];
    #endif
}
+ (void)switchToProduction {
    #ifdef DEBUG
    Configuration *sharedConfiguration = [Configuration sharedConfiguration];
    
    NSString *localPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:ConfigurationPLIST_DEBUG@".plist"];
    NSMutableDictionary *configurations = [[NSMutableDictionary alloc] initWithDictionary:[NSDictionary dictionaryWithContentsOfFile:localPath]];
    [configurations setObject:ConfigurationPRODUCTION forKey:sharedConfiguration.configuration];
    
    NSError *error = nil;
    NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:configurations format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
    
    if (plistData) {
        [plistData writeToFile:localPath atomically:YES];
        sharedConfiguration.development = NO;
        sharedConfiguration.variables = configurations[@"environments"][ConfigurationPRODUCTION];
    }
    
    [HAWebService reset];
    #endif
}
+ (void)replaceDevelopmentURIWith:(NSString *)newURI {
    #ifdef DEBUG
    Configuration *sharedConfiguration = [Configuration sharedConfiguration];
    
    NSString *localPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:ConfigurationPLIST_DEBUG@".plist"];
    NSMutableDictionary *configurations = [[NSMutableDictionary alloc] initWithDictionary:[NSDictionary dictionaryWithContentsOfFile:localPath]];
    NSMutableDictionary *environments = [[NSMutableDictionary alloc] initWithDictionary:configurations[@"environments"]];
    NSMutableDictionary *development = [[NSMutableDictionary alloc] initWithDictionary:environments[ConfigurationDEVELOPMENT]];
    [development setObject:newURI forKey:ConfigurationAPI_BASE_URI];
    
    [environments setObject:development forKey:ConfigurationDEVELOPMENT];
    [configurations setObject:environments forKey:@"environments"];
    
    NSError *error = nil;
    NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:configurations format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
    
    if (plistData) {
        [plistData writeToFile:localPath atomically:YES];
        if (sharedConfiguration.development) {
            sharedConfiguration.variables = configurations[@"environments"][ConfigurationDEVELOPMENT];
        }
    }
        
    [HAWebService reset];
    #endif
}

#pragma mark - Misc. Getters
+ (NSString *)DEVELOPMENT_BASE_URI {
    #ifdef DEBUG
    
    // Load Configurations
    NSString *localPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:ConfigurationPLIST_DEBUG@".plist"];
    NSDictionary *configurations = [NSDictionary dictionaryWithContentsOfFile:localPath];
    
    // Load Variables for Current Configuration
    return configurations[@"environments"][ConfigurationDEVELOPMENT][ConfigurationAPI_BASE_URI];
    
    #else
    
    return nil;
    
    #endif
}

+ (BOOL)isDebug {
    Configuration *sharedConfiguration = [Configuration sharedConfiguration];
    
    if (sharedConfiguration.configuration) {
        return [sharedConfiguration.configuration isEqualToString:@"Debug"];
    }
    
    return false;
}
+ (BOOL)isBeta {
    Configuration *sharedConfiguration = [Configuration sharedConfiguration];
    
    if (sharedConfiguration.configuration) {
        return [sharedConfiguration.configuration isEqualToString:@"Beta"];
    }
    
    return false;
}
+ (BOOL)isRelease {
    Configuration *sharedConfiguration = [Configuration sharedConfiguration];
    
    if (sharedConfiguration.configuration) {
        return [sharedConfiguration.configuration isEqualToString:@"Release"];
    }
    
    return false;
}

@end
