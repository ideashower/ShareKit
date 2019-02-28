/*
 * Copyright 2009 Facebook
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *    http://www.apache.org/licenses/LICENSE-2.0

 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
*/

#import "FBDialog.h"
#import "FBSession.h"

///////////////////////////////////////////////////////////////////////////////////////////////////
// global

static NSString* kDefaultTitle = @"Connect to Facebook";
static NSString* kStringBoundary = @"3i2ndDfv2rTHiSisAbouNdArYfORhtTPEefj3q2f";

static CGFloat kFacebookBlue[4] = {0.42578125, 0.515625, 0.703125, 1.0};
static CGFloat kBorderGray[4] = {0.3, 0.3, 0.3, 0.8};
static CGFloat kBorderBlack[4] = {0.3, 0.3, 0.3, 1};
static CGFloat kBorderBlue[4] = {0.23, 0.35, 0.6, 1.0};

static CGFloat kTransitionDuration = 0.3;

static CGFloat kTitleMarginX = 8;
static CGFloat kTitleMarginY = 4;
static CGFloat kPadding = 10;
static CGFloat kBorderWidth = 10;

///////////////////////////////////////////////////////////////////////////////////////////////////

@implementation FBDialog

@synthesize session = _session, delegate = _delegate;

///////////////////////////////////////////////////////////////////////////////////////////////////
// private

- (void)addRoundedRectToPath:(CGContextRef)context rect:(CGRect)rect radius:(float)radius {
  CGContextBeginPath(context);
  CGContextSaveGState(context);

  if (radius == 0) {
    CGContextTranslateCTM(context, CGRectGetMinX(rect), CGRectGetMinY(rect));
    CGContextAddRect(context, rect);
  } else {
    rect = CGRectOffset(CGRectInset(rect, 0.5, 0.5), 0.5, 0.5);
    CGContextTranslateCTM(context, CGRectGetMinX(rect)-0.5, CGRectGetMinY(rect)-0.5);
    CGContextScaleCTM(context, radius, radius);
    float fw = CGRectGetWidth(rect) / radius;
    float fh = CGRectGetHeight(rect) / radius;
    
    CGContextMoveToPoint(context, fw, fh/2);
    CGContextAddArcToPoint(context, fw, fh, fw/2, fh, 1);
    CGContextAddArcToPoint(context, 0, fh, 0, fh/2, 1);
    CGContextAddArcToPoint(context, 0, 0, fw/2, 0, 1);
    CGContextAddArcToPoint(context, fw, 0, fw, fh/2, 1);
  }

  CGContextClosePath(context);
  CGContextRestoreGState(context);
}

- (void)drawRect:(CGRect)rect fill:(const CGFloat*)fillColors radius:(CGFloat)radius {
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();

  if (fillColors) {
    CGContextSaveGState(context);
    CGContextSetFillColor(context, fillColors);
    if (radius) {
      [self addRoundedRectToPath:context rect:rect radius:radius];
      CGContextFillPath(context);
    } else {
      CGContextFillRect(context, rect);
    }
    CGContextRestoreGState(context);
  }
  
  CGColorSpaceRelease(space);
}

- (void)strokeLines:(CGRect)rect stroke:(const CGFloat*)strokeColor {
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();

  CGContextSaveGState(context);
  CGContextSetStrokeColorSpace(context, space);
  CGContextSetStrokeColor(context, strokeColor);
  CGContextSetLineWidth(context, 1.0);
    
  {
    CGPoint points[] = {rect.origin.x+0.5, rect.origin.y-0.5,
      rect.origin.x+rect.size.width, rect.origin.y-0.5};
    CGContextStrokeLineSegments(context, points, 2);
  }
  {
    CGPoint points[] = {rect.origin.x+0.5, rect.origin.y+rect.size.height-0.5,
      rect.origin.x+rect.size.width-0.5, rect.origin.y+rect.size.height-0.5};
    CGContextStrokeLineSegments(context, points, 2);
  }
  {
    CGPoint points[] = {rect.origin.x+rect.size.width-0.5, rect.origin.y,
      rect.origin.x+rect.size.width-0.5, rect.origin.y+rect.size.height};
    CGContextStrokeLineSegments(context, points, 2);
  }
  {
    CGPoint points[] = {rect.origin.x+0.5, rect.origin.y,
      rect.origin.x+0.5, rect.origin.y+rect.size.height};
    CGContextStrokeLineSegments(context, points, 2);
  }
  
  CGContextRestoreGState(context);

  CGColorSpaceRelease(space);
}

- (BOOL)shouldRotateToOrientation:(UIDeviceOrientation)orientation {
  if (orientation == _orientation) {
    return NO;
  } else {
    return orientation == UIDeviceOrientationLandscapeLeft
      || orientation == UIDeviceOrientationLandscapeRight
      || orientation == UIDeviceOrientationPortrait
      || orientation == UIDeviceOrientationPortraitUpsideDown;
  }
}

- (CGAffineTransform)transformForOrientation {
  UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
  if (orientation == UIInterfaceOrientationLandscapeLeft) {
    return CGAffineTransformMakeRotation(M_PI*1.5);
  } else if (orientation == UIInterfaceOrientationLandscapeRight) {
    return CGAffineTransformMakeRotation(M_PI/2);
  } else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
    return CGAffineTransformMakeRotation(-M_PI);
  } else {
    return CGAffineTransformIdentity;
  }
}

- (void)sizeToFitOrientation:(BOOL)transform {
  if (transform) {
    self.transform = CGAffineTransformIdentity;
  }

  CGRect frame = [UIScreen mainScreen].applicationFrame;
  CGPoint center = CGPointMake(
    frame.origin.x + ceil(frame.size.width/2),
    frame.origin.y + ceil(frame.size.height/2));

  CGFloat scale_factor = 1.0f;
  if (FBIsDeviceIPad()) {
    // On the iPad the dialog's dimensions should only be 60% of the screen's
    scale_factor = 0.6f;
  }

  CGFloat width = floor(scale_factor * frame.size.width) - kPadding * 2;
  CGFloat height = floor(scale_factor * frame.size.height) - kPadding * 2;

  _orientation = [UIApplication sharedApplication].statusBarOrientation;
  if (UIInterfaceOrientationIsLandscape(_orientation)) {
    self.frame = CGRectMake(kPadding, kPadding, height, width);
  } else {
    self.frame = CGRectMake(kPadding, kPadding, width, height);
  }
  self.center = center;

  if (transform) {
    self.transform = [self transformForOrientation];
  }
}

- (void)updateWebOrientation {
  UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
  if (UIInterfaceOrientationIsLandscape(orientation)) {
    [_webView stringByEvaluatingJavaScriptFromString:
      @"document.body.setAttribute('orientation', 90);"];
  } else {
    [_webView stringByEvaluatingJavaScriptFromString:
      @"document.body.removeAttribute('orientation');"];
  }
}

- (void)bounce1AnimationStopped {
  [UIView beginAnimations:nil context:nil];
  [UIView setAnimationDuration:kTransitionDuration/2];
  [UIView setAnimationDelegate:self];
  [UIView setAnimationDidStopSelector:@selector(bounce2AnimationStopped)];
  self.transform = CGAffineTransformScale([self transformForOrientation], 0.9, 0.9);
  [UIView commitAnimations];
}

- (void)bounce2AnimationStopped {
  [UIView beginAnimations:nil context:nil];
  [UIView setAnimationDuration:kTransitionDuration/2];
  self.transform = [self transformForOrientation];
  [UIView commitAnimations];
}

- (NSURL*)generateURL:(NSString*)baseURL params:(NSDictionary*)params {
  if (params) {
    NSMutableArray* pairs = [NSMutableArray array];
    for (NSString* key in params.keyEnumerator) {
      NSString* value = [params objectForKey:key];
      NSString* val = [value stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
      NSString* pair = [NSString stringWithFormat:@"%@=%@", key, val];
      [pairs addObject:pair];
    }
      
    NSString* query = [pairs componentsJoinedByString:@"&"];
    NSString* url = [NSString stringWithFormat:@"%@?%@", baseURL, query];
    return [NSURL URLWithString:url];
  } else {
    return [NSURL URLWithString:baseURL];
  }
}

- (NSMutableData*)generatePostBody:(NSDictionary*)params {
  if (!params) {
    return nil;
  }
  
  NSMutableData* body = [NSMutableData data];
  NSString* endLine = [NSString stringWithFormat:@"\r\n--%@\r\n", kStringBoundary];

  [body appendData:[[NSString stringWithFormat:@"--%@\r\n", kStringBoundary]
    dataUsingEncoding:NSUTF8StringEncoding]];
  
  for (id key in [params keyEnumerator]) {
    [body appendData:[[NSString
      stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key]
        dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[params valueForKey:key] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[endLine dataUsingEncoding:NSUTF8StringEncoding]];        
  }

  return body;
}

- (void)addObservers {
  [[NSNotificationCenter defaultCenter] addObserver:self
    selector:@selector(deviceOrientationDidChange:)
    name:@"UIDeviceOrientationDidChangeNotification" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
    selector:@selector(keyboardWillShow:) name:@"UIKeyboardWillShowNotification" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
    selector:@selector(keyboardWillHide:) name:@"UIKeyboardWillHideNotification" object:nil];
}

- (void)removeObservers {
  [[NSNotificationCenter defaultCenter] removeObserver:self
    name:@"UIDeviceOrientationDidChangeNotification" object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self
    name:@"UIKeyboardWillShowNotification" object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self
    name:@"UIKeyboardWillHideNotification" object:nil];
}

- (void)postDismissCleanup {
  [self removeObservers];
  [self removeFromSuperview];
}

- (void)dismiss:(BOOL)animated {
  [self dialogWillDisappear];

  [_loadingURL release];
  _loadingURL = nil;
  
  if (animated) {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:kTransitionDuration];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(postDismissCleanup)];
    self.alpha = 0;
    [UIView commitAnimations];
  } else {
    [self postDismissCleanup];
  }
}

- (void)cancel {
  [self dismissWithSuccess:NO animated:YES];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// NSObject

- (id)init {
  return [self initWithSession:[FBSession session]];
}

#pragma GCC diagnostic ignored "-Wdeprecated-declarations"

- (id)initWithSession:(FBSession*)session {
  if (self = [super initWithFrame:CGRectZero]) {
    _delegate = nil;
    _session = [session retain];
    _loadingURL = nil;
    _orientation = UIDeviceOrientationUnknown;
    _showingKeyboard = NO;
    
    self.backgroundColor = [UIColor clearColor];
    self.autoresizesSubviews = YES;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.contentMode = UIViewContentModeRedraw;
    
    UIImage* iconImage = [UIImage imageNamed:@"ShareKitResources.bundle/FBConnect.bundle/images/fbicon.png"];
    UIImage* closeImage = [UIImage imageNamed:@"ShareKitResources.bundle/FBConnect.bundle/images/close.png"];
    
    _iconView = [[UIImageView alloc] initWithImage:iconImage];
    [self addSubview:_iconView];
    
    UIColor* color = [UIColor colorWithRed:167.0/255 green:184.0/255 blue:216.0/255 alpha:1];
    _closeButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
    [_closeButton setImage:closeImage forState:UIControlStateNormal];
    [_closeButton setTitleColor:color forState:UIControlStateNormal];
    [_closeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [_closeButton addTarget:self action:@selector(cancel)
      forControlEvents:UIControlEventTouchUpInside];
  	if ([_closeButton respondsToSelector:@selector(titleLabel)]) {
		_closeButton.titleLabel.font = [UIFont boldSystemFontOfSize:12];
  	} else { // This triggers a deprecation warning but at least it will work on OS 2.x
		_closeButton.font = [UIFont boldSystemFontOfSize:12];
  	}
	_closeButton.showsTouchWhenHighlighted = YES;
    _closeButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin
      | UIViewAutoresizingFlexibleBottomMargin;
    [self addSubview:_closeButton];
    
    CGFloat titleLabelFontSize = (FBIsDeviceIPad() ? 18 : 14);
    _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _titleLabel.text = kDefaultTitle;
    _titleLabel.backgroundColor = [UIColor clearColor];
    _titleLabel.textColor = [UIColor whiteColor];
    _titleLabel.font = [UIFont boldSystemFontOfSize:titleLabelFontSize];
    _titleLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin
      | UIViewAutoresizingFlexibleBottomMargin;
    [self addSubview:_titleLabel];
        
    _webView = [[UIWebView alloc] initWithFrame:CGRectZero];
    _webView.delegate = self;
    _webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:_webView];

    _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:
      UIActivityIndicatorViewStyleWhiteLarge];
    _spinner.autoresizingMask =
      UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin
      | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [self addSubview:_spinner];
  }
  return self;
}

- (void)dealloc {
  _webView.delegate = nil;
  [_webView release];
  [_spinner release];
  [_titleLabel release];
  [_iconView release];
  [_closeButton release];
  [_loadingURL release];
  [_session release];
  [super dealloc];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// UIView

- (void)drawRect:(CGRect)rect {
  CGRect grayRect = CGRectOffset(rect, -0.5, -0.5);
  [self drawRect:grayRect fill:kBorderGray radius:10];

  CGRect headerRect = CGRectMake(
    ceil(rect.origin.x + kBorderWidth), ceil(rect.origin.y + kBorderWidth),
    rect.size.width - kBorderWidth*2, _titleLabel.frame.size.height);
  [self drawRect:headerRect fill:kFacebookBlue radius:0];
  [self strokeLines:headerRect stroke:kBorderBlue];

  CGRect webRect = CGRectMake(
    ceil(rect.origin.x + kBorderWidth), headerRect.origin.y + headerRect.size.height,
    rect.size.width - kBorderWidth*2, _webView.frame.size.height+1);
  [self strokeLines:webRect stroke:kBorderBlack];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request
    navigationType:(UIWebViewNavigationType)navigationType {
  NSURL* url = request.URL;
  if ([url.scheme isEqualToString:@"fbconnect"]) {
    if ([url.resourceSpecifier isEqualToString:@"cancel"]) {
      [self dismissWithSuccess:NO animated:YES];
    } else {
      [self dialogDidSucceed:url];
    }
    return NO;
  } else if ([_loadingURL isEqual:url]) {
    return YES;
  } else if (navigationType == UIWebViewNavigationTypeLinkClicked) {
    if ([_delegate respondsToSelector:@selector(dialog:shouldOpenURLInExternalBrowser:)]) {
      if (![_delegate dialog:self shouldOpenURLInExternalBrowser:url]) {
        return NO;
      }
    }
    
    [[UIApplication sharedApplication] openURL:request.URL];
    return NO;
  } else {
    return YES;
  }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
  [_spinner stopAnimating];
  _spinner.hidden = YES;
  
  self.title = [_webView stringByEvaluatingJavaScriptFromString:@"document.title"];
  [self updateWebOrientation];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
  // 102 == WebKitErrorFrameLoadInterruptedByPolicyChange
  if (!([error.domain isEqualToString:@"WebKitErrorDomain"] && error.code == 102)) {
    [self dismissWithError:error animated:YES];
  }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// UIDeviceOrientationDidChangeNotification

- (void)deviceOrientationDidChange:(void*)object {
  UIDeviceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
  if (!_showingKeyboard && [self shouldRotateToOrientation:orientation]) {
    [self updateWebOrientation];

    CGFloat duration = [UIApplication sharedApplication].statusBarOrientationAnimationDuration;
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:duration];
    [self sizeToFitOrientation:YES];
    [UIView commitAnimations];
  }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// UIKeyboardNotifications

- (void)keyboardWillShow:(NSNotification*)notification {
  if (FBIsDeviceIPad()) {
    // On the iPad the screen is large enough that we don't need to 
    // resize the dialog to accomodate the keyboard popping up
    return;
  }

  UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
  if (UIInterfaceOrientationIsLandscape(orientation)) {
    _webView.frame = CGRectInset(_webView.frame,
      -(kPadding + kBorderWidth),
      -(kPadding + kBorderWidth) - _titleLabel.frame.size.height);
  }

  _showingKeyboard = YES;
}

- (void)keyboardWillHide:(NSNotification*)notification {
  if (FBIsDeviceIPad()) {
    return;
  }
  UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
  if (UIInterfaceOrientationIsLandscape(orientation)) {
    _webView.frame = CGRectInset(_webView.frame,
      kPadding + kBorderWidth,
      kPadding + kBorderWidth + _titleLabel.frame.size.height);
  }

  _showingKeyboard = NO;
}
 
///////////////////////////////////////////////////////////////////////////////////////////////////
// public

- (NSString*)title {
  return _titleLabel.text;
}

- (void)setTitle:(NSString*)title {
  _titleLabel.text = title;
}

- (void)show {
  [self load];
  [self sizeToFitOrientation:NO];

  CGFloat innerWidth = self.frame.size.width - (kBorderWidth+1)*2;  
  [_iconView sizeToFit];
  [_titleLabel sizeToFit];
  [_closeButton sizeToFit];

  _titleLabel.frame = CGRectMake(
    kBorderWidth + kTitleMarginX + _iconView.frame.size.width + kTitleMarginX,
    kBorderWidth,
    innerWidth - (_titleLabel.frame.size.height + _iconView.frame.size.width + kTitleMarginX*2),
    _titleLabel.frame.size.height + kTitleMarginY*2);
  
  _iconView.frame = CGRectMake(
    kBorderWidth + kTitleMarginX,
    kBorderWidth + floor(_titleLabel.frame.size.height/2 - _iconView.frame.size.height/2),
    _iconView.frame.size.width,
    _iconView.frame.size.height);

  _closeButton.frame = CGRectMake(
    self.frame.size.width - (_titleLabel.frame.size.height + kBorderWidth),
    kBorderWidth,
    _titleLabel.frame.size.height,
    _titleLabel.frame.size.height);
  
  _webView.frame = CGRectMake(
    kBorderWidth+1,
    kBorderWidth + _titleLabel.frame.size.height,
    innerWidth,
    self.frame.size.height - (_titleLabel.frame.size.height + 1 + kBorderWidth*2));

  [_spinner sizeToFit];
  [_spinner startAnimating];
  _spinner.center = _webView.center;

  UIWindow* window = [UIApplication sharedApplication].keyWindow;
  if (!window) {
    window = [[UIApplication sharedApplication].windows objectAtIndex:0];
  }
  [window addSubview:self];

  [self dialogWillAppear];
    
  self.transform = CGAffineTransformScale([self transformForOrientation], 0.001, 0.001);
  [UIView beginAnimations:nil context:nil];
  [UIView setAnimationDuration:kTransitionDuration/1.5];
  [UIView setAnimationDelegate:self];
  [UIView setAnimationDidStopSelector:@selector(bounce1AnimationStopped)];
  self.transform = CGAffineTransformScale([self transformForOrientation], 1.1, 1.1);
  [UIView commitAnimations];

  [self addObservers];
}

- (void)dismissWithSuccess:(BOOL)success animated:(BOOL)animated {
  if (success) {
    if ([_delegate respondsToSelector:@selector(dialogDidSucceed:)]) {
      [_delegate dialogDidSucceed:self];
    }
  } else {
    if ([_delegate respondsToSelector:@selector(dialogDidCancel:)]) {
      [_delegate dialogDidCancel:self];
    }
  }

  [self dismiss:animated];
}

- (void)dismissWithError:(NSError*)error animated:(BOOL)animated {
  if ([_delegate respondsToSelector:@selector(dialog:didFailWithError:)]) {
    [_delegate dialog:self didFailWithError:error];
  }

  [self dismiss:animated];
}

- (void)load {
  // Intended for subclasses to override
}

- (void)loadURL:(NSString*)url method:(NSString*)method get:(NSDictionary*)getParams
        post:(NSDictionary*)postParams {
  // This "test cookie" is required by login.php, or it complains that you need to enable JavaScript
  NSHTTPCookieStorage* cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
  NSHTTPCookie* testCookie = [NSHTTPCookie cookieWithProperties:
    [NSDictionary dictionaryWithObjectsAndKeys:
      @"1", NSHTTPCookieValue,
      @"test_cookie", NSHTTPCookieName,
      @".facebook.com", NSHTTPCookieDomain,
      @"/", NSHTTPCookiePath,
      nil]];
  [cookies setCookie:testCookie];

  [_loadingURL release];
  _loadingURL = [[self generateURL:url params:getParams] retain];
  NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:_loadingURL];
  
  if (method) {
    [request setHTTPMethod:method];

    if ([[method uppercaseString] isEqualToString:@"POST"]) {
      NSString* contentType = [NSString
        stringWithFormat:@"multipart/form-data; boundary=%@", kStringBoundary];
      [request setValue:contentType forHTTPHeaderField:@"Content-Type"];

      NSData* body = [self generatePostBody:postParams];
      if (body) {
        [request setHTTPBody:body];
      }
    }
  }

  [_webView loadRequest:request];
}

- (void)dialogWillAppear {
}

- (void)dialogWillDisappear {
}

- (void)dialogDidSucceed:(NSURL*)url {
  [self dismissWithSuccess:YES animated:YES];
}

@end
