




// PLEASE SEE INSTALL/CONFIG INSTRUCTIONS:
// http://getsharekit.com/install



// Read one config value. Search order is:
// 1. Registrered dictionary
// 2. Main bundle plist.
// 3. A defualt is applicable
// 4. nil
extern id SHKConfigValueForKey(NSString* key);


// Keys are the string key for the values,
extern void SHKRegisterConfigValuesWithDictionary(NSDictionary* configValues);


// App Description
// These values are used by any service that shows 'shared from XYZ'
extern NSString* const SHKConfigMyAppName;
extern NSString* const SHKConfigMyAppURL;


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
extern NSString* const SHKConfigDeliciousConsumerKey;
extern NSString* const SHKConfigDeliciousSecretKey;


// Facebook - http://www.facebook.com/developers
// If SHKFacebookUseSessionProxy is enabled then SHKFacebookSecret is ignored and should be left blank
extern NSString* const SHKConfigFacebookUseSessionProxy;
extern NSString* const SHKConfigFacebookKey;
extern NSString* const SHKConfigFacebookSecret;
extern NSString* const SHKConfigFacebookSessionProxyURL;


// Read It Later - http://readitlaterlist.com/api/?shk
extern NSString* const SHKConfigReadItLaterKey;


// Twitter - http://dev.twitter.com/apps/new
/*
 Important Twitter settings to get right:
 
 Differences between OAuth and xAuth
 --
 There are two types of authentication provided for Twitter, OAuth and xAuth.  OAuth is the default and will
 present a web view to log the user in.  xAuth presents a native entry form but requires Twitter to add xAuth to your app (you have to request it from them).
 If your app has been approved for xAuth, set SHKTwitterUseXAuth to 1.
 
 Callback URL (important to get right for OAuth users)
 --
 1. Open your application settings at http://dev.twitter.com/apps/
 2. 'Application Type' should be set to BROWSER (not client)
 3. 'Callback URL' should match whatever you enter in SHKTwitterCallbackUrl.  The callback url doesn't have to be an actual existing url.  The user will never get to it because ShareKit intercepts it before the user is redirected.  It just needs to match.
 */
extern NSString* const SHKConfigTwitterConsumerKey;
extern NSString* const SHKConfigTwitterSecret;
extern NSString* const SHKConfigTwitterCallbackURL; // You need to set this if using OAuth, see note above (xAuth users can skip it)

extern NSString* const SHKConfigTwitterUseXAuth; // To use xAuth, set to YES
extern NSString* const SHKConfigTwitterUsername; // Enter your app's twitter account if you'd like to ask the user to follow it when logging in. (Only for xAuth)


// Bit.ly (for shortening URLs on Twitter) - http://bit.ly/account/register - after signup: http://bit.ly/a/your_api_key
extern NSString* const SHKConfigBitLyLogin;
extern NSString* const SHKConfigBitLyKey;


// Evernote
extern NSString* const SHKConfigEvernoteUserStoreURL;
extern NSString* const SHKConfigEvernoteConsumerKey;
extern NSString* const SHKConfigEvernoteSecretKey;
extern NSString* const SHKConfigEvernoteNetStoreURLBase;

// ShareMenu Ordering, Setting this to 1 will show list in Alphabetical Order, setting to 0 will follow the order in SHKShares.plist
extern NSString* const SHKConfigShareMenuAlphabeticalOrder;


// Append 'Shared With 'Signature to Email (and related forms)
extern NSString* const SHKConfigSharedWithSignature;


/*
 UI Configuration : Basic
 ------
 These provide controls for basic UI settings.  For more advanced configuration see below.
 */

// Toolbars
extern NSString* const SHKConfigBarStyle;
extern NSString* const SHKConfigBarTintColor;

// Forms
extern NSString* const SHKConfigFormFontColor;
extern NSString* const SHKConfigFormBackgroundColor;

// iPad views
extern NSString* const SHKConfigModalPresentationStyle; // See: http://developer.apple.com/iphone/library/documentation/UIKit/Reference/UIViewController_Class/Reference/Reference.html#//apple_ref/occ/instp/UIViewController/modalPresentationStyle
extern NSString* const SHKConfigModalTransitionStyle; // See: http://developer.apple.com/iphone/library/documentation/UIKit/Reference/UIViewController_Class/Reference/Reference.html#//apple_ref/occ/instp/UIViewController/modalTransitionStyle





/*
 UI Configuration : Advanced
 ------
 If you'd like to do more advanced customization of the ShareKit UI, like background images and more,
 check out http://getsharekit.com/customize
 */



/*
 Debugging
 ------
 To show debug output in the console:
 1. uncomment section A below
 2. comment out section B below
 
 To hide debug output in the console:
 1. uncomment section B below
 2. comment out section A below
 */

// A : show debug output
//#define SHKDebugShowLogs			1
//#define SHKLog( s, ... ) NSLog( @"<%p %@:(%d)> %@", self, [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )

// B : hide debug output
#define SHKDebugShowLogs			0
#define SHKLog( s, ... ) 



/*
 Advanced Configuration
 ------
 These settings can be left as is.  This only need to be changed for uber custom installs.
 */

#define SHK_MAX_FAV_COUNT			3
#define SHK_FAVS_PREFIX_KEY			@"SHK_FAVS_"
#define SHK_AUTH_PREFIX				@"SHK_AUTH_"