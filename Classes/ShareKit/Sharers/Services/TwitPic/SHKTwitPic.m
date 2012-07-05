//
//  SHKTwitPic.m
//  ShareKit
//
//  Created by David Linsin on 2/5/11.
//  Copyright 2011 furryfishApps.com. All rights reserved.
//

#import "SHKTwitPic.h"


@implementation SHKTwitPic

@synthesize twitPicAPIKey;

- (id)init {
    self = [super init];
	if (self) {	
		// OAUTH		
		self.consumerKey = SHKTwitterConsumerKey;		
		self.secretKey = SHKTwitterSecret;
 		self.authorizeCallbackURL = [NSURL URLWithString:SHKTwitterCallbackUrl];// HOW-TO: In your Twitter application settings, use the "Callback URL" field.  If you do not have this field in the settings, set your application type to 'Browser'.
		
		
		// You do not need to edit these, they are the same for everyone
	    self.authorizeURL = [NSURL URLWithString:@"https://twitter.com/oauth/authorize"];
	    self.requestURL = [NSURL URLWithString:@"https://twitter.com/oauth/request_token"];
	    self.accessURL = [NSURL URLWithString:@"https://twitter.com/oauth/access_token"]; 
        
        self.twitPicAPIKey = SHKTwitPicAPIKey;
	}	
	return self;
}


#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle {
	return @"TwitPic";
}

+ (BOOL)canShareImage {
	return YES;
}


#pragma mark -
#pragma mark Configuration : Dynamic Enable

- (BOOL)shouldAutoShare {
	return NO;
}


#pragma mark -
#pragma mark Authorization

- (BOOL)isAuthorized {		
	return [super restoreAccessToken];
}

- (void)promptAuthorization {		
	[super authorizationFormShow];
}


#pragma mark xAuth

+ (NSString *)authorizationFormCaption {
	return SHKLocalizedString(@"Create a free account at %@", @"Twitter.com");
}

+ (NSArray *)authorizationFormFields {
	if ([SHKTwitterUsername isEqualToString:@""])
		return [super authorizationFormFields];
	
	return [NSArray arrayWithObjects:
			[SHKFormFieldSettings label:SHKLocalizedString(@"Username") key:@"username" type:SHKFormFieldTypeText start:nil],
			[SHKFormFieldSettings label:SHKLocalizedString(@"Password") key:@"password" type:SHKFormFieldTypePassword start:nil],
			[SHKFormFieldSettings label:SHKLocalizedString(@"Send to Twitter") key:@"sendToTwitter" type:SHKFormFieldTypeSwitch start:SHKFormFieldSwitchOn],			
			nil];
}

- (void)authorizationFormValidate:(SHKFormController *)form {
	self.pendingForm = form;
	[self tokenAccess];
}

- (void)tokenAccessModifyRequest:(OAMutableURLRequest *)oRequest {	
	NSDictionary *formValues = [pendingForm formValues];
	OARequestParameter *username = [[[OARequestParameter alloc] initWithName:@"x_auth_username"
																		   value:[formValues objectForKey:@"username"]] autorelease];
		
	OARequestParameter *password = [[[OARequestParameter alloc] initWithName:@"x_auth_password"
																		   value:[formValues objectForKey:@"password"]] autorelease];
		
	OARequestParameter *mode = [[[OARequestParameter alloc] initWithName:@"x_auth_mode"
																	   value:@"client_auth"] autorelease];
		
	[oRequest setParameters:[NSArray arrayWithObjects:username, password, mode, nil]];
}

- (void)tokenAccessTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data {
	if (ticket.didSucceed) {
		[self setShareOnTwitter:[[[super.pendingForm formValues] objectForKey:@"sendToTwitter"] isEqualToString:SHKFormFieldSwitchOn]];
		[pendingForm close];
    } else {
        NSString *response = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
			
		SHKLog(@"tokenAccessTicket Response Body: %@", response);
			
		[self tokenAccessTicket:ticket didFailWithError:[SHK error:response]];
		return;
    }
	
	[super tokenAccessTicket:ticket didFinishWithData:data];		
}

#pragma mark -
#pragma mark UI Implementation

- (void)show {
	[item setCustomValue:item.title forKey:@"status"];
	[self showTwitterForm];
}

- (void)showTwitterForm {
	SHKTwitPicForm *rootView = [[SHKTwitPicForm alloc] initWithNibName:nil bundle:nil];	
	rootView.delegate = self;
	
	// force view to load so we can set textView text
	[rootView view];
	
	rootView.textView.text = [item customValueForKey:@"status"];
	rootView.hasAttachment = YES;
	
	[self pushViewController:rootView animated:NO];
	
	[[SHK currentHelper] showViewController:self];	
}

- (void)sendForm:(SHKTwitPicForm *)form {	
	[item setCustomValue:form.textView.text forKey:@"status"];
	[self tryToSend];
}

#pragma mark -
#pragma mark Share API Methods

- (BOOL)validate {
	NSString *status = [item customValueForKey:@"status"];
	return status != nil && (int)status.length >= 0 && status.length <= 140;
}

- (BOOL)send {
    if (![self validate]) {
		[self show];
	} else	{	
		[self sendImage];
		[self sendDidStart];	
		return YES;
	}
	return NO;
}

- (NSString*)oauthHeader {
    NSURL *serviceURL = [NSURL URLWithString:@"https://api.twitter.com/1/account/verify_credentials.json"];
	
	OAMutableURLRequest *oRequest = [[OAMutableURLRequest alloc] initWithURL:serviceURL
																	consumer:consumer
																	   token:accessToken
																	   realm:@"http://api.twitter.com/"
														   signatureProvider:signatureProvider];
	[oRequest prepare];
    
	NSDictionary * headerDict = [oRequest allHTTPHeaderFields];
	NSString * oauthHeader = [NSString stringWithString:[headerDict valueForKey:@"Authorization"]];
    
	[oRequest release];
	oRequest = nil;
    return oauthHeader;
}

- (NSData*)imageData {
    CGFloat compression = 0.9f;
	NSData *imageData = UIImageJPEGRepresentation([item image], compression);
	
	// TODO
	// Note from Nate to creator of sendImage method - This seems like it could be a source of sluggishness.
	// For example, if the image is large (say 3000px x 3000px for example), it would be better to resize the image
	// to an appropriate size (max of img.ly) and then start trying to compress.
	
	while ([imageData length] > 700000 && compression > 0.1) {
		// NSLog(@"Image size too big, compression more: current data size: %d bytes",[imageData length]);
		compression -= 0.1;
		imageData = UIImageJPEGRepresentation([item image], compression);
		
	}
    return imageData;
}

- (void)sendImage {	
	NSString * oauthHeader = [self oauthHeader];
		
	NSURL *serviceURL = [NSURL URLWithString:@"http://api.twitpic.com/2/upload.json"];
	OAMutableURLRequest *oRequest = [[OAMutableURLRequest alloc] initWithURL:serviceURL
												   consumer:consumer
													  token:accessToken
													  realm:@"http://api.twitter.com/"
										  signatureProvider:signatureProvider];

    // NASTY workaround to prevent Authorization HTTP header field to be set later on, TwitPic doesn't like it
    [oRequest prepare];
    [oRequest setValue:nil forHTTPHeaderField:@"Authorization"];
    // END NASTY workaround
    
	[oRequest setHTTPMethod:@"POST"];
	[oRequest setValue:@"https://api.twitter.com/1/account/verify_credentials.json" forHTTPHeaderField:@"X-Auth-Service-Provider"];
	[oRequest setValue:oauthHeader forHTTPHeaderField:@"X-Verify-Credentials-Authorization"];
    
	
	NSString *boundary = @"0xKhTmLbOuNdArY";
	NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
	[oRequest setValue:contentType forHTTPHeaderField:@"Content-Type"];
	
	NSMutableData *body = [NSMutableData data];
    
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[@"Content-Disposition: form-data; name=\"key\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[self.twitPicAPIKey dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
		
	[body appendData:[[NSString stringWithFormat:@"--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[@"Content-Disposition: form-data; name=\"media\"; filename=\"upload.jpg\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[@"Content-Type: image/jpg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[self imageData]];
	[body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	
	[body appendData:[[NSString stringWithFormat:@"--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[[NSString stringWithString:@"Content-Disposition: form-data; name=\"message\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[[item customValueForKey:@"status"] dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];	
	
	[body appendData:[[NSString stringWithFormat:@"--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	[oRequest setHTTPBody:body];
	
	[self sendDidStart];
	
	// Start the request
	OAAsynchronousDataFetcher *fetcher = [OAAsynchronousDataFetcher asynchronousFetcherWithRequest:oRequest
																						  delegate:self
																				 didFinishSelector:@selector(sendImage:didFinishWithData:)
																				   didFailSelector:@selector(sendImage:didFailWithError:)];	
	
	[fetcher start];
	
	
	[oRequest release];
}

- (void)sendImage:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data {	
	if (ticket.didSucceed) {
		if ([self shareOnTwitter]) {
            NSString *url = @"";
            NSScanner *scanner = [NSScanner scannerWithString:[[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]];
            [scanner scanUpToString:@"\"url\":\"" intoString:nil];
                       
            if ([scanner scanString:@"\"url\":\"" intoString:nil]) {
                [scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\""] intoString:&url];
                url = [url stringByReplacingOccurrencesOfString:@"\\" withString:@""];
                NSString *twitPicStatus = [NSString stringWithFormat:@"%@ %@", [item customValueForKey:@"status"], url];
                [self sendStatus: twitPicStatus];
            } else {
                [self sendDidFailWithError:nil];
            }
        } else {
       		[self sendDidFinish];
        }
	} else {
		[self sendDidFailWithError:nil];
	}
}

- (void)sendImage:(OAServiceTicket *)ticket didFailWithError:(NSError*)error {
	[self sendDidFailWithError:error];
}

- (void)sendStatus:(NSString*)status {
	OAMutableURLRequest *oRequest = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://api.twitter.com/1/statuses/update.json"]
																	consumer:consumer
																	   token:accessToken
																	   realm:nil
														   signatureProvider:nil];
	
	[oRequest setHTTPMethod:@"POST"];
	
	OARequestParameter *statusParam = [[OARequestParameter alloc] initWithName:@"status" value:status];
	NSArray *params = [NSArray arrayWithObjects:statusParam, nil];
	[oRequest setParameters:params];
	[statusParam release];
	
	OAAsynchronousDataFetcher *fetcher = [OAAsynchronousDataFetcher asynchronousFetcherWithRequest:oRequest
																						  delegate:self
																				 didFinishSelector:@selector(sendStatusTicket:didFinishWithData:)
																				   didFailSelector:@selector(sendStatusTicket:didFailWithError:)];	
	
	[fetcher start];
	[oRequest release];
}

- (void)sendStatusTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data {		

	if (ticket.didSucceed) {
		[self sendDidFinish];
	} else {		
        NSString *string = @"Your picture is on TwitPic, but we couldn't share it on Twitter!";
		NSError *error = [NSError errorWithDomain:@"Twitter" code:2 userInfo:[NSDictionary dictionaryWithObject:string forKey:NSLocalizedDescriptionKey]];
		[self sendDidFailWithError:error];
	}
    
}

- (void)sendStatusTicket:(OAServiceTicket *)ticket didFailWithError:(NSError*)error {
	[self sendDidFailWithError:error];
}

#pragma mark -
#pragma mark twitpic specific

- (BOOL)shareOnTwitter {
    return [[NSUserDefaults standardUserDefaults] boolForKey:[NSString stringWithFormat:@"%@_shareOnTwitter", [self sharerId]]];
}

- (void)setShareOnTwitter:(BOOL)share {
    [[NSUserDefaults standardUserDefaults] setBool:share forKey:[NSString stringWithFormat:@"%@_shareOnTwitter", [self sharerId]]];
}

@end
