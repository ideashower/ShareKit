//
//  SHKPlurk.m
//  ShareKit
//
//  Created by Yehnan Chiang on 5/19/11.
//  Copyright 2011 Yehnan Chiang. All rights reserved.
//

#import "SHKPlurk.h"
#import "SHKPlurkForm.h"
#import "JSONKit.h"

static NSString * const kPlurkLoginURL = @"https://www.plurk.com/API/Users/login";
static NSString * const kPlurkAddURL = @"http://www.plurk.com/API/Timeline/plurkAdd";

@implementation SHKPlurk

#pragma mark Memory management
- (void)dealloc{
	[super dealloc];
}

#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle
{
	return SHKLocalizedString(@"Plurk");
}

+ (BOOL)canShareText
{
	return YES;
}

+ (BOOL)canShareURL
{
	return YES;
}

//plurk can share image, I'll add this later.
/*
 + (BOOL)canShareImage
 {
 return YES;
 }
 */

#pragma mark -
#pragma mark Configuration : Dynamic Enable

// Subclass if you need to dynamically enable/disable the action.  (For example if it only works with specific hardware)
+ (BOOL)canShare
{
	return YES;
}

#pragma mark -
#pragma mark Authentication

+ (NSArray *)authorizationFormFields
{
	return [NSArray arrayWithObjects:
			[SHKFormFieldSettings label:SHKLocalizedString(@"Username") key:@"username" type:SHKFormFieldTypeText start:nil],
			[SHKFormFieldSettings label:SHKLocalizedString(@"Password") key:@"password" type:SHKFormFieldTypePassword start:nil],			
			nil];
}

+ (NSString *)authorizationFormCaption
{
	return SHKLocalizedString(@"Create a free account at %@", @"www.plurk.com");
}

- (void)authorizationFormValidate:(SHKFormController *)form
{
	// Display an activity indicator
	if (!quiet)
		[[SHKActivityIndicator currentIndicator] displayActivity:SHKLocalizedString(@"Logging In...")];
	
	// Authorize the user through the server
	NSDictionary *formValues = [form formValues];
	
	NSString *params = [NSMutableString stringWithFormat:@"api_key=%@&username=%@&password=%@&no_data=1",
						SHKEncode(SHKPlurkAPIKey),
                        SHKEncode([formValues objectForKey:@"username"]),
                        SHKEncode([formValues objectForKey:@"password"])
                        ];
	
	NSLog(@"authorizationFormValidate %@", params);
	
	self.request = [[[SHKRequest alloc] initWithURL:[NSURL URLWithString:kPlurkLoginURL]
                                             params:params
                                           delegate:self
                                 isFinishedSelector:@selector(authFinished:)
                                             method:@"POST"
                                          autostart:YES] autorelease];
	
	self.pendingForm = form;
}

- (void)authFinished:(SHKRequest *)aRequest
{		
	[[SHKActivityIndicator currentIndicator] hide];
	
	NSLog(@"authFinished %@", aRequest);
	
	if (aRequest.success){
		[pendingForm saveForm];
	}
	else {// If there is an error, display it to the user
		[[[[UIAlertView alloc] initWithTitle:SHKLocalizedString(@"Login Error")
									 message:SHKLocalizedString(@"Invalid username or password.")
									delegate:nil
						   cancelButtonTitle:SHKLocalizedString(@"Close")
						   otherButtonTitles:nil] autorelease] show];
	}
}

#pragma mark -
#pragma mark UI Implementation

- (void)show
{
	if (item.shareType == SHKShareTypeURL)
	{
		[item setCustomValue:[NSString stringWithFormat:@"%@ ", [item.URL absoluteString]] forKey:@"status"];
	}
	else if (item.shareType == SHKShareTypeText)
	{
		[item setCustomValue:item.text forKey:@"status"];
		
	}
	[self showPlurkForm];
}

- (void)showPlurkForm
{
	SHKPlurkForm *rootView = [[SHKPlurkForm alloc] initWithNibName:nil bundle:nil];	
	rootView.delegate = self;
	
	// force view to load so we can set textView text
	[rootView view];
	
	rootView.textView.text = [item customValueForKey:@"status"];
	
	[self pushViewController:rootView animated:NO];
	
	[[SHK currentHelper] showViewController:self];	
}

- (void)sendForm:(SHKPlurkForm *)form
{	
	[item setCustomValue:form.textView.text forKey:@"status"];
	[self tryToSend];
}

#pragma mark -
#pragma mark Share Form



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
#pragma mark Share API Methods

- (BOOL)validate
{
	NSString *status = [item customValueForKey:@"status"];
	return status != nil && status.length >= 0 && status.length <= PLURK_DATA_MAX;
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
typedef struct{
	NSString *replacee;
	NSString *replacer;
} URLencodeStruct;
static NSString *URLencode(NSString *str){
	NSMutableString *escaped = [NSMutableString stringWithString:[str stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	const URLencodeStruct rep[] = {
		{@"\t", @"%09"},
		{@"\n", @"%0A"},
		{@" ", @"%20"},
		{@"\"", @"%22"},
		{@"#", @"%23"},
		{@"$", @"%24"},
		{@"&", @"%26"},
		{@"+", @"%2B"},
		{@",", @"%2C"},
		{@"/", @"%2F"},
		{@":", @"%3A"},
		{@";", @"%3B"},
		{@"<", @"%3C"},
		{@"=", @"%3D"},
		{@">", @"%3E"},
		{@"?", @"%3F"},
		{@"@", @"%40"},
	};
	for(int i = 0, n = sizeof(rep) / sizeof(URLencodeStruct); i < n; i++){
		[escaped replaceOccurrencesOfString:rep[i].replacee withString:rep[i].replacer options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
	}
	
	return escaped;
}
- (void)sendStatus
{
	// Display an activity indicator
	if (!quiet)
		[[SHKActivityIndicator currentIndicator] displayActivity:SHKLocalizedString(@"Sending...")];
	
	// Authorize the user through the server
	NSString *status = [item customValueForKey:@"status"];
	
	NSString *params = [NSMutableString stringWithFormat:@"api_key=%@&content=%@&qualifier=%@",
						SHKEncode(SHKPlurkAPIKey),
                        URLencode(status),
                        SHKEncode(@"shares")
                        ];
	
	self.request = [[[SHKRequest alloc] initWithURL:[NSURL URLWithString:kPlurkAddURL]
                                             params:params
                                           delegate:self
                                 isFinishedSelector:@selector(sendFinished:)
                                             method:@"POST"
                                          autostart:YES] autorelease];
}
- (void)sendFinished:(SHKRequest *)aRequest
{	
	if (!aRequest.success) {
		if (aRequest.response.statusCode == 400) {
			NSDictionary *dict = [[JSONDecoder decoder] objectWithData:aRequest.data];
			NSLog(@"error happened %@", [[dict valueForKey:@"error_text"] class]);
			NSLog(@"   %@", [dict valueForKey:@"error_text"]);

			if([(NSString *)[dict valueForKey:@"error_text"] isEqualToString:@"Requires login"]){
				[self sendDidFailWithError:[SHK error:SHKLocalizedString(@"Requires login")] shouldRelogin:YES];
				NSLog(@"1 dict=%@", dict);
				return;
			}
			else if([(NSString *)[dict valueForKey:@"error_text"] isEqualToString:@"Invalid data"] ||
					[(NSString *)[dict valueForKey:@"error_text"] isEqualToString:@"Content is empty"]){
				[self sendDidFailWithError:[SHK error:SHKLocalizedString(@"Invalid plurk data")]];
				NSLog(@"2 dict=%@", dict);
				return;
			}
			else if([(NSString *)[dict valueForKey:@"error_text"] isEqualToString:@"Content too long"]){
				[self sendDidFailWithError:[SHK error:SHKLocalizedString(@"Message is too long")]];
				NSLog(@"3 dict=%@", dict);
				return;
			}
			else if([(NSString *)[dict valueForKey:@"error_text"] isEqualToString:@"anti-flood-same-content"] ||
					[(NSString *)[dict valueForKey:@"error_text"] isEqualToString:@"anti-flood-too-many-new"] ||
					[(NSString *)[dict valueForKey:@"error_text"] isEqualToString:@"anti-flood-spam-domain"]){
				[self sendDidFailWithError:[SHK error:SHKLocalizedString(@"This plurk data was already sent")]];
				NSLog(@"4 dict=%@", dict);
				return;
			}
		}
        
		[self sendDidFailWithError:[SHK error:SHKLocalizedString(@"There was an error sending your post to Plurk.")]];
		return;
	}
    
	[self sendDidFinish];
}
- (BOOL)send
{	
	if (![self validate]) {
		[self show];
	}
	else
	{	
		if (item.shareType == SHKShareTypeURL || item.shareType == SHKShareTypeText) {
			[self sendStatus];
		}
		// Notify delegate
		[self sendDidStart];	
		
		return YES;
	}
	
	return NO;
}


@end
