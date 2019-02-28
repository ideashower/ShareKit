//
//  SHK.m
//  ShareKit
//
//  Created by Nathan Weiner on 6/10/10.

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

#import "SHK.h"
#import "SHKActivityIndicator.h"
#import "SHKViewControllerWrapper.h"
#import "SHKActionSheet.h"
#import "SHKOfflineSharer.h"
#import "SFHFKeychainUtils.h"
#import "SHKReachability.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <MessageUI/MessageUI.h>


NSString* const SHKConfigMyAppName = @"SHKConfigMyAppName";
NSString* const SHKConfigMyAppURL = @"SHKConfigMyAppURL";
NSString* const SHKConfigDeliciousConsumerKey = @"SHKConfigDeliciousConsumerKey";
NSString* const SHKConfigDeliciousSecretKey = @"SHKConfigDeliciousSecretKey";
NSString* const SHKConfigFacebookUseSessionProxy = @"SHKConfigFacebookUseSessionProxy";
NSString* const SHKConfigFacebookKey = @"SHKConfigFacebookKey";
NSString* const SHKConfigFacebookSecret = @"SHKConfigFacebookSecret";
NSString* const SHKConfigFacebookSessionProxyURL = @"SHKConfigFacebookSessionProxyURL";
NSString* const SHKConfigReadItLaterKey = @"SHKConfigReadItLaterKey";
NSString* const SHKConfigTwitterConsumerKey = @"SHKConfigTwitterConsumerKey";
NSString* const SHKConfigTwitterSecret = @"SHKConfigTwitterSecret";
NSString* const SHKConfigTwitterCallbackURL = @"SHKConfigTwitterCallbackURL"; // You need to set this if using OAuth, see note above (xAuth users can skip it)
NSString* const SHKConfigTwitterUseXAuth = @"SHKConfigTwitterUseXAuth"; // To use xAuth, set to YES
NSString* const SHKConfigTwitterUsername = @"SHKConfigTwitterUsername"; // Enter your app's twitter account if you'd like to ask the user to follow it when logging in. (Only for xAuth)
NSString* const SHKConfigBitLyLogin = @"SHKConfigBitLyLogin";
NSString* const SHKConfigBitLyKey = @"SHKConfigBitLyKey";
NSString* const SHKConfigEvernoteUserStoreURL = @"SHKConfigEvernoteUserStoreURL";
NSString* const SHKConfigEvernoteConsumerKey = @"SHKConfigEvernoteConsumerKey";
NSString* const SHKConfigEvernoteSecretKey = @"SHKConfigEvernoteSecretKey";
NSString* const SHKConfigEvernoteNetStoreURLBase = @"SHKConfigEvernoteNetStoreURLBase";
NSString* const SHKConfigShareMenuAlphabeticalOrder = @"SHKConfigShareMenuAlphabeticalOrder";
NSString* const SHKConfigSharedWithSignature = @"SHKConfigSharedWithSignature";
NSString* const SHKConfigBarStyle = @"SHKConfigBarStyle";
NSString* const SHKConfigBarTintColor = @"SHKConfigBarTintColor";
NSString* const SHKConfigFormFontColor = @"SHKConfigFormFontColor";
NSString* const SHKConfigFormBackgroundColor = @"SHKConfigFormBackgroundColor";
NSString* const SHKConfigModalPresentationStyle = @"SHKConfigModalPresentationStyle";
NSString* const SHKConfigModalTransitionStyle = @"SHKConfigModalTransitionStyle";


static NSDictionary* shk_registeredConfigValues = nil;

id SHKConfigValueForKey(NSString* key) {
	id value = [shk_registeredConfigValues objectForKey:key];
    if (!value) {
    	value = [[[NSBundle mainBundle] infoDictionary] objectForKey:key];
    }
    if (!value) {
        if ([key isEqualToString:SHKConfigMyAppName]) {
        	value = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
        } else if ([key isEqualToString:SHKConfigMyAppURL]) {
        	return @"http:/example.com";
        } else if ([key isEqualToString:SHKConfigShareMenuAlphabeticalOrder]) {
        	return [NSNumber numberWithBool:YES];
        } else if ([key isEqualToString:SHKConfigSharedWithSignature]) {
        	return [NSNumber numberWithBool:YES];
        } else if ([key isEqualToString:SHKConfigBarStyle]) {
        	return [NSNumber numberWithInteger:UIBarStyleDefault];
        } else if ([key isEqualToString:SHKConfigModalPresentationStyle]) {
        	return [NSNumber numberWithInteger:UIModalPresentationFormSheet];
        } else if ([key isEqualToString:SHKConfigModalTransitionStyle]) {
        	return [NSNumber numberWithInteger:UIModalTransitionStyleCoverVertical];
        }
    } else if (![value isKindOfClass:[NSString class]] && [key hasSuffix:@"Color"]) {
    	float rgba[4] = {0.f, 0.f, 0.f, 1.f};
        NSInteger length = [value length];
		switch (length) {
         	case 3: // RGB
            case 4: // RGBA
            	for (int i = 0; i < length; i++) {
                    unsigned c = 0;
                    [[NSScanner scannerWithString:[value substringWithRange:NSMakeRange(i, 1)]] scanHexInt:&c];
                    rgba[i] = c / 15.0f;
                }
                break;
            case 6: // RGB
            case 8: // RGBA
            	for (int i = 0; i < length; i += 2) {
                    unsigned c = 0;
                    [[NSScanner scannerWithString:[value substringWithRange:NSMakeRange(i, 2)]] scanHexInt:&c];
                    rgba[i / 2] = c / 255.0f;
                }
                break;
            default:
                return nil;
        }
        return [UIColor colorWithRed:rgba[0] green:rgba[1] blue:rgba[2] alpha:rgba[3]];
    }
    
    return value;
}


// Keys are the string key for the values,
void SHKRegisterConfigValuesWithDictionary(NSDictionary* configValues) {
    [shk_registeredConfigValues release];
    shk_registeredConfigValues = [configValues copy];
}



@implementation SHK

@synthesize currentView, pendingView, isDismissingView;
@synthesize rootViewController;
@synthesize offlineQueue;

static SHK *currentHelper = nil;
BOOL SHKinit;


+ (SHK *)currentHelper
{
	if (currentHelper == nil)
		currentHelper = [[SHK alloc] init];
	
	return currentHelper;
}

+ (void)initialize
{
	[super initialize];
	
	if (!SHKinit)
	{
		SHKSwizzle([MFMailComposeViewController class], @selector(viewDidDisappear:), @selector(SHKviewDidDisappear:));			
		
		if (NSClassFromString(@"MFMessageComposeViewController") != nil)
			SHKSwizzle([MFMessageComposeViewController class], @selector(viewDidDisappear:), @selector(SHKviewDidDisappear:));	
		
		SHKinit = YES;
	}
}

- (void)dealloc
{
	[currentView release];
	[pendingView release];
	[offlineQueue release];
	[super dealloc];
}



#pragma mark -
#pragma mark View Management

+ (void)setRootViewController:(UIViewController *)vc
{	
	SHK *helper = [self currentHelper];
	[helper setRootViewController:vc];	
}

- (void)showViewController:(UIViewController *)vc
{	
	if (rootViewController == nil)
	{
		// Try to find the root view controller programmically
		
		// Find the top window (that is not an alert view or other window)
		UIWindow *topWindow = [[UIApplication sharedApplication] keyWindow];
		if (topWindow.windowLevel != UIWindowLevelNormal)
		{
			NSArray *windows = [[UIApplication sharedApplication] windows];
			for(topWindow in windows)
			{
				if (topWindow.windowLevel == UIWindowLevelNormal)
					break;
			}
		}
		
		UIView *rootView = [[topWindow subviews] objectAtIndex:0];	
		id nextResponder = [rootView nextResponder];
		
		if ([nextResponder isKindOfClass:[UIViewController class]])
			self.rootViewController = nextResponder;
		
		else
			NSAssert(NO, @"ShareKit: Could not find a root view controller.  You can assign one manually by calling [[SHK currentHelper] setRootViewController:YOURROOTVIEWCONTROLLER].");
	}
	
	// Find the top most view controller being displayed (so we can add the modal view to it and not one that is hidden)
	UIViewController *topViewController = [self getTopViewController];	
	if (topViewController == nil)
		NSAssert(NO, @"ShareKit: There is no view controller to display from");
	
		
	// If a view is already being shown, hide it, and then try again
	if (currentView != nil)
	{
		self.pendingView = vc;
		[[currentView parentViewController] dismissModalViewControllerAnimated:YES];
		return;
	}
		
	// Wrap the view in a nav controller if not already
	if (![vc respondsToSelector:@selector(pushViewController:animated:)])
	{
		UINavigationController *nav = [[[UINavigationController alloc] initWithRootViewController:vc] autorelease];
		
		if ([nav respondsToSelector:@selector(modalPresentationStyle)])
			nav.modalPresentationStyle = [SHK modalPresentationStyle];
		
		if ([nav respondsToSelector:@selector(modalTransitionStyle)])
			nav.modalTransitionStyle = [SHK modalTransitionStyle];
		
		nav.navigationBar.barStyle = nav.toolbar.barStyle = [SHK barStyle];
		
		[topViewController presentModalViewController:nav animated:YES];			
		self.currentView = nav;
	}
	
	// Show the nav controller
	else
	{		
		if ([vc respondsToSelector:@selector(modalPresentationStyle)])
			vc.modalPresentationStyle = [SHK modalPresentationStyle];
		
		if ([vc respondsToSelector:@selector(modalTransitionStyle)])
			vc.modalTransitionStyle = [SHK modalTransitionStyle];
		
		[topViewController presentModalViewController:vc animated:YES];
		[(UINavigationController *)vc navigationBar].barStyle = 
		[(UINavigationController *)vc toolbar].barStyle = [SHK barStyle];
		self.currentView = vc;
	}
		
	self.pendingView = nil;		
}

- (void)hideCurrentViewController
{
	[self hideCurrentViewControllerAnimated:YES];
}

- (void)hideCurrentViewControllerAnimated:(BOOL)animated
{
	if (isDismissingView)
		return;
	
	if (currentView != nil)
	{
		// Dismiss the modal view
		if ([currentView parentViewController] != nil)
		{
			self.isDismissingView = YES;
			[[currentView parentViewController] dismissModalViewControllerAnimated:animated];
		}
		
		else
			self.currentView = nil;
	}
}

- (void)showPendingView
{
    if (pendingView)
        [self showViewController:pendingView];
}


- (void)viewWasDismissed
{
	self.isDismissingView = NO;
	
	if (currentView != nil)
		currentView = nil;
	
    if (rootViewController != nil)
        rootViewController = nil;

	if (pendingView)
	{
		// This is an ugly way to do it, but it works.
		// There seems to be an issue chaining modal views otherwise
		// See: http://github.com/ideashower/ShareKit/issues#issue/24
		[self performSelector:@selector(showPendingView) withObject:nil afterDelay:0.02];
		return;
	}
}
										   
- (UIViewController *)getTopViewController
{
	UIViewController *topViewController = rootViewController;
	while (topViewController.modalViewController != nil)
		topViewController = topViewController.modalViewController;
	return topViewController;
}
			
+ (UIBarStyle)barStyle
{
    return [SHKConfigValueForKey(SHKConfigBarStyle) intValue];
}

+ (UIModalPresentationStyle)modalPresentationStyle
{
    return [SHKConfigValueForKey(SHKConfigModalPresentationStyle) intValue];
}

+ (UIModalTransitionStyle)modalTransitionStyle
{
    return [SHKConfigValueForKey(SHKConfigModalTransitionStyle) intValue];
}


#pragma mark -
#pragma mark Favorites


+ (NSArray *)favoriteSharersForType:(SHKShareType)type
{	
	NSArray *favoriteSharers = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@%i", SHK_FAVS_PREFIX_KEY, type]];
		
	// set defaults
	if (favoriteSharers == nil)
	{
		switch (type) 
		{
			case SHKShareTypeURL:
				favoriteSharers = [NSArray arrayWithObjects:@"SHKTwitter",@"SHKFacebook",@"SHKReadItLater",nil];
				break;
				
			case SHKShareTypeImage:
				favoriteSharers = [NSArray arrayWithObjects:@"SHKMail",@"SHKFacebook",@"SHKCopy",nil];
				break;
				
			case SHKShareTypeText:
				favoriteSharers = [NSArray arrayWithObjects:@"SHKMail",@"SHKTwitter",@"SHKFacebook",nil];
				break;
				
			case SHKShareTypeFile:
				favoriteSharers = [NSArray arrayWithObjects:@"SHKMail",@"SHKEvernote",nil];
				break;
			
			default:
				favoriteSharers = [NSArray array];
		}
		
		// Save defaults to prefs
		[self setFavorites:favoriteSharers forType:type];
	}
	
	// Make sure the favorites are not using any exclusions, remove them if they are.
	NSArray *exclusions = [[NSUserDefaults standardUserDefaults] objectForKey:@"SHKExcluded"];
	if (exclusions != nil)
	{
		NSMutableArray *newFavs = [favoriteSharers mutableCopy];
		for(NSString *sharerId in exclusions)
		{
			[newFavs removeObject:sharerId];
		}
		
		// Update
		favoriteSharers = [NSArray arrayWithArray:newFavs];
		[self setFavorites:favoriteSharers forType:type];
		
		[newFavs release];
	}
	
	return favoriteSharers;
}

+ (void)pushOnFavorites:(NSString *)className forType:(SHKShareType)type
{
	NSMutableArray *favs = [[self favoriteSharersForType:type] mutableCopy];
	
	[favs removeObject:className];
	[favs insertObject:className atIndex:0];
	
	while (favs.count > SHK_MAX_FAV_COUNT)
		[favs removeLastObject];
	
	[self setFavorites:favs forType:type];
	
	[favs release];
}

+ (void)setFavorites:(NSArray *)favs forType:(SHKShareType)type
{
	[[NSUserDefaults standardUserDefaults] setObject:favs forKey:[NSString stringWithFormat:@"%@%i", SHK_FAVS_PREFIX_KEY, type]];
}

#pragma mark -

+ (NSDictionary *)getUserExclusions
{
	return [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@Exclusions", SHK_FAVS_PREFIX_KEY]];
}

+ (void)setUserExclusions:(NSDictionary *)exclusions
{
	return [[NSUserDefaults standardUserDefaults] setObject:exclusions forKey:[NSString stringWithFormat:@"%@Exclusions", SHK_FAVS_PREFIX_KEY]];	
}



#pragma mark -
#pragma mark Credentials

// TODO someone with more keychain experience may want to clean this up.  The use of SFHFKeychainUtils may be unnecessary?

+ (NSString *)getAuthValueForKey:(NSString *)key forSharer:(NSString *)sharerId
{
#if TARGET_IPHONE_SIMULATOR
	// Using NSUserDefaults for storage is very insecure, but because Keychain only exists on a device
	// we use NSUserDefaults when running on the simulator to store objects.  This allows you to still test
	// in the simulator.  You should NOT modify in a way that does not use keychain when actually deployed to a device.
	return [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@%@%@",SHK_AUTH_PREFIX,sharerId,key]];
#else
	return [SFHFKeychainUtils passwordForUsername:key serviceName:[NSString stringWithFormat:@"%@%@",SHK_AUTH_PREFIX,sharerId] error:nil];
#endif
}

+ (void)setAuthValue:(NSString *)value forKey:(NSString *)key forSharer:(NSString *)sharerId
{
#if TARGET_IPHONE_SIMULATOR
	// Using NSUserDefaults for storage is very insecure, but because Keychain only exists on a device
	// we use NSUserDefaults when running on the simulator to store objects.  This allows you to still test
	// in the simulator.  You should NOT modify in a way that does not use keychain when actually deployed to a device.
	[[NSUserDefaults standardUserDefaults] setObject:value forKey:[NSString stringWithFormat:@"%@%@%@",SHK_AUTH_PREFIX,sharerId,key]];
#else
	[SFHFKeychainUtils storeUsername:key password:value forServiceName:[NSString stringWithFormat:@"%@%@",SHK_AUTH_PREFIX,sharerId] updateExisting:YES error:nil];
#endif
}

+ (void)removeAuthValueForKey:(NSString *)key forSharer:(NSString *)sharerId
{
#if TARGET_IPHONE_SIMULATOR
	// Using NSUserDefaults for storage is very insecure, but because Keychain only exists on a device
	// we use NSUserDefaults when running on the simulator to store objects.  This allows you to still test
	// in the simulator.  You should NOT modify in a way that does not use keychain when actually deployed to a device.
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"%@%@%@",SHK_AUTH_PREFIX,sharerId,key]];
#else
	[SFHFKeychainUtils removePasswordForUsername:key serviceName:[NSString stringWithFormat:@"%@%@",SHK_AUTH_PREFIX,sharerId] error:nil];
#endif
}

+ (void)logoutOfAll
{
	NSArray *sharers = [[SHK sharersDictionary] objectForKey:@"services"];
	for (NSString *sharerId in sharers)
		[self logoutOfService:sharerId];
}

+ (void)logoutOfService:(NSString *)sharerId
{	
	[NSClassFromString(sharerId) logout];	
}


#pragma mark -

static NSDictionary *sharersDictionary = nil;

+ (NSDictionary *)sharersDictionary
{
	if (sharersDictionary == nil) {
		sharersDictionary = [[NSDictionary dictionaryWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"SHKSharers.plist"]] retain];
    	if (!sharersDictionary) {
        	NSArray* actions = [NSArray arrayWithObjects:@"SHKPhotoAlbum", @"SHKCopy", @"SHKMail", @"SHKSafari", @"SHKTextMessage", nil];
        	NSMutableArray* services = [NSMutableArray arrayWithCapacity:4];
            if (SHKConfigValueForKey(SHKConfigEvernoteSecretKey)) {
            	[services addObject:@"SHKEvernote"];
            }
            if (SHKConfigValueForKey(SHKConfigTwitterSecret)) {
            	[services addObject:@"SHKTwitter"];
            }
            if (SHKConfigValueForKey(SHKConfigDeliciousSecretKey)) {
            	[services addObject:@"SHKDelicious"];
            }
            if (SHKConfigValueForKey(SHKConfigFacebookSecret)) {
            	[services addObject:@"SHKFacebook"];
            }
            if (SHKConfigValueForKey(SHKConfigReadItLaterKey)) {
            	[services addObject:@"SHKReadItLater"];
            }
            sharersDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:
                                 actions, @"actions", services, @"services", nil];
        }
    }
	
	return sharersDictionary;
}


#pragma mark -
#pragma mark Offline Support

+ (NSString *)offlineQueuePath
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSArray *paths = NSSearchPathForDirectoriesInDomains( NSCachesDirectory, NSUserDomainMask, YES);
	NSString *cache = [paths objectAtIndex:0];
	NSString *SHKPath = [cache stringByAppendingPathComponent:@"SHK"];
	
	// Check if the path exists, otherwise create it
	if (![fileManager fileExistsAtPath:SHKPath]) 
		[fileManager createDirectoryAtPath:SHKPath withIntermediateDirectories:YES attributes:nil error:nil];
	
	return SHKPath;
}

+ (NSString *)offlineQueueListPath
{
	return [[self offlineQueuePath] stringByAppendingPathComponent:@"SHKOfflineQueue.plist"];
}

+ (NSMutableArray *)getOfflineQueueList
{
	return [[[NSArray arrayWithContentsOfFile:[self offlineQueueListPath]] mutableCopy] autorelease];
}

+ (void)saveOfflineQueueList:(NSMutableArray *)queueList
{
	[queueList writeToFile:[self offlineQueueListPath] atomically:YES]; // TODO - should do this off of the main thread	
}

+ (BOOL)addToOfflineQueue:(SHKItem *)item forSharer:(NSString *)sharerId
{
	// Generate a unique id for the share to use when saving associated files
	NSString *uid = [NSString stringWithFormat:@"%@-%i-%i-%i", sharerId, item.shareType, [[NSDate date] timeIntervalSince1970], arc4random()];
	
	
	// store image in cache
	if (item.shareType == SHKShareTypeImage && item.image)
		[UIImageJPEGRepresentation(item.image, 1) writeToFile:[[self offlineQueuePath] stringByAppendingPathComponent:uid] atomically:YES];
	
	// store file in cache
	else if (item.shareType == SHKShareTypeFile)
		[item.data writeToFile:[[self offlineQueuePath] stringByAppendingPathComponent:uid] atomically:YES];
	
	// Open queue list
	NSMutableArray *queueList = [self getOfflineQueueList];
	if (queueList == nil)
		queueList = [NSMutableArray arrayWithCapacity:0];
	
	// Add to queue list
	[queueList addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						  [item dictionaryRepresentation],@"item",
						  sharerId,@"sharer",
						  uid,@"uid",
						  nil]];
	
	[self saveOfflineQueueList:queueList];
	
	return YES;
}

+ (void)flushOfflineQueue
{
	// TODO - if an item fails, after all items are shared, it should present a summary view and allow them to see which items failed/succeeded
	
	// Check for a connection
	if (![self connected])
		return;
	
	// Open list
	NSMutableArray *queueList = [self getOfflineQueueList];
	
	// Run through each item in the quietly in the background
	// TODO - Is this the best behavior?  Instead, should the user confirm sending these again?  Maybe only if it has been X days since they were saved?
	//		- want to avoid a user being suprised by a post to Twitter if that happens long after they forgot they even shared it.
	if (queueList != nil)
	{
		SHK *helper = [self currentHelper];
		
		if (helper.offlineQueue == nil)
			helper.offlineQueue = [[NSOperationQueue alloc] init];		
	
		SHKItem *item;
		NSString *sharerId, *uid;
		
		for (NSDictionary *entry in queueList)
		{
			item = [SHKItem itemFromDictionary:[entry objectForKey:@"item"]];
			sharerId = [entry objectForKey:@"sharer"];
			uid = [entry objectForKey:@"uid"];
			
			if (item != nil && sharerId != nil)
				[helper.offlineQueue addOperation:[[[SHKOfflineSharer alloc] initWithItem:item forSharer:sharerId uid:uid] autorelease]];
		}
		
		// Remove offline queue - TODO: only do this if everything was successful?
		[[NSFileManager defaultManager] removeItemAtPath:[self offlineQueueListPath] error:nil];

	}
}

#pragma mark -

+ (NSError *)error:(NSString *)description, ...
{
	va_list args;
    va_start(args, description);
    NSString *string = [[[NSString alloc] initWithFormat:description arguments:args] autorelease];
    va_end(args);
	
	return [NSError errorWithDomain:@"sharekit" code:1 userInfo:[NSDictionary dictionaryWithObject:string forKey:NSLocalizedDescriptionKey]];
}

#pragma mark -
#pragma mark Network

+ (BOOL)connected 
{
	//return NO; // force for offline testing
	SHKReachability *hostReach = [SHKReachability reachabilityForInternetConnection];	
	NetworkStatus netStatus = [hostReach currentReachabilityStatus];	
	return !(netStatus == NotReachable);
}

@end


NSString * SHKStringOrBlank(NSString * value)
{
	return value == nil ? @"" : value;
}

NSString * SHKEncode(NSString * value)
{
	if (value == nil)
		return @"";
	
	NSString *string = value;
	
	string = [string stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
	string = [string stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	string = [string stringByReplacingOccurrencesOfString:@"&" withString:@"%26"];
	
	return string;	
}

NSString * SHKEncodeURL(NSURL * value)
{
	if (value == nil)
		return @"";
	
	NSString *result = (NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                           (CFStringRef)value.absoluteString,
                                                                           NULL,
																		   CFSTR("!*'();:@&=+$,/?%#[]"),
                                                                           kCFStringEncodingUTF8);
    [result autorelease];
	return result;
}

void SHKSwizzle(Class c, SEL orig, SEL newClassName)
{
    Method origMethod = class_getInstanceMethod(c, orig);
    Method newMethod = class_getInstanceMethod(c, newClassName);
    if(class_addMethod(c, orig, method_getImplementation(newMethod), method_getTypeEncoding(newMethod)))
		class_replaceMethod(c, newClassName, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
	else
		method_exchangeImplementations(origMethod, newMethod);
}

NSString* SHKLocalizedString(NSString* key, ...) 
{
    static NSBundle* resourceBundle = nil;
    if (!resourceBundle) {
    	resourceBundle = [[NSBundle alloc] initWithPath:[[NSBundle mainBundle] pathForResource:@"ShareKitResources" ofType:@"bundle"]];
    }
	// Localize the format
	NSString *localizedStringFormat = NSLocalizedStringFromTableInBundle(key, nil, resourceBundle, key);
	
	va_list args;
    va_start(args, key);
    NSString *string = [[[NSString alloc] initWithFormat:localizedStringFormat arguments:args] autorelease];
    va_end(args);
	
	return string;
}
