#include "all.h"
/*
 * The keyword expressions are specified by a usage
 * table.
 * <parse.c>=
 */
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
    /*
     * <\uscheme\ [[usage_table]] entries added in exercises>=
     */
    /* add expected usage for each new syntactic form */
    /*
     * <\uscheme\ [[usage_table]] entries added in exercises>=
     */
    { ANEXP(BREAKX),     "(break)" },
    { ANEXP(CONTINUEX),  "(continue)" },
    { ANEXP(RETURNX),    "(return exp)" },
    { ANEXP(THROW),      "(throw lbl-name exp)" },
    { ANEXP(TRY_CATCH),  "(try-catch body lbl-name handler)" },
    { ANEXP(LONG_LABEL), "(long-label lbl-name body)" },
    { ANEXP(LONG_GOTO),  "(long-goto lbl-name exp)" },
    { -1, NULL }
};
/*
 * \qbreak Using the new shift functions, the
 * [[exptable]] used for parsing expressions is defined
 * here: [*]
 * <parse.c>=
 */
static ShiftFun quoteshifts[] = { sSexp,                 stop };
static ShiftFun setshifts[]   = { sName, sExp,           stop };
static ShiftFun ifshifts[]    = { sExp, sExp, sExp,      stop };
static ShiftFun whileshifts[] = { sExp, sExp,            stop };
static ShiftFun beginshifts[] = { sExps,                 stop };
static ShiftFun letshifts[]   = { sBindings, sExp,       stop };
static ShiftFun lambdashifts[]= { sNamelist, sExp,       stop };
static ShiftFun applyshifts[] = { sExp, sExps,           stop };
/*
 * <arrays of shift functions added to \uscheme\ in exercises>=
 */
/* define arrays of shift functions as needed for [[exptable]] rows */
/*
 * \qbreak
 * 
 * Parsing
 * 
 * \uschemeplus extends micro-Scheme with new syntactic
 * forms, which means extending the parsing tables and
 * functions shown in \crefschemea.chap. The new forms
 * are treated as if they were added in exercises.
 * <arrays of shift functions added to \uscheme\ in exercises>=
 */
ShiftFun breakshifts[]  = { stop };
ShiftFun returnshifts[] = { sExp, stop };
ShiftFun throwshifts[]  = { sName, sExp, stop };
ShiftFun tcshifts[]     = { sExp, sName, sExp, stop };
ShiftFun labelshifts[]  = { sName, sExp, stop };
/*
 * <arrays of shift functions added to \uscheme\ in exercises>=
 */
static ShiftFun procwhileshifts[] = { sExp, sExps,      stop };
static ShiftFun procletshifts[]   = { sBindings, sExps, stop };
/*
 * <lowering functions for {\uschemeplus}>=
 */
/* placeholder */
/*
 * The [[smartBegin]] function knows that \monobox(begin
 * e) is always and forever equivalent to e, and it
 * prefers the simpler version.
 * <lowering functions for {\uschemeplus}>=
 */
static Exp smartBegin(Explist es) {
    if (es != NULL && es->tl == NULL)
        return es->hd;
    else
        return mkBegin(es);
}

struct ParserRow exptable[] = {
  { "set",    ANEXP(SET),     setshifts },
  { "if",     ANEXP(IFX),     ifshifts },
  { "begin",  ANEXP(BEGIN),   beginshifts },
  { "lambda", ANEXP(LAMBDAX), lambdashifts },
  { "quote",  ANEXP(LITERAL), quoteshifts }, 
  /*
   * OK, not really exercises...
   * <rows of \uscheme's [[exptable]] that are sugared in {\uschemeplus} ((
                                                                 uschemeplus))>=
   */
    { "while",  ANEXP(WHILEX),  procwhileshifts },
    { "let",    ALET(LET),      procletshifts },
    { "let*",   ALET(LETSTAR),  procletshifts },
    { "letrec", ALET(LETREC),   procletshifts },
  /*
   * <rows added to \uscheme's [[exptable]] in exercises>=
   */
  /* add a row for each new syntactic form of Exp */
  /*
   * <rows added to \uscheme's [[exptable]] in exercises>=
   */
  { "break",      BREAKX,        breakshifts },
  { "continue",   CONTINUEX,     breakshifts },
  { "return",     RETURNX,       returnshifts },
  { "throw",      THROW,         throwshifts },
  { "try-catch",  TRY_CATCH,     tcshifts },
  { "long-label", LONG_LABEL,    labelshifts },
  { "long-goto",  LONG_GOTO,     labelshifts }, 
  { "when",       SUGAR(WHEN),   applyshifts },
  { "unless",     SUGAR(UNLESS), applyshifts },
  { NULL,     ANEXP(APPLY),   applyshifts }  // must come last
};
/*
 * In micro-Scheme, a quote mark in the input is
 * expanded to a [[quote]] expression. The global
 * variable [[read_tick_as_quote]] so instructs the
 * [[getpar]] function defined in \crefcinterps.chap (\
 * cpagerefgetpar.imp).
 * <parse.c>=
 */
bool read_tick_as_quote = true;
/*
 * <parse.c>=
 */
Exp reduce_to_exp(int code, struct Component *comps) {
    switch(code) {
    case ANEXP(SET):     return mkSet(comps[0].name, comps[1].exp);
    case ANEXP(IFX):     return mkIfx(comps[0].exp, comps[1].exp, comps[2].exp);
    case ANEXP(BEGIN):   return mkBegin(comps[0].exps);
    /*
     * <cases for [[reduce_to_exp]] that are sugared in {\uschemeplus} ((
                                                                 uschemeplus))>=
     */
    case ANEXP(WHILEX):  (void) whileshifts;
                         return mkWhilex(comps[0].exp, smartBegin(comps[1].exps)
                                                                              );
    case ALET(LET):
    case ALET(LETSTAR):
    case ALET(LETREC):   (void) letshifts;
                         return mkLetx(code+LET-ALET(LET), 
                                       comps[0].names, comps[0].exps,
                                       smartBegin(comps[1].exps));
    case ANEXP(LAMBDAX): return mkLambdax(mkLambda(comps[0].names, comps[1].exp)
                                                                              );
    case ANEXP(APPLY):   return mkApply(comps[0].exp, comps[1].exps);
    case ANEXP(LITERAL):
    { Exp e = mkLiteral(comps[0].value);
      pushframe(mkBeginStruct(mkEL(e, NULL)), roots.stack);
      return e;
    }
    /*
     * <cases for \uscheme's [[reduce_to_exp]] added in exercises>=
     */
    /* add a case for each new syntactic form of Exp */
    /*
     * <cases for \uscheme's [[reduce_to_exp]] added in exercises>=
     */
    case ANEXP(BREAKX):     return mkBreakx();
    case ANEXP(CONTINUEX):  return mkContinuex();
    case ANEXP(RETURNX):    return mkReturnx(comps[0].exp);
    case ANEXP(THROW):      return mkThrow(comps[0].name, comps[1].exp);
    case ANEXP(TRY_CATCH):  return mkTryCatch(comps[0].exp,
                                              comps[1].name, comps[2].exp);
    case ANEXP(LONG_LABEL): return mkLongLabel(comps[0].name, comps[1].exp);
    case ANEXP(LONG_GOTO):  return mkLongGoto(comps[0].name, comps[1].exp);
    case SUGAR(WHEN):       return mkIfx(comps[0].exp, smartBegin(comps[1].exps)
                                                                               ,
                                         mkLiteral(falsev));
    case SUGAR(UNLESS):     return mkIfx(comps[0].exp, mkLiteral(falsev),
                                         smartBegin(comps[1].exps));
    }
    assert(0);
}
/*
 * The [[xdeftable]] is shared with the Impcore parser.
 * Function [[reduce_to_xdef]] is almost shareable as
 * well, but not quite---the abstract syntax of
 * [[DEFINE]] is different.
 * <parse.c>=
 */
XDef reduce_to_xdef(int code, struct Component *out) {
    switch(code) {
    case ADEF(VAL):    return mkDef(mkVal(out[0].name, out[1].exp));
    /*
     * <[[reduce_to_xdef]] case for [[ADEF(DEFINE)]] ((uschemeplus))>=
     */
    case ADEF(DEFINE):
      return mkDef(mkDefine(out[0].name,
                            mkLambda(out[1].names, smartBegin(out[2].exps))));
    case ANXDEF(USE):  return mkUse(out[0].name);
    case ATEST(CHECK_EXPECT): 
                       return mkTest(mkCheckExpect(out[0].exp, out[1].exp));
    case ATEST(CHECK_ASSERT): 
                       return mkTest(mkCheckAssert(out[0].exp));
    case ATEST(CHECK_ERROR): 
                       return mkTest(mkCheckError(out[0].exp));
    case ADEF(EXP):    return mkDef(mkExp(out[0].exp));
    /*
     * <cases for \uscheme's [[reduce_to_xdef]] added in exercises>=
     */
    /* add a case for each new syntactic form of definition */
    default:           assert(0);  // incorrectly configured parser
    }
}
/*
 * New shift functions: S-expressions and bindings
 * 
 * Many shift functions are reused from Impcore's parser
 * (\crefcparse.chap). New shift function [[sSexp]]
 * calls [[parsesx]] to parse a literal S-expression.
 * The result is stored in a [[value]] component. [*]
 * <parse.c>=
 */
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
/*
 * New shift function [[sBindings]] calls
 * [[parseletbindings]] to parse bindings for [[LETX]]
 * forms. Function [[parseletbindings]] returns a
 * component that has both [[names]] and and [[exps]]
 * fields set.
 * <parse.c>=
 */
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
/*
 * Parsing quoted S-expressions
 * 
 * A quoted S-expression is either an atom or a list. 
 * [*]
 * <parse.c>=
 */
Value parsesx(Par p, Sourceloc source) {
    switch (p->alt) {
    case ATOM: /*
                * Inside a quoted S-expression, an atom is necessarily
                * a number, a Boolean, or a symbol. This parser does
                * not understand dot notation, which in full Scheme is
                * used to write cons cells that are not lists.
                * <return [[p->atom]] interpreted as an S-expression>=
                */
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
    case LIST: /*
                * <return [[p->list]] interpreted as an S-expression>=
                */
               if (p->list == NULL)
                   return mkNil();
               else {
                   Value v = parsesx(p->list->hd, source);
                   pushreg(&v);
                   Value w = parsesx(mkList(p->list->tl), source);
                   popreg(&v);
                   Value pair = cons(v, w);
                   cyclecheck(&pair);
                   return pair;
               }
    }
    assert(0);
}
/*
 * \qtrim2.5
 * 
 * Parsing bindings used in LETX forms
 * 
 * A sequence of let bindings has both names and
 * expressions. To capture both, [[parseletbindings]]
 * returns a component with both [[names]] and [[exps]]
 * fields set.
 * <parse.c>=
 */
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
/*
 * Parsing atomic expressions
 * 
 * When an atom appears as an expression, it is
 * a Boolean, an integer literal, or a variable. [*]
 * <parse.c>=
 */
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
/*
 * Parse-time error \chaptocsplitchecking
 * 
 * micro-Scheme requires that the names of formal
 * parameters and [[let]]-bound variables be mutually
 * distinct. If the requirement isn't met, a syntax
 * error is signaled at parse time by function
 * [[check_exp_duplicates]]. This function also checks
 * the requirement that every right-hand side in a
 * [[letrec]] expression is a [[lambda]]. [*]
 * <parse.c>=
 */
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
/*
 * Each [[define]] form also has to be checked.
 * <parse.c>=
 */
void check_def_duplicates(Sourceloc source, Def d) {
    if (d->alt == DEFINE && duplicatename(d->define.lambda.formals) != NULL)
        synerror(source,
                 "formal parameter %n appears twice in define",
                 duplicatename(d->define.lambda.formals));
}
/*
 * <parse.c>=
 */
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
/*
 * Placeholder for \chaptocsplitdesugaring
 * 
 * As described in \crefscheme.chap (\cpageref
 * scheme.let-sugar), every [[let]] form can be
 * desugared into a combination of [[lambda]]
 * expressions and function applications. The chapter
 * shows code for desugaring [[let*]], but if you want
 * to desugar [[let]], you'll need to write C code to
 * replace this function:
 * <parse.c ((prototype))>=
 */
Exp desugarLet(Namelist xs, Explist es, Exp body) {
    /* you replace the body of this function */
    runerror("desugaring for LET never got implemented");
    (void)xs; (void)es; (void)body;   // avoid warnings (OMIT)
    return NULL;
}
/*
 * Scheme, S-expressions, and first-class functions
 * 
 * [*] \invisiblelocaltableofcontents[*]
 * 
 * \minibasison
 * 
 * \notationgroupmicro-Scheme \makenowebnotdef(generated
 * automatically)
 * 
 */

/*
 * A much more interesting and efficient allocator is
 * described in Chapter [->].
 * 
 * Extending micro-Scheme with syntactic sugar
 * 
 * [*] [*] Like Impcore, micro-Scheme is stratified into
 * two layers: a core language and syntactic sugar (\
 * cpagerefimpcore.sugar-sidebar). The core language is
 * defined by the operational semantics and is
 * implemented by functions [[eval]] and [[evaldef]].
 * The syntactic sugar is defined and implemented by
 * translating it into the core language. In Scheme,
 * the core language can be very small indeed: even the
 * \xlet and \xbegin forms can be implemented as
 * syntactic sugar. (But in micro-Scheme, they are part
 * of the core.) The translations of \xlet and \xbegin
 * are shown below, as are the translations used to
 * implement short-circuit conditionals, [[cond]], and
 * the [[record]] form. These translations introduce two
 * key programming-language concepts: capture-avoiding
 * substitution and hygiene.
 * 
 * Syntactic sugar for \xlet forms
 * 
 * [*]
 * 
 * A [[let]] expression can be desugared into an
 * application of a [[lambda]]: \letsugardisplay
 * 
 * A [[let*]] expression can be desugared into a
 * sequence of nested [[let]] expressions.
 * The desugaring is defined by structural induction on
 * the list of bindings in the [[let*]], which calls for
 * two equations: one for the base case (no bindings)
 * and one for the induction step (a nonempty sequence
 * of bindings). An empty [[let*]] is desugared into its
 * body. A nonempty [[let*]] is desugared into a nested
 * sequence of [[let]] expressions: a [[let]] expression
 * for the first binding, followed by the desugaring of
 * the [[let*]] expression for the remaining bindings.
 * ---  e\mono) --- e
 * \mono(let* ([x_1 e_1] ... [x_n e_n]) ---  e\mono)
 * \mono(let ([x_1 e_1]) (let* ([x_2 e_2] ... [x_n e_n])
 * e))
 * {indented} \letstarsugardisplay This translation
 * works just like any other recursive function—but the
 * recursive function is applied to syntax, not to
 * values. It looks like this: [*]
 * <parse.c>=
 */
Exp desugarLetStar(Namelist xs, Explist es, Exp body) {
    if (xs == NULL || es == NULL) {
        assert(xs == NULL && es == NULL);
        return body;
    } else {
        return desugarLet(mkNL(xs->hd, NULL), mkEL(es->hd, NULL),
                          desugarLetStar(xs->tl, es->tl, body));
    }
}
