//
//  BTMathParser.m
//  MathParser
//
//  Created by K.H.Wang on 2016/5/15.
//  Copyright (c) 2016年 KH. All rights reserved.
//

#import "BTMathParser.h"
#define SIZE 1000
#define ARG_SIZE 30
#define MODE_BASIC 0
#define MODE_NUM 1
#define MODE_FUNC 2
#define MODE_OP 3
NSString * const customErrorDomain = @"com.khwang.MathParser";
NSString * const ErrorKeyStage = @"KeyStage";
NSString * const ErrorStagePargingString = @"parsing original string";
NSString * const ErrorStageInfixToPostfix = @"converting infix to postfix (shunting yard algorithm)";
NSString * const ErrorStageReversedPolish = @"calculating value of reversed polish notation";
NSString * const ErrorKeyFunctionName = @"functionName";
NSString * const ErrorKeyArgumentNumber = @"argumentNumber";
NSString * const ErrorKeyErroChar = @"ErrorChar";
NSString * const ErrorKeyRange=@"range";


@implementation FunctionMap
-(FunctionMap*)initWithBlock:(Function)block name:(NSString*)name argNumber:(int)number{
    if (self=[super init]) {
        self.functionBlock=block;
        self.name=name;
        self.argumentNumber=number;
        return self;
    }else{
        return nil;
    }
}


@end


@implementation BTMathParser
-(float)valueForExpression:(NSString*)string error:(NSError**)errorPtr{
    RPNToken *midFix=[self tokensForExpression:string error:errorPtr];
    if (!midFix||*errorPtr) {
        return FLT_MAX;
    }
    RPNToken *postFix=[self reversePolishNotationFromMidFlix:midFix error:errorPtr];
    if (!midFix||*errorPtr) {
        return FLT_MAX;
    }
    free(midFix);
    float value=[self valueOfRPN:postFix error:errorPtr];
    free(postFix);
    return value;
    
}
+(NSArray*)basicFunctions{
    Function f_MAX = ^float(float *f){ return f[0] > f[1] ? f[0]:f[1]; };
    Function f_MIN = ^float(float *f){ return f[0] < f[1] ? f[0]:f[1]; };
    Function f_AND = ^float(float *f){ return f[0] && f[1]; };
    Function f_OR = ^float(float *f){ return f[0] || f[1]; };
    
    FunctionMap *m_MAX, *m_MIN, *m_AND, *m_OR;
    
    m_MAX=[[FunctionMap alloc] initWithBlock:f_MAX name:@"MAX" argNumber:2];
    m_MIN=[[FunctionMap alloc] initWithBlock:f_MIN name:@"MIN" argNumber:2];
    m_AND=[[FunctionMap alloc] initWithBlock:f_AND name:@"AND" argNumber:2];
    m_OR=[[FunctionMap alloc] initWithBlock:f_OR name:@"OR" argNumber:2];

    return @[m_MAX,m_MIN,m_AND,m_OR];
}
#pragma mark private
-(RPNToken*)tokensForExpression:(NSString*)string error:(NSError**)errorPtr{
    string=[string  stringByReplacingOccurrencesOfString:@" " withString:@""];
    RPNToken *output=malloc(sizeof(RPNToken)*SIZE);
    RPNToken *nothing;
    if (!self.functions) {
        //exception
        if (errorPtr) {
            NSDictionary *userInfo=@{NSLocalizedDescriptionKey:@"function map is not available",ErrorKeyStage:ErrorStagePargingString};
            NSError *error=[NSError errorWithDomain:customErrorDomain code:RPNErrFunctionUnavailable userInfo:userInfo];
            *errorPtr=error;
        }
        return nothing;
    }

    NSUInteger len = [string length];
    unichar buffer[len];
    [string getCharacters:buffer range:NSMakeRange(0, len)];
    int i_output=0;
    int mode=MODE_BASIC;
    NSMutableString *numberString, *functionString, *operatorString;
    numberString=[NSMutableString string];
    functionString=[NSMutableString string];
    operatorString=[NSMutableString string];
    tokenLength_=0;
    int rangeStart=0,rangeEnd;
    //出現output[i_output++]=[self XXXTokenFromString:XXXString]之前， rangeEnd=i-1, 輸出token
    //出現“stringWithFormat”的地方，rangeStart=i, (有輸出token要先輸出)
    //出現output[i_output++]=[self operatorTokenFromChar:c];rangeEnd = rangeStart =i
    

    for(int i = 0; i < len; ++i) {
        //ASICC codes:
        // numbers: 0x30~0x39, dot: 0x21
        // alphabet: 0x41~0x5a
        
        /*
         ***** type of char  ****
         current mode         +*-/^()  number   alphabet    =><
         Basic                Basic    Num      Func        Op
         Num                  Basic    Num      error       Op
         Func                 Basic    Func     Func        Op
         Op                   Basic    Num      Func        Op(max 2 char)
         */
        unichar c = buffer[i];
        //NSLog(@"%c",c);

        if (c=='+'||c=='*'||c=='/'||c=='('||c==')'||c=='^'||c==','){//單一運算子
            if (mode==MODE_BASIC) {
                output[i_output++]=[self operatorTokenFromChar:c];
                
            }else if (mode==MODE_NUM){
                mode=MODE_BASIC;
                rangeEnd=i-1;
                RPNToken token=[self numberTokenFromString:numberString];
                token.range=NSMakeRange(rangeStart, rangeEnd-rangeStart+1);
                output[i_output++]=token;
                
                rangeStart=i;rangeEnd=i;
                RPNToken tokenC=[self operatorTokenFromChar:c];
                tokenC.range=NSMakeRange(rangeStart, rangeEnd-rangeStart+1);
                output[i_output++]=tokenC;
                
            }else if (mode==MODE_FUNC){
                mode=MODE_BASIC;

                rangeEnd=i-1;
                RPNToken token=[self functionTokenFromString:functionString];
                token.range=NSMakeRange(rangeStart, rangeEnd-rangeStart+1);
                output[i_output++]=token;
                
                rangeStart=i;rangeEnd=i;
                RPNToken tokenC=[self operatorTokenFromChar:c];
                tokenC.range=NSMakeRange(rangeStart, rangeEnd-rangeStart+1);
                output[i_output++]=tokenC;
            }else{//MODE_OP
                mode=MODE_BASIC;
                
                rangeEnd=i-1;
                RPNToken token=[self operatorTokenFromString:operatorString];
                token.range=NSMakeRange(rangeStart, rangeEnd-rangeStart+1);
                output[i_output++]=token;
                
                rangeStart=i;rangeEnd=i;
                RPNToken tokenC=[self operatorTokenFromChar:c];
                tokenC.range=NSMakeRange(rangeStart, rangeEnd-rangeStart+1);
                output[i_output++]=tokenC;
            }
        }else if (c=='-'){//負號需獨立出來考量
            if (mode==MODE_NUM) {//視為減法運算子
                mode=MODE_BASIC;
                
                rangeEnd=i-1;
                RPNToken token=[self numberTokenFromString:numberString];
                token.range=NSMakeRange(rangeStart, rangeEnd-rangeStart+1);
                output[i_output++]=token;
                
                rangeStart=i;rangeEnd=i;
                RPNToken tokenC=[self operatorTokenFromChar:c];
                tokenC.range=NSMakeRange(rangeStart, rangeEnd-rangeStart+1);
                output[i_output++]=tokenC;
                
            }else if (i_output!=0 && mode==MODE_BASIC && output[i_output-1].subType==tokenSubType_Other_RightParenthesis){//視為減法運算子
                rangeStart=i;rangeEnd=i;
                RPNToken tokenC=[self operatorTokenFromChar:c];
                tokenC.range=NSMakeRange(rangeStart, rangeEnd-rangeStart+1);
                output[i_output++]=tokenC;
            }else{//視為負號,當作數字處理
                if (mode==MODE_BASIC) {
                    mode=MODE_NUM;
                    rangeStart=i;
                    numberString=[NSMutableString stringWithFormat:@"%c",c];
                }/*
                else if (mode==MODE_NUM){//?
                    [numberString appendFormat:@"%c",c ];
                }*/
                else if (mode==MODE_FUNC){
                    //will not change mode, means number can after function
                    [functionString appendFormat:@"%c",c ];
                    
                }else{//MODE_OP
                    mode=MODE_NUM;
                    numberString=[NSMutableString stringWithFormat:@"%c",c];
                    
                    rangeEnd=i-1;
                    RPNToken token=[self operatorTokenFromString:operatorString];
                    token.range=NSMakeRange(rangeStart, rangeEnd-rangeStart+1);
                    output[i_output++]=token;

                    rangeStart=i;

                    
                }
                
            }
        }
        else if ((c>=0x30&&c<=0x39)||c==0x2e) {//數字字元
            if (mode==MODE_BASIC) {
                mode=MODE_NUM;
                numberString=[NSMutableString stringWithFormat:@"%c",c];
                rangeStart=i;

            }else if (mode==MODE_NUM){
                [numberString appendFormat:@"%c",c];
            }else if (mode==MODE_FUNC){
                //will not change mode, means number can after function
                [functionString appendFormat:@"%c",c ];
                
            }else{//MODE_OP
                mode=MODE_NUM;
                numberString=[NSMutableString stringWithFormat:@"%c",c];

                rangeEnd=i-1;
                RPNToken token=[self operatorTokenFromString:operatorString];
                token.range=NSMakeRange(rangeStart, rangeEnd-rangeStart+1);
                output[i_output++]=token;
                rangeStart=i;

            }
        }else if ((c>=0x41&&c<=0x5a)||(c>=0x61&&c<=0x7a)){//英文字母
            if (mode==MODE_BASIC) {
                mode=MODE_FUNC;
                functionString=[NSMutableString stringWithFormat:@"%c",c];
                rangeStart=i;

            }else if (mode==MODE_NUM){
                //exception
                if (errorPtr) {
                    NSRange range=NSMakeRange(i, 1);
                    NSDictionary *userInfo=@{NSLocalizedDescriptionKey:@"Cannot put alphabet after number",ErrorKeyErroChar:[NSString stringWithCharacters:&c length:1],ErrorKeyStage:ErrorStagePargingString, ErrorKeyRange:[NSValue valueWithRange:range]};
                    NSError *error=[NSError errorWithDomain:customErrorDomain code:RPNErrNumberBeforeAlphabet userInfo:userInfo];
                    *errorPtr=error;
                }
                return nothing;
            }else if (mode==MODE_FUNC){
                [functionString appendFormat:@"%c",c ];
                
            }else{//MODE_OP
                mode=MODE_FUNC;
                functionString=[NSMutableString stringWithFormat:@"%c",c];

                rangeEnd=i-1;
                RPNToken token=[self operatorTokenFromString:operatorString];
                token.range=NSMakeRange(rangeStart, rangeEnd-rangeStart+1);
                output[i_output++]=token;

                rangeStart=i;

            }
        }else if(c=='>'||c=='<'||c=='='||c=='!'||c=='|'||c=='&'){//複數運算子
            if (mode==MODE_BASIC) {
                mode=MODE_OP;
                operatorString=[NSMutableString stringWithFormat:@"%c",c];
                rangeStart=i;

            }else if (mode==MODE_NUM){
                mode=MODE_OP;
                operatorString=[NSMutableString stringWithFormat:@"%c",c];

                rangeEnd=i-1;
                RPNToken token=[self numberTokenFromString:numberString];
                token.range=NSMakeRange(rangeStart, rangeEnd-rangeStart+1);
                output[i_output++]=token;
                
                rangeStart=i;

            }else if (mode==MODE_FUNC){
                mode=MODE_OP;
                operatorString=[NSMutableString stringWithFormat:@"%c",c];

                rangeEnd=i-1;
                RPNToken token=[self functionTokenFromString:functionString];
                token.range=NSMakeRange(rangeStart, rangeEnd-rangeStart+1);
                output[i_output++]=token;
                
                rangeStart=i;
                
            }else{//MODE_OP
                //need to check number;
                if (operatorString.length>=2) {
                    if (errorPtr) {
                        NSRange range=NSMakeRange(i, 1);
                        NSDictionary *userInfo=@{NSLocalizedDescriptionKey:@"Opperator must put between values.",ErrorKeyStage:ErrorStagePargingString, ErrorKeyErroChar:[NSString stringWithCharacters:&c length:1], ErrorKeyRange:[NSValue valueWithRange:range]};
                        NSError *error=[NSError errorWithDomain:customErrorDomain code:RPNErrOperatorError userInfo:userInfo];
                        *errorPtr=error;
                    }
                    return nothing;
                }else{
                    [operatorString appendFormat:@"%c",c ];
                }
            }
        }else{
            //exception unrecognizable 無法辨識字元
            if (errorPtr) {
                NSRange range=NSMakeRange(i, 1);

                NSDictionary *userInfo=@{NSLocalizedDescriptionKey:@"Unrecognizable operator", ErrorKeyStage:ErrorStagePargingString, ErrorKeyErroChar:[NSString stringWithCharacters:&c length:1], ErrorKeyRange:[NSValue valueWithRange:range]};
                NSError *error=[NSError errorWithDomain:customErrorDomain code:RPNErrOperatorError userInfo:userInfo];
                *errorPtr=error;
            }
            return nothing;
        }
    }
    //字串跑完還沒把string輸入成唯一的一個token
    if (mode==MODE_FUNC) {
        rangeEnd=len-1;
        RPNToken token=[self functionTokenFromString:functionString];
        token.range=NSMakeRange(rangeStart, rangeEnd-rangeStart+1);
        output[i_output++]=token;

    }
    else if (mode==MODE_NUM){
        rangeEnd=len-1;
        RPNToken token=[self numberTokenFromString:numberString];
        token.range=NSMakeRange(rangeStart, rangeEnd-rangeStart+1);
        output[i_output++]=token;

    }else if (mode==MODE_OP){
        rangeEnd=len-1;
        RPNToken token=[self operatorTokenFromString:operatorString];
        token.range=NSMakeRange(rangeStart, rangeEnd-rangeStart+1);
        output[i_output++]=token;
 
        output[i_output++]=[self operatorTokenFromString:operatorString];
    }
    tokenLength_=i_output;

    
    
    return output;
}
-(RPNToken*)reversePolishNotationFromMidFlix:(RPNToken*)midflix error:(NSError**)errorPtr{
    RPNToken *output=malloc(sizeof(RPNToken)*tokenLength_), stack[tokenLength_],*nothing;
    
    int i_output=0,i_stack=0;
    for(int i=0;i<tokenLength_;i++){
        RPNToken it=midflix[i];
        if (it.mainType==tokenMainTypeNumber) {//數字
            output[i_output++]=it;
            //printf("%f",it.value);
            
        }//數字
        else if(it.mainType==tokenMainTypeFunction){//函數
            stack[i_stack++]=it;
//            printf("put # %i th item (number) into stack, stack size: %i \n",count,i_stack);
            
        }//函數
        else if(it.mainType==tokenMainTypeOther) {//括號與逗點
            if(it.subType==tokenSubType_Other_RightParenthesis||it.subType==tokenSubType_Other_Comma){//處理右括號與逗號
                if (i_stack==0) {
                    //exception
                    if (it.subType==tokenSubType_Other_RightParenthesis) {
                        if (errorPtr) {
                            
                            NSDictionary *userInfo=@{NSLocalizedDescriptionKey:@"right parenthsis not matched with left parenthsis.",ErrorKeyRange:[NSValue valueWithRange:it.range]};
                            
                            NSError *error=[NSError errorWithDomain:customErrorDomain code:RPNErrParenthesisNotMatched userInfo:userInfo];
                            *errorPtr=error;
                        }
                    }else{
                            if (errorPtr) {
                                NSDictionary *userInfo=@{NSLocalizedDescriptionKey:@"Comma not placed in right position or unnecessary comma.",ErrorKeyStage:ErrorStageInfixToPostfix ,ErrorKeyRange:[NSValue valueWithRange:it.range]};
                                NSError *error=[NSError errorWithDomain:customErrorDomain code:RPNErrUnnecessayComma userInfo:userInfo];
                                *errorPtr=error;
                            }
                    }
                    return nothing;
                }
                while(stack[i_stack-1].subType!=tokenSubType_Other_LeftParenthesis){//直到stack頂端出現左括號為止
                    output[i_output++]=stack[--i_stack];

                    //printf("pop from stack to output when right/comma appear, stack size: %i \n",i_stack);
                    if (i_stack==0) {//如果stack空了還是沒有左括號，錯誤
                        //exception
                        if (errorPtr) {
                            NSDictionary *userInfo=@{NSLocalizedDescriptionKey:@"right parenthsis not matched with left parenthsis.", ErrorKeyStage:ErrorStageInfixToPostfix ,ErrorKeyRange:[NSValue valueWithRange:it.range]};
                            NSError *error=[NSError errorWithDomain:customErrorDomain code:RPNErrParenthesisNotMatched userInfo:userInfo];
                            *errorPtr=error;
                        }
                        return nothing;
                    }
                }
                if (it.subType==tokenSubType_Other_RightParenthesis) {
                    i_stack--;//把左括號拿掉，但不放入output
                    //printf("found left in stack after right apear, stack size: %i \n",i_stack);
                    if(i_stack>0 && stack[i_stack-1].mainType==tokenMainTypeFunction){//如果stack頂是函數(會放入stack的只有函數跟左括號)
                        output[i_output++]=stack[--i_stack];

                        //printf("function move to output from stack after left found %i \n",i_stack);
                    }
                }
            }else if (it.subType==tokenSubType_Other_LeftParenthesis){//左括號
                stack[i_stack++]=it;
                //printf("push number %i th item (left) into stack\n",count);
                
            }
        }//括號與逗點
        else{//處理operator
            if (i_stack==0) {
                stack[i_stack++]=it;
                //printf("push operator (%i th)to blank stack\n",count);
            }else{
                
                while(i_stack>0 && stack[i_stack-1].subType!=tokenSubType_Other_LeftParenthesis && ![self priorityHigher_left:it.subType thanRight:stack[i_stack-1].subType]){
                    output[i_output++]=stack[--i_stack];
                    //這邊以後有可能stack變空的
                    printf("priority in stack top higher %i \n",i_stack);
                }
                stack[i_stack++]=it;
                //printf("push operator (%i th)to blank stack\n",count);
            }
            
            
        }//處理operator
    }
    //pop all from stack
    
    while(i_stack>0){
        if (stack[i_stack-1].subType==tokenSubType_Other_LeftParenthesis||stack[i_stack-1].subType==tokenSubType_Other_RightParenthesis) {
            if (errorPtr) {
                NSDictionary *userInfo=@{NSLocalizedDescriptionKey:@"parenthsis not matched.", ErrorKeyStage:ErrorStageInfixToPostfix ,ErrorKeyRange:[NSValue valueWithRange:stack[i_stack-1].range]};
                NSError *error=[NSError errorWithDomain:customErrorDomain code:RPNErrParenthesisNotMatched userInfo:userInfo];
                *errorPtr=error;
            }
            return nothing;

        }
        output[i_output++]=stack[--i_stack];

    }
    tokenLength_=i_output;
    return output;
}
-(float)valueOfRPN:(RPNToken*)tokens error:(NSError**)errorPtr{
    if (!tokens) {
        if (errorPtr) {
            NSDictionary *userInfo=@{NSLocalizedDescriptionKey:@"No notations parsed from string" ,ErrorKeyStage:ErrorStageReversedPolish};
            NSError *error=[NSError errorWithDomain:customErrorDomain code:RPNErrEmptyToken userInfo:userInfo];
            *errorPtr=error;
        }
        return FLT_MAX;
    }

    RPNToken stack[tokenLength_];
    int i_stack=0;
    for (int i=0;i<tokenLength_;i++){
        RPNToken it=tokens[i];
        if (it.mainType==tokenMainTypeNumber) {
            stack[i_stack++]=it;
        }//Number
        else{
            float newValue;
            if (it.mainType==tokenMainTypeOperator) {
                if (i_stack<2) {//operator always take 2 argument
                    if (errorPtr) {
                        NSDictionary *userInfo=@{NSLocalizedDescriptionKey:@"not enough argument for operator",ErrorKeyStage:ErrorStageReversedPolish ,ErrorKeyRange:[NSValue valueWithRange:it.range]};
                        NSError *error=[NSError errorWithDomain:customErrorDomain code:RPNErrNotEnoughArgument userInfo:userInfo];
                        *errorPtr=error;
                    }
                    return FLT_MAX;//exception;
                }
                RPNToken rightToken,leftToken;
                rightToken=stack[--i_stack];
                leftToken=stack[--i_stack];
                if (it.subType==tokenSubType_Operator_Plus) {
                    newValue=rightToken.value+leftToken.value;
                }else if (it.subType==tokenSubType_Operator_Minus){
                    newValue=leftToken.value-rightToken.value;
                }else if (it.subType==tokenSubType_Operator_Muiltiply){
                    newValue=leftToken.value*rightToken.value;
                }else if (it.subType==tokenSubType_Operator_Devide){
                    newValue=leftToken.value/rightToken.value;
                }else if (it.subType==tokenSubType_Operator_Power){
                    newValue=pow(leftToken.value,rightToken.value);
                }
                //comparison
                else if (it.subType==TokenSubtype_Operator_Smaller){
                    newValue=leftToken.value < rightToken.value;
                }else if (it.subType==TokenSubtype_Operator_SmallerEqual){
                    newValue=leftToken.value <= rightToken.value;
                }else if (it.subType==TokenSubtype_Operator_Equal){
                    newValue=leftToken.value == rightToken.value;
                }else if (it.subType==TokenSubtype_Operator_GreaterEqual){
                    newValue=leftToken.value >= rightToken.value;
                }else if (it.subType==TokenSubtype_Operator_Greater){
                    newValue=leftToken.value > rightToken.value;
                }else if (it.subType==TokenSubtype_Operator_NotEqual){
                    newValue=leftToken.value != rightToken.value;
                }else if (it.subType==TokenSubtype_Operator_Or){
                    newValue=leftToken.value || rightToken.value;
                }else if (it.subType==TokenSubtype_Operator_And){
                    newValue=leftToken.value && rightToken.value;
                }
            }//operator
            
            else{
                if (it.subType==TokenSubtype_function_unrecognized) {
                    //exception
                    if (errorPtr) {
                        NSDictionary *userInfo=@{NSLocalizedDescriptionKey:@"unrecognized function name", ErrorKeyStage:ErrorStageReversedPolish ,ErrorKeyRange:[NSValue valueWithRange:it.range]};
                        NSError *error=[NSError errorWithDomain:customErrorDomain code:RPNErrUnrecognizableFunction userInfo:userInfo];
                        *errorPtr=error;
                    }
                    return FLT_MAX;
                }
                FunctionMap *functor_map=[self.functions objectAtIndex:it.value];
                if (i_stack<functor_map.argumentNumber) {
                    if (errorPtr) {
                        NSDictionary *userInfo=@{NSLocalizedDescriptionKey:@"Not Enough Argument for function", ErrorKeyStage:ErrorStageReversedPolish ,ErrorKeyFunctionName:functor_map.name,ErrorKeyArgumentNumber:@(functor_map.argumentNumber),ErrorKeyRange:[NSValue valueWithRange:it.range]};
                        NSError *error=[NSError errorWithDomain:customErrorDomain code:RPNErrNotEnoughArgument userInfo:userInfo];
                        *errorPtr=error;
                    }
                    return FLT_MAX;//exception;
                }
                float arguments[ARG_SIZE];
                for (int j=0; j<functor_map.argumentNumber; j++) {// get argument from stack
                    float newArgument=stack[--i_stack].value;
                    arguments[j]=newArgument;//reversed sequence from stack
                    
                }
                newValue=functor_map.functionBlock(arguments); //use functor from map
            }//function
            RPNToken newToken;
            newToken.mainType=tokenMainTypeNumber;
            newToken.value=newValue;
            stack[i_stack++]=newToken;
            
        }
    }
    
    RPNToken stackTop=stack[i_stack-1];
    return stackTop.value;

}

#pragma mark -tokens
-(RPNToken)operatorTokenFromChar:(char)c{
    RPNToken token;
    switch (c) {
        case '+':
            token.mainType= tokenMainTypeOperator;
            token.subType=tokenSubType_Operator_Plus;
            token.value=0;
            break;
        case '-':
            token.mainType= tokenMainTypeOperator;
            token.subType=tokenSubType_Operator_Minus;
            token.value=0;
            break;
        case '*':
            token.mainType= tokenMainTypeOperator;
            token.subType=tokenSubType_Operator_Muiltiply;
            token.value=0;
            break;
        case '/':
            token.mainType= tokenMainTypeOperator;
            token.subType=tokenSubType_Operator_Devide;
            token.value=0;
            break;
        case '^':
            token.mainType= tokenMainTypeOperator;
            token.subType=tokenSubType_Operator_Power;
            token.value=0;
            break;
        case '(':
            token.mainType= tokenMainTypeOther;
            token.subType=tokenSubType_Other_LeftParenthesis;
            token.value=0;
            break;
        case ')':
            token.mainType= tokenMainTypeOther;
            token.subType=tokenSubType_Other_RightParenthesis;
            token.value=0;
            break;
        case ',':
            token.mainType= tokenMainTypeOther;
            token.subType=tokenSubType_Other_Comma;
            token.value=0;
            break;
        default:
            break;
    }
    
    
    return token;
}
-(RPNToken)numberTokenFromString:(NSString*)string{
    RPNToken token;
    float value=[string floatValue];
    token.mainType = tokenMainTypeNumber;
    token.subType = TokenSubtype_Default;
    token.value = value;
    return token;
}
-(RPNToken)operatorTokenFromString:(NSString*)string{
    RPNToken token;
    token.mainType = tokenMainTypeOperator;
    token.value = 0;
    if([string isEqualToString:@"<"]){
        token.subType = TokenSubtype_Operator_Smaller;
    }else if([string isEqualToString:@"<="]){
        token.subType = TokenSubtype_Operator_SmallerEqual;
    }else if([string isEqualToString:@"="]){
        token.subType = TokenSubtype_Operator_Equal;
    }else if([string isEqualToString:@">="]){
        token.subType = TokenSubtype_Operator_GreaterEqual;
    }else if([string isEqualToString:@">"]){
        token.subType = TokenSubtype_Operator_Greater;
    }else if([string isEqualToString:@"!="]){
        token.subType = TokenSubtype_Operator_NotEqual;
    }else if([string isEqualToString:@"||"]){
        token.subType = TokenSubtype_Operator_Or;
    }else if([string isEqualToString:@"|"]){
        token.subType = TokenSubtype_Operator_Or;
    }else if([string isEqualToString:@"&&"]){
        token.subType = TokenSubtype_Operator_And;
    }else if([string isEqualToString:@"&"]){
        token.subType = TokenSubtype_Operator_And;
    }else{
     //exception
        NSLog(@"unable to recognize opeartor string %@",string);
        token.subType=TokenSubtype_function_unrecognized;
    }

    return token;
}
-(RPNToken)functionTokenFromString:(NSString*)string{
    RPNToken token;
    token.mainType = tokenMainTypeFunction;
    token.subType = TokenSubtype_function_unrecognized;
    if (self.functions) {
        for (int i=0; i<self.functions.count; i++) {
            FunctionMap *map=[self.functions objectAtIndex:i];
            if ([string isEqualToString:map.name]) {
                token.value=i;
                token.subType = TokenSubtype_function;
                break;
            }
        }
    }
    return token;
}

#pragma mark -utility
-(BOOL)priorityHigher_left:(TokenSubtype)left thanRight:(TokenSubtype)right{
    int leftValue, rightValue;
    switch (left){
        case tokenSubType_Operator_Plus: case tokenSubType_Operator_Minus:
            leftValue=1;
            break;
        case tokenSubType_Operator_Muiltiply: case tokenSubType_Operator_Devide:
            leftValue=2;
            break;
        case tokenSubType_Operator_Power:
            leftValue=3;
            break;
        default:
            leftValue=0;
            break;
    }
    switch (right){
        case tokenSubType_Operator_Plus: case tokenSubType_Operator_Minus:
            rightValue=1;
            break;
        case tokenSubType_Operator_Muiltiply: case tokenSubType_Operator_Devide:
            rightValue=2;
            break;
        case tokenSubType_Operator_Power:
            rightValue=3;
            break;
        default:
            rightValue=0;
            break;
    }
    bool b=leftValue>rightValue;
    return b;
}
-(NSDictionary*)dictionaryFromRPNToken:(RPNToken)token{
    int mainType=token.mainType;
    int subType=token.subType;
    float value=token.value;
    return @{@"mainType":@(mainType),@"subType":@(subType),@"value":@(value)};
}
-(int)length{
    return tokenLength_;
    
}
@end
