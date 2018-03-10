#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void (*INT_CALLBACK)(int);

@interface MyPlugin: NSObject <UIAlertViewDelegate>
{
    INT_CALLBACK alertCallBack;
    NSDate *creationDate;
    INT_CALLBACK shareCallBack;
    UIPopoverController *popover;
}
@end

@implementation MyPlugin

static MyPlugin *_sharedInstance;

+(MyPlugin*) sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLog(@"Creating MyPlugin shared instance");
        _sharedInstance = [[MyPlugin alloc] init];
    });
    return _sharedInstance;
}

+(NSString*)createNSString:(const char*) string {
    if (string!=nil)
        return [NSString stringWithUTF8String:string];
    else
        return @"";
}

-(id)init
{
    self = [super init];
    if (self)
        [self initHelper];
    return self;
}

-(void)initHelper
{
    NSLog(@"InitHelper called");
    creationDate = [NSDate date];
}

-(double)getElapsedTime
{
    return [[NSDate date] timeIntervalSinceDate:creationDate];
}

-(void)createAlertDialog:(const char**) strings_in stringCount:(int)stringCount callback:(INT_CALLBACK)callback
{
    NSMutableArray *strings = [NSMutableArray new];
    for (int ix=0;ix<stringCount;ix++)
    {
        if (strlen(strings_in[ix])>0)
            [strings addObject:[MyPlugin createNSString:strings_in[ix]]];
    }
    stringCount = (int)[strings count];
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:strings[0] message:strings[1] delegate:self cancelButtonTitle:strings[2] otherButtonTitles:nil];
    if (stringCount>3)
    {
        int ix = 3;
        while (ix<stringCount)
        {
            [alertView addButtonWithTitle:strings[ix]];
            ix++;
        }
    }
    alertCallBack = callback;
    
    [alertView show];
}

-(void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSLog(@"iOS: clicked button index: %ld",buttonIndex);
    alertCallBack((int)buttonIndex);
}

-(void)shareScreenImage:(const unsigned char*)imagePNG_in length:(long)length caption:(const char*) caption_in
               callback:(INT_CALLBACK)callback
{
    NSMutableArray *shareableItems = [NSMutableArray arrayWithCapacity:2];
    NSString *caption;
    UIImage *image;
    if (caption_in!=nil)
    {
        caption = [MyPlugin createNSString:caption_in];
        [shareableItems addObject:caption];
    }
    
    if (imagePNG_in!=nil)
    {
        NSData *pngData = [NSData dataWithBytes:imagePNG_in length:length];
        image = [UIImage imageWithData:pngData];
        [shareableItems addObject:image];
        pngData = nil;
    }
    
    shareCallBack = callback;
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc]
                                                        initWithActivityItems:shareableItems applicationActivities:nil];
    activityViewController.completionWithItemsHandler = ^(NSString *activityType, BOOL completed,
                                                          NSArray *returnedItems, NSError *activityError){
        NSLog(@"Activity %@ completed: %d",activityType, completed);
        if (activityError!=nil)
            NSLog(@"Error: %@",[activityError localizedDescription]);
        if (shareCallBack!=nil)
            shareCallBack(completed);
    };
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        [UnityGetGLViewController() presentViewController:activityViewController animated:YES completion:^{
            NSLog(@"share presented");
        }];
    }
    else
    {
        popover = [[UIPopoverController alloc] initWithContentViewController:activityViewController];
        UIView *mainView = UnityGetGLView();
        popover.delegate = nil;
        [popover presentPopoverFromRect:CGRectMake(mainView.frame.size.width/2,mainView.frame.size.height-10,0,0) inView:mainView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

@end

extern "C"
{
    double IOSgetElapsedTime()
    {
        return [[MyPlugin sharedInstance] getElapsedTime];
    }
    
    void IOScreateNativeAlert(const char** strings, int stringCount, INT_CALLBACK callback)
    {
        [[MyPlugin sharedInstance] createAlertDialog:strings stringCount:stringCount callback:callback];
    }
    
    void IOSshareScreenImage(const unsigned char* imagePNG, long imageLen, const char* caption, INT_CALLBACK callback)
    {
        [[MyPlugin sharedInstance] shareScreenImage:imagePNG length:imageLen caption:caption callback:callback];
    }
}

