//
//  SHKMail.m
//  ShareKit
//
//  Created by Nathan Weiner on 6/17/10.

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

#import "SHKMail.h"


@implementation MFMailComposeViewController (SHK)

- (void)SHKviewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	
	// Remove the SHK view wrapper from the window
	[[SHK currentHelper] viewWasDismissed];
}

@end



@implementation SHKMail

#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle
{
	return @"Email";
}

+ (BOOL)canShareText
{
	return YES;
}

+ (BOOL)canShareURL
{
	return YES;
}

+ (BOOL)canShareImage
{
	return YES;
}

+ (BOOL)canShareFile
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
	return YES;
}

- (BOOL)shouldAutoShare
{
	return YES;
}



#pragma mark -
#pragma mark Share API Methods

- (void)share
{
    if (![MFMailComposeViewController canSendMail]) {
        [[[[UIAlertView alloc] initWithTitle:SHKLocalizedString(@"No Account")
    								 message:SHKLocalizedString(@"Please set up an account in Mail.")
    								delegate:nil
    					   cancelButtonTitle:SHKLocalizedString(@"Close")
    					   otherButtonTitles:nil] autorelease] show];
    }
    else {
        [super tryToSend];
    }
}

- (BOOL)send
{
	self.quiet = YES;
	
	if (![self validateItem])
		return NO;
	
	return [self sendMail]; // Put the actual sending action in another method to make subclassing SHKMail easier
}

- (BOOL)sendMail
{	
	MFMailComposeViewController *mailController = [[[MFMailComposeViewController alloc] init] autorelease];
	mailController.mailComposeDelegate = self;
	
	NSString *body = [item customValueForKey:@"body"];
	
	if (body == nil)
	{
		if (item.text != nil)
			body = item.text;
		
		if (item.URL != nil)
		{	
			NSString *urlStr = [item.URL.absoluteString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			
			if (body != nil)
				body = [body stringByAppendingFormat:@"<br/><br/>%@", urlStr];
			
			else
				body = urlStr;
		}
		
		if (item.data)
		{
			NSString *attachedStr = SHKLocalizedString(@"Attached: %@", item.title ? item.title : item.filename);
			
			if (body != nil)
				body = [body stringByAppendingFormat:@"<br/><br/>%@", attachedStr];
			
			else
				body = attachedStr;
			
			[mailController addAttachmentData:item.data mimeType:item.mimeType fileName:item.filename];
		}
		
		if (item.image)
			[mailController addAttachmentData:UIImageJPEGRepresentation(item.image, 1) mimeType:@"image/jpeg" fileName:@"Image.jpg"];		
		
		// fallback
		if (body == nil)
			body = @"";
		
		// sig
		if (SHKSharedWithSignature)
		{
			body = [body stringByAppendingString:@"<br/><br/>"];
			body = [body stringByAppendingString:SHKLocalizedString(@"Sent from %@", SHKMyAppName)];
		}
		
		// save changes to body
		[item setCustomValue:body forKey:@"body"];
	}
	
	[mailController setSubject:item.title];
	[mailController setMessageBody:body isHTML:YES];
			
	[[SHK currentHelper] showViewController:mailController];
	
	return YES;
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
	[[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
	
	switch (result) 
	{
		case MFMailComposeResultSent:
			[self sendDidFinish];
			break;
		case MFMailComposeResultSaved:
			[self sendDidFinish];
			break;
		case MFMailComposeResultCancelled:
			[self sendDidCancel];
			break;
		case MFMailComposeResultFailed:
			[self sendDidFailWithError:nil];
			break;
	}
}

- (void)sharerFinishedSending:(SHKSharer *)sharer
{
	if (!quiet) {
    	[SHK displayCompleted:SHKLocalizedString(@"E-mail Sent")];
    }
}


@end
