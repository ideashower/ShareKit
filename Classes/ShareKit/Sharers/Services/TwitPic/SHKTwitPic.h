//
//  SHKTwitPic.h
//  ShareKit
//
//  Created by David Linsin on 2/5/11.
//  Copyright 2011 furryfishApps.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SHKOAuthSharer.h"
#import "SHKTwitPicForm.h"

@interface SHKTwitPic : SHKOAuthSharer {
    NSString *twitPicAPIKey;
}

@property (nonatomic, retain) NSString *twitPicAPIKey;

#pragma mark -
#pragma mark UI Implementation

- (void)showTwitterForm;

#pragma mark -
#pragma mark Share API Methods

- (void)sendForm:(SHKTwitPicForm *)form;

- (void)sendImage;
- (void)sendImage:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data;
- (void)sendImage:(OAServiceTicket *)ticket didFailWithError:(NSError*)error;

@end
