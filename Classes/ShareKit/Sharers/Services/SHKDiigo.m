//
//  SHKDiigo.m
//  ShareKit
//
//  Created by Arrix Zhou on 1/21/11.
//  Copyright 2011 Diigo. All rights reserved.
//

#import "SHKDiigo.h"
#include "Base64Transcoder.h"

@implementation SHKDiigo

static NSString * const kDiigoAPIUrl = @"https://secure.diigo.com/api/v2/";

#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle
{
	return @"Diigo";
}

+ (BOOL)canShareURL {
 return YES;
}

#pragma mark -
#pragma mark Configuration : Dynamic Enable

+ (BOOL)canShare
{
	return YES;
}



#pragma mark -
#pragma mark Authentication

// Return the form fields required to authenticate the user with the service
+ (NSArray *)authorizationFormFields
{
	return [NSArray arrayWithObjects:
			[SHKFormFieldSettings label:@"Username" key:@"username" type:SHKFormFieldTypeText start:nil],
			[SHKFormFieldSettings label:@"Password" key:@"password" type:SHKFormFieldTypePassword start:nil],			
			nil];
}

// Return the footer title to display under the login form
+ (NSString *)authorizationFormCaption
{
	// This should tell the user how to get an account.  Be concise!  The standard format is:
	return SHKLocalizedString(@"Create a free account at %@", @"diigo.com"); // This function works like (NSString *)stringWithFormat:(NSString*)format, ... | but translates the 'create a free account' part into any supported languages automatically
}

// Authenticate the user using the data they've entered into the form
- (void)authorizationFormValidate:(SHKFormController *)form
{
	/*
	 This is called when the user taps 'Login' on the login form after entering their information.
	 
	 Supply the necessary logic to validate the user input and authenticate the user.
	 
	 You can get a dictionary of the field values from [form formValues]
	 
	 --
	 
	 A common implementation looks like:
	 
	 1. Validate the form data.  
	 - Make sure necessary fields were completed.
	 - If there is a problem, display an error with UIAlertView
	 
	 2. Authenticate the user with the web service.
	 - Display the activity indicator
	 - Send a request to the server
	 - If the request fails, display an error
	 - If the request is successful, save the form
	 */ 
	
	
	
	 // Here is an example.  
	 // This example assumes the form created by authorizationFormFields had a username and password field.
	 
	 // Get the form data
	NSDictionary *formValues = [form formValues];
	
	// 1. Validate the form data	 
	if ([formValues objectForKey:@"username"] == nil || [formValues objectForKey:@"password"] == nil)
	{
		// display an error
		[[[[UIAlertView alloc] initWithTitle:@"Login Error"
									 message:@"You must enter a username and password"
									delegate:nil
						   cancelButtonTitle:@"Close"
						   otherButtonTitles:nil] autorelease] show];
		
	}
	
	// 2. Authenticate the user with the web service
	else 
	{
		// Show the activity spinner
		[[SHKActivityIndicator currentIndicator] displayActivity:@"Logging In..."];
		
		// Retain the form so we can access it after the request finishes
		self.pendingForm = form;
		
		// -- Send a request to the server
		// See http://getsharekit.com/docs/#requests for documentation on using the SHKRequest and SHKEncode helpers
		
		// Set the parameters for the request
		NSString *params = [NSMutableString stringWithFormat:@"username=%@&password=%@",
							SHKEncode([formValues objectForKey:@"username"]),
							SHKEncode([formValues objectForKey:@"password"])
							];
		
		// Send request
		self.request = [[[SHKRequest alloc] initWithURL:[NSURL URLWithString:[kDiigoAPIUrl stringByAppendingFormat:@"check_sign_in"]]
												 params:params
											   delegate:self
									 isFinishedSelector:@selector(authFinished:)
												 method:@"POST"
											  autostart:YES] autorelease];
	}
	 								 
}

// This is a continuation of the example provided in authorizationFormValidate above.  It handles the SHKRequest response
// This is not a required method and is only provided as an example

 - (void)authFinished:(SHKRequest *)aRequest
 {		
	 // Hide the activity indicator
	 [[SHKActivityIndicator currentIndicator] hide];
	 
	 // If the result is successful, save the form to continue sharing
	 if (aRequest.success)
		 [pendingForm saveForm];
	 
	 // If there is an error, display it to the user
	 else
	 {
		 // See http://getsharekit.com/docs/#requests for documentation on SHKRequest
		 // SHKRequest contains three properties that may assist you in responding to errors:
		 // aRequest.response is the NSHTTPURLResponse of the request
		 // aRequest.response.statusCode is the HTTTP status code of the response
		 // [aRequest getResult] returns a NSString of the body of the response
		 // aRequest.headers is a NSDictionary of all response headers
		 
		 [[[[UIAlertView alloc] initWithTitle:@"Login Error"
									  message:@"Your username and password did not match"
									 delegate:nil
							cancelButtonTitle:@"Close"
							otherButtonTitles:nil] autorelease] show];
	 }
 }
 


#pragma mark -
#pragma mark Share Form

- (NSArray *)shareFormFieldsForType:(SHKShareType)type
{
	if (type == SHKShareTypeURL)
	{
		return [NSArray arrayWithObjects:
				[SHKFormFieldSettings label:@"Title" key:@"title" type:SHKFormFieldTypeText start:item.title],
				[SHKFormFieldSettings label:@"Tags" key:@"tags" type:SHKFormFieldTypeText start:item.tags],
				[SHKFormFieldSettings label:@"Description" key:@"text" type:SHKFormFieldTypeText start:item.text],
				[SHKFormFieldSettings label:@"Read later" key:@"unread" type:SHKFormFieldTypeSwitch start:SHKFormFieldSwitchOff],
				[SHKFormFieldSettings label:@"Private" key:@"private" type:SHKFormFieldTypeSwitch start:SHKFormFieldSwitchOff],
				nil];
	}
	return nil;
}

// Validate the user input on the share form
- (void)shareFormValidate:(SHKCustomFormController *)form
{	
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

// When an attempt is made to share the item, verify that it has everything it needs, otherwise display the share form
/*
 - (BOOL)validateItem
 { 
 // The super class will verify that:
 // -if sharing a url	: item.url != nil
 // -if sharing an image : item.image != nil
 // -if sharing text		: item.text != nil
 // -if sharing a file	: item.data != nil
 
 // You only need to implement this if you need to check additional variables.
 
 // If you return NO, you should probably pop up a UIAlertView to notify the user they missed something.
 
 return [super validateItem];
 }
 */

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

// Send the share item to the server
- (BOOL)send
{	
	// Make sure that the item has minimum requirements
	if (![self validateItem])
		return NO;
	
	/*
	 Enter the necessary logic to share the item here.
	 
	 The shared item and relevant data is in self.item
	 // See http://getsharekit.com/docs/#sending
	 
	 --
	 
	 A common implementation looks like:
	 
	 -  Send a request to the server
	 -  call [self sendDidStart] after you start your action
	 -	after the action completes, fails or is cancelled, call one of these on 'self':
	 - (void)sendDidFinish (if successful)
	 - (void)sendDidFailShouldRelogin (if failed because the user's current credentials are out of date)
	 - (void)sendDidFailWithError:(NSError *)error shouldRelogin:(BOOL)shouldRelogin
	 - (void)sendDidCancel
	 */ 
	
	
	// Here is an example.  
	// This example is for a service that can share a URL
	
	
	// Determine which type of share to do
	if (item.shareType == SHKShareTypeURL) // sharing a URL
	{
		// Set the parameters for the request
		NSString *params = [NSMutableString stringWithFormat:@"key=%@&url=%@&title=%@&shared=%@&readLater=%@&tags=%@%&desc=%@",
							SHKDiigoKey,
							SHKEncodeURL(item.URL),
							SHKEncode(item.title),
							![item customBoolForSwitchKey:@"private"] ? @"yes" : @"no",
							[item customBoolForSwitchKey:@"unread"] ? @"yes" : @"no",
							SHKEncode(item.tags),
							SHKEncode(item.text)
							];
		
		// Send request
		self.request = [[[SHKRequest alloc] initWithURL:[NSURL URLWithString:[kDiigoAPIUrl stringByAppendingFormat:@"bookmarks"]]
												 params:params
											   delegate:self
									 isFinishedSelector:@selector(sendFinished:)
												 method:@"POST"
											  autostart:NO] autorelease];
		
		// Attach the HTTP Basic Auth header
		NSString *username = [self getAuthValueForKey:@"username"];
		NSString *password = [self getAuthValueForKey:@"password"];
		NSMutableDictionary *headers = [NSMutableDictionary dictionaryWithDictionary: self.request.headerFields];
		[headers setObject:[self httpAuthBasicHeaderWith:username andPass:password] forKey:@"Authorization"];
		self.request.headerFields = headers;

		[self.request start];
		
		// Notify self and it's delegates that we started
		[self sendDidStart];
		
		return YES; // we started the request
	}
	
	return NO;
}


// This is a continuation of the example provided in authorizationFormValidate above.  It handles the SHKRequest response
// This is not a required method and is only provided as an example

- (void)sendFinished:(SHKRequest *)aRequest
{	
	if (!aRequest.success)
	{
		// See http://getsharekit.com/docs/#requests for documentation on SHKRequest
		// SHKRequest contains three properties that may assist you in responding to errors:
		// aRequest.response is the NSHTTPURLResponse of the request
		// aRequest.response.statusCode is the HTTTP status code of the response
		// [aRequest getResult] returns a NSString of the body of the response
		// aRequest.headers is a NSDictionary of all response headers
		
		if (aRequest.response.statusCode == 401)
		{
			[self sendDidFailShouldRelogin];
			return;
		}
		
		// If there was an error that was not login related, send error along to the delegate
		[self sendDidFailWithError:[SHK error:@"There was a problem sharing"] shouldRelogin:NO];
		return;
	}
	
	[self sendDidFinish];
}


@end
