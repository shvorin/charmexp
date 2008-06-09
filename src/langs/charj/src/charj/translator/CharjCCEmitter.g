/**
 * ANTLR (v3) Tree Parser for the Charj Language
 */

tree grammar CharjCCEmitter;

options {
    backtrack = true; 
    memoize = true;
    tokenVocab = Charj;
    ASTLabelType = CommonTree;
    output = template;
//    rewrite = true;
}


@treeparser::header {
package charj.translator;
}

@treeparser::members {
    
    boolean mMessageCollectionEnabled = false;
    private boolean mHasErrors = false;
    List<String> mMessages;

    /**
     *  Switches error message collection on or off.
     *
     *  The standard destination for parser error messages is <code>System.err</code>.
     *  However, if <code>true</code> gets passed to this method this default
     *  behaviour will be switched off and all error messages will be collected
     *  instead of written to anywhere.
     *
     *  The default value is <code>false</code>.
     *
     *  @param pNewState  <code>true</code> if error messages should be collected.
     */
    public void enableErrorMessageCollection(boolean pNewState) {
        mMessageCollectionEnabled = pNewState;
        if (mMessages == null && mMessageCollectionEnabled) {
            mMessages = new ArrayList<String>();
        }
    }
    
    /**
     *  Collects an error message or passes the error message to <code>
     *  super.emitErrorMessage(...)</code>.
     *
     *  The actual behaviour depends on whether collecting error messages
     *  has been enabled or not.
     *
     *  @param pMessage  The error message.
     */
     @Override
    public void emitErrorMessage(String pMessage) {
        if (mMessageCollectionEnabled) {
            mMessages.add(pMessage);
        } else {
            super.emitErrorMessage(pMessage);
        }
    }
    
    /**
     *  Returns collected error messages.
     *
     *  @return  A list holding collected error messages or <code>null</code> if
     *           collecting error messages hasn't been enabled. Of course, this
     *           list may be empty if no error message has been emited.
     */
    public List<String> getMessages() {
        return mMessages;
    }
    
    /**
     *  Tells if parsing a Charj source has caused any error messages.
     *
     *  @return  <code>true</code> if parsing a Charj source has caused at 
     *           least one error message.
     */
    public boolean hasErrors() {
        return mHasErrors;
    }
}

// Starting point for parsing a Charj file.
charjSource
    :   ^(CHARJ_SOURCE (p=packageDeclaration)? (i+=importDeclaration)* (t+=typeDeclaration)*)
        -> charjSource(pd={$p.st}, ids={$i}, tds={$t})
    ;

packageDeclaration
    :   ^(PACKAGE qualifiedIdentifier)  
        -> template(t={$text}) "//<t>"
    ;
    
importDeclaration
    :   ^(IMPORT STATIC? qualifiedIdentifier DOTSTAR?)
        -> template(t={$text}) "//<t>"
    ;
    
typeDeclaration
    :   ^(CLASS m=modifierList IDENT g=genericTypeParameterList? e=classExtendsClause? i=implementsClause? c=classTopLevelScope) 
        -> classDeclaration(
            mod={$m.st}, 
            ident={$IDENT.text}, 
            gen={$g.st}, 
            ext={$e.st}, 
            impl={$i.st},
            ctls={$c.st})
    |   ^(INTERFACE modifierList IDENT genericTypeParameterList? interfaceExtendsClause? interfaceTopLevelScope)
        -> template(t={$text}) "<t>"
    |   ^(ENUM modifierList IDENT implementsClause? enumTopLevelScope)
        -> template(t={$text}) "<t>"
    ;


classExtendsClause
    :   ^(EXTENDS_CLAUSE t=type) 
        -> classExtends(type={$t.st})
    ;   

interfaceExtendsClause 
    :   ^(EXTENDS_CLAUSE (typeList+=type)+) 
        -> interfaceExtends(ts={$typeList})
    ;   
    
implementsClause
    :   ^(IMPLEMENTS_CLAUSE type+)
        -> template(t={$text}) "<t>"
    ;
        
genericTypeParameterList
    :   ^(GENERIC_TYPE_PARAM_LIST genericTypeParameter+)
        -> template(t={$text}) "<t>"
    ;

genericTypeParameter
    :   ^(IDENT bound?)
        -> template(t={$text}) "<t>"
    ;
        
bound
    :   ^(EXTENDS_BOUND_LIST type+)
        -> template(t={$text}) "<t>"
    ;

enumTopLevelScope
    :   ^(ENUM_TOP_LEVEL_SCOPE enumConstant+ classTopLevelScope?)
        -> template(t={$text}) "<t>"
    ;
    
enumConstant
    :   ^(IDENT arguments? classTopLevelScope?)
        -> template(t={$text}) "<t>"
    ;
    
    
classTopLevelScope
    :   ^(CLASS_TOP_LEVEL_SCOPE (csd+=classScopeDeclarations)*) 
        -> classTopLevelScope(classScopeDeclarations={$csd})
    ;
    
classScopeDeclarations
    :   ^(CLASS_INSTANCE_INITIALIZER block)
        -> template(t={$text}) "/*cii*/ <t>"
    |   ^(CLASS_STATIC_INITIALIZER block)
        -> template(t={$text}) "/*csi*/ <t>"
    |   ^(FUNCTION_METHOD_DECL m=modifierList g=genericTypeParameterList? 
            ty=type IDENT f=formalParameterList a=arrayDeclaratorList? 
            tt=throwsClause? b=block?)
        //-> template(t={$text}) "/*funcmethod*/ <t>"
        -> funcMethodDecl(
            modl={$m.st}, 
            gtpl={$g.st}, 
            ty={$t.text},
            id={$IDENT.text}, 
            fpl={$f.st}, 
            adl={$a.st},
            tc={$tt.st}, 
            block={$b.st})
    |   ^(VOID_METHOD_DECL m=modifierList g=genericTypeParameterList? IDENT 
            f=formalParameterList t=throwsClause? b=block?)
        -> voidMethodDecl(
            modl={$m.st}, 
            gtpl={$g.st}, 
            id={$IDENT.text}, 
            fpl={$f.st}, 
            tc={$t.st}, 
            block={$b.st})
// template(t={$text}) "/*voidmethod*/ <t>"
    |   ^(VAR_DECLARATION modifierList type variableDeclaratorList)
        -> template(t={$text}) "vardecl <t>"
    |   ^(CONSTRUCTOR_DECL m=modifierList g=genericTypeParameterList? IDENT f=formalParameterList 
            t=throwsClause? b=block)
        -> ctorDecl(
            modl={$m.st}, 
            gtpl={$g.st}, 
            id={$IDENT.text}, 
            fpl={$f.st}, 
            tc={$t.st}, 
            block={$b.st})
        //-> template(t={$text}) "ctor <t>"
    |   d=typeDeclaration
        -> template(t={$d.st}) "type <t>"
    ;
    
interfaceTopLevelScope
    :   ^(INTERFACE_TOP_LEVEL_SCOPE interfaceScopeDeclarations*)
        -> template(t={$text}) "<t>"
    ;
    
interfaceScopeDeclarations
    :   ^(FUNCTION_METHOD_DECL modifierList genericTypeParameterList? type IDENT formalParameterList arrayDeclaratorList? throwsClause?)
        -> template(t={$text}) "<t>"
    |   ^(VOID_METHOD_DECL modifierList genericTypeParameterList? IDENT formalParameterList throwsClause?)
        -> template(t={$text}) "<t>"
        // Interface constant declarations have been switched to variable
        // declarations by Charj.g; the parser has already checked that
        // there's an obligatory initializer.
    |   ^(VAR_DECLARATION modifierList type variableDeclaratorList)
        -> template(t={$text}) "<t>"
    |   typeDeclaration
        -> template(t={$text}) "<t>"
    ;

variableDeclaratorList
    :   ^(VAR_DECLARATOR_LIST variableDeclarator+)
        -> template(t={$text}) "<t>"
    ;

variableDeclarator
    :   ^(VAR_DECLARATOR variableDeclaratorId variableInitializer?)
        -> template(t={$text}) "<t>"
    ;
    
variableDeclaratorId
    :   ^(IDENT arrayDeclaratorList?)
        -> template(t={$text}) "<t>"
    ;

variableInitializer
    :   arrayInitializer
        -> template(t={$text}) "<t>"
    |   expression
        -> template(t={$text}) "<t>"
    ;

arrayDeclarator
    :   LBRACK RBRACK
        -> template(t={$text}) "<t>"
    ;

arrayDeclaratorList
    :   ^(ARRAY_DECLARATOR_LIST ARRAY_DECLARATOR*)  
        -> template(t={$text}) "<t>"
    ;
    
arrayInitializer
    :   ^(ARRAY_INITIALIZER variableInitializer*)
        -> template(t={$text}) "<t>"
    ;

throwsClause
    :   ^(THROWS_CLAUSE qualifiedIdentifier+)
        -> template(t={$text}) "<t>"
    ;

modifierList
    :   ^(MODIFIER_LIST (m+=modifier)*)
        -> template(mod={$m}) "<mod; separator=\" \">"
    ;

modifier
    :   PUBLIC
        -> template(t={$text}) "<t>"
    |   PROTECTED
        -> template(t={$text}) "<t>"
    |   PRIVATE
        -> template(t={$text}) "<t>"
    |   ENTRY
        -> template() "public"
    |   STATIC
        -> template(t={$text}) "<t>"
    |   ABSTRACT
        -> template(t={$text}) "<t>"
    |   NATIVE
        -> template(t={$text}) "<t>"
    |   SYNCHRONIZED
        -> template(t={$text}) "<t>"
    |   TRANSIENT
        -> template(t={$text}) "<t>"
    |   VOLATILE
        -> template(t={$text}) "<t>"
    |   localModifier
        -> template(t={$text}) "<t>"
    ;

localModifierList
    :   ^(LOCAL_MODIFIER_LIST localModifier*)
        -> template(t={$text}) "<t>"
    ;

localModifier
    :   FINAL
        -> template(t={$text}) "<t>"
    ;

type
    :   ^(TYPE (primitiveType | qualifiedTypeIdent) arrayDeclaratorList?) 
        -> template(t={$text}) "<t>"
    ;

qualifiedTypeIdent
    :   ^(QUALIFIED_TYPE_IDENT typeIdent+) 
        -> template(t={$text}) "<t>"
    ;

typeIdent
    :   ^(IDENT genericTypeArgumentList?)
        -> template(t={$text}) "<t>"
    ;

primitiveType
    :   BOOLEAN
        -> template(t={$text}) "<t>"
    |   CHAR
        -> template(t={$text}) "<t>"
    |   BYTE
        -> template(t={$text}) "<t>"
    |   SHORT
        -> template(t={$text}) "<t>"
    |   INT
        -> template(t={$text}) "<t>"
    |   LONG
        -> template(t={$text}) "<t>"
    |   FLOAT
        -> template(t={$text}) "<t>"
    |   DOUBLE
        -> template(t={$text}) "<t>"
    ;

genericTypeArgumentList
    :   ^(GENERIC_TYPE_ARG_LIST genericTypeArgument+)
        -> template(t={$text}) "<t>"
    ;
    
genericTypeArgument
    :   type
        -> template(t={$text}) "<t>"
    |   ^(QUESTION genericWildcardBoundType?)
        -> template(t={$text}) "<t>"
    ;

genericWildcardBoundType                                                                                                                      
    :   ^(EXTENDS type)
        -> template(t={$text}) "<t>"
    |   ^(SUPER type)
        -> template(t={$text}) "<t>"
    ;

formalParameterList
    :   ^(FORMAL_PARAM_LIST formalParameterStandardDecl* formalParameterVarargDecl?) 
        -> template(t={$text}) "<t>"
    ;
    
formalParameterStandardDecl
    :   ^(FORMAL_PARAM_STD_DECL localModifierList type variableDeclaratorId)
        -> template(t={$text}) "<t>"
    ;
    
formalParameterVarargDecl
    :   ^(FORMAL_PARAM_VARARG_DECL localModifierList type variableDeclaratorId)
        -> template(t={$text}) "<t>"
    ;
    
qualifiedIdentifier
    :   IDENT
        -> template(t={$text}) "<t>"
    |   ^(DOT qualifiedIdentifier IDENT)
        -> template(t={$text}) "<t>"
    ;
    
block
    :   ^(BLOCK_SCOPE blockStatement*)
        -> template(t={$text}) "<t>"
    ;
    
blockStatement
    :   localVariableDeclaration
        -> template(t={$text}) "<t>"
    |   typeDeclaration
        -> template(t={$text}) "<t>"
    |   statement
        -> template(t={$text}) "<t>"
    ;
    
localVariableDeclaration
    :   ^(VAR_DECLARATION localModifierList type variableDeclaratorList)
        -> template(t={$text}) "<t>"
    ;
    
        
statement
    :   block
        -> template(t={$text}) "<t>"
    |   ^(ASSERT expression expression?)
        -> template(t={$text}) "<t>"
    |   ^(IF parenthesizedExpression statement statement?)
        -> template(t={$text}) "<t>"
    |   ^(FOR forInit forCondition forUpdater statement)
        -> template(t={$text}) "<t>"
    |   ^(FOR_EACH localModifierList type IDENT expression statement) 
        -> template(t={$text}) "<t>"
    |   ^(WHILE parenthesizedExpression statement)
        -> template(t={$text}) "<t>"
    |   ^(DO statement parenthesizedExpression)
        -> template(t={$text}) "<t>"
    |   ^(TRY block catches? block?)  // The second optional block is the optional finally block.
        -> template(t={$text}) "<t>"
    |   ^(SWITCH parenthesizedExpression switchBlockLabels)
        -> template(t={$text}) "<t>"
    |   ^(SYNCHRONIZED parenthesizedExpression block)
        -> template(t={$text}) "<t>"
    |   ^(RETURN expression?)
        -> template(t={$text}) "<t>"
    |   ^(THROW expression)
        -> template(t={$text}) "<t>"
    |   ^(BREAK IDENT?)
        -> template(t={$text}) "<t>"
    |   ^(CONTINUE IDENT?)
        -> template(t={$text}) "<t>"
    |   ^(LABELED_STATEMENT IDENT statement)
        -> template(t={$text}) "<t>"
    |   expression
        -> template(t={$text}) "<t>"
    |   SEMI // Empty statement.
        -> template(t={$text}) "<t>"
    ;
        
catches
    :   ^(CATCH_CLAUSE_LIST catchClause+)
        -> template(t={$text}) "<t>"
    ;
    
catchClause
    :   ^(CATCH formalParameterStandardDecl block)
        -> template(t={$text}) "<t>"
    ;

switchBlockLabels
    :   ^(SWITCH_BLOCK_LABEL_LIST switchCaseLabel* switchDefaultLabel? switchCaseLabel*)
        -> template(t={$text}) "<t>"
    ;
        
switchCaseLabel
    :   ^(CASE expression blockStatement*)
        -> template(t={$text}) "<t>"
    ;
    
switchDefaultLabel
    :   ^(DEFAULT blockStatement*)
        -> template(t={$text}) "<t>"
    ;
    
forInit
    :   ^(FOR_INIT (localVariableDeclaration | expression*)?)
        -> template(t={$text}) "<t>"
    ;
    
forCondition
    :   ^(FOR_CONDITION expression?)
        -> template(t={$text}) "<t>"
    ;
    
forUpdater
    :   ^(FOR_UPDATE expression*)
        -> template(t={$text}) "<t>"
    ;
    
// EXPRESSIONS

parenthesizedExpression
    :   ^(PARENTESIZED_EXPR expression)
        -> template(t={$text}) "<t>"
    ;
    
expression
    :   ^(EXPR expr)
        -> template(t={$text}) "<t>"
    ;

expr
    :   ^(ASSIGN expr expr)
        -> template(t={$text}) "<t>"
    |   ^(PLUS_ASSIGN expr expr)
        -> template(t={$text}) "<t>"
    |   ^(MINUS_ASSIGN expr expr)
        -> template(t={$text}) "<t>"
    |   ^(STAR_ASSIGN expr expr)
        -> template(t={$text}) "<t>"
    |   ^(DIV_ASSIGN expr expr)
        -> template(t={$text}) "<t>"
    |   ^(AND_ASSIGN expr expr)
        -> template(t={$text}) "<t>"
    |   ^(OR_ASSIGN expr expr)
        -> template(t={$text}) "<t>"
    |   ^(XOR_ASSIGN expr expr)
        -> template(t={$text}) "<t>"
    |   ^(MOD_ASSIGN expr expr)
        -> template(t={$text}) "<t>"
    |   ^(BIT_SHIFT_RIGHT_ASSIGN expr expr)
        -> template(t={$text}) "<t>"
    |   ^(SHIFT_RIGHT_ASSIGN expr expr)
        -> template(t={$text}) "<t>"
    |   ^(SHIFT_LEFT_ASSIGN expr expr)
        -> template(t={$text}) "<t>"
    |   ^(QUESTION expr expr expr)
        -> template(t={$text}) "<t>"
    |   ^(LOGICAL_OR expr expr)
        -> template(t={$text}) "<t>"
    |   ^(LOGICAL_AND expr expr)
        -> template(t={$text}) "<t>"
    |   ^(OR expr expr)
        -> template(t={$text}) "<t>"
    |   ^(XOR expr expr)
        -> template(t={$text}) "<t>"
    |   ^(AND expr expr)
        -> template(t={$text}) "<t>"
    |   ^(EQUAL expr expr)
        -> template(t={$text}) "<t>"
    |   ^(NOT_EQUAL expr expr)
        -> template(t={$text}) "<t>"
    |   ^(INSTANCEOF expr type)
        -> template(t={$text}) "<t>"
    |   ^(LESS_OR_EQUAL expr expr)
        -> template(t={$text}) "<t>"
    |   ^(GREATER_OR_EQUAL expr expr)
        -> template(t={$text}) "<t>"
    |   ^(BIT_SHIFT_RIGHT expr expr)
        -> template(t={$text}) "<t>"
    |   ^(SHIFT_RIGHT expr expr)
        -> template(t={$text}) "<t>"
    |   ^(GREATER_THAN expr expr)
        -> template(t={$text}) "<t>"
    |   ^(SHIFT_LEFT expr expr)
        -> template(t={$text}) "<t>"
    |   ^(LESS_THAN expr expr)
        -> template(t={$text}) "<t>"
    |   ^(PLUS expr expr)
        -> template(t={$text}) "<t>"
    |   ^(MINUS expr expr)
        -> template(t={$text}) "<t>"
    |   ^(STAR expr expr)
        -> template(t={$text}) "<t>"
    |   ^(DIV expr expr)
        -> template(t={$text}) "<t>"
    |   ^(MOD expr expr)
        -> template(t={$text}) "<t>"
    |   ^(UNARY_PLUS expr)
        -> template(t={$text}) "<t>"
    |   ^(UNARY_MINUS expr)
        -> template(t={$text}) "<t>"
    |   ^(PRE_INC expr)
        -> template(t={$text}) "<t>"
    |   ^(PRE_DEC expr)
        -> template(t={$text}) "<t>"
    |   ^(POST_INC expr)
        -> template(t={$text}) "<t>"
    |   ^(POST_DEC expr)
        -> template(t={$text}) "<t>"
    |   ^(NOT expr)
        -> template(t={$text}) "<t>"
    |   ^(LOGICAL_NOT expr)
        -> template(t={$text}) "<t>"
    |   ^(CAST_EXPR type expr)
        -> template(t={$text}) "<t>"
    |   primaryExpression
        -> template(t={$text}) "<t>"
    ;
    
primaryExpression
    :   ^(  DOT
            (   primaryExpression
                (   IDENT
                |   THIS
                |   SUPER
                |   innerNewExpression
                |   CLASS
                )
            |   primitiveType CLASS
            |   VOID CLASS
            )
        )
        -> template(t={$text}) "<t>"
    |   parenthesizedExpression
        -> template(t={$text}) "<t>"
    |   IDENT
        -> template(t={$text}) "<t>"
    |   ^(METHOD_CALL primaryExpression genericTypeArgumentList? arguments)
        -> template(t={$text}) "<t>"
    |   explicitConstructorCall
        -> template(t={$text}) "<t>"
    |   ^(ARRAY_ELEMENT_ACCESS primaryExpression expression)
        -> template(t={$text}) "<t>"
    |   literal
        -> template(t={$text}) "<t>"
    |   newExpression
        -> template(t={$text}) "<t>"
    |   THIS
        -> template(t={$text}) "<t>"
    |   arrayTypeDeclarator
        -> template(t={$text}) "<t>"
    |   SUPER
        -> template(t={$text}) "<t>"
    ;
    
explicitConstructorCall
    :   ^(THIS_CONSTRUCTOR_CALL genericTypeArgumentList? arguments)
        -> template(t={$text}) "<t>"
    |   ^(SUPER_CONSTRUCTOR_CALL primaryExpression? genericTypeArgumentList? arguments)
        -> template(t={$text}) "<t>"
    ;

arrayTypeDeclarator
    :   ^(ARRAY_DECLARATOR (arrayTypeDeclarator | qualifiedIdentifier | primitiveType))
        -> template(t={$text}) "<t>"
    ;

newExpression
    :   ^(  STATIC_ARRAY_CREATOR
            (   primitiveType newArrayConstruction
            |   genericTypeArgumentList? qualifiedTypeIdent newArrayConstruction
            )
        )
        -> template(t={$text}) "<t>"
    |   ^(CLASS_CONSTRUCTOR_CALL genericTypeArgumentList? qualifiedTypeIdent arguments classTopLevelScope?)
        -> template(t={$text}) "<t>"
    ;

innerNewExpression // something like 'InnerType innerType = outer.new InnerType();'
    :   ^(CLASS_CONSTRUCTOR_CALL genericTypeArgumentList? IDENT arguments classTopLevelScope?)
        -> template(t={$text}) "<t>"
    ;
    
newArrayConstruction
    :   arrayDeclaratorList arrayInitializer
        -> template(t={$text}) "<t>"
    |   expression+ arrayDeclaratorList?
        -> template(t={$text}) "<t>"
    ;

arguments
    :   ^(ARGUMENT_LIST expression*)
        -> template(t={$text}) "<t>"
    ;

literal 
    :   HEX_LITERAL
        -> template(t={$text}) "<t>"
    |   OCTAL_LITERAL
        -> template(t={$text}) "<t>"
    |   DECIMAL_LITERAL
        -> template(t={$text}) "<t>"
    |   FLOATING_POINT_LITERAL
        -> template(t={$text}) "<t>"
    |   CHARACTER_LITERAL
        -> template(t={$text}) "<t>"
    |   STRING_LITERAL
        -> template(t={$text}) "<t>"
    |   TRUE
        -> template(t={$text}) "<t>"
    |   FALSE
        -> template(t={$text}) "<t>"
    |   NULL
        -> template(t={$text}) "<t>"
    ;