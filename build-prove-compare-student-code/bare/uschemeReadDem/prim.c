#include "all.h"
/* prim.c ((elided)) (THIS CAN'T HAPPEN -- claimed code was not used) */
static int32_t divide(int32_t n, int32_t m);

/* prim.c 161a */
static int32_t projectint32(Exp e, Value v) {
    if (v.alt != NUM)
        runerror("in %e, expected an integer, but got %v", e, v);
    return v.num;
}

static Value make_list(Valuelist args);

/* prim.c 161b */
Value arith(Exp e, int tag, Valuelist args) {
    checkargc(e, 2, lengthVL(args));
    int32_t n = projectint32(e, nthVL(args, 0));
    int32_t m = projectint32(e, nthVL(args, 1));

    switch (tag) {                                       // OMIT
    case PLUS:                                           // OMIT
        checkarith('+', n, m, 32); // OMIT               // OMIT
        break;                                           // OMIT
    case MINUS:                                          // OMIT
        checkarith('-', n, m, 32); // OMIT               // OMIT
        break;                                           // OMIT
    case TIMES:                                          // OMIT
        checkarith('*', n, m, 32); // OMIT               // OMIT
        break;                                           // OMIT
    case DIV:                                            // OMIT
        if (m != 0) checkarith('/', n, m, 32); // OMIT   // OMIT
        break;                                           // OMIT
    default:                                             // OMIT
        break;                                           // OMIT
    }                                                    // OMIT
    switch (tag) {
    case PLUS:  return mkNum(n + m);
    case MINUS: return mkNum(n - m);
    case TIMES: return mkNum(n * m);
    case DIV:   if (m==0) runerror("division by zero");
                else return mkNum(divide(n, m));  // round to minus infinity
    case LT:    return mkBoolv(n < m);
    case GT:    return mkBoolv(n > m);
    default:    assert(0);
    }
}
/* prim.c 161c */
Value cons(Value v, Value w) {
    return mkPair(allocate(v), allocate(w));
}
/* prim.c 162a */
Value unary(Exp e, int tag, Valuelist args) {
    checkargc(e, 1, lengthVL(args));
    Value v = nthVL(args, 0);
    switch (tag) {
    case NULLP:
        return mkBoolv(v.alt == NIL);
    case CAR:
        if (v.alt == NIL)
            runerror("in %e, car applied to empty list", e);
        else if (v.alt != PAIR)
            runerror("car applied to non-pair %v in %e", v, e);
        return *v.pair.car;
    case PRINTU:
        if (v.alt != NUM)
            runerror("printu applied to non-number %v in %e", v, e);
        print_utf8(v.num);
        return v;
    case ERROR:
        runerror("%v", v);
        return v;
    /* other cases for unary primitives S314c */
    case BOOLEANP:
        return mkBoolv(v.alt == BOOLV);
    case NUMBERP:
        return mkBoolv(v.alt == NUM);
    case SYMBOLP:
        return mkBoolv(v.alt == SYM);
    case PAIRP:
        return mkBoolv(v.alt == PAIR);
    case FUNCTIONP:
        return mkBoolv(v.alt == CLOSURE || v.alt == PRIMITIVE);
    /* other cases for unary primitives S315a */
    case CDR:
        if (v.alt == NIL)
            runerror("in %e, cdr applied to empty list", e);
        else if (v.alt != PAIR)
            runerror("cdr applied to non-pair %v in %e", v, e);
        return *v.pair.cdr;
    case PRINTLN:
        print("%v\n", v);
        return v;
    case PRINT:
        print("%v", v);
        return v;
    case READ:
    {
        int32_t val;
        if (scanf("%d", &val) != 1) {
            runerror("failed to read an integer in %e", e);
        }
        return mkNum(val);
    }
    default:
        assert(0);
    }
}
/* prim.c S313a */
static int32_t divide(int32_t n, int32_t m) {
    if (n >= 0)
        if (m >= 0)
            return n / m;
        else
            return -(( n - m - 1) / -m);
    else
        if (m >= 0)
            return -((-n + m - 1) /  m);
        else
            return -n / -m;
}

Valuelist asValuelist(Value list) {
    // Base case: if list is empty (NIL), end recursion.
    if (list.alt == NIL) {
        return NULL;
    }

    // Ensure we are dealing with a pair (cons cell) before proceeding.
    if (list.alt != PAIR) {
        runerror("Expected a pair, but got %v", list);
    }

    Value current_head = *list.pair.car;
    Value current_tail = *list.pair.cdr;

    // Recursive call, ensuring that it moves towards the base case.
    return mkVL(current_head, asValuelist(current_tail));
}

Value apply(Exp e, Value fun, Value args) {
    // Check if the first argument is a function (closure or primitive)
    if (fun.alt != CLOSURE && fun.alt != PRIMITIVE) {
        runerror("in %e, expected a function, but got %v", e, fun);
    }

    // Check if the second argument is a list
    // if (!listp(args)) {
    //     runerror("in %e, expected a list, but got %v", e, args);
    // }

    // If we have a primitive function, we need to extract the actual function
    if (fun.alt == PRIMITIVE) {
        // Evaluate the primitive function with the arguments from the list
        return fun.primitive.function(e, fun.primitive.tag, asValuelist(args));
    } else if (fun.alt == CLOSURE) {
        // For a closure, we need to apply the function to the arguments
        Namelist xs = fun.closure.lambda.formals;
        checkargc(e, lengthNL(xs), lengthVL(asValuelist(args)));
        return eval(fun.closure.lambda.body, bindalloclist(xs, asValuelist(args), fun.closure.env));
    }

    // We shouldn't reach here, but if we do, return an error
    assert(0);
    return mkNum(0); // just to make the compiler happy; this should never execute
}

/* Modify nullary function in prim.c */
Value nullary(Exp e, int tag, Valuelist args) {
    checkargc(e, 0, lengthVL(args));
    switch (tag) {
        case READ:
        {
            // Buffer to read the input s-expression.
            const int BUFFER_SIZE = 1024;
            char buffer[BUFFER_SIZE];

            // Prompt the user and read the input expression.
            printf("-> "); // or use the provided prompt in your system
            if (!fgets(buffer, BUFFER_SIZE, stdin)) {
                runerror("failed to read an integer in %e", e);
            }

            // Remove the newline character at the end of the string, if there is one.
            size_t len = strlen(buffer);
            if (len > 0 && buffer[len - 1] == '\n') {
                buffer[len - 1] = '\0';
            }

            // Now, we have the s-expression as a string in 'buffer'.
            // We need to parse this string to create the internal representation.

            // First, create a Linestream from the buffer.
            Linestream lineStream = stringlines("<stdin>", buffer);

            // Then create a Parstream (parenthesized expression stream).
            Parstream parStream = parstream(lineStream, NOT_PROMPTING);

            // Read the parenthesized expression from the stream.
            Par par = getpar(parStream);

            // Check for an end-of-file or error condition from getpar (if applicable in your implementation).
            if (par == NULL) {
                runerror("End of file or error while reading the expression.\n");
            }

            // Parse the s-expression and convert it to a Value.
            Value result = parsesx(par, parsource(parStream));

            // Free resources if necessary (depending on your memory management).
            // freeline(lineStream);
            // freepar(parStream);

            // Return the parsed s-expression.
            return result;
        }
        // ... other cases ...
        default:
            assert(0); // or proper error handling
    }
}


/* prim.c S313d */
Value binary(Exp e, int tag, Valuelist args) {
    checkargc(e, 2, lengthVL(args));
    Value v = nthVL(args, 0);
    Value w = nthVL(args, 1);

    switch (tag) {
    case CONS: 
        return cons(v, w);
    case EQ:   
        return equalatoms(v, w);
    case APPLYFN:
        return apply(e, v, w);
    default:
        assert(0);
    }
}
/* prim.c S314a */
Value equalatoms(Value v, Value w) {
    if (v.alt != w.alt)
        return falsev;

    switch (v.alt) {
    case NUM:
        return mkBoolv(v.num   == w.num);
    case BOOLV:
        return mkBoolv(v.boolv == w.boolv);
    case SYM:
        return mkBoolv(v.sym   == w.sym);
    case NIL:
        return truev;
    default:
        return falsev;
    }
}

Value nary(Exp e, int tag, Valuelist args) {
    (void)e;  // suppress unused variable warning

    switch (tag) {
    case MAKE_LIST:
        return make_list(args);
    default:
        assert(0);  // This shouldn't be reached
    }
}

Value make_list(Valuelist args) {
    if (args == NULL)
        return mkNil();
    else
        return cons(nthVL(args, 0), make_list(args->tl));
}
