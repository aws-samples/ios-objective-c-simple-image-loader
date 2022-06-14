// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

#import <UIKit/UIKit.h>

@interface SimpleImageLoader: UIViewController <UITextFieldDelegate,NSURLSessionDataDelegate,NSURLSessionDelegate>
@property (weak, nonatomic) IBOutlet UITextField *filename;
@property (weak, nonatomic) IBOutlet UIButton *fetch;
@property (weak, nonatomic) IBOutlet UIImageView *image;
@property (weak, nonatomic) IBOutlet UILabel *output;
- (IBAction)fetchPressed:(id)sender;
@end

