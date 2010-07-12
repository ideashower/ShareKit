//
//  SHKConfig.h
//  ShareKit
//
//  Created by Nathan Weiner on 6/23/10.

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


#error Setup the SHKConfig.h file, then remove this error by commenting it out.


// App Description
// These values are used by any service that shows 'shared from XYZ'

#define SHKMyAppName			@"My App Name"
#define SHKMyAppURL				@"http://example.com"



/*
API Keys
--------
This is the longest step to getting set up, it involves filling in API keys for the supported services.
It should be pretty painless though and should hopefully take no more than a few minutes.
 
Each key below as a link to a page where you can generate an api key.  Fill in the key for each service below.
 
A note on services you don't need:
If, for example, your app only shares URLs then you probably won't need image services like Flickr.
In these cases it is safe to leave an API key blank.
 
However, it is STRONGLY recommended that you do your best to support all services for the types of sharing you support.
The core principle behind ShareKit is to leave the service choices up to the user.  Thus, you should not remove any services,
leaving that decision up to the user.
*/



// Delicious - https://developer.apps.yahoo.com/projects
#define SHKDeliciousConsumerKey		@""
#define SHKDeliciousSecretKey		@""
#define SHKDeliciousCallbackUrl		@""

// Facebook - http://www.facebook.com/developers
#define SHKFacebookKey				@""
#define SHKFacebookSecret			@""

// Flickr

// Read It Later - http://readitlaterlist.com/api/?shk
#define SHKReadItLaterKey			@""

// Twitter - http://dev.twitter.com/apps/new
#define SHKTwitterConsumerKey		@""
#define SHKTwitterSecret			@""
#define SHKTwitterCallbackUrl		@"" // HOW-TO: In your Twitter application settings, use the "Callback URL" field.  If you do not have this field in the settings, set your application type to 'Browser'.
#define SHKTwitterUseXAuth			0 // To use xAuth, set to 1
#define SHKTwitterUsername			@"" // Enter your app's twitter account if you'd like to ask the user to follow it when logging in. (Only for xAuth)

// Bit.ly (for shortening URLs on Twitter) - http://bit.ly/account/register - after signup: http://bit.ly/a/your_api_key
#define SHKBitLyLogin				@""
#define SHKBitLyKey					@""




/*
 UI Configuration : Basic
 ------
 These provide controls for basic UI settings.  For more advanced configuration see below.
 */

// Toolbars
#define SHKBarStyle					@"UIBarStyleDefault" // See: http://developer.apple.com/iphone/library/documentation/UIKit/Reference/UIKitDataTypesReference/Reference/reference.html#//apple_ref/c/econst/UIBarStyleDefault
#define SHKBarTintColorRed			-1 // Value between 0-255, set all to -1 for default
#define SHKBarTintColorGreen		-1 // Value between 0-255, set all to -1 for default
#define SHKBarTintColorBlue			-1 // Value between 0-255, set all to -1 for default

// Forms
#define SHKFormFontColorRed			-1 // Value between 0-255, set all to -1 for default
#define SHKFormFontColorGreen		-1 // Value between 0-255, set all to -1 for default
#define SHKFormFontColorBlue		-1 // Value between 0-255, set all to -1 for default

#define SHKFormBgColorRed			-1 // Value between 0-255, set all to -1 for default
#define SHKFormBgColorGreen			-1 // Value between 0-255, set all to -1 for default
#define SHKFormBgColorBlue			-1 // Value between 0-255, set all to -1 for default


/*
 UI Configuration : Advanced
 ------
 If you'd like to do more advanced customization of the ShareKit UI, like background images and more,
 check out http://getsharekit.com/customize
 */




/*
 Advanced Configuration
 ------
 These settings can be left as is.  This only need to be changed for uber custom installs.
 */

#define SHK_MAX_FAV_COUNT			4
#define SHK_FAVS_PREFIX_KEY			@"SHK_FAVS_"
#define SHK_AUTH_PREFIX				@"SHK_AUTH_"