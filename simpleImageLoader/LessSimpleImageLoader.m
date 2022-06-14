// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

#import "SimpleImageLoader.h"
#include <Network/Network.h>

@interface SimpleImageLoader ()

@end

@implementation SimpleImageLoader

static BOOL pathConstrained = NO;
static BOOL pathExpensive = NO;
static NSURLSession *standardSession = nil;
static NSURLSession *saveDataSession = nil;
static NSMutableData *rxbuf = nil;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.filename setDelegate:self];
    static nw_path_monitor_t pathmon = nil;
    
    // Set up monitoring of network paths
    if (!pathmon) {
        pathmon = nw_path_monitor_create();
        nw_path_monitor_set_queue(pathmon, dispatch_get_main_queue());
        nw_path_monitor_set_update_handler(pathmon, ^(nw_path_t path) {
            // This code is called when our path has changed:
            //   just store the value of the flags
            pathExpensive   = nw_path_is_expensive(path);
            pathConstrained = nw_path_is_constrained(path);
        });
        nw_path_monitor_start(pathmon);
    }
}

// This is called if the 'go' button is pressed on the keyboard

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self fetchPressed:self.fetch];
    return YES;
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
 //   NSLog(@"didReceiveData on %@", (session==saveDataSession)?@"saveDataSession":@"standardSession");
    [rxbuf appendData:data];
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    NSLog(@"didReceiveResponse on %@", (session==saveDataSession)?@"saveDataSession":@"standardSession");
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *http = (NSHTTPURLResponse *)response;
        NSLog(@"%ld response with headers %@", (long)http.statusCode, http.allHeaderFields);
    } else {
        NSLog(@"not a NSHTTPURLResponse weirdly");
    }
    rxbuf = [NSMutableData dataWithLength:0];
    completionHandler(NSURLSessionResponseAllow);
}

- (void)        URLSession:(NSURLSession *)session
                      task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
                newRequest:(NSURLRequest *)request
         completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler
{
    NSLog(@"willPerformHTTPRedirection on %@", (session==saveDataSession)?@"saveDataSession":@"standardSession");
    completionHandler(NULL);
}

- (void)  URLSession:(NSURLSession *)session
                task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
    NSLog(@"didCompleteWithError: %p on %@", error, (session==saveDataSession)?@"saveDataSession":@"standardSession");
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!error && rxbuf.length > 0) {
            [self.output setText:[NSString stringWithFormat:@"Success (%0.1f kilobytes)",
                                 (rxbuf.length / 1024.0)]];
            [self.image setImage:[UIImage imageWithData:rxbuf]];
        } else if (error) {
            [self.output setText:[NSString stringWithFormat:@"%@", error]];
        }
    });
}

- (IBAction)fetchPressed:(id)sender
{
    NSString *message = [NSString stringWithFormat:@"Fetch %@%@%@",
                         [self.filename text], pathConstrained?@" CONSTRAINED":@"", pathExpensive?@" EXPENSIVE":@""];
    NSURL *url = [NSURL URLWithString:[self.filename text]];
    NSURLSession *session = nil;

    [self.filename resignFirstResponder];
    [self.output setText:message];

    if (standardSession == nil && saveDataSession == nil) {
        // First time
        
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSDictionary *myHeaders = nil;
        
        // Here we just use the pathConstrained flag to influence our
        // added HTTP request headers; we could do something more complex
        // using both flags
        
        standardSession = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];

        // Add Save-Data: On header
        myHeaders = [NSDictionary dictionaryWithObject:@"on" forKey:@"Save-Data"];
        [config setHTTPAdditionalHeaders:myHeaders];
        
        saveDataSession = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    }

    // Pick a session based on the pathConstrained flag
    session = pathConstrained?saveDataSession:standardSession;
    
    NSURLSessionDataTask *task = [session dataTaskWithURL:url];
    task.delegate = self;
    [task resume];
#if 0
    
completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        // Note we must explicitly call the UI functions on the main queue, this code
        // could be called from a background queue
        if (data && !error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.output setText:[NSString stringWithFormat:@"Success (%0.1f kilobytes)",
                                     (data.length / 1024.0)]];
                [self.image setImage:[UIImage imageWithData:data]];
            });
        } else if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.output setText:[NSString stringWithFormat:@"Failure %@", error]];
            });
        }
    }];
#endif
}
@end
