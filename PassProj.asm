
; Password Strength Checker

.MODEL SMALL
.DATA
    Username DB 21 DUP('$')
    Password DB 21 DUP('$')

    UserMsg DB "Enter Username: $"
    Msg DB 10, "Enter Password: $"
    StrongMsg DB 10,10, "Your Password is Strong$", 0
    GoodMsg DB 10,10, "Your Password is Good$", 0
    WeakMsg DB 10,10, "Your password is weak. Here are some feedback suggestions about your password: $", 0
    SameAsUsernameMsg DB 10,10, "Password cannot be the same as Username$", 0
    LockoutMsg DB 10,10, "Too many failed attempts. You are locked out.$", 0

    MissingLowerMsg DB "Missing lowercase letters$", 0
    MissingUpperMsg DB 10, "Missing uppercase letters$", 0
    MissingDigitMsg DB 10, "Missing digits$", 0
    MissingSpecialMsg DB 10, "Missing special characters$", 0

    MinLength DW 8
    hasLower DB 0
    hasUpper DB 0
    hasDigit DB 0
    hasSpecial DB 0 
    Score DB 0
    
    WeakCounter DB 0

.STACK 64

.CODE
MAIN PROC FAR
    .startup

UserNamelabel:
    LEA DX, UserMsg
    MOV AH, 09H
    INT 21H

    LEA DX, Username
    MOV AH, 0AH
    INT 21H

PasswordLabel:
    LEA DX, Msg
    MOV AH, 09H
    INT 21H

    CALL PasswordInput
    CALL CheckUsername

PasswordChecker:
    MOV hasLower, 0
    MOV hasUpper, 0
    MOV hasDigit, 0
    MOV hasSpecial, 0

    LEA DI, Password
    ADD DI, 2
    MOV CL, [Password + 1]
    XOR CH, CH

PasswordLoop:
    JCXZ CheckScore

    MOV AL, [DI]
    CALL CheckChars
    INC DI
    LOOP PasswordLoop

CheckScore:
    XOR AL, AL

    MOV BL, [Password+1]
    CMP BX, MinLength
    JL WeakWithFeedback

    ADD AL, hasLower
    ADD AL, hasUpper
    ADD AL, hasDigit
    ADD AL, hasSpecial
    MOV Score, AL

    CMP Score, 2
    JLE WeakWithFeedback
    
    CMP Score, 3
    JE Good

    JMP Strong

WeakWithFeedback:
    LEA DX, WeakMsg
    MOV AH, 09H
    INT 21H

    CMP hasLower, 0
    JNE CheckUppercase
    LEA DX, MissingLowerMsg
    MOV AH, 09H
    INT 21H

CheckUppercase:
    CMP hasUpper, 0
    JNE CheckDigits
    LEA DX, MissingUpperMsg
    MOV AH, 09H
    INT 21H

CheckDigits:
    CMP hasDigit, 0
    JNE CheckSpecials
    LEA DX, MissingDigitMsg
    MOV AH, 09H
    INT 21H

CheckSpecials:
    CMP hasSpecial, 0
    JNE RetryPassword
    LEA DX, MissingSpecialMsg
    MOV AH, 09H
    INT 21H

RetryPassword:
    INC WeakCounter
    MOV AL, WeakCounter
    CMP AL, 3
    JE Lockout
    
    JMP PasswordLabel

Lockout:
    LEA DX, LockoutMsg
    MOV AH, 09H
    INT 21H
    JMP Exit

Good:
    LEA DX, GoodMsg
    MOV AH, 09H
    INT 21H
    JMP Exit

Strong:
    LEA DX, StrongMsg
    MOV AH, 09H
    INT 21H
    JMP Exit

Exit:
    .exit
MAIN ENDP

PasswordInput PROC NEAR
    MOV CX, 0
    LEA DI, Password + 2
    
InputLoop:
    MOV AH, 07H
    INT 21H

    CMP AL, 0DH
    JE EndInput 
    
    CMP AL, 08H
    JE HandleBackspace
    
    CMP CX, 20
    JGE InputLoop
    
    MOV [DI], AL
    INC DI
    INC CX

    MOV DL, '*'
    MOV AH, 02H
    INT 21H

    JMP InputLoop

    
HandleBackspace:
    CMP CX, 0
    JE InputLoop
    
    DEC DI
    DEC CX

    MOV DL, 08H
    MOV AH, 02H
    INT 21H
    MOV DL, ' '
    MOV AH, 02H
    INT 21H
    MOV DL, 08H
    MOV AH, 02H
    INT 21H

    JMP InputLoop
    
    
EndInput:
    MOV [Password + 1], CL
    RET
PasswordInput ENDP

CheckUsername PROC NEAR
    LEA SI, Username
    LEA DI, Password


    MOV AL, [SI + 1]
    CMP AL, [DI + 1]
    JNE NotSame

    MOV CL, AL
    ADD SI, 2
    ADD DI, 2

CompareLoop:
    JCXZ PasswordIsSame
    MOV AH, [SI]
    MOV BH, [DI]
    CMP AH, BH
    JNE NotSame
    INC SI
    INC DI
    LOOP CompareLoop

PasswordIsSame:
    LEA DX, SameAsUsernameMsg
    MOV AH, 09H
    INT 21H
    JMP PasswordLabel

NotSame:
    RET
CheckUsername ENDP

CheckChars PROC NEAR
CheckLower:
    CMP AL, 'a'
    JL CheckUpper
    CMP AL, 'z'
    JG CheckUpper
    MOV hasLower, 1
    JMP EndCharCheck

CheckUpper:
    CMP AL, 'A'
    JL CheckDigit
    CMP AL, 'Z'
    JG CheckDigit
    MOV hasUpper, 1
    JMP EndCharCheck

CheckDigit:
    CMP AL, '0'
    JL CheckSpecial
    CMP AL, '9'
    JG CheckSpecial
    MOV hasDigit, 1
    JMP EndCharCheck

CheckSpecial:
    CMP AL, '!'
    JE MarkSpecial
    CMP AL, '@'
    JE MarkSpecial
    CMP AL, '#'
    JE MarkSpecial
    CMP AL, '&'
    JE MarkSpecial
    JMP EndCharCheck

MarkSpecial:
    MOV hasSpecial, 1

EndCharCheck:
    RET
CheckChars ENDP

END MAIN
