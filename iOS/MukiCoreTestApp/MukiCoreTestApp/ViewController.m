//
//  ViewController.m
//  MukiCoreTestApp
//
//  Created by Nikita Mosiakov on 29/08/16.
//  Copyright © 2016 Muki. All rights reserved.
//
//#import "makeURL.h"
#import "ViewController.h"
#import "MukiCupAPI.h"
#import "Utilities.h"
#import <MediaPlayer/MediaPlayer.h>

#define QR_PLACER 50.0f
#define MAX_CUP_WIDTH       176.0f
#define MAX_CUP_HEIGHT      264.0f
#define CUP_IMAGE_SIZE CGSizeMake(MAX_CUP_WIDTH, MAX_CUP_HEIGHT)

@interface ViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UILabel *contrastLabel;
@property (weak, nonatomic) IBOutlet UILabel *startPointLabel;

@property (weak, nonatomic) IBOutlet UISlider *contrastSlider;

@property (weak, nonatomic) IBOutlet UITextField *cupIDTextField;
@property (weak, nonatomic) IBOutlet UITextField *pointXTextField;
@property (weak, nonatomic) IBOutlet UITextField *pointYTextField;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (nonatomic) MukiCupAPI *cupAPI;
@property (nonatomic) Utilities *utilities;

@end

@implementation ViewController

////===================================================================
#pragma mark -
#pragma mark - UIViewController life cycle





- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.utilities = [Utilities new];
    self.contrastLabel.text = [NSString stringWithFormat:@"Contrast value: %f", self.contrastSlider.value];
}

////===================================================================
#pragma mark -
#pragma mark - IBAction

- (IBAction)sliderValueChanged:(UISlider *)sender
{
    self.contrastLabel.text = [NSString stringWithFormat:@"Contrast value: %f", sender.value];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}
- (IBAction)dismiss:(id)sender
{
    [self.view endEditing:YES];
}



- (IBAction)shareSong:(id)sender
{
    NSString *cupIdentifier = [self cupIdentifierFromSN];
    self.cupAPI = [MukiCupAPI new];

    
    MPMusicPlayerController *iPhoneMediaPlayer;
    iPhoneMediaPlayer = [MPMusicPlayerController iPodMusicPlayer];
    
    // Check if it is now playing
    if([iPhoneMediaPlayer nowPlayingItem])
    {
        
        // Get the now playing item
        MPMediaItem *nowPlayingMediaItem = [iPhoneMediaPlayer nowPlayingItem];
        
        // Get info of the item
        NSString *itemTitle = [nowPlayingMediaItem valueForProperty:MPMediaItemPropertyTitle];
        NSString *itemArtist = [nowPlayingMediaItem valueForProperty: MPMediaItemPropertyArtist];
        //NSString *itemURL = [nowPlayingMediaItem valueForProperty:MPMediaItemPropertyAssetURL];
        // NSLog(@"%@", itemTitle);


        NSString *url_string = [NSString stringWithFormat:
                                @"https://itunes.apple.com/search?term=%@+%@&media=music&limit=1",
                                itemArtist, itemTitle];
        
        NSURL *url = [NSURL URLWithString:url_string];
        NSURLRequest *req = [[NSURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0];
        NSError *error = nil;
        NSURLResponse *res = nil;
        NSData *json = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&error];
        NSString *myString = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
        NSArray *components = [myString componentsSeparatedByString: @":"];
        NSArray *com1 = [components[18] componentsSeparatedByString: @"\""];



        
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    

    
    NSString *qrString = [NSString stringWithFormat:
                            @"https:%@",com1[0]];
    NSData *stringData = [qrString dataUsingEncoding: NSUTF8StringEncoding];
    
    CIFilter *qrFilter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    [qrFilter setValue:stringData forKey:@"inputMessage"];
    [qrFilter setValue:@"H" forKey:@"inputCorrectionLevel"];
    
    CIImage *qrImage = qrFilter.outputImage;
    float scaleX = MAX_CUP_WIDTH;
    float scaleY = MAX_CUP_WIDTH;
    
    qrImage = [qrImage imageByApplyingTransform:CGAffineTransformMakeScale(scaleX, scaleY)];
    
    UIImage *imageQR = [UIImage imageWithCIImage:qrImage
                                           scale:QR_PLACER
                                     orientation:UIImageOrientationUp];
    
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    
    
    UIImage *myImage = [UIImage imageNamed:@"blackBackground.png"];
    UIGraphicsBeginImageContext(myImage.size);
    [myImage drawInRect:CGRectMake(0,0,myImage.size.width,myImage.size.height)];
    UITextView *myText = [[UITextView alloc] init];
    myText.font = [UIFont fontWithName:@"TrebuchetMS-Bold" size:20.0f];
    myText.textColor = [UIColor blackColor];
    myText.text = NSLocalizedString(@"Taste this song with coffee :)", @"");

    
    CGSize maximumLabelSize = CGSizeMake(myImage.size.width,myImage.size.height);
    CGSize expectedLabelSize = [myText.text sizeWithFont:myText.font
                                       constrainedToSize:maximumLabelSize
                                           lineBreakMode:UILineBreakModeWordWrap];
    
    myText.frame = CGRectMake((myImage.size.width / 2) - (expectedLabelSize.width / 2),
                              (myImage.size.height / 2) - (expectedLabelSize.height / 2),
                              myImage.size.width,
                              myImage.size.height);
    
    [[UIColor whiteColor] set];
    [myText.text drawInRect:myText.frame withFont:myText.font];
    UIImage *myNewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    
    
    UIImage *image1 = myNewImage;
    UIImage *image2 = imageQR;
    
    CGSize size = CGSizeMake(image1.size.width, image1.size.height + image2.size.height);
    
    UIGraphicsBeginImageContext(size);
    
    [image1 drawInRect:CGRectMake(0,0,size.width, image1.size.height)];
    [image2 drawInRect:CGRectMake(0,image1.size.height,size.width, image2.size.height)];
    
    UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    

    
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    CGFloat contrastValue = 3.0;

    UIImage *resultedImage = [self.utilities ditheringImage:finalImage contrastValue:contrastValue];
    
    self.imageView.image = resultedImage;

    [self.cupAPI sendImage:resultedImage toCup:cupIdentifier completion:^(NSError * _Nullable error) {
        NSLog(@"%@", error);
    }];
    }
}



- (IBAction)sendData:(id)sender
{
    NSString *cupIdentifier = [self cupIdentifierFromSN];
    self.cupAPI = [MukiCupAPI new];
    NSData *data = [NSData new];

    [self.cupAPI sendData:data toCup:cupIdentifier completion:^(NSError * _Nullable error) {
        NSLog(@"%@", error);
    }];
}




- (IBAction)sendImage:(id)sender
{
    NSString *cupIdentifier = [self cupIdentifierFromSN];
    self.cupAPI = [MukiCupAPI new];
    UIImage *image = [UIImage imageNamed:@"img"];
    
    CGFloat contrastValue = 3.0;
    UIImage *resultedImage = [self.utilities scaleAndCropImage:image size:CUP_IMAGE_SIZE];
    resultedImage = [self.utilities ditheringImage:resultedImage contrastValue:contrastValue];
    
    self.imageView.image = resultedImage;
    
    [self.cupAPI sendImage:image toCup:cupIdentifier completion:^(NSError * _Nullable error) {
        NSLog(@"%@", error);
    }];
    
   }





- (IBAction)sendImageWithOptions:(id)sender
{
    NSString *cupIdentifier = [self cupIdentifierFromSN];
    self.cupAPI = [MukiCupAPI new];
    
    ImageProperties *imageProperties = [ImageProperties new];
    
    CGPoint point = CGPointMake(self.pointXTextField.text.floatValue, self.pointYTextField.text.floatValue);
    CGFloat contrast = self.contrastSlider.value;
    imageProperties.contrast = contrast;
    imageProperties.startPoint = point;

    UIImage *image = [UIImage imageNamed:@"img"];
    
    CGRect rect = CGRectMake(point.x, point.y, MAX_CUP_WIDTH, MAX_CUP_HEIGHT);
    UIImage *resultedImage = [self.utilities cropImage:image rect:rect];
    resultedImage = [self.utilities ditheringImage:resultedImage contrastValue:contrast];
    self.imageView.image = resultedImage;
    
    [self.cupAPI sendImage:image toCup:cupIdentifier withImageProperties:imageProperties completion:^(NSError * _Nullable error) {
        NSLog(@"%@", error);
    }];
}

- (IBAction)clear:(id)sender
{
    NSString *cupIdentifier = [self cupIdentifierFromSN];
    self.cupAPI = [MukiCupAPI new];
    [self.cupAPI clearCupWithIdentifier:cupIdentifier completion:^(NSError * _Nullable error) {
        NSLog(@"%@", error);
    }];
}

- (IBAction)readDeviceInfo:(id)sender
{
    NSString *cupIdentifier = [self cupIdentifierFromSN];
    self.cupAPI = [MukiCupAPI new];
    [self.cupAPI readDeviceInfoWithIdentifier:cupIdentifier completion:^(DeviceInfo * _Nullable deviceInfo, NSError * _Nullable error) {
        NSLog(@"%@", error);
        if (deviceInfo) {
            NSLog(@"%@", deviceInfo.description);
        }
    }];
}


////===================================================================
#pragma mark -
#pragma mark - Private methods

- (NSString *)cupIdentifierFromSN
{
    NSError *error;
    NSString *cupID = [MukiCupAPI cupIdentifierFromSerialNumber:self.cupIDTextField.text error:&error];
    NSLog(@"%@", error);
    return cupID;
}

@end
