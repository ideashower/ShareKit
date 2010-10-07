//
//  SHKPastebot.m
//  ShareKit
//
//  Created by Anh Quang Do on 07/10/2010.
//

#import "SHKPastebot.h"


@implementation SHKPastebot


#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle
{
	return @"Send to Pastebot";
}

+ (BOOL)canShareText
{
	return YES;
}

+ (BOOL)shareRequiresInternetConnection
{
	return NO;
}

+ (BOOL)requiresAuthentication
{
	return NO;
}

#pragma mark -
#pragma mark Configuration : Dynamic Enable

+ (BOOL)canShare
{
	return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"pastebot://test"]];
}

#pragma mark -
#pragma mark Implementation

- (BOOL)send
{	
	self.quiet = YES;
	
	NSString *pastebotURLString = [NSString stringWithFormat:@"pastebot://%@", SHKEncode(item.text)];
	
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:pastebotURLString]];
	
	[self sendDidFinish];
	
	return YES;
}

@end
