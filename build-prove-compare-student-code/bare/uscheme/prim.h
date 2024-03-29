/* prim.h S312e */
xx("+", PLUS,  arith)
xx("-", MINUS, arith)
xx("*", TIMES, arith)
xx("/", DIV,   arith)
xx("<", LT,    arith)
xx(">", GT,    arith)
/* prim.h S313b */
xx("cons", CONS,     binary)
xx("=",    EQ,       binary)
xx("apply", APPLYFN, binary)          // NEW
//xx("list", LIST, binary)            // NEW
/* prim.h S314b */
xx("boolean?",   BOOLEANP,   unary)
xx("null?",      NULLP,      unary)
xx("number?",    NUMBERP,    unary)
xx("pair?",      PAIRP,      unary)
xx("function?",  FUNCTIONP,  unary)
xx("symbol?",    SYMBOLP,    unary)
xx("car",        CAR,        unary)
xx("cdr",        CDR,        unary)
xx("println",    PRINTLN,    unary)
xx("print",      PRINT,      unary)
xx("printu",     PRINTU,     unary)
xx("error",      ERROR,      unary)
xx("read",       READ,     mulnary) // NEW
// MULNARY FOR LIST // NEW
xx("list",       MAKELIST, mulnary) // NEW
