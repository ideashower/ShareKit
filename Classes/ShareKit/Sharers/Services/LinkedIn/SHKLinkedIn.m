//
//  SHKLinkedIn.m
//  ShareKit
//
//  Created by Jim Spoto on 7/11/11.
//  With permission from Dot Matrix, LLC.

//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
//

/////////////////////////////////////////////////////////////////////////////////
/*	SHKLinkedIn (7/11/2011) Jim Spoto

	Some notes on getting this service up and running...

	Reference Code: http://lee.hdgreetings.com/2011/03/iphone-oauth.html

		* The project linked above has a working implementation of OAuth via LinkedIn, and was used
		primarily as a point of reference.  It appears to have a different flavor of OAuth which,
		frustratingly, couldn't be integrated directly into ShareKit without what appeared to be
		a substantial amount of work.


	OAuth: OAMutableURLRequest modified to enable authorization via LinkedIn
		
		* Modifications/additions to better support realm / callback in the request
		* An appropriate callback & verifier is necessary to avoid LinkedIn's OOB (pin) validation path
		* Both the header and signature have to be created and assembled correctly.  Some parameters
		seem to require being in both, some not.  Perhaps the OAuth spec can be reviewed to validate
		this (http://oauth.net/core/1.0/)
		
		
	UI: A new style UI class cluster has been created, based largely on the SHKTwitter source
	
		* The class cluster includes classes for form, form style, abstract field, and three specific
		field types: text, URL, and multiline text
		
		* Discussion:  The reason for going this route was the apparent incompatibility between the
		way custom ShareKit forms are designed to work, and the way the SHKTwitter form works, in terms
		of available UI functionality and composition of controls.  LinkedIn includes support for very
		long (700 characters) input fields, and UITextField controls are not usable for long input.  The
		SHKTwitter style control is, but does not support multiple multi-line input fields - something
		again supported by LinkedIn share data.  
		
		* Features: The UI classes support custom coloring via the style property of the form class, and
		new field classes should be fairly simple to add by extending the SHKLinkedInForm class.
		
		* Implementation: The form is created using a custom UIScrollView class instead of a UITableView.
		the primary reasons for this are the issues associated with embedding UITextView controls inside of
		a UITableViewCell object.  It may be desirable to rework SHK form code, to support dynamically
		sized, multi-line cell classes, but there were enough caveats to avoid this on a first pass.
		
		For what it's worth, AddressBook appears to do this somehow, so it's possible (if you're Apple)...
		
		* "SHK Native UI:  If this is desired, moving the core share functionality of SHKLinkedIn.m into
		a vanilla custom share class should be straightforward
		
		
	Categories:  Created to experiment with some class methods, without modifying them
	
		SHKItem+KVC: Facilitates KVC methods on the Item, instead of using the methods to conver to an
		NSDictionary, which would seem unnecessary (and acutally only supports string parms).  Making
		getting/setting item data more dynamic greatly improved the ease with which fields (and their
		associated keys) can automatically sync with the share Item.
		
		UIWebView+SHKPlus:  A bit of a toy, really.  Javascript to get the Document meta tag from a web
		page.  Many social networking sites do something like this automatically when posting a link, and
		since LinkedIn supports a link description, I used this data to auto-fill the Description field
		by adding support in ExampleShareLink.m
		
		
		
	TDB / Incomplete Features:  The important stuff I haven't yet gotten to..	
		
		Error Handling, Login/Auth Failure Handling is *incomplete*!  Currently, virtually no error handling
		exists based on LinkedIn's return data.  Need to include authorization issues (and reauthentication loop)
		as well as share/api return errors.
	
	
	Known Issues / Bugs:
	
		* Twitter: Using the Example project, having issues when attempting to re-login after logging out with Twitter.
		Not sure if the unmodified project has this issue (need to test).  May have broken something with Twitter when
		getting LinkedIn working (JRS)
		
		* Memory Leak:  Occaisional leak sharing with LinkedIn using the Example project, when doing the following:
		Authenticate, cancel out of share form, log out, authenticate again, cancel during share step, etc.  At a glance,
		the leak does not appear to be coming from any of the SHK classes directly (and may be in another thread related
		to the URL connection).  Need to test and compare to the unmodified (ie non-LinkedIn) project (JRS)
	
			
	Reference:	
		
		* Information on the LinkedIn API & OAuth
		
	LinkedIn Rest Doc. Home: http://developer.linkedin.com/community/apis
				  Share API: http://developer.linkedin.com/docs/DOC-1212#
			Throttle Limits: http://developer.linkedin.com/docs/DOC-1112
			  Common Issues: http://developer.linkedin.com/docs/DOC-1121
			
		
		
	For more information and discussion, please see:https://github.com/jspoto/ShareKit
	
*////////////////////////////////////////////////////////////////////////////////

#import "SHKLinkedIn.h"
#import "SHKLinkedInField.h"

@implementation SHKLinkedIn


#pragma mark -
#pragma mark Configuration : Service Defination

// Enter the name of the service
+ (NSString *)sharerTitle
{
	return @"LinkedIn";
}


// What types of content can the action handle?

// If the action can handle URLs, uncomment this section

+ (BOOL)canShareURL
{
	return YES;
}


// If the action can handle images, uncomment this section
/*
+ (BOOL)canShareImage
{
	return YES;
}
*/

// If the action can handle text, uncomment this section

+ (BOOL)canShareText
{
	return YES;
}


// If the action can handle files, uncomment this section
/*
+ (BOOL)canShareFile
{
	return YES;
}
*/


// Does the service require a login?  If for some reason it does NOT, uncomment this section:
/*
+ (BOOL)requiresAuthentication
{
	return NO;
}
*/ 


#pragma mark -
#pragma mark Configuration : Dynamic Enable

// Subclass if you need to dynamically enable/disable the service.  (For example if it only works with specific hardware)
+ (BOOL)canShare
{
	return YES;
}


#pragma mark -
#pragma mark Authentication

// These defines should be renamed (to match your service name).
// They will eventually be moved to SHKConfig so the user can modify them.

// linkedin.com key info here: https://www.linkedin.com/secure/developer (JRS)

#define SHKLinkedInCallbackUrl		@"hdlinked://linkedin/oauth"
#define SHKLinkedInRealm			@"https://api.linkedin.com/"
#define SHKLinkedInShareURL			@"http://api.linkedin.com/v1/people/~/shares"

/*		
	The site: https://api.linkedin.com. Some libraries will have you enter this root URL.
	Request token path: /uas/oauth/requestToken
	Access token path: /uas/oauth/accessToken
	Authorize path: /uas/oauth/authorize
*/

#define SHKLinkedInAPIRequestURL		@"https://api.linkedin.com/uas/oauth/requestToken"
#define SHKLinkedInAPIAccessURL			@"https://api.linkedin.com/uas/oauth/accessToken"
#define SHKLinkedInAPIAuthorizeURL		@"https://www.linkedin.com/uas/oauth/authorize"

#define SHKLinkedInShareLimit			(700)	// char limit for shares
#define SHKLinkedInDescriptionLimit		(400)	// char limit for URL descriptions
#define SHKLInkedInTitleLimit			(200)	// char limit for titles

////////

- (id)init
{
	if ((self = [super init]))
	{		
		self.consumerKey = SHKLinkedInConsumerKey;		
		self.secretKey = SHKLinkedInSecretKey;
 		self.authorizeCallbackURL = [NSURL URLWithString:SHKLinkedInCallbackUrl];
		
		// Set to correct URL's for OAuth steps, as defined above (JRS)
	    self.requestURL = [NSURL URLWithString:SHKLinkedInAPIRequestURL];
	    self.accessURL = [NSURL URLWithString:SHKLinkedInAPIAccessURL];
	    self.authorizeURL = [NSURL URLWithString:SHKLinkedInAPIAuthorizeURL];
		self.realm = SHKLinkedInRealm;
		
		// Allows you to set a default signature type, uncomment only one
		self.signatureProvider = [[[OAHMAC_SHA1SignatureProvider alloc] init] autorelease];
	}	
	return self;
}

// If you need to add additional headers or parameters to the request_token request, uncomment this section:

- (void)tokenRequestModifyRequest:(OAMutableURLRequest *)oRequest
{
	// Here is an example that adds the user's callback to the request headers
//	[oRequest setOAuthParameterName:@"oauth_callback" withValue:authorizeCallbackURL.absoluteString];

	oRequest.callback = authorizeCallbackURL.absoluteString;

}


// If you need to add additional headers or parameters to the access_token request, uncomment this section:

- (void)tokenAccessModifyRequest:(OAMutableURLRequest *)oRequest
{
	// Here is an example that adds the oauth_verifier value received from the authorize call.
	// authorizeResponseQueryVars is a dictionary that contains the variables sent to the callback url
	[oRequest setOAuthParameterName:@"oauth_verifier" withValue:[authorizeResponseQueryVars objectForKey:@"oauth_verifier"]];
}



#pragma mark -
#pragma mark Share Form

// If your action has options or additional information it needs to get from the user,
// use this to create the form that is presented to user upon sharing.



- (NSArray *)shareFormFieldsForType:(SHKShareType)type
{
	// See http://getsharekit.com/docs/#forms for documentation on creating forms
	
	if (type == SHKShareTypeURL)
	{
		// An example form that has a single text field to let the user edit the share item's title
		return [NSArray arrayWithObjects:
				
			[SHKLinkedInField textField:@"Title" key:@"title" placeholder:@"the title" type:SHKLinkedInTextFieldPlain newGroup:false],		
			[SHKLinkedInField urlField:@"URL" key:@"URL" placeholder:@"the url" newGroup:false],			
			
			[SHKLinkedInField multilineTextField:@"Link Description" key:@"linkDescription" placeholder:@"Link Description (optional)" charLimit:SHKLinkedInDescriptionLimit newGroup:false required:false],
				
			[SHKLinkedInField multilineTextField:@"Status Update" key:@"text" placeholder:@"Status Update (optional)" charLimit:SHKLinkedInShareLimit newGroup:true required:false],
				
			nil ];

	}
	else if (type == SHKShareTypeText)
	{
		// An example form that has a single text field to let the user edit the share item's title
		return [NSArray arrayWithObjects:
				
				[SHKLinkedInField multilineTextField:@"Status Update" key:@"text" placeholder:@"Post Status Update" charLimit:SHKLinkedInShareLimit newGroup:false required:true],				
				
				nil ];	
	}
	else if (type == SHKShareTypeImage)
	{
		// return a form if required when sharing an image
		return nil;		
	}	
	else if (type == SHKShareTypeFile)
	{
		// return a form if required when sharing a file
		return nil;		
	}
	
	return nil;
}



// If you have a share form the user will have the option to skip it in the future.
// If your form has required information and should never be skipped, uncomment this section.
+ (BOOL)canAutoShare
{
	return NO;
}



- (void)show
{
	if (item.shareType == SHKShareTypeURL)
	{
//		[self shortenURL];
		[self showLinkedInForm];

	}
	else if (item.shareType == SHKShareTypeText)
	{
		[self showLinkedInForm];
	}

}

- (void)showLinkedInForm
{
	SHKLinkedInForm *rootView = [[SHKLinkedInForm alloc] initWithNibName:nil bundle:nil];	
	rootView.delegate = self;
	rootView.item = item;
	rootView.style.backgroundColor = [UIColor colorWithRed:0.8f green:0.92f blue:1.0f alpha:1.0f];
	
	// force view to load so we can set textView text
	[rootView view];
	
	[rootView setFieldValuesForItem:item];
	
	[self pushViewController:rootView animated:NO];
	[[SHK currentHelper] showViewController:self];	
}

- (void)sendForm:(SHKLinkedInForm *)form
{	

	[form applyFieldValuesToItem:item];
	
	[self tryToSend];
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

- (BOOL)validateItem
{ 
	// The super class will verify that:
	// -if sharing a url	: item.url != nil
	// -if sharing an image : item.image != nil
	// -if sharing text		: item.text != nil
	// -if sharing a file	: item.data != nil

	return [super validateItem];
}


// Send the share item to the server
- (BOOL)send
{	
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
	
	
	// Determine which type of share to do
	if (item.shareType == SHKShareTypeURL || item.shareType == SHKShareTypeText) // sharing a URL
	{
		// For more information on OAMutableURLRequest see http://code.google.com/p/oauthconsumer/wiki/UsingOAuthConsumer
		
		OAMutableURLRequest *oRequest = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:SHKLinkedInShareURL]
																 consumer:consumer // this is a consumer object already made available to us
																	token:self.accessToken // this is our accessToken already made available to us
																	realm:self.realm
															   signatureProvider:signatureProvider];
		
		// Set the http method (POST or GET)
		[oRequest setHTTPMethod:@"POST"];

		// Build the share document (XML)  More information on the share format can be found here:
		//
		// http://developer.linkedin.com/docs/DOC-1212
		// 

		NSString *comment = nil;
		NSString *content = nil;
		NSString *visibility = @"<visibility><code>anyone</code></visibility>";

		if(item.text)
			comment = [NSString stringWithFormat:@"<comment>%@</comment>", item.text];

		if(item.URL)
		{
			NSString *contentTitle = [NSString stringWithFormat:@"<title>%@</title>", item.title];
			NSString *contentURL = [NSString stringWithFormat:@" <submitted-url>%@</submitted-url>", [item.URL absoluteString]];
			NSString *contentDescription = @"";

			NSString *desc = [item customValueForKey:@"linkDescription"];
			
			if(desc)
				contentDescription = [NSString stringWithFormat:@" <description>%@</description>", desc];
			
			content = [NSString stringWithFormat:@"<content>%@%@%@</content>", contentTitle, contentURL, contentDescription];
			
		}
				
		NSMutableString *share = [NSMutableString string];
		
		if(comment)
			[share appendString:comment];
			
		if(content)
			[share appendString:content];
			
		[share appendString:visibility];

		NSString *body = [NSString stringWithFormat:@"<?xml version='1.0' encoding='UTF-8'?><share>%@</share>", share ];

		// Prepare the request before setting the body, because OAuthConsumer wants to parse the body
		// for parameters to include in the signature, but LinkedIn doesn't work that way (JRS)
		[oRequest prepare];		
		
		if([body length])
			[oRequest setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
  
 //       [oRequest setValue:[NSString stringWithFormat:@"%d", [body length]] forHTTPHeaderField:@"Content-Length"];
		[oRequest setValue:@"text/xml;charset=UTF-8" forHTTPHeaderField:@"Content-Type"]; 
  
		// Start the request
		OAAsynchronousDataFetcher *fetcher = [OAAsynchronousDataFetcher asynchronousFetcherWithRequest:oRequest
																							  delegate:self
																					 didFinishSelector:@selector(sendTicket:didFinishWithData:)
																					   didFailSelector:@selector(sendTicket:didFailWithError:)];	
		
		[fetcher start];
		[oRequest release];
		
		// Notify delegate
		[self sendDidStart];
		
		return true;
	}
	
	return false;
	
}

// This is a continuation of the example provided in 'send' above.  It handles the OAAsynchronousDataFetcher response
// This is not a required method and is only provided as an example

- (void)sendTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data 
{	
	if (ticket.didSucceed)
	{
		// The send was successful
		[self sendDidFinish];
	}
	else 
	{
		// Handle the error
/*		NSString *responseBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		SHKLog(@"*ERROR* Share Ticket Response:%@", responseBody);
		[responseBody release];
*/				
		// If the error was the result of the user no longer being authenticated, you can reprompt
		// for the login information with:
		// [self sendDidFailShouldRelogin];
		
		// Otherwise, all other errors should end with:
		[self sendDidFailWithError:[SHK error:@"Why it failed"] shouldRelogin:NO];
	}
}
- (void)sendTicket:(OAServiceTicket *)ticket didFailWithError:(NSError*)error
{
	[self sendDidFailWithError:error shouldRelogin:NO];
}


@end
