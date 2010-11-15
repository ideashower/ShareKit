//
//  SHKLicorize.h
//  ShareKit
//
//  Created by Federico Soldani on 11/13/10.

#import "SHKLicorize.h"

@interface SHKLicorize ()
NSString * UrlOrBlank(NSURL * value);
BOOL SendDidSuccess(NSData * data);
@end

@implementation SHKLicorize

@synthesize xAuth;

#pragma mark -
#pragma mark Configuration : Service Defination

// Enter the name of the service
+ (NSString *)sharerTitle {
	return @"Licorize";
}

+ (BOOL)canShareURL {
	return YES;
}

+ (BOOL)canShareText {
	return YES;	
}

#pragma mark -
#pragma mark Configuration : Dynamic Enable

// Subclass if you need to dynamically enable/disable the service.  (For example if it only works with specific hardware)
+ (BOOL)canShare {
	return YES;
}

#pragma mark -
#pragma mark Authorization

- (BOOL)isAuthorized {		
	return [self restoreAccessToken];
}

- (void)promptAuthorization {		
	if (xAuth) {
		[super authorizationFormShow]; // xAuth process
	} else {
		[super promptAuthorization]; // OAuth process
	}
}


#pragma mark xAuth

+ (NSString *)authorizationFormCaption {
	return SHKLocalizedString(@"Create a free account at %@", @"Licorize.com");
}

- (void)authorizationFormValidate:(SHKFormController *)form {
	self.pendingForm = form;
	[self tokenAccess];
}

#pragma mark -
#pragma mark Authentication

- (id)init {
	if (self = [super init]) {		
		// OAUTH		
		self.consumerKey = SHKLicorizeConsumerKey;		
		self.secretKey = SHKLicorizeSecret;
 		self.authorizeCallbackURL = [NSURL URLWithString:SHKLicorizeCallbackUrl];
		
		// XAUTH
		self.xAuth = SHKLicorizeUseXAuth ? YES : NO;
		
		
		// -- //
		
		
		// You do not need to edit these, they are the same for everyone
	    self.requestURL = [NSURL URLWithString:@"http://api.licorize.com/oauth/request_token"];
	    self.authorizeURL = [NSURL URLWithString:@"http://api.licorize.com/oauth/authorize"];
	    self.accessURL = [NSURL URLWithString:@"http://api.licorize.com/oauth/access_token"];
		
		self.signatureProvider = [[[OAHMAC_SHA1SignatureProvider alloc] init] autorelease];
	}	
	return self;
}

- (void)tokenAccessModifyRequest:(OAMutableURLRequest *)oRequest {	
	if (xAuth) {
		NSDictionary *formValues = [pendingForm formValues];
		
		OARequestParameter *username = [[[OARequestParameter alloc] initWithName:@"x_auth_username"
																		   value:[formValues objectForKey:@"username"]] autorelease];
		
		OARequestParameter *password = [[[OARequestParameter alloc] initWithName:@"x_auth_password"
																		   value:[formValues objectForKey:@"password"]] autorelease];
		
		OARequestParameter *mode = [[[OARequestParameter alloc] initWithName:@"x_auth_mode"
																	   value:@"client_auth"] autorelease];
		
		[oRequest setParameters:[NSArray arrayWithObjects:username, password, mode, nil]];
	}
}

// Validate the user input on the share form
- (void)shareFormValidate:(SHKCustomFormController *)form {	
	/*
	 
	 Services should subclass this if they need to validate any data before sending.
	 You can get a dictionary of the field values from [form formValues]
	 
	 --
	 
	 You should perform one of the following actions:
	 
	 1.	Save the form - If everything is correct call [form saveForm]
	 
	 2.	Display an error - If the user input was incorrect, display an error to the user and tell them what to do to fix it
	 
	 
	 */	
	
	// default does no checking and proceeds to share
	[form saveForm];
}



#pragma mark -
#pragma mark Implementation

// Send the share item to the server
- (BOOL)send {	
	if (![self validateItem])
		return NO;
	
	if ( (item.shareType == SHKShareTypeURL) || (item.shareType == SHKShareTypeText)) {
		if ( item.shareType == SHKShareTypeURL ) {
			[self remindMeLater];
		} else {
			[self saveStrip];
		}
		
		// Notify delegate
		[self sendDidStart];
		
		return YES;			
	} else {
		return NO;
	}
}

- (void)remindMeLater {
	OAMutableURLRequest *oRequest = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://api.licorize.com/1/strips/remindMeLater.json"]
																	consumer:consumer
																	   token:accessToken
																	   realm:nil
														   signatureProvider:nil];
	
	[oRequest setHTTPMethod:@"POST"];

	OARequestParameter *urlParam = [[OARequestParameter alloc] initWithName:@"url"
																	  value:UrlOrBlank(item.URL)];
	OARequestParameter *titleParam = [[OARequestParameter alloc] initWithName:@"title"
																		value:SHKStringOrBlank(item.title)];
	
	NSArray *params = [NSArray arrayWithObjects:urlParam, titleParam, nil];
	[oRequest setParameters:params];
	[urlParam release];
	[titleParam release];
	
	OAAsynchronousDataFetcher *fetcher = [OAAsynchronousDataFetcher asynchronousFetcherWithRequest:oRequest
																						  delegate:self
																				 didFinishSelector:@selector(sendTicket:didFinishWithData:)
																				   didFailSelector:@selector(sendTicket:didFailWithError:)];	
	
	[fetcher start];
	[oRequest release];
}

- (void)saveStrip {
	OAMutableURLRequest *oRequest = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://api.licorize.com/1/strips/update.json"]
																	consumer:consumer
																	   token:accessToken
																	   realm:nil
														   signatureProvider:nil];
	
	[oRequest setHTTPMethod:@"POST"];
	
	OARequestParameter *urlParam = [[OARequestParameter alloc] initWithName:@"url"
																	  value:UrlOrBlank(item.URL)];
	OARequestParameter *titleParam = [[OARequestParameter alloc] initWithName:@"title"
																		value:SHKStringOrBlank(item.title)];
	OARequestParameter *textParam = [[OARequestParameter alloc] initWithName:@"notes"
																	   value:SHKStringOrBlank(item.text)];
	OARequestParameter *typeParam = [[OARequestParameter alloc] initWithName:@"type"
																	   value:@"NOTE"];
	OARequestParameter *tagsParam = [[OARequestParameter alloc] initWithName:@"tags"
																	   value:SHKStringOrBlank(item.tags)];
	
	NSArray *params = [NSArray arrayWithObjects:urlParam, titleParam, textParam, typeParam, tagsParam, nil];
	[oRequest setParameters:params];
	[urlParam release];
	[titleParam release];
	[textParam release];
	[typeParam release];
	[tagsParam release];
	
	OAAsynchronousDataFetcher *fetcher = [OAAsynchronousDataFetcher asynchronousFetcherWithRequest:oRequest
																						  delegate:self
																				 didFinishSelector:@selector(sendTicket:didFinishWithData:)
																				   didFailSelector:@selector(sendTicket:didFailWithError:)];	
	
	[fetcher start];
	[oRequest release];
}

- (void)sendTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data {
	if (ticket.didSucceed && SendDidSuccess(data)) {
		[self sendDidFinish];
	} else {
		NSString *string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
		
		if (SHKDebugShowLogs)
			SHKLog(@"Licorize RemindMeLater Error: %@", string);
		
		// in case our makeshift parsing does not yield an error message
		NSString *errorMessage = @"Unknown Error";		
		
		NSScanner *scanner = [NSScanner scannerWithString:string];
		
		// skip until error message
		[scanner scanUpToString:@"\"message\":\"" intoString:nil];
		
		
		if ([scanner scanString:@"\"message\":\"" intoString:nil]) {
			// get the message until the closing double quotes
			[scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\""] intoString:&errorMessage];
		}
		
		
		// this is the error message for revoked access
		if ([errorMessage isEqualToString:@"Invalid / used nonce"]) {
			[self sendDidFailShouldRelogin];
		} else  {
			NSError *error = [NSError errorWithDomain:@"Licorize" code:2 userInfo:[NSDictionary dictionaryWithObject:errorMessage forKey:NSLocalizedDescriptionKey]];
			[self sendDidFailWithError:error];
		}		
	}
}	

- (void)sendTicket:(OAServiceTicket *)ticket didFailWithError:(NSError *)error {
	[self sendDidFailWithError:error];
}

#pragma mark -
#pragma mark Utilities

NSString * UrlOrBlank(NSURL * value) {
	return value == nil ? @"" : [value absoluteString];
}

BOOL SendDidSuccess(NSData * data) {
	NSString *string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];

	NSScanner *scanner = [NSScanner scannerWithString:string];

	NSString *success = @"true";	
	
	// skip until success message
	[scanner scanUpToString:@"\"ok\":" intoString:nil];

	if ([scanner scanString:@"\"ok\":" intoString:nil]) {
		// get the message until the closing double quotes
		[scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@","] intoString:&success];
	}
	
	if([success isEqualToString:@"true"]) {
		return YES;		
	} else {
		return NO;
	}

} 

@end
