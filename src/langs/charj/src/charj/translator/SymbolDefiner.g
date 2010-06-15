
tree grammar SymbolDefiner;

options {
    tokenVocab = Charj;
    ASTLabelType = CharjAST;
    filter = true;
}

@header {
package charj.translator;
}

@members {
    SymbolTable symtab;
    Scope currentScope;
    ClassSymbol currentClass;

    public SymbolDefiner(TreeNodeStream input, SymbolTable symtab) {
        this(input);
        this.symtab = symtab;
        this.currentScope = symtab.getDefaultPkg();
    }
}


topdown
    :   enterClass
    |   enterMethod
    |   enterBlock
    |   varDeclaration
    |   type
    |   atoms
    ;

bottomup
    :   exitClass
    |   exitMethod
    |   exitBlock
    ;

enterBlock
    :   BLOCK {
            currentScope = new LocalScope(symtab, currentScope);
        }
    ;

exitBlock
    :   BLOCK {
            //System.out.println("exiting block scope, members: " + currentScope);
            currentScope = currentScope.getEnclosingScope();
        }
    ;

enterMethod
@init {
boolean entry = false;
}
    :   ^((FUNCTION_METHOD_DECL | ENTRY_FUNCTION_DECL {entry = true;})
            (^(MODIFIER_LIST .*))?
            (^(GENERIC_TYPE_PARAM_LIST .*))? 
            type IDENT .*)
        {
            //System.out.println("entering method scope " + $IDENT.text);
            String typeName = $type.typeName;
            if (typeName == null) {
                /*System.out.println("Warning: return type of " + $IDENT.text + " has null text, using void");*/
                typeName = "void";
            }
            Type returnType = currentScope.resolveType(typeName);
            //System.out.println("Resolving type " + typeName + " in scope " + currentScope + "->" + returnType);
            MethodSymbol sym = new MethodSymbol(symtab, $IDENT.text, currentClass, returnType);
            sym.isEntry = entry;
            sym.definition = $enterMethod.start;
            sym.definitionTokenStream = input.getTokenStream();
            currentScope.define($IDENT.text, sym);
            $IDENT.def = sym;
            currentScope = sym;
            $IDENT.scope = currentScope;
            //System.out.println(currentScope);
        }
    |   ^((CONSTRUCTOR_DECL | ENTRY_CONSTRUCTOR_DECL {entry = true;})
            (^(MODIFIER_LIST .*))?
            (^(GENERIC_TYPE_PARAM_LIST .*))? 
            IDENT .*)
        {
            //System.out.println("entering constructor scope " + $IDENT.text);
            MethodSymbol sym = new MethodSymbol(symtab, $IDENT.text, currentClass, currentClass);
            sym.isEntry = entry;
            sym.isCtor = true;
            sym.definition = $enterMethod.start;
            sym.definitionTokenStream = input.getTokenStream();
            currentScope.define($IDENT.text, sym);
            $IDENT.def = sym;
            currentScope = sym;
            $IDENT.scope = currentScope;
            //System.out.println(currentScope);
        }
    ;

exitMethod
    :   ^((FUNCTION_METHOD_DECL | ENTRY_FUNCTION_DECL | CONSTRUCTOR_DECL | ENTRY_CONSTRUCTOR_DECL) .*) {
            //System.out.println("method " + currentScope);
            currentScope = currentScope.getEnclosingScope();
        }
    ;



enterClass
    :   ^(TYPE classType IDENT
            (^('extends' parent=type))?
            (^('implements' type+))?
            (^((FUNCTION_METHOD_DECL | ENTRY_FUNCTION_DECL | PRIMITIVE_VAR_DECLARATION |
                OBJECT_VAR_DECLARATION | CONSTRUCTOR_DECL | ENTRY_CONSTRUCTOR_DECL) .*))*)
        {
            //System.out.println("Entering class scope");
            ClassSymbol sym = new ClassSymbol(symtab, $IDENT.text,
                    (ClassSymbol)currentScope.resolveType($parent.text), currentScope);
            currentScope.define(sym.name, sym);
            currentClass = sym;
            sym.definition = $IDENT;
            sym.definitionTokenStream = input.getTokenStream();
            $IDENT.def = sym;
            currentScope = sym;
            $IDENT.scope = currentScope;
            $IDENT.symbolType = sym;
            String classTypeName = $classType.text;
            if (classTypeName.equals("class")) {
            } else if (classTypeName.equals("chare")) {
                currentClass.isChare = true;
            } else if (classTypeName.equals("group")) {
                currentClass.isChare = true;
            } else if (classTypeName.equals("nodegroup")) {
                currentClass.isChare = true;
            } else if (classTypeName.equals("chare_array")) {
                // TODO: test this; might need to use startswith instead of equals
                currentClass.isChare = true;
            } else if (classTypeName.equals("mainchare")) {
                currentClass.isChare = true;
                currentClass.isMainChare = true;
            } else System.out.println("Error: type " + classTypeName + " not recognized.");
        }
    ;

exitClass
    :   ^(TYPE classType IDENT
            (^('extends' parent=type))?
            (^('implements' type+))?
            (^((FUNCTION_METHOD_DECL | ENTRY_FUNCTION_DECL | PRIMITIVE_VAR_DECLARATION |
                OBJECT_VAR_DECLARATION | CONSTRUCTOR_DECL | ENTRY_CONSTRUCTOR_DECL) .*))*)
        {
            //System.out.println("class " + currentScope);
            currentScope = currentScope.getEnclosingScope();
        }
    ;

varDeclaration
    :   ^((PRIMITIVE_VAR_DECLARATION | OBJECT_VAR_DECLARATION)
            (^(MODIFIER_LIST .*))? type
            ^(VAR_DECLARATOR_LIST (^(VAR_DECLARATOR ^(IDENT .*) .*)
            {
                Type varType = currentScope.resolveType($type.typeName);
                /*System.out.println("Defining var " + $IDENT.text + " with type " + varType + " typename " + $type.typeName);*/
                VariableSymbol sym = new VariableSymbol(symtab, $IDENT.text, varType);
                sym.definition = $IDENT;
                sym.definitionTokenStream = input.getTokenStream();
                $IDENT.def = sym;
                $IDENT.scope = currentScope;
                $IDENT.symbolType = varType;
                currentScope.define($IDENT.text, sym);
            }
            )+))
    |   ^(FORMAL_PARAM_STD_DECL (^(MODIFIER_LIST .*))? type ^(IDENT .*))
        {
            Type varType = currentScope.resolveType($type.typeName);
            /*System.out.println("Defining argument var " + $IDENT.text + " with type " + varType);*/
            VariableSymbol sym = new VariableSymbol(symtab, $IDENT.text,
                    currentScope.resolveType($type.typeName));
            sym.definition = $IDENT;
            sym.definitionTokenStream = input.getTokenStream();
            $IDENT.def = sym;
            $IDENT.scope = currentScope;
            $IDENT.symbolType = varType;
            currentScope.define($IDENT.text, sym);
        }
    ;


type returns [String typeName]
@init {
    $typeName = "";
    if (currentScope == null) System.out.println("*****ERROR: null type scope");
    assert currentScope != null;
}
@after {
    $typeName = $typeName.substring(1);
}
    :   VOID {
            $VOID.scope = currentScope;
            $typeName = ".void";
        }
    |   ^(SIMPLE_TYPE t=. .*) {
            $SIMPLE_TYPE.scope = currentScope;
            $typeName = "." + $t;
        }
    |   ^(OBJECT_TYPE ^(QUALIFIED_TYPE_IDENT (^(IDENT {$typeName += "." + $IDENT.text;} .*))+) .*)
            { $OBJECT_TYPE.scope = currentScope; }
    |   ^(REFERENCE_TYPE ^(QUALIFIED_TYPE_IDENT (^(IDENT {$typeName += "." + $IDENT.text;} .*))+) .*)
            { $REFERENCE_TYPE.scope = currentScope; }
    |   ^(PROXY_TYPE ^(QUALIFIED_TYPE_IDENT (^(IDENT {$typeName += "." + $IDENT.text;} .*))+) .*)
            { $PROXY_TYPE.scope = currentScope; }
    |   ^(POINTER_TYPE ^(QUALIFIED_TYPE_IDENT (^(IDENT {$typeName += "." + $IDENT.text;} .*))+) .*)
            { $POINTER_TYPE.scope = currentScope; }
    ;

classType
    :   CLASS
    |   CHARE
    |   GROUP
    |   NODEGROUP
    |   MAINCHARE
    |   ^(CHARE_ARRAY ARRAY_DIMENSION)
    ;

atoms
@init {CharjAST t = (CharjAST)input.LT(1);}
    :  (IDENT|THIS|SUPER) {
            assert currentScope != null;
            t.scope = currentScope;
       }
    ;