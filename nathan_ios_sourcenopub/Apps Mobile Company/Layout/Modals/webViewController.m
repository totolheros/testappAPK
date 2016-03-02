//
//  webViewController.m
//  Siberian
//
//  Created by The Tiger App Creator Team on 24/02/14.
//
//

#import "webViewController.h"

@interface webViewController ()

@end

@implementation webViewController

@synthesize webViewUrl;
@synthesize wv, line, toolbar, loader;
@synthesize btnClose, btnBack, btnForth, btnStop, btnRefresh;
@synthesize delegate;

- (void)viewDidLoad {
    
    NSDictionary *headerColors = [common getColors:@"header"];
    UIColor *headerColor = [headerColors objectForKey:@"color"];
    UIColor *headerBackgroundColor = [headerColors objectForKey:@"backgroundColor"];
    UIColor *tintColor = [UIColor blackColor];
    
    NSLog(@"headerColor : %@", headerColor);
    NSLog(@"headerBackgroundColor : %@", headerBackgroundColor);
    [line setBackgroundColor:headerColor];
    if(isAtLeastiOS7()) {
        [toolbar setTintColor:headerColor];
        [toolbar setBarTintColor:headerBackgroundColor];
    } else {
        [[UINavigationBar appearance] setTintColor:tintColor];
    }
    
    [super viewDidLoad];
    
    // Créé et affiche le loader
    CGRect frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height);
    loader = [[loaderView alloc] initWithFrame:frame];
    // Ajoute le loader à la vue en cours
    [self.view addSubview:loader];
    [self.view bringSubviewToFront:loader];
    
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:webViewUrl];
    wv.delegate = self;
    [wv loadRequest:request];
    

}

- (IBAction)closeModal:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)goBack:(id)sender {
    [wv goBack];
}

- (IBAction)goForth:(id)sender {
    [wv goForward];
}

- (IBAction)refresh:(id)sender {
    [wv reload];
}

- (IBAction)stop:(id)sender {
    [wv stopLoading];
}

- (void)viewDidUnload {
    [self setWebViewUrl:nil];
    [self setWv:nil];
    [self setBtnBack:nil];
    [self setBtnForth:nil];
    [self setBtnRefresh:nil];
    [self setBtnStop:nil];
    [self setBtnStop:nil];
    [self setToolbar:nil];
    [super viewDidUnload];
}

- (void)updateButtons {
    btnForth.enabled = wv.canGoForward;
    btnBack.enabled = wv.canGoBack;
    btnStop.enabled = wv.loading;
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    NSString *url = [[request URL] absoluteString];
    NSLog(@"url : %@", url);
    if([url rangeOfString:@"close/1"].length > 0) {
        [self dismissViewControllerAnimated:YES completion:nil];
        return NO;
    } else if([url rangeOfString:@"musics://itunes"].length > 0 || [url rangeOfString:@"itmss://itunes"].length > 0) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [loader show];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [self updateButtons];
}
- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self updateButtons];
    
    bool closeWebview = false;
    NSString *url = [[webView.request URL] absoluteString];
    NSString *bodyHTML = [webView stringByEvaluatingJavaScriptFromString:@"document.body.innerHTML"];

    NSError *error;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^(https://m.facebook.com/)((v)?\\d.\\d/)?(dialog/oauth)(/read)?/?"
                                    options:NSRegularExpressionCaseInsensitive
                                    error:&error];

    NSUInteger numberOfMatches = [regex numberOfMatchesInString:url
                                    options:0
                                    range:NSMakeRange(0, [url length])];

    if(numberOfMatches > 0) {
        if([bodyHTML isEqualToString:@""]) {
            if([delegate respondsToSelector:@selector(facebookDidClose:)]) {
                [delegate facebookDidClose:true];
            }
            closeWebview = true;
        }
    
    }
    
    if(closeWebview) {
        
        [self dismissViewControllerAnimated:YES completion:nil];
        
    } else {
    
        NSString *js = @"window.close=function(){window.location='app:close';};window.open=function(url){var t=document.createElement('a');t.setAttribute('href',url);var e=document.createEvent('MouseEvent');e.initMouseEvent('click');t.dispatchEvent(e);};";
        [webView stringByEvaluatingJavaScriptFromString:js];
        [loader hide];
        
    }
    
}
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self updateButtons];
    [loader hide];
}


@end
