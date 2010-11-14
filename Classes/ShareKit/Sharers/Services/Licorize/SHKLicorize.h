//
//  SHKLicorize.h
//  ShareKit
//
//  Created by Federico Soldani on 11/13/10.

#import <Foundation/Foundation.h>
#import "SHKOAuthSharer.h"

@interface SHKLicorize : SHKOAuthSharer {
	BOOL xAuth;		
}

@property BOOL xAuth;

#pragma mark -
#pragma mark Share API Methods

- (void)remindMeLater;
- (void)saveStrip;

- (void)sendTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data;
- (void)sendTicket:(OAServiceTicket *)ticket didFailWithError:(NSError *)error;

@end
