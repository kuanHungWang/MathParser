//
//  BTMathParser.h
//  MathParser
//
//  Created by K.H.Wang on 2016/5/15.
//  Copyright (c) 2016年 KH. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef enum{
    tokenMainTypeNumber,
    // just number
    tokenMainTypeFunction, //anything that need "()", mostly prefix
    //    TokenSubtype_function_AND, TokenSubtype_function_OR, TokenSubtype_function_MAX, TokenSubtype_function_MIN,
    tokenMainTypeOperator, //anything that is inFix
    //     tokenSubType_Operator_Plus, tokenSubType_Operator_Minus, tokenSubType_Operator_Muiltiply,tokenSubType_Operator_Devide,tokenSubType_Operator_Power,
    
    tokenMainTypeOther,// left parenthesis, right parenthesis, comma
    //    tokenSubType_Other_LeftParenthesis, tokenSubType_Other_RightParenthesis, tokenSubType_Other_Comma,
}tokenMainType;
typedef enum{
    TokenSubtype_Default,
    //Others (parenthesis and comma)
    tokenSubType_Other_LeftParenthesis,
    tokenSubType_Other_RightParenthesis,
    tokenSubType_Other_Comma,
    
    //Operators
    //Arithmetic operators
    tokenSubType_Operator_Plus,
    tokenSubType_Operator_Minus,
    tokenSubType_Operator_Muiltiply,
    tokenSubType_Operator_Devide,
    tokenSubType_Operator_Power,
    //Comparison operators
    TokenSubtype_Operator_Smaller,
    TokenSubtype_Operator_SmallerEqual,
    TokenSubtype_Operator_Equal,
    TokenSubtype_Operator_GreaterEqual,
    TokenSubtype_Operator_Greater,
    TokenSubtype_Operator_NotEqual,
    TokenSubtype_Operator_Or,
    TokenSubtype_Operator_And,
    
    //functionType
    TokenSubtype_function_AND,
    TokenSubtype_function_OR,
    TokenSubtype_function_MAX,
    TokenSubtype_function_MIN,
    
    //expandable function
    TokenSubtype_function,
    TokenSubtype_function_unrecognized
    
    
} TokenSubtype;


enum{
    RPNErrFunctionUnavailable=2001,
    RPNErrNumberBeforeAlphabet =2002, //cannot have aphabet after number
    RPNErrUnrecognizableChar  = 2003,
    RPNErrOperatorError =2004,//operator should put between value
    RPNErrParenthesisNotMatched =2005,
    RPNErrUnnecessayComma = 2006,
    RPNErrNotEnoughArgument = 2007,
    RPNErrUnrecognizableFunction=2008,
    RPNErrEmptyToken = 2009
};
extern NSString * const customErrorDomain;
extern NSString * const ErrorKeyStage;
extern NSString * const ErrorStagePargingString;
extern NSString * const ErrorStageMidFixToPostFix;
extern NSString * const ErrorStageReversedPolish;
extern NSString * const ErrorKeyFunctionName;
extern NSString * const ErrorKeyArgumentNumber;
extern NSString * const ErrorKeyErroChar;
extern NSString * const ErrorKeyRange;



typedef struct RPNToken{
    tokenMainType mainType;
    TokenSubtype subType;
    float value;
    NSRange range;
}RPNToken;

typedef float (^Function)(float *a) ;

@interface FunctionMap : NSObject
@property(nonatomic,strong) Function functionBlock;
@property(nonatomic,assign) int argumentNumber;
@property(nonatomic,strong) NSString *name;
-(FunctionMap*)initWithBlock:(Function)block name:(NSString*)name argNumber:(int)number;
@end


@interface BTMathParser : NSObject{
    int tokenLength_;
}
/*
Array of FuncitonMaps., including basic function or customized-define function.
 
by default this prperty of initalized BTMathParser is nil, if you want to use some basic function like
AND(x,y), OR(x,y), MAX(x,y), MIN(x,y), you need to assign one by using class method: +(NSArray*)basicFunctions

you can also create your own function with the class "FunctionMap", which is define in @interface FunctionMap : NSObject
which have 3 requried property:
(1) the function itself, which is in the form of a block: float (^)(float *a)
(2) the number of argument
(3) the name of function, which is capital-sensitive
 
*/
@property NSArray *functions;
/*
 return array of basic FuncitonMaps: AND(x,y), OR(x,y), MAX(x,y), MIN(x,y)
*/
+(NSArray*)basicFunctions;

/*

 The parsing and calculation are in three stage:
 (1) Parse the string into notations in 4 categories: number, operator, function, other,
 (2) Use shunting yard algorithm to converte notations derived in (1) into reversed polish notations.
 (3) calculate the value of reversed polish notations.
 
 All stage have a instance method, and also have a method that execute above stages.
 If error occurs in any stage, the funciton will immediately return FLT_MAX and will not procced to next stage.
 
 error userInfo include keys:(some keys are errorcode-special)
 ErrorKeyStage: the stage that error occor;
 ErrorKeyFunctionName: function name (if error reason is unrecognizable function or enough argument)
 ErrorKeyArgumentNumber number of argument that the function require (if error reason is not enough argument)
 ErrorKeyErroChar: char that the error occor (in NSString form)
 ErrorKeyRange: NSValue object that encapsulate the NSRange which indicate where the error is in the original string
 */



/*
 Return calculation of a mathematic expression in a string form. If a NSError object is provided, error information will be return by reference if any error occurs.

*/
-(float)valueForExpression:(NSString*)string error:(NSError**)errorPtr;



/*
 Parse the string of Infix mathematic expression into a point to an array of notations
 notations are in 4 categories:
 number: includes negative number, decimal number.
 operator: include plus(+), minus(-), multiply(*), devide(/), power(^), AND(& or &&), OR(| or ||)
 function: Alphabets, in this stage, the exsistence of the funciton will not be checked
 other:  parenthesis and comma

*/
-(RPNToken*)tokensForExpression:(NSString*)string error:(NSError**)errorPtr;
/*
 convert and return postfix notation (reversed polish notation) from Infix notations.
 */
-(RPNToken*)reversePolishNotationFromMidFlix:(RPNToken*)midflix error:(NSError**)errorPtr;
/*
 calculate the value of reversed polish notations.
 */
-(float)valueOfRPN:(RPNToken*)tokens error:(NSError**)errorPtr;
/*
return the number of original notations (Infix)
 */
-(int)length;

//-(RPNToken)functionTokenFromString:(NSString*)string;
//-(RPNToken)operatorTokenFromString:(NSString*)string;
//-(RPNToken)numberTokenFromString:(NSString*)string;
@end
