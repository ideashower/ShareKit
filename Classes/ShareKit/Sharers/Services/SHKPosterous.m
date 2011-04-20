//
//  SHKPinboard.m
//  ShareKit
//
//  Created by Arik Devens on 4/8/11.

#import "SHKPosterous.h"
#include "Base64Transcoder.h"

static NSString * const kPosterousPostURL = @"http://posterous.com/api/2/sites/primary/posts";

@implementation SHKPosterous

#pragma mark -
#pragma mark Memory management
- (void)dealloc {
    [photoData release];
    [URLResponse release];
	
    [super dealloc];
}

#pragma mark -
#pragma mark Configuration : Service Definition

+ (NSString *)sharerTitle {
	return @"Posterous";
}

+ (BOOL)canShareText {
    return YES;
}

+ (BOOL)canShareImage {
    return YES;
}

#pragma mark -
#pragma mark Authorization

+ (NSString *)authorizationFormCaption {
	return SHKLocalizedString(@"Create an account at %@", @"http://posterous.com");
}

- (void)authorizationFormValidate:(SHKFormController *)form {
	if (!quiet) {
		[[SHKActivityIndicator currentIndicator] displayActivity:SHKLocalizedString(@"Logging In...")];
	}	

	[form saveForm];
}

- (void)authFinished:(SHKRequest *)aRequest {	
	[[SHKActivityIndicator currentIndicator] hide];
}


#pragma mark -
#pragma mark Share Form

- (NSArray *)shareFormFieldsForType:(SHKShareType)type {
	if (type == SHKShareTypeText) {
		return [NSArray arrayWithObjects:[SHKFormFieldSettings label:SHKLocalizedString(@"Title") key:@"title" type:SHKFormFieldTypeText start:item.title], nil];
	}
	
	return nil;
}

#pragma mark -
#pragma mark Share API Methods

- (NSString *)httpAuthBasicHeaderWith:(NSString *)user andPass:(NSString *)pass {
	NSData *data = [[NSString stringWithFormat:@"%@:%@", user, pass] dataUsingEncoding:NSUTF8StringEncoding];

	size_t est_out_len = EstimateBas64DecodedDataSize([data length]);
	size_t out_len = est_out_len + 512; // a safety margin of 512 is perhaps too big	
	char outdata[out_len];
	Base64EncodeData([data bytes], [data length], outdata, &out_len);	
	outdata[out_len] = '\0'; // make it a null terminated string	
	
	NSString *value = [NSString stringWithFormat:@"Basic %@", [NSString stringWithCString:outdata encoding:NSUTF8StringEncoding]];
	
	return value;
}

- (BOOL)send {	
	if ([self validateItem]) {
		NSMutableURLRequest *aRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:kPosterousPostURL] cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:90];
		
		NSString *username = [self getAuthValueForKey:@"username"];
		NSString *password = [self getAuthValueForKey:@"password"];
		NSString *boundary = @"0xKhTmLbOuNdArY";
		
		NSMutableDictionary *headers = [NSMutableDictionary dictionaryWithDictionary: self.request.headerFields];
		[headers setObject:[self httpAuthBasicHeaderWith:username andPass:password] forKey:@"Authorization"];
		[headers setObject:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary] forKey:@"Content-Type"];
		
		[aRequest setAllHTTPHeaderFields:headers];	
		[aRequest setHTTPMethod:@"POST"];
		
		NSMutableData *body = [NSMutableData data];
		
		[body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[@"Content-Disposition: form-data; name=\"api_token\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[[NSString stringWithString:SHKPosterousAPIKey] dataUsingEncoding:NSUTF8StringEncoding]];
			
		if ([item title]) {
			[body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
			[body appendData:[@"Content-Disposition: form-data; name=\"post[title]\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
			[body appendData:[item.title dataUsingEncoding:NSUTF8StringEncoding]];			
		}
		
		if ([item text]) {
			[body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
			[body appendData:[@"Content-Disposition: form-data; name=\"post[body]\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
			[body appendData:[item.text dataUsingEncoding:NSUTF8StringEncoding]];
		}
		
		if ([item image]) {
            [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[@"Content-Disposition: form-data; name=\"media[0]\"; filename=\"upload.jpg\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[@"Content-Transfer-Encoding: image/jpg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:UIImageJPEGRepresentation([item image], 0.9)];
		}
		
		[body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		
		[aRequest setHTTPBody:body];
		
		[NSURLConnection connectionWithRequest:aRequest delegate:self];
		[aRequest release];

		[self sendDidStart];
		
		return YES;			
	}
	
	return NO;
}

#pragma mark -
#pragma mark NSURLConnection delegate methods
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)theResponse {
    [URLResponse release];
	URLResponse = [theResponse retain];
	
	[photoData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)d {
	[photoData appendData:d];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self finish];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {    
	[self finish];
}

- (void)finish {
    if (URLResponse.statusCode == 200 || URLResponse.statusCode == 201) {
		[self sendDidFinish];
    } else {
        if (URLResponse.statusCode == 403) {
            [self sendDidFailWithError:[SHK error:SHKLocalizedString(@"Invalid username or password.")] shouldRelogin:YES];
        } else if (URLResponse.statusCode == 500) {
            [self sendDidFailWithError:[SHK error:SHKLocalizedString(@"The service encountered an error. Please try again later.")]];
        } else {		
			[self sendDidFailWithError:[SHK error:SHKLocalizedString(@"There was an error sending your post to Posterous.")]];
		}
    }
}

@end
