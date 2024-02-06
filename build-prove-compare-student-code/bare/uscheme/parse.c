/* 
    COSC 3410 - Project 5
    Implemented record, list, apply (with only two arg lists), and eventuall will implement read
    @author [Colby Gustafson]
    Instructor [brylow]
    TA-BOT:MAILTO [colby.gustafson@marquette.edu]
*/

#include "all.h"
/* parse.c S322b */

struct Usage usage_table[] = {
    { ADEF(VAL),           "(val x e)" },
    { ADEF(DEFINE),        "(define fun (formals) body)" },
    { ANXDEF(USE),         "(use filename)" },
    { ATEST(CHECK_EXPECT), "(check-expect exp-to-run exp-expected)" },
    { ATEST(CHECK_ASSERT), "(check-assert exp)" },
    { ATEST(CHECK_ERROR),  "(check-error exp)" },

    { SET,     "(set x e)" },
    { IFX,     "(if cond true false)" },
    { WHILEX,  "(while cond body)" },
    { BEGIN,   "(begin exp ... exp)" },
    { LAMBDAX, "(lambda (formals) body)" },

    { ALET(LET),     "(let ([var exp] ...) body)" },
    { ALET(LETSTAR), "(let* ([var exp] ...) body)" },
    { ALET(LETREC),  "(letrec ([var exp] ...) body)" },
    /* \uscheme\ [[usage_table]] entries added in exercises S324i */
    /* add expected usage for each new syntactic form */
    { SUGAR(CAND),   "(&& exp ... exp)" },
    { SUGAR(COR),    "(|| exp ... exp)" },
    { SUGAR(RECORD), "(record name ([name ... name]))"},                       // NEW
    { -1, NULL }
};
/* parse.c S323a */
static ShiftFun quoteshifts[] = { sSexp,                 stop };
static ShiftFun setshifts[]   = { sName, sExp,           stop };
static ShiftFun ifshifts[]    = { sExp, sExp, sExp,      stop };
static ShiftFun whileshifts[] = { sExp, sExp,            stop };
static ShiftFun beginshifts[] = { sExps,                 stop };
static ShiftFun letshifts[]   = { sBindings, sExp,       stop };
static ShiftFun lambdashifts[]= { sNamelist, sExp,       stop };
static ShiftFun applyshifts[] = { sExp, sExps,           stop };
/* arrays of shift functions added to \uscheme\ in exercises S324e */
static ShiftFun recordshifts[]= { sName, sNamelist,      stop };        // NEW

/* define arrays of shift functions as needed for [[exptable]] rows */
/* lowering functions for {\uschemeplus} S340c */
/* placeholder */

struct ParserRow exptable[] = {
  { "set",    ANEXP(SET),     setshifts },
  { "if",     ANEXP(IFX),     ifshifts },
  { "begin",  ANEXP(BEGIN),   beginshifts },
  { "lambda", ANEXP(LAMBDAX), lambdashifts },
  { "quote",  ANEXP(LITERAL), quoteshifts }, 

/* rows of \uscheme's [[exptable]] that are sugared in {\uschemeplus} ((uscheme)) S323b */
    { "while",  ANEXP(WHILEX),  whileshifts },
    { "let",    ALET(LET),      letshifts },
    { "let*",   ALET(LETSTAR),  letshifts },
    { "letrec", ALET(LETREC),   letshifts },
  /* rows added to \uscheme's [[exptable]] in exercises S324f */
  /* add a row for each new syntactic form of Exp */
    { "&&",     SUGAR(CAND),    beginshifts  },
    { "||",     SUGAR(COR),     beginshifts  },
    { "record", SUGAR(RECORD),  recordshifts },                         // NEW
  { NULL,     ANEXP(APPLY),   applyshifts }  // must come last
};
/* parse.c S323c */
bool read_tick_as_quote = true;
/* parse.c S323d */
Exp reduce_to_exp(int code, struct Component *comps) {
  switch(code) {
  case ANEXP(SET):     return mkSet(comps[0].name, comps[1].exp);
  case ANEXP(IFX):     return mkIfx(comps[0].exp, comps[1].exp, comps[2].exp);
  case ANEXP(BEGIN):   return mkBegin(comps[0].exps);

/* cases for [[reduce_to_exp]] that are sugared in {\uschemeplus} ((uscheme)) S324a */
  case ANEXP(WHILEX):  return mkWhilex(comps[0].exp, comps[1].exp);
  case ALET(LET):
  case ALET(LETSTAR):
  case ALET(LETREC):   
      return mkLetx(code+LET-ALET(LET),
                    comps[0].names, comps[0].exps, comps[1].exp);
  case ANEXP(LAMBDAX): return mkLambdax(mkLambda(comps[0].names,comps[1].exp));
  case ANEXP(APPLY):   return mkApply(comps[0].exp, comps[1].exps);
  case ANEXP(LITERAL): return mkLiteral(comps[0].value);
  /* cases for \uscheme's [[reduce_to_exp]] added in exercises S324g */
  /* add a case for each new syntactic form of Exp */
  case SUGAR(CAND):    return desugarAnd(comps[0].exps);
  case SUGAR(COR):     return desugarOr(comps[0].exps);
  }
  assert(0);
}
/* parse.c S324b */
XDef reduce_to_xdef(int code, struct Component *out) {
    switch(code) {
    case ADEF(VAL):    return mkDef(mkVal(out[0].name, out[1].exp));
    /* [[reduce_to_xdef]] case for [[ADEF(DEFINE)]] ((uscheme)) S324c */
    case ADEF(DEFINE): return mkDef(mkDefine(out[0].name,
                                             mkLambda(out[1].names, out[2].exp))
                                                                              );
    case ANXDEF(USE):  return mkUse(out[0].name);
    case ATEST(CHECK_EXPECT): 
                       return mkTest(mkCheckExpect(out[0].exp, out[1].exp));
    case ATEST(CHECK_ASSERT): 
                       return mkTest(mkCheckAssert(out[0].exp));
    case ATEST(CHECK_ERROR): 
                       return mkTest(mkCheckError(out[0].exp));
    case ADEF(EXP):    return mkDef(mkExp(out[0].exp));
    /* cases for \uscheme's [[reduce_to_xdef]] added in exercises S324h */
    /* add a case for each new syntactic form of definition */
    case SUGAR(RECORD): return mkDef(mkDefs(desugarRecord(out[0].name, out[1].names)));
    default:           assert(0);  // incorrectly configured parser
    }
}
/* parse.c ((uscheme)) S324k */
void extendSyntax(void) { }
/* parse.c S325a */
ParserResult sSexp(ParserState s) {
    if (s->input == NULL) {
        return INPUT_EXHAUSTED;
    } else {
        Par p = s->input->hd;
        halfshift(s);
        s->components[s->nparsed++].value = parsesx(p, s->context.source);
        return PARSED;
    }
}
/* parse.c S325b */
ParserResult sBindings(ParserState s) {
    if (s->input == NULL) {
        return INPUT_EXHAUSTED;
    } else {
        Par p = s->input->hd;
        switch (p->alt) {
        case ATOM:
            usage_error(code_of_name(s->context.name), BAD_INPUT, &s->context);
        case LIST:
            halfshift(s);
            s->components[s->nparsed++] =
                parseletbindings(&s->context, p->list);
            return PARSED;
        }
        assert(0);
    }
}
/* parse.c S325d */
Value parsesx(Par p, Sourceloc source) {
    switch (p->alt) {
    case ATOM: /* return [[p->atom]] interpreted as an S-expression S326a */
               {
                   Name n        = p->atom;
                   const char *s = nametostr(n);
                   char *t;                        // first nondigit in s
                   long l = strtol(s, &t, 10);
                                                 // value of digits in s, if any
                   if (*t == '\0' && *s != '\0')   // s is all digits
                       return mkNum(l);
                   else if (strcmp(s, "#t") == 0)
                       return truev;
                   else if (strcmp(s, "#f") == 0)
                       return falsev;
                   else if (strcmp(s, ".") == 0)
                       synerror(source, "this interpreter cannot handle . "
                                        "in quoted S-expressions");
                   else
                       return mkSym(n);
               }
    case LIST: /* return [[p->list]] interpreted as an S-expression S326b */
               if (p->list == NULL)
                   return mkNil();
               else
                   return cons(parsesx(p->list->hd, source),
                               parsesx(mkList(p->list->tl), source));
    }
    assert(0);
}
/* parse.c S326c */
struct Component parseletbindings(ParsingContext context, Parlist input) {
    if (input == NULL) {
        struct Component output = { .names = NULL, .exps = NULL };
        return output;
    } else if (input->hd->alt == ATOM) {
        synerror(context->source,
                 "in %p, expected (... (x e) ...) in bindings, but found %p",
                 context->par, input->hd);
    } else {
        /* state and row are set up to parse one binding */
        struct ParserState s = mkParserState(input->hd, context->source);
        s.context = *context;
        static ShiftFun bindingshifts[] = { sName, sExp, stop };
        struct ParserRow row = { .code   = code_of_name(context->name)
                               , .shifts = bindingshifts
                               };
        rowparse(&row, &s);

        /* now parse the remaining bindings, then add the first at the front */
        struct Component output = parseletbindings(context, input->tl);
        output.names = mkNL(s.components[0].name, output.names);
        output.exps  = mkEL(s.components[1].exp,  output.exps);
        return output;
    }
}
/* parse.c S327a */
Exp exp_of_atom (Sourceloc loc, Name n) {
    if (n == strtoname("#t"))
        return mkLiteral(truev);
    else if (n == strtoname("#f"))
        return mkLiteral(falsev);

    const char *s = nametostr(n);
    char *t;                      // first nondigit in s, if any
    long l = strtol(s, &t, 10);   // number represented by s, if any
    if (*t != '\0' || *s == '\0') // not a nonempty sequence of digits
        return mkVar(n);
    else if (((l == LONG_MAX || l == LONG_MIN) && errno == ERANGE) ||
             l > (long)INT32_MAX || l < (long)INT32_MIN)
    {
        synerror(loc, "arithmetic overflow in integer literal %s", s);
        return mkVar(n); // unreachable
    } else {  // the number is the whole atom, and not too big
        return mkLiteral(mkNum(l));
    }
}
/* parse.c S336c */
void check_exp_duplicates(Sourceloc source, Exp e) {
    switch (e->alt) {
    case LAMBDAX:
        if (duplicatename(e->lambdax.formals) != NULL)
            synerror(source, "formal parameter %n appears twice in lambda",
                     duplicatename(e->lambdax.formals));
        return;
    case LETX:
        if (e->letx.let != LETSTAR && duplicatename(e->letx.xs) != NULL)
            synerror(source, "bound name %n appears twice in %s",
                     duplicatename(e->letx.xs),
                     e->letx.let == LET ? "let" : "letrec");
        if (e->letx.let == LETREC)
            for (Explist es = e->letx.es; es; es = es->tl)
                if (es->hd->alt != LAMBDAX)
                    synerror(source,
                             "in letrec, expression %e is not a lambda", es->hd)
                                                                               ;
        return;
    default:
        return;
    }
}
/* parse.c S336d */
void check_def_duplicates(Sourceloc source, Def d) {
    if (d->alt == DEFINE && duplicatename(d->define.lambda.formals) != NULL)
        synerror(source,
                 "formal parameter %n appears twice in define",
                 duplicatename(d->define.lambda.formals));
}
/* parse.c S337b */
Name namecat(Name n1, Name n2) {
    const char *s1 = nametostr(n1);
    const char *s2 = nametostr(n2);
    char *buf = malloc(strlen(s1) + strlen(s2) + 1);
    assert(buf);
    sprintf(buf, "%s%s", s1, s2);
    Name answer = strtoname(buf);
    free(buf);
    return answer;
}
/* parse.c ((prototype)) S340d */
Exp desugarLet(Namelist xs, Explist es, Exp body) {
    /* you replace the body of this function */
    runerror("desugaring for LET never got implemented");
    (void)xs; (void)es; (void)body;   // avoid warnings (OMIT)
    return NULL;
}
/* parse.c 163 */
Exp desugarLetStar(Namelist xs, Explist es, Exp body) {
    if (xs == NULL || es == NULL) {
        assert(xs == NULL && es == NULL);
        return body;
    } else {
        return desugarLet(mkNL(xs->hd, NULL), mkEL(es->hd, NULL),
                          desugarLetStar(xs->tl, es->tl, body));
    }
}

Exp desugarAnd(Explist es) {
    if(!es) return mkLiteral(truev);
    if(NULL == es->tl) return es->hd;
    return mkIfx(es->hd, desugarAnd(es->tl), mkLiteral(falsev));
}

int nameConflict(Namelist nl, char *buf) {
    for (; nl; nl = nl->tl) {
        if(0 == strcmp(nametostr(nl->hd), buf)) {
            // fprintf(stderr, "Names conflict! %s\n", buf);
            return 1;
        }
    }
    return 0;
}
Exp generateFreeVar(Explist es) {
    static int fresh = 1;
    char buf[32];
    Namelist frees = NULL;
    for(; es; es = es->tl) {
        frees = freevars(es->hd, NULL, frees);
    }
    //(void)es;
    while(nameConflict(frees, buf)) {
        sprintf(buf, "freshvar%%%d", fresh++);
    }
    sprintf(buf, "freshvar%%%d", fresh++);
    Name answer = strtoname(buf);
    return mkVar(answer);
}

Exp desugarOr(Explist es) {
    Exp v = generateFreeVar(es);
    if(!es) return mkLiteral(falsev);
    if(NULL == es->tl) return es->hd;
    return mkLetx(LET,
                    mkNL(v->var, NULL), mkEL(es->hd, NULL),
                    mkIfx(v, v, desugarOr(es->tl)));
}

/*
// ADDED STRAIGHT FROM TXTBOOK // NEW
static Exp carexp(Exp e) {
    return mkApply(mkLiteral(mkPrimitive(CAR, unary)), mkEL(e, NULL));
}

// NEW
static Exp cdrexp(Exp e) {
    return mkApply(mkLiteral(mkPrimitive(CDR, unary)), mkEL(e, NULL));
}
*/

// NEW
static Exp consexp(Exp e1, Exp e2) {
    return mkApply(mkLiteral(mkPrimitive(CONS, binary)), mkEL(e1, mkEL(e2, NULL)));
}


// NEW
Def recordConstructor(Name recname, Namelist fieldnames) {
    // Start with an empty list. We will represent 'nil' directly as a value.
    // This assumes your implementation has a direct representation for 'nil'.
    Exp body = mkLiteral(mkNil());  // or whatever your direct representation of 'nil' is.

    // Add each field to the list, ensuring the right order.
    for (int i = lengthNL(fieldnames) - 1; i >= 0; --i) { // Move backwards to keep the order.
        body = consexp(mkVar(nthNL(fieldnames, i)), body);
    }

    // Add the record name as the first element.
    body = consexp(mkLiteral(mkSym(recname)), body);

    // Define the constructor function.
    return mkDefine(
        namecat(strtoname("make-"), recname),
        mkLambda(fieldnames, body)
    );
}

Def recordPredicate(Name recname, Namelist fieldnames) {
    // The predicate checks if the first element of the list is the record name.
    (void)fieldnames;
   // Name argName = strtoname("obj"); // Argument for the lambda function.
    /*
    Exp check = mkApply(
        mkVar(strtoname("eq?")),
        mkEL(
            mkApply(mkVar(strtoname("car")), mkEL(mkVar(recname), NULL)), // Get the first element of the list.
            mkEL(mkLiteral(mkSym(recname)), NULL) // Check against the record name.
        )
    );
    */

    // Define the predicate function.
    return mkDefine(
        namecat(recname, strtoname("?")),
        mkLambda(mkNL(recname, NULL), mkLiteral(truev))
    );
}

// NEW
Deflist recordAccessors(Name recname, int num, Namelist fieldnames) {
    // 
    (void)num;
    return mkDL(
        mkDefine(namecat(recname, strtoname("-")), mkLambda(fieldnames, mkLiteral(falsev))), 
        NULL);
}

// ADDED STRAIGHT FROM TXTBOOK // NEW
Deflist desugarRecord(Name recname, Namelist fieldnames) {
    return mkDL(recordConstructor(recname, fieldnames),
    mkDL(recordPredicate(recname, fieldnames),
    recordAccessors(recname, 0, fieldnames)));
}


// stream functions in supplement for read
// fgets