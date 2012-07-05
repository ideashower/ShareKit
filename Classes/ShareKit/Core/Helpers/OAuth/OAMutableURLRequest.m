//
// OAMutableURLRequest.m
// OAuthConsumer
//
// Created by Jon Crosby on 10/19/07.
// Copyright 2007 Kaboomerang LLC. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


#import "OAMutableURLRequest.h"
#import "SHKConfig.h"


@interface OAMutableURLRequest (Private)
- (void)_generateTimestamp;
- (void)_generateNonce;
- (NSString *)_signatureBaseString;
@end

@implementation OAMutableURLRequest
@synthesize signature, nonce;
@synthesize callback;
#pragma mark init

- (id)initWithURL:(NSURL *)aUrl
		 consumer:(OAConsumer *)aConsumer
			token:(OAToken *)aToken
            realm:(NSString *)aRealm
signatureProvider:(id<OASignatureProviding, NSObject>)aProvider
{
	
	return [self initWithURL:aUrl consumer:aConsumer token:aToken realm:aRealm signatureProvider:aProvider nonce:nil timestamp:nil];
}

// Setting a timestamp and nonce to known
// values can be helpful for testing
- (id)initWithURL:(NSURL *)aUrl
		 consumer:(OAConsumer *)aConsumer
			token:(OAToken *)aToken
            realm:(NSString *)aRealm
signatureProvider:(id<OASignatureProviding, NSObject>)aProvider
            nonce:(NSString *)aNonce
        timestamp:(NSString *)aTimestamp
{
	if ((self = [super initWithURL:aUrl
					  cachePolicy:NSURLRequestReloadIgnoringCacheData
				  timeoutInterval:10.0]))
	{
		consumer = [aConsumer retain];
		
		// empty token for Unauthorized Request Token transaction
		if (aToken == nil)
			token = [[OAToken alloc] init];
		else
			token = [aToken retain];
		
		if (aRealm == nil)
			realm = [[NSString alloc] initWithString:@""];
		else
			realm = [aRealm retain];
		
		
		self.callback = nil;
		
		// default to HMAC-SHA1
		if (aProvider == nil)
			signatureProvider = [[OAHMAC_SHA1SignatureProvider alloc] init];
		else
			signatureProvider = [aProvider retain];
		
		
		if(timestamp)
			timestamp = [aTimestamp retain];
		else
			[self _generateTimestamp];

		if(nonce)
			nonce = [aNonce retain];
		else
			[self _generateNonce];
		
		didPrepare = NO;
	}
    return self;
}

- (void)dealloc
{
	[consumer release];
	[token release];
	
	self.callback = nil;
	
	[realm release];
	[signatureProvider release];
	[timestamp release];
	[nonce release];
	[extraOAuthParameters release];
	[super dealloc];
}

#pragma mark -
#pragma mark Public

- (void)setOAuthParameterName:(NSString*)parameterName withValue:(NSString*)parameterValue
{
	assert(parameterName && parameterValue);
	
	if (extraOAuthParameters == nil) {
		extraOAuthParameters = [NSMutableDictionary new];
	}
	
	[extraOAuthParameters setObject:parameterValue forKey:parameterName];
}

- (void)prepare
{
	if (didPrepare) {
		return;
	}
	
	didPrepare = YES;
    
	// sign
	// Secrets must be urlencoded before concatenated with '&'
	// TODO: if later RSA-SHA1 support is added then a little code redesign is needed
	
    signature = [signatureProvider signClearText:[self _signatureBaseString]
                                      withSecret:[NSString stringWithFormat:@"%@&%@",
												  [consumer.secret URLEncodedString],
                                                  [token.secret URLEncodedString]]];
    
    // set OAuth headers
    NSString *oauthToken = nil;
    if (!([token.key isEqualToString:@""]))
        oauthToken = [NSString stringWithFormat:@"oauth_token=\"%@\"", [token.key URLEncodedString]];
	
	NSMutableString *extraParameters = [NSMutableString string];
	
	// Adding the optional parameters in sorted order isn't required by the OAuth spec, but it makes it possible to hard-code expected values in the unit tests
	for(NSString *parameterName in [[extraOAuthParameters allKeys] sortedArrayUsingSelector:@selector(compare:)])
	{
		[extraParameters appendFormat:@", %@=\"%@\"", [parameterName URLEncodedString], [[extraOAuthParameters objectForKey:parameterName] URLEncodedString] ];
	}

	NSMutableArray *parameters = [NSMutableArray array];
	
	[parameters addObject:[NSString stringWithFormat:@"realm=\"%@\"", [realm URLEncodedString]]];
    
    if ([callback length] > 0)
        [parameters addObject:[NSString stringWithFormat:@"oauth_callback=\"%@\"", [callback URLEncodedString]]];

	if(oauthToken)
		[parameters addObject:oauthToken];

	[parameters addObject:[NSString stringWithFormat:@"oauth_consumer_key=\"%@\"", [consumer.key URLEncodedString]]];
	
	[parameters addObject:[NSString stringWithFormat:@"oauth_signature_method=\"%@\"", [[signatureProvider name] URLEncodedString]]];
	[parameters addObject:[NSString stringWithFormat:@"oauth_signature=\"%@\"", [signature URLEncodedString]]];
	[parameters addObject:[NSString stringWithFormat:@"oauth_timestamp=\"%@\"", timestamp]];
	[parameters addObject:[NSString stringWithFormat:@"oauth_nonce=\"%@\"", nonce]];
	[parameters	addObject:@"oauth_version=\"1.0\""];	
	
	NSString *oauthHeader = [NSString stringWithFormat:@"OAuth %@%@", [parameters componentsJoinedByString:@", "], extraParameters];
    [self setValue:oauthHeader forHTTPHeaderField:@"Authorization"];

	SHKLog(@"Auth Header: %@", oauthHeader);

}

#pragma mark -
#pragma mark Private

- (void)_generateTimestamp
{
    timestamp = [[NSString stringWithFormat:@"%d", time(NULL)] retain];
}

- (void)_generateNonce
{
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    NSMakeCollectable(theUUID);
    nonce = (NSString *)string;
}

- (NSString *)_signatureBaseString
{
    // OAuth Spec, Section 9.1.1 "Normalize Request Parameters"
    // build a sorted array of both request parameters and OAuth header parameters
    NSMutableArray *parameterPairs = [NSMutableArray arrayWithCapacity:(6)]; // 6 being the number of OAuth params in the Signature Base String
    
	[parameterPairs addObject:[[OARequestParameter requestParameterWithName:@"oauth_consumer_key" value:consumer.key] URLEncodedNameValuePair]];
	[parameterPairs addObject:[[OARequestParameter requestParameterWithName:@"oauth_signature_method" value:[signatureProvider name]] URLEncodedNameValuePair]];
	[parameterPairs addObject:[[OARequestParameter requestParameterWithName:@"oauth_timestamp" value:timestamp] URLEncodedNameValuePair]];
	[parameterPairs addObject:[[OARequestParameter requestParameterWithName:@"oauth_nonce" value:nonce] URLEncodedNameValuePair]];
	[parameterPairs addObject:[[OARequestParameter requestParameterWithName:@"oauth_version" value:@"1.0"] URLEncodedNameValuePair]];
    
	
    if ([callback length] > 0)
    {
		[parameterPairs addObject:[[OARequestParameter requestParameterWithName:@"oauth_callback" value:callback] URLEncodedNameValuePair]];
    }		
	
    if (![token.key isEqualToString:@""]) {
        [parameterPairs addObject:[[OARequestParameter requestParameterWithName:@"oauth_token" value:token.key] URLEncodedNameValuePair]];
    }
    
	
	for(NSString *parameterName in [[extraOAuthParameters allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
		[parameterPairs addObject:[[OARequestParameter requestParameterWithName:[parameterName URLEncodedString] value: [[extraOAuthParameters objectForKey:parameterName] URLEncodedString]] URLEncodedNameValuePair]];
	}
	
	if (![[self valueForHTTPHeaderField:@"Content-Type"] hasPrefix:@"multipart/form-data"]) {
		for (OARequestParameter *param in [self parameters]) {
			[parameterPairs addObject:[param URLEncodedNameValuePair]];
		}
	}
    
    NSArray *sortedPairs = [parameterPairs sortedArrayUsingSelector:@selector(compare:)];
    NSString *normalizedRequestParameters = [sortedPairs componentsJoinedByString:@"&"];
    
    // OAuth Spec, Section 9.1.2 "Concatenate Request Elements"
    NSString *ret = [NSString stringWithFormat:@"%@&%@&%@",
					 [self HTTPMethod],
					 [[[self URL] URLStringWithoutQuery] URLEncodedString],
					 [normalizedRequestParameters URLEncodedString]];
	
	SHKLog(@"OAMutableURLRequest Parameter Pairs:  %@", normalizedRequestParameters);
	
	return ret;
}

@end
