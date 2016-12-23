//
//  DemoViewController.m
//  demo
//
//  Created by K.H.Wang on 2016/12/20.
//  Copyright © 2016年 KH. All rights reserved.
//

#import "DemoViewController.h"
#import "BTMathParser.h"

@interface DemoViewController ()

@end

@implementation DemoViewController

- (void)viewDidLoad {
    [self.view updateConstraints];
    //[self.view layoutSubviews];
    [self clearLabels];

    [super viewDidLoad];

    // Do view setup here.
}

- (IBAction)calculate:(id)sender {

    
    [self clearLabels];
    BTMathParser *mathParser = [[BTMathParser alloc] init];
    NSArray *functionMaps=[BTMathParser basicFunctions];
    functionMaps=[functionMaps arrayByAddingObjectsFromArray:@[[self factorial],[self MA]]];
    mathParser.functions=functionMaps;
    NSError *error;
    NSString *expression=self.textField.stringValue;
    float result = [mathParser valueForExpression:expression error:&error];
    
    if (result != FLT_MAX) {
        self.labelResult.stringValue=[@(result) stringValue];

    }else{
        if (error) {
            
            NSDictionary *attributes = @{NSBackgroundColorAttributeName:NSColor.greenColor};
            NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:[expression stringByReplacingOccurrencesOfString:@" " withString:@""]];
            NSValue *value=[error.userInfo valueForKey:ErrorKeyRange];
            NSRange range=[value rangeValue];
            [attrString setAttributes:attributes range:range];
            [self.labelErrorRange setAttributedStringValue:attrString];
            NSString *stringStage=@"Stage: ";
            stringStage = [stringStage stringByAppendingString:[error.userInfo valueForKey:ErrorKeyStage]];
            [self.labelErrorStage setStringValue:stringStage];
            [self.labelErrorMessage setStringValue:error.localizedDescription];
            if ([error.userInfo valueForKey:ErrorKeyFunctionName]) {
                NSString *stringFunction=@"Function Name: ";
                stringFunction = [stringFunction stringByAppendingString:[error.userInfo valueForKey:ErrorKeyFunctionName]];
                if ([error.userInfo valueForKey:ErrorKeyArgumentNumber]) {
                    stringFunction = [stringFunction stringByAppendingString:@", Argument number: "];
                    NSNumber *arguNumber=[error.userInfo valueForKey:ErrorKeyArgumentNumber];
                    stringFunction = [stringFunction stringByAppendingString:[arguNumber stringValue]];
                }
                [self.labelFunctionInfo setStringValue:stringFunction];
            }
        }
    }

}
-(void)clearLabels{
    [self.labelResult setStringValue:@""];
    [self.labelErrorRange setStringValue:@""];
    [self.labelErrorMessage setStringValue:@""];
    [self.labelFunctionInfo setStringValue:@""];
    [self.labelErrorStage setStringValue:@""];
}
#pragma mark - custom function
-(FunctionMap*)factorial{
    Function factorialBlock=^float(float *a){
        int k=a[0];
        int factorialValue = 1;
        for (int i = 1; i<=k; i++) {
            factorialValue=factorialValue*i;
        }
        return factorialValue;
    };
    return [[FunctionMap alloc] initWithBlock:factorialBlock name:@"factorial" argNumber:1];
}
-(FunctionMap*)MA{
    NSArray *stockPrice=@[
    @219.57,
    @219.68,
    @221,
    @221.7,
    @224.6,
    @225.15,
    @226.51,
    @226.25,
    @227.76,
    @225.88,
    @226.81,
    @225.04,
    @225.53,
    @226.4,
    @209.74,
    @208.78,
    @208.55,
    @213.15,
    @214.11,
    @216.38,
    @216.92,
    @216.42,
    @216.59,
    @218.28,
    @217.87,
    @218.99,
    @218.5,
    @220.15,
    @220.58,
    @220.7];
    Function MABlock=^float(float *a){
        int k=a[0];
        float sum = 0;
        for (int i=0; i<MIN(k, stockPrice.count); i++) {
            sum+=[[stockPrice objectAtIndex:i] floatValue];
        }
        return sum/k;
    };
    return [[FunctionMap alloc] initWithBlock:MABlock name:@"MA" argNumber:1];
}
@end
