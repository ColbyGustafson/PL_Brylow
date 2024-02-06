(* <timpcore.sml>=                              *)


(*****************************************************************)
(*                                                               *)
(*   EXCEPTIONS USED IN LANGUAGES WITH TYPE CHECKING             *)
(*                                                               *)
(*****************************************************************)

(* <exceptions used in languages with type checking>= *)
exception TypeError of string
exception BugInTypeChecking of string


(*****************************************************************)
(*                                                               *)
(*   \FOOTNOTESIZE SHARED: NAMES, ENVIRONMENTS, STRINGS, ERRORS, PRINTING, INTERACTION, STREAMS, \&\ INITIALIZATION *)
(*                                                               *)
(*****************************************************************)

(* <\footnotesize shared: names, environments, strings, errors, printing, interaction, streams, \&\ initialization>= *)
(* <for working with curried functions: [[id]], [[fst]], [[snd]], [[pair]], [[curry]], and [[curry3]]>= *)
fun id x = x
fun fst (x, y) = x
fun snd (x, y) = y
fun pair x y = (x, y)
fun curry  f x y   = f (x, y)
fun curry3 f x y z = f (x, y, z)
(* <boxed values 121>=                          *)
val _ = op fst    : ('a * 'b) -> 'a
val _ = op snd    : ('a * 'b) -> 'b
val _ = op pair   : 'a -> 'b -> 'a * 'b
val _ = op curry  : ('a * 'b -> 'c) -> ('a -> 'b -> 'c)
val _ = op curry3 : ('a * 'b * 'c -> 'd) -> ('a -> 'b -> 'c -> 'd)
(* [[bindList]] tried to                        *)
(*              extend an environment, but it passed *)
(*              two lists (names and values) of *)
(*              different lengths.              *)
(* RuntimeError    Something else went wrong during *)
(*              evaluation, i.e., during the    *)
(*              execution of [[eval]].          *)
(* \bottomrule                                  *)
(*                                              *)
(* Exceptions defined especially for this interpreter  *)
(* [*]                                          *)
(* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ *)
(*                                              *)
(* Abstract syntax and values                   *)
(*                                              *)
(* An abstract-syntax tree can contain a literal value. *)
(* A value, if it is a closure, can contain an  *)
(* abstract-syntax tree. These two types are therefore *)
(* mutually recursive, so I define them together, using *)
(* [[and]].                                     *)
(*                                              *)
(* These particular types use as complicated a nest of *)
(* definitions as you'll ever see. The keyword  *)
(* [[datatype]] defines a new algebraic datatype; the *)
(* keyword [[withtype]] introduces a new type   *)
(* abbreviation that is mutually recursive with the *)
(* [[datatype]]. The first group of [[and]] keywords *)
(* define additional algebraic datatypes, and the second *)
(* group of [[and]] keywords define additional type *)
(* abbreviations. Everything in the whole nest is *)
(* mutually recursive. [*] [*]                  *)

(* Interlude: micro-Scheme in ML                *)
(*                                              *)
(* [*] \invisiblelocaltableofcontents[*]        *)
(*                                              *)
(* {epigraph}Conversation with David R. Hanson, coauthor *)
(* of A Retargetable C Compiler: Design and     *)
(* Implementation\break\citep                   *)
(* hanson-fraser:retargetable:book.             *)
(*                                              *)
(*  \myblock=\wd0 =0.8=0pt                      *)
(*                                              *)
(*  to \myblock\upshapeHanson: C is a lousy language *)
(*  to write a compiler in.                     *)
(*                                              *)
(* {epigraph} The interpreters in \crefrange    *)
(* impcore.chapgc.chap are written in C, which has much *)
(* to recommend it: C is relatively small and simple; *)
(* it is widely known and widely supported; its *)
(* perspicuous cost model makes it is easy to discover *)
(* what is happening at the machine level; and  *)
(* it provides pointer arithmetic, which makes it a fine *)
(* language in which to write a garbage collector. *)
(* But for implementing more complicated or ambitious *)
(* languages, C is less than ideal. In this and *)
(* succeeding chapters, I therefore present interpreters *)
(* written in the functional language Standard ML. *)
(*                                              *)
(* Standard ML is particularly well suited to symbolic *)
(* computing, especially functions that operate on *)
(* abstract-syntax trees; some advantages are detailed *)
(* in the sidebar \vpagerefmlscheme.good-ml. And an *)
(* ML program can illustrate connections between *)
(* language design, formal semantics, and       *)
(* implementations more clearly than a C program can. *)
(* Infrastructure suitable for writing interpreters *)
(* in ML is presented in this chapter and in \cref *)
(* mlinterps.chap,lazyparse.chap. That infrastructure is *)
(* introduced by using it to implement a language that *)
(* is now familiar: micro-Scheme.               *)
(*                                              *)
(* {sidebar}[t]Helpful properties of the ML family of *)
(* languages [*]                                *)
(*                                              *)
(*  \advance\parsepby -5.5pt \advance\itemsepby *)
(*  -5.5pt \advanceby -0.5pt                    *)
(*   • ML is safe: there are no unchecked run-time *)
(*  errors, which means there are no faults that are *)
(*  entirely up to the programmer to avoid.     *)
(*   • Like Scheme, ML is naturally polymorphic. *)
(*  Polymorphism simplifies everything. For example, *)
(*  unlike the C code in \crefrange             *)
(*  impcore.chapgcs.chap, the ML code in \crefrange *)
(*  mlscheme.chapsmall.chap uses just one       *)
(*  representation of lists and one length function. *)
(*  As another example, where the C code in \cref *)
(*  cinterps.chap defines three different types of *)
(*  streams, each with its own [[get]] function, the *)
(*  ML code in \crefmlinterps.chap defines one type *)
(*  of stream and one [[streamGet]] function. And *)
(*  when a job is done by just one polymorphic  *)
(*  function, not a group of similar functions, you *)
(*  know that the one function always does the same *)
(*  thing.                                      *)
(*   • Unlike Scheme, ML uses a static type system, and *)
(*  this system guarantees that data structures are *)
(*  internally consistent. For example, if one  *)
(*  element of a list is a function, every element of *)
(*  that list is a function. This happens without *)
(*  requiring variable declarations or type     *)
(*  annotations to be written in the code.      *)
(*                                              *)
(*  If talk of polymorphism mystifies you, don't *)
(*  worry; polymorphism in programming languages is *)
(*  an important topic in its own right. Polymorphism *)
(*  is formally introduced and defined in \cref *)
(*  typesys.chap, and the algorithms that ML uses to *)
(*  provide polymorphism without type annotations are *)
(*  described in \crefml.chap.                  *)
(*   • Like Scheme, ML provides first-class, nested *)
(*  functions, and its initial basis contains useful *)
(*  higher-order functions. These functions help *)
(*  simplify and clarify code. For example, they can *)
(*  eliminate the special-purpose functions that the *)
(*  C code uses to run a list of unit tests from back *)
(*  to front; the ML code just uses [[foldr]].  *)
(*   • To detect and signal errors, ML provides *)
(*  exception handlers and exceptions, which are more *)
(*  flexible and easier to use then C's [[setjmp]] *)
(*  and [[longjmp]].                            *)
(*   • Finally, least familiar but most important, *)
(*  ML provides native support for algebraic data *)
(*  types, which I use to represent both abstract *)
(*  syntax and values. These types provide value *)
(*  constructors like the [[IFX]] or [[APPLY]] used *)
(*  in previous chapters, but instead of [[switch]] *)
(*  statements, ML provides pattern matching. Pattern *)
(*  matching enables ML programmers to write function *)
(*  definitions that look like algebraic laws; such *)
(*  definitions are easier to follow than C code. *)
(*  The technique is demonstrated in the definition *)
(*  of function [[valueString]] on \cpageref    *)
(*  mlscheme.code.valueString. For a deeper dive into *)
(*  algebraic data types, jump ahead to \crefadt.chap *)
(*  and read through \crefadt.howto.            *)
(*                                              *)
(* {sidebar}                                    *)
(*                                              *)
(* The micro-Scheme interpreter in this chapter is *)
(* structured in the same way as the interpreter in *)
(* Chapter [->]. Like that interpreter, it has  *)
(* environments, abstract syntax, primitives, an *)
(* evaluator for expressions, and an evaluator for *)
(* definitions. Many details are as similar as I can *)
(* make them, but many are not: I want the interpreters *)
(* to look similar, but even more, I want my ML code to *)
(* look like ML and my C code to look like C.   *)
(*                                              *)
(* The ML code will be easier to read if you know my *)
(* programming conventions.                     *)
(*                                              *)
(*   • My naming conventions are the ones recommended by *)
(*  the SML'97 Standard Basis Library [cite     *)
(*  gansner:basis]. Names of types are written in *)
(*  lowercase letters with words separated by   *)
(*  underscores, like [[exp]], [[def]], or      *)
(*  [[unit_test]]. Names of functions and variables *)
(*  begin with lowercase letters, like [[eval]] or *)
(*  [[evaldef]], but long names may be written in *)
(*  ``camel case'' with a mix of uppercase and  *)
(*  lowercase letters, like [[processTests]] instead *)
(*  of the C-style [[process_tests]]. (Rarely, I may *)
(*  use an underscore in the name of a local    *)
(*  variable.)                                  *)
(*                                              *)
(*  Names of exceptions are capitalized, like   *)
(*  [[NotFound]] or [[RuntimeError]], and they use *)
(*  camel case. Names of value constructors, which *)
(*  identify alternatives in algebraic data types, *)
(*  are written in all capitals, possibly with  *)
(*  underscores, like [[IFX]], [[APPLY]], or    *)
(*  [[CHECK_EXPECT]]—just like enumeration literals *)
(*  in C.                                       *)
(*   • \qtrim0.5 If you happen to be a seasoned *)
(*  ML programmer, you'll notice something missing: *)
(*  the interpreter is not decomposed into modules. *)
(*  Modules get a book chapter of their own (\cref *)
(*  mcl.chap), but compared to what's in \cref  *)
(*  mcl.chap, Standard ML's module system is    *)
(*  complicated and hard to understand. To avoid *)
(*  explaining it, I define no modules—although I do *)
(*  use ``dot notation'' to select functions that are *)
(*  defined in Standard ML's predefined modules. *)
(*  By avoiding module definitions, I enable you to *)
(*  digest this chapter even if your only previous *)
(*  functional-programming experience is with   *)
(*  micro-Scheme.                               *)
(*                                              *)
(*  Because I don't use ML modules, I cannot easily *)
(*  write interfaces or distinguish them from   *)
(*  implementations. Instead, I use a           *)
(*  literate-programming trick: I put the types of *)
(*  functions and values, which is mostly what  *)
(*  ML interfaces describe, in boxes preceding the *)
(*  implementations. These types are checked by the *)
(*  ML compiler, and the trick makes it possible to *)
(*  present a function's interface just before its *)
(*  implementation.                             *)
(*                                              *)
(* My code is also affected by two limitations of ML: *)
(* ML is persnickety about the order in which   *)
(* definitions appear, and it has miserable support for *)
(* mutually recursive data definitions. These   *)
(* limitations arise because unlike C, which has *)
(* syntactic forms for both declarations and    *)
(* definitions, ML has only definition forms.   *)
(*                                              *)
(* In C, as long as declarations precede definitions, *)
(* you can be careless about the order in which both *)
(* appear. Declare all your structures (probably in *)
(* [[typedef]]s) in any order you like, and you can *)
(* define them in just about any order you like. Then *)
(* declare all your functions in any order you like, and *)
(* you can define them in any order you like—even if *)
(* your data structures and functions are mutually *)
(* recursive. Of course there are drawbacks: not all *)
(* variables are guaranteed to be initialized, and *)
(* global variables can be initialized only in limited *)
(* ways. And you can easily define mutually recursive *)
(* data structures that allow you to chase pointers *)
(* forever.                                     *)
(*                                              *)
(* In ML, there are no declarations, and you may write a *)
(* definition only after the definitions of the things *)
(* it refers to. Of course there are benefits: every *)
(* definition initializes its name, and initialization *)
(* may use any valid expression, including [[let]] *)
(* expressions, which in ML can contain nested  *)
(* definitions. And unless your code assigns to mutable *)
(* reference cells, you cannot define circular data *)
(* structures that allow you to chase pointers forever. *)
(* As a consequence, unless a structurally recursive *)
(* function fetches the contents of mutable reference *)
(* cells, it is guaranteed to terminate. ML's designers *)
(* thought this guarantee was more important than the *)
(* convenience of writing data definitions in many *)
(* orders. (And to be fair, using ML modules makes it *)
(* relatively convenient to get things in the right *)
(* order.)                                      *)
(*                                              *)
(* What about mutually recursive data? Suppose for *)
(* example, that type [[exp]] refers to [[value]] and *)
(* type [[value]] refers to [[exp]]? Mutually recursive *)
(* definitions like [[exp]] and [[value]] must be *)
(* written together, adjacent in the source code, *)
(* connected with the keyword [[and]]. (You won't see *)
(* [[and]] often, but when you do, please remember this: *)
(* it means mutual recursion, never a Boolean   *)
(* operation.)                                  *)
(*                                              *)
(* Mutually recursive function definitions provide more *)
(* options: they can be joined with [[and]], but it is *)
(* usually more convenient and more idiomatic to nest *)
(* one inside the other using a [[let]] binding. You *)
(* would use [[and]] only when both mutually recursive *)
(* functions need to be called by some third, client *)
(* function. When I use mutual recursion, I identify the *)
(* technique I use. Now, on to the code!        *)
(*                                              *)
(* Names and \chaptocsplitenvironments\cull, with \ *)
(* chaptocsplitintroduction to ML               *)
(*                                              *)
(* [*] In my C code, [[Name]] is an abstract type, and *)
(* by design, two values of type [[Name]] can be *)
(* compared using C's built-in [[==]] operator. In my ML *)
(* code, because ML strings are immutable and can be *)
(* meaningfully compared using ML's built-in [[=]] *)
(* operator, names are represented as strings. \mlslabel *)
(* name                                         *)
(* <support for names and environments>=        *)
type name = string
(* ML's [[type]] syntax is like C's [[typedef]]; *)
(* it defines a type by type abbreviation.      *)

(* Each micro-Scheme name is bound to a location that *)
(* contains a value. In C, such a location is   *)
(* represented by a pointer of C type \monoboxValue *. *)
(* In ML, such a pointer has type \monoboxvalue ref. *)
(* Like a C pointer, an ML [[ref]] can be read from and *)
(* written to, but unlike a C pointer, it can't be added *)
(* to or subtracted from.                       *)
(*                                              *)
(* In C, the code that looks up or binds a name has to *)
(* know what kind of thing a name stands for; that's why *)
(* the Impcore interpreter uses one set of environment *)
(* functions for value environments xi and rho and *)
(* another set for a function environment phi. In ML, *)
(* the code that looks up or binds a name is independent *)
(* of what a name stands for; it is naturally   *)
(* polymorphic. One set of polymorphic functions *)
(* suffices to implement environments that hold *)
(* locations, values, or types.                 *)
(*                                              *)
(* ML has a static type system, and polymorphism is *)
(* reflected in the types. An environment has type \ *)
(* monobox'a env; such an environment binds each name in *)
(* its domain to a value of type [['a]]. The [['a]] is *)
(* called a type parameter or type variable; it stands *)
(* for an unknown type. (Type parameters are explained *)
(* in detail in \creftypesys.tuscheme, where they have *)
(* an entire language devoted to them.) Type \monobox'a *)
(* env, like any type that takes a type parameter, can *)
(* be instantiated at any type; instantiation   *)
(* substitutes a known type for every occurrence of  *)
(* [['a]]. micro-Scheme's environment binds each name to *)
(* a mutable location, and it is obtained by    *)
(* instantiating type \monobox'a env using \nomathbreak\ *)
(* monobox'a = \monoboxvalue ref; the resulting type is *)
(* \monoboxvalue ref env.                       *)
(*                                              *)
(* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ *)
(* \advanceby 0.8pt \newskip\myskip \myskip=6pt *)
(*                                              *)
(*    Semantics   Concept        Interpreter    *)
(*        d       Definition     def (\cpageref *)
(*                               mlscheme.type.def) *)
(*        e       Expression     \mlstypeexp    *)
(*        x       Name           \mlstypename   *)
(*   [\myskip] v  Value          \mlstypevalue  *)
(*        l       Location       \monovalue ref (ref is *)
(*                               built into ML) *)
(*       rho      Environment    \monovalue ref env (\ *)
(*                               cpagerefmlscheme.type.env) *)
(*      sigma     Store          Machine memory (the *)
(*                               ML heap)       *)
(*                    Expression     \monoboxeval(e, rho) = *)
(*   [\myskip] \      evaluation     v, \break with sigma *)
(*   evale ==>\                      updated to sigma' \ *)
(*   evalr['] v                      mlsfunpageeval *)
(*                                              *)
(*                    Definition     \monoboxevaldef(d, rho *)
(*  <d,rho,sigma>     evaluation     ) = (rho', s), \break *)
(*   --><rho',                       with sigma updated to  *)
(*     sigma'>                       sigma' \mlsfunpage *)
(*                                   evaldef    *)
(*                                              *)
(*                Definedness    \monofind (x, rho) *)
(*   [\myskip] x                 terminates without raising *)
(*   in dom rho                  an exception (\cpageref *)
(*                               mlscheme.fun.find) *)
(*     rho(x)     Location       \monofind (x, rho) (\ *)
(*                lookup         cpagerefmlscheme.fun.find) *)
(*  sigma(rho(x)) Value lookup   \mono!(find (x, rho)) (\ *)
(*                               cpagerefmlscheme.fun.find) *)
(*   rho{x |->l}  Binding        \monobind (x, l, rho) (\ *)
(*                               cpagerefmlscheme.fun.bind) *)
(*          \     Allocation     call \monoboxref v; the *)
(*      centering                result is l    *)
(*      sigma{l|                                *)
(*       ->v}, \                                *)
(*        break                                 *)
(*      where l\                                *)
(*      notindom                                *)
(*        sigma                                 *)
(*                                              *)
(*          \     Store update   \monol := v    *)
(*      centering                               *)
(*      sigma{l|                                *)
(*       ->v}, \                                *)
(*        break                                 *)
(*      where lin                               *)
(*      dom sigma                               *)
(*                                              *)
(*                                              *)
(* Correspondence between micro-Scheme semantics and ML *)
(* code [*]                                     *)
(* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ *)
(*                                              *)
(* My environments are implemented using ML's native *)
(* support for lists and pairs. Although my C code *)
(* represents an environment as a pair of lists, in ML, *)
(* it's easier and simpler to use a list of pairs. The *)
(* type of the list is \monobox(name * 'a) list; *)
(* the type of a single pair is \monoboxname * 'a. *)
(* A pair is created by an ML expression of the form \ *)
(* monobox(e_1, e_2); this pair contains the value of  *)
(* e_1 and the value of e_2. The pair \monobox(e_1, e_2) *)
(* has type \monoboxname * 'a if e_1 has type [[name]] *)
(* and e_2 has type [['a]]. \mlslabelenv        *)
(* <support for names and environments>=        *)
type 'a env = (name * 'a) list
(* <support for names and environments>=        *)
val emptyEnv = []
(* <support for names and environments>=        *)
exception NotFound of name
fun find (name, []) = raise NotFound name
  | find (name, (x, v)::tail) = if name = x then v else find (name, tail)
(* The [[fun]] definition form is ML's analog to *)
(* [[define]], but unlike micro-Scheme's [[define]], *)
(* it uses multiple clauses with pattern matching. Each *)
(* clause is like an algebraic law. The first clause *)
(* says that calling [[find]] with an empty environment *)
(* raises an exception; the second clause handles a *)
(* nonempty environment. The infix [[::]] is ML's way of *)
(* writing [[cons]], and it is pronounced ``cons.'' *)
(*                                              *)
(* To check x in dom rho, the ML code uses function *)
(* [[isbound]].                                 *)
(* <support for names and environments>=        *)
fun isbound (name, []) = false
  | isbound (name, (x, v)::tail) = name = x orelse isbound (name, tail)
(* <support for names and environments>=        *)
fun bind (name, v, rho) =
  (name, v) :: rho
(* <support for names and environments>=        *)
exception BindListLength
fun bindList (x::vars, v::vals, rho) = bindList (vars, vals, bind (x, v, rho))
  | bindList ([], [], rho) = rho
  | bindList _ = raise BindListLength

fun mkEnv (xs, vs) = bindList (xs, vs, emptyEnv)
(* <support for names and environments>=        *)
(* composition *)
infix 6 <+>
fun pairs <+> pairs' = pairs' @ pairs
(* The representation guarantees that there is an [['a]] *)
(* for every [[name]].                          *)
(*                                              *)
(* \setcodemargin7pt                            *)
(*                                              *)
(* The empty environment is represented by the empty *)
(* list. In ML, that's written using square brackets. *)
(* The [[val]] form is like micro-Scheme's [[val]] form. *)
(* <boxed values 1>=                            *)
val _ = op emptyEnv : 'a env
(* (The phrase in the box is like a declaration that *)
(* could appear in an interface to an ML module; through *)
(* some Noweb hackery, it is checked by the     *)
(* ML compiler.)                                *)
(*                                              *)
(* A name is looked up by function [[find]], which is *)
(* closely related to the [[find]] from \cref   *)
(* scheme.chap: it returns whatever is in the   *)
(* environment, which has type [['a]]. If the name is *)
(* unbound, [[find]] raises an exception. Raising an *)
(* exception is a lot like the [[throw]] operator in \ *)
(* crefschemes.chap; it is roughly analogous to *)
(* [[longjmp]]. The exceptions I use are listed in \vref *)
(* mlscheme.tab.exns.                           *)
(* <boxed values 1>=                            *)
val _ = op find : name * 'a env -> 'a
(* \mlsflabelfind                               *)

(* Again using [[::]], function [[bind]] adds a new *)
(* binding to an existing environment. Unlike \cref *)
(* scheme.chap's [[bind]], it does not allocate a *)
(* mutable reference cell.                      *)
(* <boxed values 1>=                            *)
val _ = op bind : name * 'a * 'a env -> 'a env
(* \mlsflabelbind                               *)

(* <boxed values 1>=                            *)
val _ = op bindList : name list * 'a list * 'a env -> 'a env
val _ = op mkEnv    : name list * 'a list -> 'a env
(* Finally, environments can be composed using the + *)
(*  operator. In my ML code, this operator is   *)
(* implemented by function [[<+>]], which I declare to *)
(* be [[infix]]. It uses the predefined infix function  *)
(* [[@]], which is ML's way of writing [[append]]. \ *)
(* mlsflabel<+>                                 *)
(* <boxed values 1>=                            *)
val _ = op <+> : 'a env * 'a env -> 'a env
(* <support for names and environments>=        *)
fun duplicatename [] = NONE
  | duplicatename (x::xs) =
      if List.exists (fn x' => x' = x) xs then
        SOME x
      else
        duplicatename xs
(* <boxed values 51>=                           *)
val _ = op duplicatename : name list -> name option
(* All interpreters incorporate these two exceptions: *)
(* <exceptions used in every interpreter>=      *)
exception RuntimeError of string (* error message *)
exception LeftAsExercise of string (* string identifying code *)
(* Some errors might be caused not by a fault in a *)
(* user's code but in my interpreter code. Such faults *)
(* are signaled by the [[InternalError]] exception. *)
(* <support for detecting and signaling errors detected at run time>= *)
exception InternalError of string (* bug in the interpreter *)
(* <list functions not provided by \sml's initial basis>= *)
fun unzip3 [] = ([], [], [])
  | unzip3 (trip::trips) =
      let val (x,  y,  z)  = trip
          val (xs, ys, zs) = unzip3 trips
      in  (x::xs, y::ys, z::zs)
      end

fun zip3 ([], [], []) = []
  | zip3 (x::xs, y::ys, z::zs) = (x, y, z) :: zip3 (xs, ys, zs)
  | zip3 _ = raise ListPair.UnequalLengths
(* \qbreak                                      *)
(*                                              *)
(* List utilities                               *)
(*                                              *)
(* Most of the list utilities anyone would need are part *)
(* of the initial basis of Standard ML. But the type *)
(* checker for pattern matching in \crefadt.chap *)
(* sometimes needs to unzip a list of triples into a *)
(* triple of lists. I define [[unzip3]] and also the *)
(* corresponding [[zip3]].                      *)
(* <boxed values 49>=                           *)
val _ = op unzip3 : ('a * 'b * 'c) list -> 'a list * 'b list * 'c list
val _ = op zip3   : 'a list * 'b list * 'c list -> ('a * 'b * 'c) list
(* Standard ML's list-reversal function is called *)
(* [[rev]], but in this book I use [[reverse]]. *)
(* <list functions not provided by \sml's initial basis>= *)
val reverse = rev
(* <list functions not provided by \sml's initial basis>= *)
fun optionList [] = SOME []
  | optionList (NONE :: _) = NONE
  | optionList (SOME x :: rest) =
      (case optionList rest
         of SOME xs => SOME (x :: xs)
          | NONE    => NONE)
(* Function [[optionList]] inspects a list of optional *)
(* values, and if every value is actually present (made *)
(* with [[SOME]]), then it returns the values. Otherwise *)
(* it returns [[NONE]].                         *)
(* <boxed values 50>=                           *)
val _ = op optionList : 'a option list -> 'a list option
(* The [[xdeftable]] is shared with the Impcore parser. *)
(* Function [[reduce_to_xdef]] is almost shareable as *)
(* well, but not quite---the abstract syntax of *)
(* [[DEFINE]] is different.                     *)

(* <utility functions for string manipulation and printing>= *)
fun intString n =
  String.map (fn #"~" => #"-" | c => c) (Int.toString n)
(* <boxed values 41>=                           *)
val _ = op intString : int -> string
(* The [[xdeftable]] is shared with the Impcore parser. *)
(* Function [[reduce_to_xdef]] is almost shareable as *)
(* well, but not quite---the abstract syntax of *)
(* [[DEFINE]] is different.                     *)

(* To characterize a list by its length and contents, *)
(* interpreter messages use strings like        *)
(* ``3 arguments,'' which come from functions [[plural]] *)
(* and [[countString]].                         *)
(* <utility functions for string manipulation and printing>= *)
fun plural what [x] = what
  | plural what _   = what ^ "s"

fun countString xs what =
  intString (length xs) ^ " " ^ plural what xs
(* <utility functions for string manipulation and printing>= *)
val spaceSep = String.concatWith " "   (* list separated by spaces *)
val commaSep = String.concatWith ", "  (* list separated by commas *)
(* To separate items by spaces or commas, interpreters *)
(* use [[spaceSep]] and [[commaSep]], which are special *)
(* cases of the basis-library function          *)
(* [[String.concatWith]].                       *)
(*                                              *)
(* <boxed values 42>=                           *)
val _ = op spaceSep : string list -> string
val _ = op commaSep : string list -> string
(* [[bindList]] tried to                        *)
(*              extend an environment, but it passed *)
(*              two lists (names and values) of *)
(*              different lengths.              *)
(* RuntimeError    Something else went wrong during *)
(*              evaluation, i.e., during the    *)
(*              execution of [[eval]].          *)
(* \bottomrule                                  *)
(*                                              *)
(* Exceptions defined especially for this interpreter  *)
(* [*]                                          *)
(* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ *)
(*                                              *)
(* Abstract syntax and values                   *)
(*                                              *)
(* An abstract-syntax tree can contain a literal value. *)
(* A value, if it is a closure, can contain an  *)
(* abstract-syntax tree. These two types are therefore *)
(* mutually recursive, so I define them together, using *)
(* [[and]].                                     *)
(*                                              *)
(* These particular types use as complicated a nest of *)
(* definitions as you'll ever see. The keyword  *)
(* [[datatype]] defines a new algebraic datatype; the *)
(* keyword [[withtype]] introduces a new type   *)
(* abbreviation that is mutually recursive with the *)
(* [[datatype]]. The first group of [[and]] keywords *)
(* define additional algebraic datatypes, and the second *)
(* group of [[and]] keywords define additional type *)
(* abbreviations. Everything in the whole nest is *)
(* mutually recursive. [*] [*]                  *)

(* <utility functions for string manipulation and printing>= *)
fun nullOrCommaSep empty [] = empty
  | nullOrCommaSep _     ss = commaSep ss                   
(* Sometimes, as when printing substitutions for *)
(* example, the empty list should be represented by *)
(* something besides the empty string. Like maybe the *)
(* string [["idsubst"]]. Such output can be produced by, *)
(* e.g., [[nullOrCommaSep "idsubst"]].          *)
(* <boxed values 43>=                           *)
val _ = op nullOrCommaSep : string -> string list -> string
(* <utility functions for string manipulation and printing>= *)
fun fnvHash s =
  let val offset_basis = 0wx011C9DC5 : Word.word  (* trim the high bit *)
      val fnv_prime    = 0w16777619  : Word.word
      fun update (c, hash) = Word.xorb (hash, Word.fromInt (ord c)) * fnv_prime
      fun int w =
        Word.toIntX w handle Overflow => Word.toInt (Word.andb (w, 0wxffffff))
  in  int (foldl update offset_basis (explode s))
  end
(* The [[hash]] primitive in the \usm interpreter uses *)
(* an algorithm by Glenn Fowler, Phong Vo, and Landon *)
(* Curt Noll, which I implement in function [[fnvHash]]. *)
(* [*] I have adjusted the algorithm's ``offset basis'' *)
(* by removing the high bit, so the computation works *)
(* using 31-bit integers. The algorithm is described by *)
(* an IETF draft at \urlhttp://tools.ietf.org/html/ *)
(* draft-eastlake-fnv-03, and it's also described by the *)
(* web page at \urlhttp://www.isthe.com/chongo/tech/comp *)
(* /fnv/.                                       *)
(* <boxed values 44>=                           *)
val _ = op fnvHash : string -> int
(* [[funty]] stand for \tau, [[actualtypes]]    *)
(* stand for \ldotsntau, and [[rettype]] stand for alpha *)
(* . The first premise is implemented by a call to *)
(* [[typesof]] and the second by a call to      *)
(* [[freshtyvar]]. The constraint is represented just as *)
(* written in the rule.                         *)

(* <utility functions for string manipulation and printing>= *)
fun println  s = (print s; print "\n")
fun eprint   s = TextIO.output (TextIO.stdErr, s)
fun eprintln s = (eprint s; eprint "\n")
(* <utility functions for string manipulation and printing>= *)
fun predefinedFunctionError s =
  eprintln ("while reading predefined functions, " ^ s)
(* <utility functions for string manipulation and printing>= *)
val xprinter = ref print
fun xprint   s = !xprinter s
fun xprintln s = (xprint s; xprint "\n")
(* <utility functions for string manipulation and printing>= *)
fun tryFinally f x post =
  (f x handle e => (post (); raise e)) before post ()

fun withXprinter xp f x =
  let val oxp = !xprinter
      val ()  = xprinter := xp
  in  tryFinally f x (fn () => xprinter := oxp)
  end
(* \qbreak The printing function that is stored in *)
(* [[xprinter]] can be changed temporarily by calling *)
(* function [[withXprinter]]. This function changes *)
(* [[xprinter]] just for the duration of a call to \ *)
(* monoboxf x. To restore [[xprinter]], function *)
(* [[withXprinter]] uses [[tryFinally]], which ensures *)
(* that its [[post]] handler is always run, even if an *)
(* exception is raised.                         *)
(* <boxed values 45>=                           *)
val _ = op withXprinter : (string -> unit) -> ('a -> 'b) -> ('a -> 'b)
val _ = op tryFinally   : ('a -> 'b) -> 'a -> (unit -> unit) -> 'b
(* And the function stored in [[xprinter]] might be *)
(* [[bprint]], which ``prints'' by appending a string to *)
(* a buffer. Function [[bprinter]] returns a pair that *)
(* contains both [[bprint]] and a function used to *)
(* recover the contents of the buffer.          *)
(* <utility functions for string manipulation and printing>= *)
fun bprinter () =
  let val buffer = ref []
      fun bprint s = buffer := s :: !buffer
      fun contents () = concat (rev (!buffer))
  in  (bprint, contents)
  end
(* \qtrim2                                      *)
(*                                              *)
(* Function [[xprint]] is used by function      *)
(* [[printUTF8]], which prints a Unicode character using *)
(* the Unicode Transfer Format (UTF-8).         *)
(* <utility functions for string manipulation and printing>= *)
fun printUTF8 code =
  let val w = Word.fromInt code
      val (&, >>) = (Word.andb, Word.>>)
      infix 6 & >>
      val _ = if (w & 0wx1fffff) <> w then
                raise RuntimeError (intString code ^
                                    " does not represent a Unicode code point")
              else
                 ()
      val printbyte = xprint o str o chr o Word.toInt
      fun prefix byte byte' = Word.orb (byte, byte')
  in  if w > 0wxffff then
        app printbyte [ prefix 0wxf0  (w >> 0w18)
                      , prefix 0wx80 ((w >> 0w12) & 0wx3f)
                      , prefix 0wx80 ((w >>  0w6) & 0wx3f)
                      , prefix 0wx80 ((w      ) & 0wx3f)
                      ]
      else if w > 0wx7ff then
        app printbyte [ prefix 0wxe0  (w >> 0w12)
                      , prefix 0wx80 ((w >>  0w6) & 0wx3f)
                      , prefix 0wx80 ((w        ) & 0wx3f)
                      ]
      else if w > 0wx7f then
        app printbyte [ prefix 0wxc0  (w >>  0w6)
                      , prefix 0wx80 ((w        ) & 0wx3f)
                      ]
      else
        printbyte w
  end
(* The internal function [[kind]] computes the kind of  *)
(* [[tau]]; the environment [[Delta]] is assumed. *)
(* Function [[kind]] implements the kinding rules in the *)
(* same way that [[typeof]] implements the typing rules *)
(* and [[eval]] implements the operational semantics. *)
(*                                              *)
(* The kind of a type variable is looked up in the *)
(* environment. \usetyKindIntroVar Thanks to the parser *)
(* in \creftuschemea.parser, the name of a type variable *)
(* always begins with a quote mark, so it is distinct *)
(* from any type constructor. \tusflabelkind    *)
(* <utility functions for string manipulation and printing>= *)
fun stripNumericSuffix s =
      let fun stripPrefix []         = s   (* don't let things get empty *)
            | stripPrefix (#"-"::[]) = s
            | stripPrefix (#"-"::cs) = implode (reverse cs)
            | stripPrefix (c   ::cs) = if Char.isDigit c then stripPrefix cs
                                       else implode (reverse (c::cs))
      in  stripPrefix (reverse (explode s))
      end
(* \stdbreak                                    *)
(*                                              *)
(* Utility functions for sets, collections, and lists *)
(*                                              *)
(* Sets                                         *)
(*                                              *)
(* Quite a few analyses of programs, including a type *)
(* checker in \creftypesys.chap and the type inference *)
(* in \crefml.chap, need to manipulate sets of  *)
(* variables. In small programs, such sets are usually *)
(* small, so I provide a simple implementation that *)
(* represents a set using a list with no duplicate *)
(* elements. It's essentially the same implementation *)
(* that you see in micro-Scheme in \crefscheme.chap. [ *)
(* The~\ml~types of the set operations include type *)
(* variables with double primes, like~[[''a]]. The type *)
(* variable~[[''a]] can be instantiated only with an *)
(* ``equality type.'' Equality types include base types *)
(* like strings and integers, as well as user-defined *)
(* types that do not contain functions. Functions \emph *)
(* {cannot} be compared for equality.]          *)

(* Representing error outcomes as values        *)
(*                                              *)
(* When an error occurs, especially during evaluation, *)
(* the best and most convenient thing to do is often to *)
(* raise an ML exception, which can be caught in a *)
(* handler. But it's not always easy to put a handler *)
(* exactly where it's needed. To get the code right, it *)
(* may be better to represent an error outcome as a *)
(* value. Like any other value, such a value can be *)
(* passed and returned until it reaches a place where a *)
(* decision is made.                            *)
(*                                              *)
(*   • When representing the outcome of a unit test, an *)
(*  error means failure for [[check-expect]] but *)
(*  success for [[check-error]]. Rather than juggle *)
(*  ``exception'' versus ``non-exception,'' I treat *)
(*  both outcomes on the same footing, as values. *)
(*  Successful evaluation to produce bridge-language *)
(*  value v is represented as ML value \monoOK v. *)
(*  Evaluation that signals an error with message m *)
(*  is represented as ML value \monoERROR m.    *)
(*  Constructors [[OK]] and [[ERROR]] are the value *)
(*  constructors of the algebraic data type     *)
(*  [[error]], defined here:                    *)
(* <support for representing errors as \ml\ values>= *)
datatype 'a error = OK of 'a | ERROR of string
(* <support for representing errors as \ml\ values>= *)
infix 1 >>=
fun (OK x)      >>= k  =  k x
  | (ERROR msg) >>= k  =  ERROR msg
(* What if we have a function [[f]] that could return *)
(* an [['a]] or an error, and another function [[g]] *)
(* that expects an [['a]]? Because the expression \ *)
(* monoboxg (f x) isn't well typed, standard function *)
(* composition doesn't exactly make sense, but the idea *)
(* of composition is good. Composition just needs to *)
(* take a new form, and luckily, there's already a *)
(* standard. The standard composition relies on a *)
(* sequencing operator written [[>>=]], which uses a *)
(* special form of continuation-passing style. (The *)
(* [[>>=]] operator is traditionally called ``bind,'' *)
(* but you might wish to pronounce it ``and then.'') *)
(* The idea is to apply [[f]] to [[x]], and if the *)
(* result is [[OK y]], to continue by applying [[g]] to  *)
(* [[y]]. But if the result of applying [[(f x)]] is an *)
(* error, that error is the result of the whole *)
(* computation. The [[>>=]] operator sequences the *)
(* possibly erroneous result [[(f x)]] with the *)
(* continuation [[g]], so where we might wish to write \ *)
(* monoboxg (f x), we instead write             *)
(*                                              *)
(*  [[f x >>= g]].                              *)
(*                                              *)
(* In the definition of [[>>=]], I write the second *)
(* function as [[k]], not [[g]], because [[k]] is a *)
(* traditional metavariable for a continuation. *)
(* <boxed values 53>=                           *)
val _ = op >>= : 'a error * ('a -> 'b error) -> 'b error
(* The [[xdeftable]] is shared with the Impcore parser. *)
(* Function [[reduce_to_xdef]] is almost shareable as *)
(* well, but not quite---the abstract syntax of *)
(* [[DEFINE]] is different.                     *)

(* A very common special case occurs when the   *)
(* continuation always succeeds; that is, the   *)
(* continuation [[k']] has type \monobox'a -> 'b instead *)
(* of \monobox'a -> 'b error. In this case, the *)
(* execution plan is that when [[(f x)]] succeeds, *)
(* continue by applying [[k']] to the result; otherwise *)
(* propagate the error. I know of no standard way to *)
(* write this operator, [Haskell uses [[flip fmap]].] , *)
(* so I use [[>>=+]], which you might also choose to *)
(* pronounce ``and then.''                      *)

(* <support for representing errors as \ml\ values>= *)
infix 1 >>=+
fun e >>=+ k'  =  e >>= (OK o k')
(* <boxed values 54>=                           *)
val _ = op >>=+ : 'a error * ('a -> 'b) -> 'b error
(* <support for representing errors as \ml\ values>= *)
fun errorList es =
  let fun cons (OK x, OK xs) = OK (x :: xs)
        | cons (ERROR m1, ERROR m2) = ERROR (m1 ^ "; " ^ m2)
        | cons (ERROR m, OK _) = ERROR m
        | cons (OK _, ERROR m) = ERROR m
  in  foldr cons (OK []) es
  end
(* Sometimes I map an error-producing function over a *)
(* list of values to get a list of [['a error]] results. *)
(* Such a list is hard to work with, and the right thing *)
(* to do with it is to convert it to a single value *)
(* that's either an [['a list]] or an error. In my code, *)
(* the conversion operation is called [[errorList]]. [ *)
(* Haskell calls it [[sequence]].] It is implemented by *)
(* folding over the list of possibly erroneous results, *)
(* concatenating all error messages.            *)
(* <boxed values 55>=                           *)
val _ = op errorList : 'a error list -> 'a list error
(* [[funty]] stand for \tau, [[actualtypes]]    *)
(* stand for \ldotsntau, and [[rettype]] stand for alpha *)
(* . The first premise is implemented by a call to *)
(* [[typesof]] and the second by a call to      *)
(* [[freshtyvar]]. The constraint is represented just as *)
(* written in the rule.                         *)

(* <support for representing errors as \ml\ values>= *)
fun errorLabel s (OK x) = OK x
  | errorLabel s (ERROR msg) = ERROR (s ^ msg)
(* A reusable read-eval-print loop              *)
(*                                              *)
(* [*] In each bridge-language interpreter, functions *)
(* [[eval]] and [[evaldef]] process expressions and true *)
(* definitions. But each interpreter also has to process *)
(* the extended definitions [[USE]] and [[TEST]], which *)
(* need more tooling:                           *)
(*                                              *)
(*   • To process a [[USE]], the interpreter must be *)
(*  able to parse definitions from a file and enter a *)
(*  read-eval-print loop recursively.           *)
(*   • To process a [[TEST]] (like [[check_expect]] or *)
(*  [[check_error]]), the interpreter must be able to *)
(*  run tests, and to run a test, it must call  *)
(*  [[eval]].                                   *)
(*                                              *)
(* Much the tooling can be shared among more than one *)
(* bridge language. To make sharing easy, I introduce *)
(* some abstraction.                            *)
(*                                              *)
(*   • Type [[basis]], which is different for each *)
(*  bridge language, stands for the collection of *)
(*  environment or environments that are used at top *)
(*  level to evaluate a definition. The name basis *)
(*  comes from The Definition of Standard ML \citep *)
(*  milner:definition-revised.                  *)
(*                                              *)
(*  For micro-Scheme, a [[basis]] is a single   *)
(*  environment that maps each name to a mutable *)
(*  location holding a value. For Impcore, a    *)
(*  [[basis]] would include both global-variable and *)
(*  function environments. And for later languages *)
(*  that have static types, a [[basis]] includes *)
(*  environments that store information about types. *)
(*   • Function [[processDef]], which is different for *)
(*  each bridge language, takes a [[def]] and a *)
(*  [[basis]] and returns an updated [[basis]]. *)
(*  For micro-Scheme, [[processDef]] just evaluates *)
(*  the definition, using [[evaldef]]. For languages *)
(*  that have static types (Typed Impcore, Typed *)
(*  uScheme, and \nml in \creftuscheme.chap,ml.chap, *)
(*  among others), [[processDef]] includes two  *)
(*  phases: type checking followed by evaluation. *)
(*                                              *)
(*  Function [[processDef]] also needs to be told *)
(*  about interaction, which has two dimensions: *)
(*  input and output. On input, an interpreter may or *)
(*  may not prompt:                             *)
(* <type [[interactivity]] plus related functions and value>= *)
datatype input_interactivity = PROMPTING | NOT_PROMPTING
(* On output, an interpreter may or may not show a *)
(* response to each definition.                 *)

(* <type [[interactivity]] plus related functions and value>= *)
datatype output_interactivity = ECHOING | NOT_ECHOING
(* <type [[interactivity]] plus related functions and value>= *)
type interactivity = 
  input_interactivity * output_interactivity
val noninteractive = 
  (NOT_PROMPTING, NOT_ECHOING)
fun prompts (PROMPTING,     _) = true
  | prompts (NOT_PROMPTING, _) = false
fun echoes (_, ECHOING)     = true
  | echoes (_, NOT_ECHOING) = false
(* The two of information together form a value of type *)
(* [[interactivity]]. Such a value can be queried by *)
(* predicates [[prompts]] and [[print]].        *)
(* <boxed values 86>=                           *)
type interactivity = interactivity
val _ = op noninteractive : interactivity
val _ = op prompts : interactivity -> bool
val _ = op echoes  : interactivity -> bool
(* <simple implementations of set operations>=  *)
type 'a set = 'a list
val emptyset = []
fun member x = 
  List.exists (fn y => y = x)
fun insert (x, ys) = 
  if member x ys then ys else x::ys
fun union (xs, ys) = foldl insert ys xs
fun inter (xs, ys) =
  List.filter (fn x => member x ys) xs
fun diff  (xs, ys) = 
  List.filter (fn x => not (member x ys)) xs
(* <boxed values 46>=                           *)
type 'a set = 'a set
val _ = op emptyset : 'a set
val _ = op member   : ''a -> ''a set -> bool
val _ = op insert   : ''a     * ''a set  -> ''a set
val _ = op union    : ''a set * ''a set  -> ''a set
val _ = op inter    : ''a set * ''a set  -> ''a set
val _ = op diff     : ''a set * ''a set  -> ''a set
(* [[bindList]] tried to                        *)
(*              extend an environment, but it passed *)
(*              two lists (names and values) of *)
(*              different lengths.              *)
(* RuntimeError    Something else went wrong during *)
(*              evaluation, i.e., during the    *)
(*              execution of [[eval]].          *)
(* \bottomrule                                  *)
(*                                              *)
(* Exceptions defined especially for this interpreter  *)
(* [*]                                          *)
(* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ *)
(*                                              *)
(* Abstract syntax and values                   *)
(*                                              *)
(* An abstract-syntax tree can contain a literal value. *)
(* A value, if it is a closure, can contain an  *)
(* abstract-syntax tree. These two types are therefore *)
(* mutually recursive, so I define them together, using *)
(* [[and]].                                     *)
(*                                              *)
(* These particular types use as complicated a nest of *)
(* definitions as you'll ever see. The keyword  *)
(* [[datatype]] defines a new algebraic datatype; the *)
(* keyword [[withtype]] introduces a new type   *)
(* abbreviation that is mutually recursive with the *)
(* [[datatype]]. The first group of [[and]] keywords *)
(* define additional algebraic datatypes, and the second *)
(* group of [[and]] keywords define additional type *)
(* abbreviations. Everything in the whole nest is *)
(* mutually recursive. [*] [*]                  *)

(* <ability to interrogate environment variable [[BPCOPTIONS]]>= *)
local
  val split = String.tokens (fn c => c = #",")
  val optionTokens =
    getOpt (Option.map split (OS.Process.getEnv "BPCOPTIONS"), [])
in
  fun hasOption s = member s optionTokens
(* <boxed values 52>=                           *)
val _ = op hasOption : string -> bool
end
(* <collections with mapping and combining functions>= *)
datatype 'a collection = C of 'a set
fun elemsC (C xs) = xs
fun singleC x     = C [x]
val emptyC        = C []
(* <boxed values 47>=                           *)
type 'a collection = 'a collection
val _ = op elemsC  : 'a collection -> 'a set
val _ = op singleC : 'a -> 'a collection
val _ = op emptyC  :       'a collection
(* <collections with mapping and combining functions>= *)
fun joinC     (C xs) = C (List.concat (map elemsC xs))
fun mapC  f   (C xs) = C (map f xs)
fun filterC p (C xs) = C (List.filter p xs)
fun mapC2 f (xc, yc) = joinC (mapC (fn x => mapC (fn y => f (x, y)) yc) xc)
(* The [[collection]] type is intended to be used some *)
(* more functions that are defined below. In particular, *)
(* functions [[joinC]] and [[mapC]], together with *)
(* [[singleC]], form a monad. (If you've heard of *)
(* monads, you may know that they are a useful  *)
(* abstraction for containers and collections of all *)
(* kinds; they also have more exotic uses, such as *)
(* expressing input and output as pure functions. The  *)
(* [[collection]] type is the monad for nondeterminism, *)
(* which is to say, all possible combinations or *)
(* outcomes. If you know about monads, you may have *)
(* picked up some programming tricks you can reuse. But *)
(* you don't need to know monads to do any of the *)
(* exercises in this book.)                     *)
(*                                              *)
(* The key functions on collections are as follows: *)
(*                                              *)
(*   • Functions [[mapC]] and [[filterC]] do for *)
(*  collections what [[map]] and [[filter]] do for *)
(*  lists.                                      *)
(*   • Function [[joinC]] takes a collection of *)
(*  collections of tau's and reduces it to a single *)
(*  collection of tau's. When [[mapC]] is used with a *)
(*  function that itself returns a collection,  *)
(*  [[joinC]] usually follows, as exemplified in the *)
(*  implementation of [[mapC2]] below.          *)
(*   • Function [[mapC2]] is the most powerful of *)
(*  all—its type resembles the type of Standard ML's *)
(*  [[ListPair.map]], but it works differently: where *)
(*  [[ListPair.map]] takes elements pairwise,   *)
(*  [[mapC2]] takes all possible combinations.  *)
(*  In particular, if you give [[ListPair.map]] two *)
(*  lists containing N and M elements respectively, *)
(*  the number of elements in the result is min(N,M). *)
(*  If you give collections of size N and M to  *)
(*  [[mapC2]], the number of elements in the result *)
(*  is N\atimesM.                               *)
(*                                              *)
(* \nwnarrowboxes                               *)
(* <boxed values 48>=                           *)
val _ = op joinC   : 'a collection collection -> 'a collection
val _ = op mapC    : ('a -> 'b)      -> ('a collection -> 'b collection)
val _ = op filterC : ('a -> bool)    -> ('a collection -> 'a collection)
val _ = op mapC2   : ('a * 'b -> 'c) -> ('a collection * 'b collection -> 'c
                                                                     collection)
(* <suspensions>=                               *)
datatype 'a action
  = PENDING  of unit -> 'a
  | PRODUCED of 'a

type 'a susp = 'a action ref
(* Suspensions: repeatable access to the result of one *)
(* action                                       *)
(*                                              *)
(* Streams are built around a single abstraction: the *)
(* suspension, which is also called a thunk.    *)
(* A suspension of type [['a susp]] represents a value *)
(* of type [['a]] that is produced by an action, like *)
(* reading a line of input. The action is not performed *)
(* until the suspension's value is demanded by function *)
(* [[demand]]. [If~you're familiar with suspensions or *)
(* with lazy computation in general, you know that the *)
(* function [[demand]] is traditionally called  *)
(* [[force]]. But I~use the name [[force]] to refer to a *)
(* similar function in the \uhaskell\ interpreter, which *)
(* implements a full language around the idea of lazy *)
(* computation. It~is possible to have two functions *)
(* called [[force]]---they can coexist peacefully---but *)
(* I~think it's too confusing. So~the less important *)
(* function, which is presented here, is called *)
(* [[demand]]. Even though my \uhaskell\ chapter never *)
(* made it into the book.] The action itself is *)
(* represented by a function of type \monoboxunit -> 'a. *)
(* A suspension is created by passing an action to the *)
(* function [[delay]]; at that point, the action is *)
(* ``pending.'' If [[demand]] is never called, the *)
(* action is never performed and remains pending. The *)
(* first time [[demand]] is called, the action is *)
(* performed, and the suspension saves the result that *)
(* is produced. \stdbreak If [[demand]] is called *)
(* multiple times, the action is still performed just *)
(* once—later calls to [[demand]] don't repeat the *)
(* action; instead they return the value previously *)
(* produced.                                    *)
(*                                              *)
(* To implement suspensions, I use a standard   *)
(* combination of imperative and functional code. *)
(* A suspension is a reference to an [[action]], which *)
(* can be pending or can have produced a result. *)
(* <boxed values 62>=                           *)
type 'a susp = 'a susp
(* <suspensions>=                               *)
fun delay f = ref (PENDING f)
fun demand cell =
  case !cell
    of PENDING f =>  let val result = f ()
                     in  (cell := PRODUCED result; result)
                     end
     | PRODUCED v => v
(* \qbreak Functions [[delay]] and [[demand]] convert to *)
(* and from suspensions.                        *)
(* <boxed values 63>=                           *)
val _ = op delay  : (unit -> 'a) -> 'a susp
val _ = op demand : 'a susp -> 'a
(* Streams: results of a sequence of actions    *)
(*                                              *)
(* [*] A stream behaves much like a list, except that *)
(* the first time an element is inspected, an action *)
(* might be taken. And unlike a list, a stream can be *)
(* infinite. My code uses streams of lines, streams of *)
(* characters, streams of definitions, and even streams *)
(* of source-code locations. In this section I define *)
(* streams and many related utility functions. Most of *)
(* the utility functions are inspired by list functions *)
(* like [[map]], [[filter]], [[concat]], [[zip]], and *)
(* [[foldl]].                                   *)
(*                                              *)
(* Stream representation and basic functions    *)
(*                                              *)
(* The representation of a stream takes one of three *)
(* forms: [There are representations that use fewer *)
(* forms, but this one has the merit that I~can define a *)
(* polymorphic empty stream without running afoul of \ *)
(* ml's ``value restriction.'']                 *)
(*                                              *)
(*   • The [[EOS]] constructor represents an empty *)
(*  stream.                                     *)
(*                                              *)
(*   • The [[:::]] constructor (pronounced ``cons''), *)
(*  which should remind you of ML's [[::]]      *)
(*  constructor for lists, represents a stream in *)
(*  which an action has already been taken, and the *)
(*  first element of the stream is available (as are *)
(*  the remaining elements). Like the [[::]]    *)
(*  constructor for lists, the [[:::]] constructor is *)
(*  written as an infix operator.               *)
(*                                              *)
(*   • The [[SUSPENDED]] constructor represents a stream *)
(*  in which the action needed to produce the next *)
(*  element may not yet have been taken. Getting the *)
(*  element requires demanding a value from a   *)
(*  suspension, and if the action in the suspension *)
(*  is pending, it is performed at that time.   *)
(*                                              *)
(* [*]                                          *)
(* <streams>=                                   *)
datatype 'a stream 
  = EOS
  | :::       of 'a * 'a stream
  | SUSPENDED of 'a stream susp
infixr 3 :::
(* <streams>=                                   *)
fun streamGet EOS = NONE
  | streamGet (x ::: xs)    = SOME (x, xs)
  | streamGet (SUSPENDED s) = streamGet (demand s)
(* <streams>=                                   *)
fun streamOfList xs = 
  foldr (op :::) EOS xs
(* Even though its representation uses mutable state *)
(* (the suspension), the stream is an immutable *)
(* abstraction. [When debugging, I~sometimes violate the *)
(* abstraction and look at the state of a [[SUSPENDED]] *)
(* stream.] To observe that abstraction, call   *)
(* [[streamGet]]. This function performs whatever *)
(* actions are needed either to produce a pair holding *)
(* an element an a stream (represented as \monoSOME (x, *)
(* xs)) or to decide that the stream is empty and no *)
(* more elements can be produced (represented as *)
(* [[NONE]]).                                   *)
(* <boxed values 64>=                           *)
val _ = op streamGet : 'a stream -> ('a * 'a stream) option
(* [[funty]] stand for \tau, [[actualtypes]]    *)
(* stand for \ldotsntau, and [[rettype]] stand for alpha *)
(* . The first premise is implemented by a call to *)
(* [[typesof]] and the second by a call to      *)
(* [[freshtyvar]]. The constraint is represented just as *)
(* written in the rule.                         *)

(* The simplest way to create a stream is by using the *)
(* [[:::]] or [[EOS]] constructor. A stream can also be *)
(* created from a list. When such a stream is read, no *)
(* new actions are performed.                   *)
(* <boxed values 64>=                           *)
val _ = op streamOfList : 'a list -> 'a stream
(* <streams>=                                   *)
fun listOfStream xs =
  case streamGet xs
    of NONE => []
     | SOME (x, xs) => x :: listOfStream xs
(* <streams>=                                   *)
fun delayedStream action = 
  SUSPENDED (delay action)
(* Function [[listOfStream]] creates a list from a *)
(* stream. It is useful for debugging.          *)
(* <boxed values 65>=                           *)
val _ = op listOfStream : 'a stream -> 'a list
(* The more interesting streams are those that result *)
(* from actions. To help create such streams, I define *)
(* [[delayedStream]] as a convenience abbreviation for *)
(* creating a stream from one action.           *)
(* <boxed values 65>=                           *)
val _ = op delayedStream : (unit -> 'a stream) -> 'a stream
(* <streams>=                                   *)
fun streamOfEffects action =
  delayedStream (fn () => case action ()
                            of NONE   => EOS
                             | SOME a => a ::: streamOfEffects action)
(* Creating streams using actions and functions *)
(*                                              *)
(* Function [[streamOfEffects]] produces the stream of *)
(* results obtained by repeatedly performing a single *)
(* action (like reading a line of input). \stdbreak The *)
(* action must have type [[unit -> 'a option]]; the *)
(* stream performs the action repeatedly, producing a *)
(* stream of [['a]] values until performing the action *)
(* returns [[NONE]].                            *)
(* <boxed values 66>=                           *)
val _ = op streamOfEffects : (unit -> 'a option) -> 'a stream
(* Function [[streamOfEffects]] can be used to produce a *)
(* stream of lines from an input file:          *)

(* <streams>=                                   *)
type line = string
fun filelines infile = 
  streamOfEffects (fn () => TextIO.inputLine infile)
(* <boxed values 67>=                           *)
type line = line
val _ = op filelines : TextIO.instream -> line stream
(* [[funty]] stand for \tau, [[actualtypes]]    *)
(* stand for \ldotsntau, and [[rettype]] stand for alpha *)
(* . The first premise is implemented by a call to *)
(* [[typesof]] and the second by a call to      *)
(* [[freshtyvar]]. The constraint is represented just as *)
(* written in the rule.                         *)

(* <streams>=                                   *)
fun streamRepeat x =
  delayedStream (fn () => x ::: streamRepeat x)
(* <boxed values 68>=                           *)
val _ = op streamRepeat : 'a -> 'a stream
(* The [[xdeftable]] is shared with the Impcore parser. *)
(* Function [[reduce_to_xdef]] is almost shareable as *)
(* well, but not quite---the abstract syntax of *)
(* [[DEFINE]] is different.                     *)

(* <streams>=                                   *)
fun streamOfUnfold next state =
  delayedStream
    (fn () => case next state
                of NONE => EOS
                 | SOME (a, state') => a ::: streamOfUnfold next state')
(* A more sophisticated way to produce a stream is to *)
(* use a function that depends on an evolving state of *)
(* some unknown type [['b]]. The function is applied to *)
(* a state (of type [['b]]) and may produce a pair *)
(* containing a value of type [['a]] and a new state. *)
(* Repeatedly applying the function can produce a *)
(* sequence of results of type [['a]]. This operation, *)
(* in which a function is used to expand a value into a *)
(* sequence, is the dual of the fold operation, which is *)
(* used to collapse a sequence into a value. The new *)
(* operation is therefore called unfold.        *)
(* <boxed values 69>=                           *)
val _ = op streamOfUnfold : ('b -> ('a * 'b) option) -> 'b -> 'a stream
(* Function [[streamOfUnfold]] can turn any ``get'' *)
(* function into a stream. In fact, the unfold and get *)
(* operations should obey the following algebraic law: *)
(*                                              *)
(*  streamOfUnfold streamGet xs ===xs\text.     *)
(*                                              *)
(* Another useful ``get'' function is [[(fn n => SOME *)
(* (n, n+1))]]; passing this function to        *)
(* [[streamOfUnfold]] results in an infinite stream of *)
(* increasing integers. [*]                     *)

(* <streams>=                                   *)
val naturals = 
  streamOfUnfold (fn n => SOME (n, n+1)) 0   (* 0 to infinity *)
(* <boxed values 70>=                           *)
val _ = op naturals : int stream
(* [[funty]] stand for \tau, [[actualtypes]]    *)
(* stand for \ldotsntau, and [[rettype]] stand for alpha *)
(* . The first premise is implemented by a call to *)
(* [[typesof]] and the second by a call to      *)
(* [[freshtyvar]]. The constraint is represented just as *)
(* written in the rule.                         *)

(* (Streams, like lists, support not only unfolding but *)
(* also folding. The fold function [[streamFold]] is *)
(* defined below in chunk [->].)                *)
(*                                              *)
(* Attaching extra actions to streams           *)
(*                                              *)
(* A stream built with [[streamOfEffects]] or   *)
(* [[filelines]] has an imperative action built in. *)
(* But in an interactive interpreter, the action of *)
(* reading a line should be preceded by another action: *)
(* printing the prompt. And deciding just what prompt to *)
(* print requires orchestrating other actions.  *)
(* One option, which I use below, is to attach an *)
(* imperative action to a ``get'' function used with *)
(* [[streamOfUnfold]]. Another option, which is *)
(* sometimes easier to understand, is to attach an *)
(* action to the stream itself. Such an action could *)
(* reasonably be performed either before or after the *)
(* action of getting an element from the stream. *)
(*                                              *)
(* Given an action [[pre]] and a stream xs, I define a *)
(* stream \monoboxpreStream (pre, xs) that adds \monobox *)
(* pre () to the action performed by the stream. Roughly *)
(* speaking,                                    *)
(*                                              *)
(*  \monostreamGet (preStream (pre, xs)) = \mono(pre *)
(*  (); streamGet xs).                          *)
(*                                              *)
(* (The equivalence is only rough because the pre action *)
(* is performed lazily, only when an action is needed to *)
(* get a value from xs.)                        *)

(* <streams>=                                   *)
fun preStream (pre, xs) = 
  streamOfUnfold (fn xs => (pre (); streamGet xs)) xs
(* It's also useful to be able to perform an action *)
(* immediately after getting an element from a stream. *)
(* In [[postStream]], I perform the action only if *)
(* [[streamGet]] succeeds. By performing the [[post]] *)
(* action only when [[streamGet]] succeeds, I make it *)
(* possible to write a [[post]] action that has access *)
(* to the element just gotten. Post-get actions are *)
(* especially useful for debugging.             *)

(* <streams>=                                   *)
fun postStream (xs, post) =
  streamOfUnfold (fn xs => case streamGet xs
                             of NONE => NONE
                              | head as SOME (x, _) => (post x; head)) xs
(* <boxed values 71>=                           *)
val _ = op preStream : (unit -> unit) * 'a stream -> 'a stream
(* <boxed values 71>=                           *)
val _ = op postStream : 'a stream * ('a -> unit) -> 'a stream
(* <streams>=                                   *)
fun streamMap f xs =
  delayedStream (fn () => case streamGet xs
                            of NONE => EOS
                             | SOME (x, xs) => f x ::: streamMap f xs)
(* <boxed values 72>=                           *)
val _ = op streamMap : ('a -> 'b) -> 'a stream -> 'b stream
(* [[funty]] stand for \tau, [[actualtypes]]    *)
(* stand for \ldotsntau, and [[rettype]] stand for alpha *)
(* . The first premise is implemented by a call to *)
(* [[typesof]] and the second by a call to      *)
(* [[freshtyvar]]. The constraint is represented just as *)
(* written in the rule.                         *)

(* <streams>=                                   *)
fun streamFilter p xs =
  delayedStream (fn () => case streamGet xs
                            of NONE => EOS
                             | SOME (x, xs) => if p x then x ::: streamFilter p
                                                                              xs
                                               else streamFilter p xs)
(* <boxed values 73>=                           *)
val _ = op streamFilter : ('a -> bool) -> 'a stream -> 'a stream
(* <streams>=                                   *)
fun streamFold f z xs =
  case streamGet xs of NONE => z
                     | SOME (x, xs) => streamFold f (f (x, z)) xs
(* The only sensible order in which to fold the elements *)
(* of a stream is the order in which the actions are *)
(* taken and the results are produced: from left to *)
(* right. [*]                                   *)
(* <boxed values 74>=                           *)
val _ = op streamFold : ('a * 'b -> 'b) -> 'b -> 'a stream -> 'b
(* <streams>=                                   *)
fun streamZip (xs, ys) =
  delayedStream
  (fn () => case (streamGet xs, streamGet ys)
              of (SOME (x, xs), SOME (y, ys)) => (x, y) ::: streamZip (xs, ys)
               | _ => EOS)
(* <streams>=                                   *)
fun streamConcat xss =
  let fun get (xs, xss) =
        case streamGet xs
          of SOME (x, xs) => SOME (x, (xs, xss))
           | NONE => case streamGet xss
                       of SOME (xs, xss) => get (xs, xss)
                        | NONE => NONE
  in  streamOfUnfold get (EOS, xss)
  end
(* Function [[streamZip]] returns a stream that is as *)
(* long as the shorter of the two argument streams. *)
(* In particular, if [[streamZip]] is applied to a *)
(* finite stream and an infinite stream, the result is a *)
(* finite stream.                               *)
(* <boxed values 75>=                           *)
val _ = op streamZip : 'a stream * 'b stream -> ('a * 'b) stream
(* <boxed values 75>=                           *)
val _ = op streamConcat : 'a stream stream -> 'a stream
(* <streams>=                                   *)
fun streamConcatMap f xs = streamConcat (streamMap f xs)
(* In list and stream processing, [[concat]] is very *)
(* often composed with [[map f]]. The composition is *)
(* usually called [[concatMap]].                *)
(* <boxed values 76>=                           *)
val _ = op streamConcatMap : ('a -> 'b stream) -> 'a stream -> 'b stream
(* <streams>=                                   *)
infix 5 @@@
fun xs @@@ xs' = streamConcat (streamOfList [xs, xs'])
(* The code used to append two streams is much like the *)
(* code used to concatenate arbitrarily many streams. *)
(* To avoid duplicating the tricky manipulation of *)
(* states, I implement append using concatenation. *)
(* <boxed values 77>=                           *)
val _ = op @@@ : 'a stream * 'a stream -> 'a stream
(* [[funty]] stand for \tau, [[actualtypes]]    *)
(* stand for \ldotsntau, and [[rettype]] stand for alpha *)
(* . The first premise is implemented by a call to *)
(* [[typesof]] and the second by a call to      *)
(* [[freshtyvar]]. The constraint is represented just as *)
(* written in the rule.                         *)

(* <streams>=                                   *)
fun streamTake (0, xs) = []
  | streamTake (n, xs) =
      case streamGet xs
        of SOME (x, xs) => x :: streamTake (n-1, xs)
         | NONE => []
(* Whenever I rename bound variables, for example in a *)
(* type \/\ldotsnalpha\alldottau, I have to choose new *)
(* names that don't conflict with existing names in tau *)
(* or in the environment. The easiest way to get good *)
(* names to build an infinite stream of names by using *)
(* [[streamMap]] on [[naturals]], then use      *)
(* [[streamFilter]] to choose only the good ones, and *)
(* finally to take exactly as many good names as I need *)
(* by calling [[streamTake]], which is defined here. *)
(* <boxed values 78>=                           *)
val _ = op streamTake : int * 'a stream -> 'a list
(* <streams>=                                   *)
fun streamDrop (0, xs) = xs
  | streamDrop (n, xs) =
      case streamGet xs
        of SOME (_, xs) => streamDrop (n-1, xs)
         | NONE => EOS
(* Once I've used [[streamTake]], I get the rest of the *)
(* stream with [[streamDrop]] (\chunkref        *)
(* mlinterps.chunk.use-streamDrop).             *)
(* <boxed values 79>=                           *)
val _ = op streamDrop : int * 'a stream -> 'a stream
(* <stream transformers and their combinators>= *)
type ('a, 'b) xformer = 
  'a stream -> ('b error * 'a stream) option
(* Stream transformers, which act as parsers    *)
(*                                              *)
(* The purpose of a parser is to turn streams of input *)
(* lines into streams of definitions. Intermediate *)
(* representations may include streams of characters, *)
(* tokens, types, expressions, and more. To handle all *)
(* these different kinds of streams using a single set *)
(* of operators, I define a type representing a stream *)
(* transformer. A stream transformer from A to B takes a *)
(* stream of A's as input and either succeeds, fails, or *)
(* detects an error:                            *)
(*                                              *)
(*   • If it succeeds, it consumes zero or more A's from *)
(*  the input stream and produces exactly one B. *)
(*  It returns a pair containing [[OK]] B plus  *)
(*  whatever A's were not consumed.             *)
(*   • If it fails, it returns [[NONE]].      *)
(*   • If it detects an error, it returns a pair *)
(*  containing [[ERROR]] m, where m is a message, *)
(*  plus whatever A's were not consumed.        *)
(*                                              *)
(* A stream transformer from A to B has type \monobox(A, *)
(* B) transformer.                              *)
(* <boxed values 117>=                          *)
type ('a, 'b) xformer = ('a, 'b) xformer
(* <stream transformers and their combinators>= *)
fun pure y = fn xs => SOME (OK y, xs)
(* The stream-transformer abstraction supports many, *)
(* many operations. These operations, known as parsing *)
(* combinators, have been refined by functional *)
(* programmers for over two decades, and they can be *)
(* expressed in a variety of guises. The guise I have *)
(* chosen uses notation from applicative functors and *)
(* from the ParSec parsing library.             *)
(*                                              *)
(* I begin very abstractly, by presenting combinators *)
(* that don't actually consume any inputs. The next two *)
(* sections present only ``constant'' transformers and *)
(* ``glue'' functions that build transformers from other *)
(* transformers. With those functions in place, *)
(* I proceed to real, working parsing combinators. These *)
(* combinators are split into two groups: ``universal'' *)
(* combinators that work with any stream, and   *)
(* ``parsing'' combinators that expect a stream of *)
(* tokens with source-code locations.           *)
(*                                              *)
(* My design includes a lot of combinators. Too many, *)
(* really. I would love to simplify the design, but *)
(* simplifying software can be hard, and I don't want to *)
(* delay the book by another year.              *)
(*                                              *)
(* --- #2                                       *)
(* \newskip\myskip \myskip=4pt                  *)
(*                                              *)
(* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ *)
(* \catcode`=\other \catcode`_=\other \catcode`$=\other *)
(*                                              *)
(*  Stream transformers; applying functions to  *)
(*  transformers                                *)
(*  \type('a, 'b) xformer \                     *)
(*  tableboxpure : 'b -> ('a, 'b)               *)
(*  xformer \splitbox<*>('a, 'b ->              *)
(*  'c) xformer * ('a, 'b)                      *)
(*  xformer-> ('a, 'c) xformer \                *)
(*  tablebox<> : ('b -> 'c) * ('a,              *)
(*  'b) xformer -> ('a, 'c)                     *)
(*  xformer \tablebox<>? : ('b ->               *)
(*  'c option) * ('a, 'b) xformer               *)
(*  -> ('a, 'c) xformer \splitbox               *)
(*  <*>!('a, 'b -> 'c error)                    *)
(*  xformer * ('a, 'b) xformer->                *)
(*  ('a, 'c) xformer \tablebox<>!               *)
(*  : ('b -> 'c error) * ('a, 'b)               *)
(*  xformer -> ('a, 'c) xformer                 *)
(*  [8pt] Functions useful with                 *)
(*  [[<>]] and [[<*>]]                          *)
(*  \tableboxfst : ('a * 'b) -> 'a              *)
(*  \tableboxsnd : ('a * 'b) -> 'b              *)
(*  \tableboxpair : 'a -> 'b -> 'a              *)
(*  * 'b \tableboxcurry : ('a * 'b              *)
(*  -> 'c) -> ('a -> 'b -> 'c) \                *)
(*  tableboxcurry3 : ('a * 'b * 'c              *)
(*  -> 'd) -> ('a -> 'b -> 'c ->                *)
(*  'd) [8pt] Combining                         *)
(*  transformers in sequence,                   *)
(*  alternation, or conjunction                 *)
(*  \tablebox<* : ('a, 'b) xformer >]] : ('a, 'b) *)
(*  * ('a, 'c) xformer -> ('a, 'b) xformer * ('a, 'c) *)
(*  xformer \tablebox *> : ('a,    xformer -> ('a, *)
(*  'b) xformer * ('a, 'c) xformer 'c) xformer [8pt] *)
(*  -> ('a, 'c) xformer \tablebox< Transformers *)
(*  : 'b * ('a, 'c) xformer ->     useful for both *)
(*  ('a, 'b) xformer \tablebox<|>  lexical analysis *)
(*  : ('a, 'b) xformer * ('a, 'b)  and parsing  *)
(*  xformer -> ('a, 'b) xformer \               *)
(*  tableboxpzero : ('a, 'b)                    *)
(*  xformer \tableboxanyParser :                *)
(*  ('a, 'b) xformer list -> ('a,               *)
(*  'b) xformer \tablebox[[<                    *)
(*  \tableboxone : ('a, 'a)                     *)
(*  xformer \tableboxeos : ('a,                 *)
(*  unit) xformer \tableboxsat :                *)
(*  ('b -> bool) -> ('a, 'b)                    *)
(*  xformer -> ('a, 'b) xformer \               *)
(*  tableboxeqx : ''b -> ('a, ''b)              *)
(*  xformer -> ('a, ''b) xformer                *)
(*  notFollowedBy                               *)
(*                                 ('a, 'b) xformer *)
(*                                 -> ('a, unit) *)
(*                                 xformer      *)
(*  \tableboxmany : ('a, 'b)                    *)
(*  xformer -> ('a, 'b list)                    *)
(*  xformer \tableboxmany1 : ('a,               *)
(*  'b) xformer -> ('a, 'b list)                *)
(*  xformer \tableboxoptional :                 *)
(*  ('a, 'b) xformer -> ('a, 'b                 *)
(*  option) xformer \tableboxpeek               *)
(*  : ('a, 'b) xformer -> 'a                    *)
(*  stream -> 'b option \tablebox               *)
(*  rewind : ('a, 'b) xformer ->                *)
(*  ('a, 'b) xformer                            *)
(*                                              *)
(* Stream transformers and their combinators [*] *)
(* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ *)
(*                                              *)
(* Error-free transformers and their composition *)
(*                                              *)
(* The [[pure]] combinator takes a value [[y]] of type B *)
(* as argument. It returns an \atob transformer that *)
(* consumes no A's as input and produces [[y]]. *)
(* <boxed values 118>=                          *)
val _ = op pure : 'b -> ('a, 'b) xformer
(* <stream transformers and their combinators>= *)
infix 3 <*>
fun tx_f <*> tx_b =
  fn xs => case tx_f xs
             of NONE => NONE
              | SOME (ERROR msg, xs) => SOME (ERROR msg, xs)
              | SOME (OK f, xs) =>
                  case tx_b xs
                    of NONE => NONE
                     | SOME (ERROR msg, xs) => SOME (ERROR msg, xs)
                     | SOME (OK y, xs) => SOME (OK (f y), xs)
(* To build a stream transformer that reads inputs in *)
(* sequence, I compose smaller stream transformers that *)
(* read parts of the input. The sequential composition *)
(* operator may look quite strange. To compose [[tx_f]] *)
(* and [[tx_b]] in sequence, I use the infix operator *)
(* [[<*>]], which is pronounced ``applied to.'' The *)
(* composition is written \monobox[[tx_f]] <*> [[tx_b]], *)
(* and it works like this:                      *)
(*                                              *)
(*  1. First [[tx_f]] reads some A's and produces a *)
(*  function [[f]] of type B -->C.              *)
(*  2. Next [[tx_b]] reads some more A's and produces a *)
(*  value [[y]] of type B.                      *)
(*  3. The combination [[tx_f <*> tx_b]] reads no more *)
(*  input but simply applies [[f]] to [[y]] and *)
(*  returns \monoboxf y (of type C) as its result. *)
(*                                              *)
(* This idea may seem crazy. How can reading a sequence *)
(* of A's produce a function? The secret is that almost *)
(* always, the function is produced by [[pure]], without *)
(* actually reading any A's, or it's the result of using *)
(* the [[<*>]] operator to apply a Curried function to *)
(* its first argument. But the                  *)
(* read-and-produce-a-function idiom is a great way to *)
(* do business, because when the parser is written using *)
(* the [[pure]] and [[<*>]] combinators, the code *)
(* resembles a Curried function application.    *)
(*                                              *)
(* For the combination [[tx_f <*> tx_b]] to succeed, *)
(* both [[tx_f]] and [[tx_b]] must succeed. Ensuring *)
(* that two transformers succeed requires a nested case *)
(* analysis.                                    *)
(* <boxed values 119>=                          *)
val _ = op <*> : ('a, 'b -> 'c) xformer * ('a, 'b) xformer -> ('a, 'c) xformer
(* <stream transformers and their combinators>= *)
infixr 4 <$>
fun f <$> p = pure f <*> p
(* The common case of creating [[tx_f]] using [[pure]] *)
(* is normally written using the special operator [[< *)
(* >]], which is also pronounced ``applied to.'' *)
(* It combines a B-to-C function with an \atob  *)
(* transformer to produce an \atoc transformer. *)
(* <boxed values 120>=                          *)
val _ = op <$> : ('b -> 'c) * ('a, 'b) xformer -> ('a, 'c) xformer
(* [[funty]] stand for \tau, [[actualtypes]]    *)
(* stand for \ldotsntau, and [[rettype]] stand for alpha *)
(* . The first premise is implemented by a call to *)
(* [[typesof]] and the second by a call to      *)
(* [[freshtyvar]]. The constraint is represented just as *)
(* written in the rule.                         *)

(* <stream transformers and their combinators>= *)
infix 1 <|>
fun t1 <|> t2 = (fn xs => case t1 xs of SOME y => SOME y | NONE => t2 xs) 
(* <boxed values 122>=                          *)
val _ = op <|> : ('a, 'b) xformer * ('a, 'b) xformer -> ('a, 'b) xformer
(* [[funty]] stand for \tau, [[actualtypes]]    *)
(* stand for \ldotsntau, and [[rettype]] stand for alpha *)
(* . The first premise is implemented by a call to *)
(* [[typesof]] and the second by a call to      *)
(* [[freshtyvar]]. The constraint is represented just as *)
(* written in the rule.                         *)

(* I sometimes want to combine a list of parsers with *)
(* the choice operator. I can do this by folding over *)
(* the list, provided I have a ``zero'' parser, which *)
(* always fails.                                *)

(* <stream transformers and their combinators>= *)
fun pzero _ = NONE
(* <stream transformers and their combinators>= *)
fun anyParser ts = 
  foldr op <|> pzero ts
(* <boxed values 123>=                          *)
val _ = op pzero : ('a, 'b) xformer
(* This parser obeys the algebraic law          *)
(*                                              *)
(*  \monoboxt <|> pzero = \monoboxpzero <|> t = \ *)
(*  monoboxt\text.                              *)
(*                                              *)
(* Because building choices from lists is common, *)
(* I implement this special case as [[anyParser]]. *)
(* <boxed values 123>=                          *)
val _ = op anyParser : ('a, 'b) xformer list -> ('a, 'b) xformer
(* [[funty]] stand for \tau, [[actualtypes]]    *)
(* stand for \ldotsntau, and [[rettype]] stand for alpha *)
(* . The first premise is implemented by a call to *)
(* [[typesof]] and the second by a call to      *)
(* [[freshtyvar]]. The constraint is represented just as *)
(* written in the rule.                         *)

(* <stream transformers and their combinators>= *)
infix 6 <* *>
fun p1 <*  p2 = curry fst <$> p1 <*> p2
fun p1  *> p2 = curry snd <$> p1 <*> p2

infixr 4 <$
fun v <$ p = (fn _ => v) <$> p
(* Ignoring results produced by transformers    *)
(*                                              *)
(* If a parser sees the stream of tokens {indented} *)
(* [[(]]                                        *)
(* [[if]]                                       *)
(* [[(]]                                        *)
(* [[<]]                                        *)
(* [[x]]                                        *)
(* [[y]]                                        *)
(* [[)]]                                        *)
(* [[x]]                                        *)
(* [[y]]                                        *)
(* [[)]] , {indented} I want it to build an     *)
(* abstract-syntax tree using [[IFX]] and three *)
(* expressions. The parentheses and keyword [[if]] serve *)
(* to identify the [[if]]-expression and to make sure it *)
(* is well formed, so the parser does have to read them *)
(* from the input, but it doesn't need to do anything *)
(* with the results that are produced. Using a parser *)
(* and then ignoring the result is such a common *)
(* operation that special abbreviations have evolved to *)
(* support it.                                  *)
(*                                              *)
(* The abbreviations are formed by modifying the [[<*>]] *)
(* or [[<>]] operator to remove the angle bracket on the *)
(* side containing the result to be ignored. For *)
(* example,                                     *)
(*                                              *)
(*   • Parser [[p1 <* p2]] reads the input of [[p1]] and *)
(*  then the input of [[p2]], but it returns only the *)
(*  result of [[p1]].                           *)
(*   • Parser [[p1 *> p2]] reads the input of [[p1]] and *)
(*  then the input of [[p2]], but it returns only the *)
(*  result of [[p2]].                           *)
(*   • Parser [[v < p]] parses the input the way [[p]] *)
(*   does, but it then ignores [[p]]'s result and *)
(*  instead produces the value [[v]].           *)
(*                                              *)
(* <boxed values 124>=                          *)
val _ = op <*  : ('a, 'b) xformer * ('a, 'c) xformer -> ('a, 'b) xformer
val _ = op  *> : ('a, 'b) xformer * ('a, 'c) xformer -> ('a, 'c) xformer
val _ = op <$  : 'b               * ('a, 'c) xformer -> ('a, 'b) xformer
(* <stream transformers and their combinators>= *)
fun one xs = case streamGet xs
               of NONE => NONE
                | SOME (x, xs) => SOME (OK x, xs)
(* At last, transformers that look at the input stream *)
(*                                              *)
(* None of the transformers above inspects an input *)
(* stream. The fundamental operations are [[pure]], *)
(* [[<*>]], and [[<|>]]; [[pure]] never looks at the *)
(* input, and [[<*>]] and [[<|>]] simply sequence or *)
(* alternate between other parsers which do the actual *)
(* looking. Those parsers are up next.          *)
(*                                              *)
(* The simplest input-inspecting parser is [[one]]. It's *)
(* an \atoa transformer that succeeds if and only if *)
(* there is a value in the input. If there's no value in *)
(* the input, [[one]] fails; it never signals an error. *)
(* <boxed values 125>=                          *)
val _ = op one : ('a, 'a) xformer
(* <stream transformers and their combinators>= *)
fun eos xs = case streamGet xs
               of NONE => SOME (OK (), EOS)
                | SOME _ => NONE
(* <boxed values 126>=                          *)
val _ = op eos : ('a, unit) xformer
(* [[funty]] stand for \tau, [[actualtypes]]    *)
(* stand for \ldotsntau, and [[rettype]] stand for alpha *)
(* . The first premise is implemented by a call to *)
(* [[typesof]] and the second by a call to      *)
(* [[freshtyvar]]. The constraint is represented just as *)
(* written in the rule.                         *)

(* Perhaps surprisingly, these are the only two standard *)
(* parsers that inspect input. The only other parsing *)
(* combinator that looks directly at input is the *)
(* function [[stripAndReportErrors]], which removes *)
(* [[ERROR]] and [[OK]] from error streams.     *)

(* <stream transformers and their combinators>= *)
fun peek tx xs =
  case tx xs of SOME (OK y, _) => SOME y
              | _ => NONE
(* It is sometimes useful to look at input without *)
(* consuming it. For this purpose I define two  *)
(* functions: [[peek]] just looks at a transformed *)
(* stream and maybe produces a value, whereas [[rewind]] *)
(* changes any transformer into a transformer that *)
(* behaves identically, but that doesn't consume any *)
(* input. I use these functions either to debug, or to *)
(* find the source-code location of the next token in a *)
(* token stream.                                *)
(* <boxed values 127>=                          *)
val _ = op peek : ('a, 'b) xformer -> 'a stream -> 'b option
(* [[funty]] stand for \tau, [[actualtypes]]    *)
(* stand for \ldotsntau, and [[rettype]] stand for alpha *)
(* . The first premise is implemented by a call to *)
(* [[typesof]] and the second by a call to      *)
(* [[freshtyvar]]. The constraint is represented just as *)
(* written in the rule.                         *)

(* <stream transformers and their combinators>= *)
fun rewind tx xs =
  case tx xs of SOME (ey, _) => SOME (ey, xs)
              | NONE => NONE
(* Given a transformer [[tx]], transformer \monobox *)
(* rewind tx computes the same value as [[tx]], but when *)
(* it's done, it rewinds the input stream back to where *)
(* it was before it ran [[tx]]. The actions performed by *)
(* [[tx]] can't be undone, but the inputs can be read *)
(* again.                                       *)
(* <boxed values 128>=                          *)
val _ = op rewind : ('a, 'b) xformer -> ('a, 'b) xformer
(* [[funty]] stand for \tau, [[actualtypes]]    *)
(* stand for \ldotsntau, and [[rettype]] stand for alpha *)
(* . The first premise is implemented by a call to *)
(* [[typesof]] and the second by a call to      *)
(* [[freshtyvar]]. The constraint is represented just as *)
(* written in the rule.                         *)

(* <stream transformers and their combinators>= *)
fun sat p tx xs =
  case tx xs
    of answer as SOME (OK y, xs) => if p y then answer else NONE
     | answer => answer
(* <boxed values 129>=                          *)
val _ = op sat : ('b -> bool) -> ('a, 'b) xformer -> ('a, 'b) xformer
(* <stream transformers and their combinators>= *)
fun eqx y = 
  sat (fn y' => y = y') 
(* Transformer [[eqx b]] is [[sat]] specialized to an *)
(* equality predicate. It is typically used to recognize *)
(* special characters like keywords and minus signs. *)
(* <boxed values 130>=                          *)
val _ = op eqx : ''b -> ('a, ''b) xformer -> ('a, ''b) xformer
(* The [[xdeftable]] is shared with the Impcore parser. *)
(* Function [[reduce_to_xdef]] is almost shareable as *)
(* well, but not quite---the abstract syntax of *)
(* [[DEFINE]] is different.                     *)

(* <stream transformers and their combinators>= *)
infixr 4 <$>?
fun f <$>? tx =
  fn xs => case tx xs
             of NONE => NONE
              | SOME (ERROR msg, xs) => SOME (ERROR msg, xs)
              | SOME (OK y, xs) =>
                  case f y
                    of NONE => NONE
                     | SOME z => SOME (OK z, xs)
(* A predicate of type \monobox('b -> bool) asks, ``Is *)
(* this a thing?'' But sometimes code wants to ask, ``Is *)
(* this a thing, and if so, what thing is it?'' *)
(* For example, a parser for Impcore or micro-Scheme *)
(* will want to know if an atom represents a numeric *)
(* literal, but if so, it would also like to know what *)
(* number is represented. Instead of a predicate, the *)
(* parser would use a function of type \monoboxatom -> *)
(* int option. In general, an \atob transformer can be *)
(* composed with a function of type \monoboxB -> C *)
(* option, and the result is an \atoxC transformer. *)
(* Because there's a close analogy with the application *)
(* operator [[<>]], I notate the composition operator as *)
(* [[<>?]], with a question mark.               *)
(* <boxed values 131>=                          *)
val _ = op <$>? : ('b -> 'c option) * ('a, 'b) xformer -> ('a, 'c) xformer
(* <stream transformers and their combinators>= *)
infix 3 <&>
fun t1 <&> t2 = fn xs =>
  case t1 xs
    of SOME (OK _, _) => t2 xs
     | SOME (ERROR _, _) => NONE    
     | NONE => NONE
(* Transformer \monoboxf [[<>?]] tx can be defined as \ *)
(* monoboxvalOf [[<>]] sat isSome (f [[<>]] tx), but *)
(* writing out the cases helps clarify what's going on. *)
(*                                              *)
(* A transformer might be run only if a another *)
(* transformer succeeds on the same input. For example, *)
(* the parser for uSmalltalk tries to parse an array *)
(* literal only when it knows the input begins with a *)
(* left bracket. Transformer \monoboxt1 [[< --- >]] t2 *)
(* succeeds only if both [[t1]] and [[t2]] succeed at *)
(* the same point. An error in [[t1]] is treated as *)
(* failure. The combined transformer looks at enough *)
(* input to decide if [[t1]] succeeds, but it does not *)
(* consume input consumed by [[t1]]—it consumes only the *)
(* input of [[t2]].                             *)
(* <boxed values 132>=                          *)
val _ = op <&> : ('a, 'b) xformer * ('a, 'c) xformer -> ('a, 'c) xformer
(* [[funty]] stand for \tau, [[actualtypes]]    *)
(* stand for \ldotsntau, and [[rettype]] stand for alpha *)
(* . The first premise is implemented by a call to *)
(* [[typesof]] and the second by a call to      *)
(* [[freshtyvar]]. The constraint is represented just as *)
(* written in the rule.                         *)

(* <stream transformers and their combinators>= *)
fun notFollowedBy t xs =
  case t xs
    of NONE => SOME (OK (), xs)
     | SOME _ => NONE
(* <boxed values 133>=                          *)
val _ = op notFollowedBy : ('a, 'b) xformer -> ('a, unit) xformer
(* <stream transformers and their combinators>= *)
fun many t = 
  curry (op ::) <$> t <*> (fn xs => many t xs) <|> pure []
(* Adding [[< --- >]] and [[notFollowedBy]] to our *)
(* library gives it the flavor of a little Boolean *)
(* algebra for transformers: functions [[< --- >]], *)
(* [[<|>]], and [[notFollowedBy]] play the roles of *)
(* ``and,'' ``or,'' and ``not,'' and [[pzero]] plays the *)
(* role of ``false.''                           *)
(*                                              *)
(* Transformers for sequences                   *)
(*                                              *)
(* Concrete syntax is full of sequences. A function *)
(* takes a sequence of arguments, a program is a *)
(* sequence of definitions, and a method definition *)
(* contains a sequence of expressions. To create *)
(* transformers that process sequences, I define *)
(* functions [[many]] and [[many1]]. If [[t]] is an \ *)
(* atob transformer, then \monoboxmany t is an \atox *)
(* list-of-B transformer. It runs [[t]] as many times as *)
(* possible. And even if [[t]] fails, \monoboxmany t *)
(* always succeeds: when [[t]] fails, \monoboxmany t *)
(* returns an empty list of B's.                *)
(* <boxed values 134>=                          *)
val _ = op many  : ('a, 'b) xformer -> ('a, 'b list) xformer
(* [[funty]] stand for \tau, [[actualtypes]]    *)
(* stand for \ldotsntau, and [[rettype]] stand for alpha *)
(* . The first premise is implemented by a call to *)
(* [[typesof]] and the second by a call to      *)
(* [[freshtyvar]]. The constraint is represented just as *)
(* written in the rule.                         *)

(* I'd really like to write that first alternative as *)
(*                                              *)
(*  [[curry (op ::) <> t <*> many t]]           *)
(*                                              *)
(* but that formulation leads to instant death by *)
(* infinite recursion. In your own parsers, it's a *)
(* problem to watch out for.                    *)
(*                                              *)
(* Sometimes an empty list isn't acceptable. In such *)
(* cases, I use \monoboxmany1 t, which succeeds only if *)
(* [[t]] succeeds at least once—in which case it returns *)
(* a nonempty list.                             *)

(* <stream transformers and their combinators>= *)
fun many1 t = 
  curry (op ::) <$> t <*> many t
(* <boxed values 135>=                          *)
val _ = op many1 : ('a, 'b) xformer -> ('a, 'b list) xformer
(* [[funty]] stand for \tau, [[actualtypes]]    *)
(* stand for \ldotsntau, and [[rettype]] stand for alpha *)
(* . The first premise is implemented by a call to *)
(* [[typesof]] and the second by a call to      *)
(* [[freshtyvar]]. The constraint is represented just as *)
(* written in the rule.                         *)

(* Although \monoboxmany t always succeeds, \monobox *)
(* many1 t can fail.                            *)

(* <stream transformers and their combinators>= *)
fun optional t = 
  SOME <$> t <|> pure NONE
(* Both [[many]] and [[many1]] are ``greedy''; that is, *)
(* they repeat [[t]] as many times as possible. Client *)
(* code has to be careful to ensure that calls to *)
(* [[many]] and [[many1]] terminate. In particular, if *)
(* [[t]] can succeed without consuming any input, then \ *)
(* monoboxmany t does not terminate. To pass [[many]] a *)
(* transformer that succeeds without consuming input is *)
(* therefor an unchecked run-time error. The same goes *)
(* for [[many1]].                               *)
(*                                              *)
(* Client code also has to be careful that when [[t]] *)
(* sees something it doesn't recognize, it doesn't *)
(* signal an error. In particular, [[t]] had better not *)
(* be built with the [[<?>]] operator defined in \ *)
(* chunkrefmlinterps.chunk.<?> below.           *)
(*                                              *)
(* Sometimes instead of zero, one, or many B's, concrete *)
(* syntax calls for zero or one; such a B might be *)
(* called ``optional.'' For example, a numeric literal *)
(* begins with an optional minus sign. Function *)
(* [[optional]] turns an \atob transformer into an \atox *)
(* optional-B transformer. Like \monoboxmany t, \monobox *)
(* optional t always succeeds.                  *)
(* <boxed values 136>=                          *)
val _ = op optional : ('a, 'b) xformer -> ('a, 'b option) xformer
(* [[funty]] stand for \tau, [[actualtypes]]    *)
(* stand for \ldotsntau, and [[rettype]] stand for alpha *)
(* . The first premise is implemented by a call to *)
(* [[typesof]] and the second by a call to      *)
(* [[freshtyvar]]. The constraint is represented just as *)
(* written in the rule.                         *)

(* <stream transformers and their combinators>= *)
infix 2 <*>!
fun tx_ef <*>! tx_x =
  fn xs => case (tx_ef <*> tx_x) xs
             of NONE => NONE
              | SOME (OK (OK y),      xs) => SOME (OK y,      xs)
              | SOME (OK (ERROR msg), xs) => SOME (ERROR msg, xs)
              | SOME (ERROR msg,      xs) => SOME (ERROR msg, xs)
infixr 4 <$>!
fun ef <$>! tx_x = pure ef <*>! tx_x
(* Transformers made with [[many]] and [[optional]] *)
(* succeed even when there is no input. They also *)
(* succeed when there is input that they don't  *)
(* recognize.                                   *)
(*                                              *)
(* Error-detecting transformers and their composition *)
(*                                              *)
(* Sometimes an error is detected not by a parser but by *)
(* a function that is applied to the results of parsing. *)
(* A classic example is a function definition: if the *)
(* formal parameters are syntactically correct but *)
(* contain a duplicate name, an error should be *)
(* signaled. Formal parameters could be handled by a *)
(* parser whose result type is \monoboxname list *)
(* error—but every transformer type already includes the *)
(* possibility of error! I would prefer that the *)
(* parser's result type be just \monoboxname list, and *)
(* that if duplicate names are detected, that the error *)
(* be managed in the same way as a syntax error. *)
(* To enable such management, I define [[<*>!]] and [[< *)
(* >!]] combinators, which merge function-detected *)
(* errors with parser-detected errors. \nwnarrowboxes *)
(* <boxed values 137>=                          *)
val _ = op <*>! : ('a, 'b -> 'c error) xformer * ('a, 'b) xformer -> ('a, 'c)
                                                                         xformer
val _ = op <$>! : ('b -> 'c error)                 * ('a, 'b) xformer -> ('a, 'c
                                                                       ) xformer
(* <support for source-code locations and located streams>= *)
type srcloc = string * int
fun srclocString (source, line) =
  source ^ ", line " ^ intString line
(* Source-code locations are useful when reading code *)
(* from a file. When reading code interactively, *)
(* however, a message that says the error occurred ``in *)
(* standard input, line 12,'' is more annoying than *)
(* helpful. As in the C code in \crefpage       *)
(* (cinterps.error-format, I use an error format to *)
(* control when error messages include source-code *)
(* locations. The format is initially set to include *)
(* them. [*]                                    *)
(* <support for source-code locations and located streams>= *)
datatype error_format = WITH_LOCATIONS | WITHOUT_LOCATIONS
val toplevel_error_format = ref WITH_LOCATIONS
(* The format is consulted by function [[synerrormsg]], *)
(* which produces the message that accompanies a syntax *)
(* error. The source location may be omitted only for *)
(* standard input; error messages about files loaded *)
(* with [[use]] are always accompanied by source-code *)
(* locations.                                   *)
(* <support for source-code locations and located streams>= *)
fun synerrormsg (source, line) strings =
  if !toplevel_error_format = WITHOUT_LOCATIONS
  andalso source = "standard input"
  then
    concat ("syntax error: " :: strings)
  else    
    concat ("syntax error in " :: srclocString (source, line) :: ": " :: strings
                                                                               )

(* <support for source-code locations and located streams>= *)
fun warnAt (source, line) strings =
  ( app eprint
      (if !toplevel_error_format = WITHOUT_LOCATIONS
       andalso source = "standard input"
       then
         "warning: " :: strings
       else
         "warning in " :: srclocString (source, line) :: ": " :: strings)
  ; eprint "\n"
  )
(* Parsing bindings used in LETX forms          *)
(*                                              *)
(* A sequence of let bindings has both names and *)
(* expressions. To capture both, [[parseletbindings]] *)
(* returns a component with both [[names]] and [[exps]] *)
(* fields set.                                  *)
(* <support for source-code locations and located streams>= *)
exception Located of srcloc * exn
(* <support for source-code locations and located streams>= *)
type 'a located = srcloc * 'a
(* <boxed values 81>=                           *)
type srcloc = srcloc
val _ = op srclocString : srcloc -> string
(* To keep track of the source location of a line, *)
(* token, expression, or other datum, I put the location *)
(* and the datum together in a pair. To make it easier *)
(* to read the types, I define a type abbreviation which *)
(* says that a value paired with a location is  *)
(* ``located.''                                 *)
(* <boxed values 81>=                           *)
type 'a located = 'a located
(* <support for source-code locations and located streams>= *)
fun atLoc loc f a =
  f a handle e as RuntimeError _ => raise Located (loc, e)
           | e as NotFound _     => raise Located (loc, e)
           (* In addition to exceptions that I have defined, *)
           (* [[atLoc]] also recognizes and wraps some of Standard *)
           (* ML's predefined exceptions. Handlers for even more *)
           (* exceptions, like [[TypeError]], can be added using *)
           (* Noweb.                                       *)
           (* <more handlers for [[atLoc]]>=               *)
           | e as IO.Io _   => raise Located (loc, e)
           | e as Div       => raise Located (loc, e)
           | e as Overflow  => raise Located (loc, e)
           | e as Subscript => raise Located (loc, e)
           | e as Size      => raise Located (loc, e)
           (* <more handlers for [[atLoc]] ((type-checking))>= *)
           | e as TypeError _         => raise Located (loc, e)
           | e as BugInTypeChecking _ => raise Located (loc, e)
(* The [[Located]] exception is raised by function *)
(* [[atLoc]]. Calling \monoboxatLoc f x applies [[f]] *)
(* to [[x]] within the scope of handlers that convert *)
(* recognized exceptions to the [[Located]] exception: *)
(* <boxed values 82>=                           *)
val _ = op atLoc : srcloc -> ('a -> 'b) -> ('a -> 'b)
(* [[funty]] stand for \tau, [[actualtypes]]    *)
(* stand for \ldotsntau, and [[rettype]] stand for alpha *)
(* . The first premise is implemented by a call to *)
(* [[typesof]] and the second by a call to      *)
(* [[freshtyvar]]. The constraint is represented just as *)
(* written in the rule.                         *)

(* <support for source-code locations and located streams>= *)
fun located f (loc, a) = atLoc loc f a
fun leftLocated f ((loc, a), b) = atLoc loc f (a, b)
(* Function [[atLoc]] is often called by the    *)
(* higher-order function [[located]], which converts a *)
(* function that expects [['a]] into a function that *)
(* expects \monobox'a located. Function [[leftLocated]] *)
(* does something similar for a pair in which only the *)
(* left half must include a source-code location. *)
(* <boxed values 83>=                           *)
val _ = op located : ('a -> 'b) -> ('a located -> 'b)
val _ = op leftLocated : ('a * 'b -> 'c) -> ('a located * 'b -> 'c)
(* [[bindList]] tried to                        *)
(*              extend an environment, but it passed *)
(*              two lists (names and values) of *)
(*              different lengths.              *)
(* RuntimeError    Something else went wrong during *)
(*              evaluation, i.e., during the    *)
(*              execution of [[eval]].          *)
(* \bottomrule                                  *)
(*                                              *)
(* Exceptions defined especially for this interpreter  *)
(* [*]                                          *)
(* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ *)
(*                                              *)
(* Abstract syntax and values                   *)
(*                                              *)
(* An abstract-syntax tree can contain a literal value. *)
(* A value, if it is a closure, can contain an  *)
(* abstract-syntax tree. These two types are therefore *)
(* mutually recursive, so I define them together, using *)
(* [[and]].                                     *)
(*                                              *)
(* These particular types use as complicated a nest of *)
(* definitions as you'll ever see. The keyword  *)
(* [[datatype]] defines a new algebraic datatype; the *)
(* keyword [[withtype]] introduces a new type   *)
(* abbreviation that is mutually recursive with the *)
(* [[datatype]]. The first group of [[and]] keywords *)
(* define additional algebraic datatypes, and the second *)
(* group of [[and]] keywords define additional type *)
(* abbreviations. Everything in the whole nest is *)
(* mutually recursive. [*] [*]                  *)

(* <support for source-code locations and located streams>= *)
fun fillComplaintTemplate (s, maybeLoc) =
  let val string_to_fill = " <at loc>"
      val (prefix, atloc) =
        Substring.position string_to_fill (Substring.full s)
      val suffix = Substring.triml (size string_to_fill) atloc
      val splice_in =
        Substring.full
          (case maybeLoc
             of NONE => ""
              | SOME (loc as (file, line)) =>
                  if !toplevel_error_format = WITHOUT_LOCATIONS
                  andalso file = "standard input"
                  then
                    ""
                  else
                    " in " ^ srclocString loc)
  in  if Substring.size atloc = 0 then (* <at loc> is not present *)
        s
      else
        Substring.concat [prefix, splice_in, suffix]
  end
fun fillAtLoc (s, loc) = fillComplaintTemplate (s, SOME loc)
fun stripAtLoc s = fillComplaintTemplate (s, NONE)
(* \qbreak A source-code location can appear anywhere in *)
(* an error message. To make it easy to write error *)
(* messages that include source-code locations, I define *)
(* function [[fillComplaintTemplate]]. This function *)
(* replaces the string \monobox"<at loc>" with a *)
(* reference to a source-code location—or if there is no *)
(* source-code location, it strips \monobox"<at loc>" *)
(* entirely. The implementation uses Standard ML's *)
(* [[Substring]] module.                        *)
(* <boxed values 84>=                           *)
val _ = op fillComplaintTemplate : string * srcloc option -> string
(* <support for source-code locations and located streams>= *)
fun synerrorAt msg loc = 
  ERROR (synerrormsg loc [msg])
(* <support for source-code locations and located streams>= *)
fun locatedStream (streamname, inputs) =
  let val locations =
        streamZip (streamRepeat streamname, streamDrop (1, naturals))
  in  streamZip (locations, inputs)
  end
(* To signal a syntax error at a given location, code *)
(* calls [[synerrorAt]]. [*]                    *)
(* <boxed values 85>=                           *)
val _ = op synerrorAt : string -> srcloc -> 'a error
(* All locations originate in a located stream of lines. *)
(* The locations share a filename, and the line numbers *)
(* are 1, 2, 3, ... and so on. [*]              *)
(* <boxed values 85>=                           *)
val _ = op locatedStream : string * line stream -> line located stream
(* <streams that track line boundaries>=        *)
datatype 'a eol_marked
  = EOL of int (* number of the line that ends here *)
  | INLINE of 'a

fun drainLine EOS = EOS
  | drainLine (SUSPENDED s)     = drainLine (demand s)
  | drainLine (EOL _    ::: xs) = xs
  | drainLine (INLINE _ ::: xs) = drainLine xs
(* <streams that track line boundaries>=        *)
local 
  fun asEol (EOL n) = SOME n
    | asEol (INLINE _) = NONE
  fun asInline (INLINE x) = SOME x
    | asInline (EOL _)    = NONE
in
  fun eol    xs = (asEol    <$>? one) xs
  fun inline xs = (asInline <$>? many eol *> one) xs
  fun srcloc xs = rewind (fst <$> inline) xs
end
(* Parsers: reading tokens and source-code locations *)
(*                                              *)
(* [*] To read definitions, expressions, and types, *)
(* it helps to work at a higher level of abstraction *)
(* than individual characters. All the parsers in this *)
(* book use two stages: first a lexer groups characters *)
(* into tokens, then a parser transforms tokens into *)
(* syntax. Not all languages use the same tokens, so the *)
(* code in this section assumes that the type [[token]] *)
(* and function [[tokenString]] are defined. Function *)
(* [[tokenString]] returns a string representation of *)
(* any given token; it is used in debugging. As an *)
(* example, the definitions used in micro-Scheme appear *)
(* in \crefmlschemea.chap (\cpagerefmlschemea.tokens). *)
(*                                              *)
(* Transforming a stream of characters to a stream of *)
(* tokens to a stream of definitions should sound *)
(* appealing, but it simplifies the story a little too *)
(* much. \qbreak That's because if something goes wrong, *)
(* a parser can't just throw up its hands. If an error *)
(* occurs,                                      *)
(*                                              *)
(*   • The parser should say where things went wrong—at *)
(*  what source-code location.                  *)
(*   • The parser should get rid of the bad tokens that *)
(*  caused the error.                           *)
(*   • The parser should be able to keep going, without *)
(*  having to kill the interpreter and start over. *)
(*                                              *)
(* To support error reporting and recovery takes a lot *)
(* of machinery. And that means a parser's input has to *)
(* contain more than just tokens.               *)
(*                                              *)
(* Flushing bad tokens                          *)
(*                                              *)
(* A standard parser for a batch compiler needs only to *)
(* see a stream of tokens and to know from what *)
(* source-code location each token came. A batch *)
(* compiler can simply read all its input and report all *)
(* the errors it wants to report. [Batch compilers vary *)
(* widely in the ambitions of their parsers. Some simple *)
(* parsers report just one error and stop. Some *)
(* sophisticated parsers analyze the entire input and *)
(* report the smallest number of changes needed to make *)
(* the input syntactically correct. And some    *)
(* ill-mannered parsers become confused after an error *)
(* and start spraying meaningless error messages. But *)
(* all of them have access to the entire input. *)
(* The~bridge-language interpreters don't. ] But an *)
(* interactive interpreter may not use an error as an *)
(* excuse to read an indefinite amount of input. It must *)
(* instead recover from the error and ready itself to *)
(* read the next line. To do so, it needs to know where *)
(* the line boundaries are! For example, if a parser *)
(* finds an error on line 6, it should read all the *)
(* tokens on line 6, throw them away, and start over *)
(* again on line 7. And it should do this without *)
(* reading line 7—reading line 7 will take an action and *)
(* will likely have the side effect of printing a *)
(* prompt. To mark line boundaries, I define a new type *)
(* constructor [[eol_marked]]. A value of type \monobox *)
(* 'a [[eol_marked]] is either an end-of-line marker, or *)
(* it contains a value of type [['a]] that occurs in a *)
(* line. A stream of such values can be drained up to *)
(* the end of the line.                         *)
(* <boxed values 146>=                          *)
type 'a eol_marked = 'a eol_marked
val _ = op drainLine : 'a eol_marked stream -> 'a eol_marked stream
(* \qbreak To support a stream of marked lines—possibly *)
(* marked, located lines—I define transformers [[eol]], *)
(* [[inline]], and [[srcloc]]. The [[eol]] transformer *)
(* returns the number of the line just ended.   *)
(* <boxed values 146>=                          *)
val _ = op eol      : ('a eol_marked, int) xformer
val _ = op inline   : ('a eol_marked, 'a)  xformer
val _ = op srcloc   : ('a located eol_marked, srcloc) xformer
(* <support for lexical analysis>=              *)
type 'a lexer = (char, 'a) xformer
(* <boxed values 138>=                          *)
type 'a lexer = 'a lexer
(* The type [['a lexer]] should be pronounced ``lexer *)
(* returning [['a]].''                          *)

(* <support for lexical analysis>=              *)
fun isDelim c =
  Char.isSpace c orelse Char.contains "()[]{};" c
(* <boxed values 139>=                          *)
val _ = op isDelim : char -> bool
(* [[                                           *)
(* Char.isSpace]] recognizes all whitespace     *)
(* characters. [[Char.contains]] takes a string and a *)
(* character and says if the string contains the *)
(* character. These functions are in the initial basis *)
(* of Standard ML.                              *)
(*                                              *)
(* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ *)
(* \catcode`=\other \catcode`_=\other \catcode`$=\other *)
(*                                              *)
(*  Lexical analyzers; tokens                   *)
(*  \type'a lexer = (char, 'a) xformer \        *)
(*  tableboxisDelim : char -> bool \            *)
(*  tableboxwhitespace : char list lexer \      *)
(*  tableboxintChars : (char -> bool) ->        *)
(*  char list lexer \tableboxintFromChars :     *)
(*  char list -> int error \tablebox            *)
(*  intToken : (char -> bool) -> int lexer      *)
(*  \typetoken \tableboxtokenString : token     *)
(*  -> string \tableboxlexLineWith : token      *)
(*  lexer -> line -> token stream [8pt]         *)
(*  Streams with end-of-line markers            *)
(*  \type'a eol_marked \tableboxdrainLine :     *)
(*  'a eol_marked stream -> 'a eol_marked       *)
(*  stream [8pt] Parsers                        *)
(*  \type'a parser = (token located             *)
(*  eol_marked, 'a) xformer \tableboxeol :      *)
(*  ('a eol_marked, int) xformer \tablebox      *)
(*  inline : ('a eol_marked, 'a) xformer \      *)
(*  tableboxtoken : token parser \tablebox      *)
(*  srcloc : srcloc parser \tablebox            *)
(*  noTokens : unit parser \tablebox@@ : 'a     *)
(*  parser -> 'a located parser \tablebox       *)
(*  <?> : 'a parser * string -> 'a parser \     *)
(*  tablebox<!> : 'a parser * string -> 'b      *)
(*  parser \tableboxliteral : string ->         *)
(*  unit parser \tablebox>– : string * 'a     *)
(*  parser -> 'a parser \tablebox–< : 'a      *)
(*  parser * string -> 'a parser \tablebox      *)
(*  bracket : string * string * 'a parser       *)
(*  -> 'a parser \splitboxnodupsstring *        *)
(*  string -> srcloc * name list-> name         *)
(*  list error \tableboxsafeTokens : token      *)
(*  located eol_marked stream -> token list     *)
(*  \tableboxechoTagStream : line stream ->     *)
(*  line stream stripAndReportErrors            *)
(*                                          'a error *)
(*                                          stream -> *)
(*                                          'a stream *)
(*  [8pt] A complete, interactive source of     *)
(*  abstract syntax                             *)
(*  interactiveParsedStream : token lexer * 'a parser *)
(*                                          -> string *)
(*                                          * line *)
(*                                          stream * *)
(*                                          prompts *)
(*                                          -> 'a *)
(*                                          stream *)
(*                                              *)
(* Transformers specialized for lexical analysis or *)
(* parsing [*]                                  *)
(*                                              *)
(* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ *)
(* All languages in this book ignore whitespace. Lexer *)
(* [[whitespace]] is typically combined with another *)
(* lexer using the [[*>]] operator.             *)

(* <support for lexical analysis>=              *)
val whitespace = many (sat Char.isSpace one)
(* <boxed values 140>=                          *)
val _ = op whitespace : char list lexer
(* <support for lexical analysis>=              *)
fun intChars isDelim = 
  (curry (op ::) <$> eqx #"-" one <|> pure id) <*>
  many1 (sat Char.isDigit one) <* 
  notFollowedBy (sat (not o isDelim) one)
(* Most languages in this book are, like Scheme, liberal *)
(* about names. Just about any sequence of characters, *)
(* as long as it is free of delimiters, can form a name. *)
(* But there's one big exception: a sequence of digits *)
(* forms an integer literal, not a name. Because integer *)
(* literals introduce several complications, and because *)
(* they are used in all the languages in this book, *)
(* it makes sense to deal with the complications in one *)
(* place: here.                                 *)
(*                                              *)
(* Integer literals are subject to these rules: *)
(*                                              *)
(*   • An integer literal may begin with a minus sign. *)
(*   • It continues with one or more digits.  *)
(*   • If it is followed by character, that character *)
(*  must be a delimiter. (In other words, it must not *)
(*  be followed by a non-delimiter.)            *)
(*   • When the sequence of digits is converted to an *)
(*  [[int]], the arithmetic used in the conversion *)
(*  must not overflow.                          *)
(*                                              *)
(* Function [[intChars]] does the lexical analysis to *)
(* grab the characters; [[intFromChars]] handles the *)
(* conversion and its potential overflow, and   *)
(* [[intToken]] puts everything together. Because not *)
(* every language uses the same delimiters, both *)
(* [[intChars]] and [[intToken]] receive a predicate *)
(* that identifies delimiters.                  *)
(* <boxed values 141>=                          *)
val _ = op intChars : (char -> bool) -> char list lexer
(* [[funty]] stand for \tau, [[actualtypes]]    *)
(* stand for \ldotsntau, and [[rettype]] stand for alpha *)
(* . The first premise is implemented by a call to *)
(* [[typesof]] and the second by a call to      *)
(* [[freshtyvar]]. The constraint is represented just as *)
(* written in the rule.                         *)

(* Function [[Char.isDigit]], like [[Char.isSpace]], is *)
(* part of Standard ML.                         *)

(* <support for lexical analysis>=              *)
fun intFromChars (#"-" :: cs) = 
      intFromChars cs >>=+ Int.~
  | intFromChars cs =
      (OK o valOf o Int.fromString o implode) cs
      handle Overflow =>
        ERROR "this interpreter can't read arbitrarily large integers"
(* <boxed values 142>=                          *)
val _ = op intFromChars : char list -> int error
(* <support for lexical analysis>=              *)
fun intToken isDelim =
  intFromChars <$>! intChars isDelim
(* In this book, every language except uProlog can use *)
(* [[intToken]].                                *)
(* <boxed values 143>=                          *)
val _ = op intToken : (char -> bool) -> int lexer
(* The [[xdeftable]] is shared with the Impcore parser. *)
(* Function [[reduce_to_xdef]] is almost shareable as *)
(* well, but not quite---the abstract syntax of *)
(* [[DEFINE]] is different.                     *)

(* All the bridge languages use balanced brackets, which *)
(* may come in three shapes. So that lexers for *)
(* different languages can share code related to *)
(* brackets, bracket shapes and tokens are defined here. *)
(* <support for lexical analysis>=              *)
datatype bracket_shape = ROUND | SQUARE | CURLY
(* <support for lexical analysis>=              *)
datatype 'a plus_brackets
  = LEFT  of bracket_shape
  | RIGHT of bracket_shape
  | PRETOKEN of 'a

fun bracketLexer pretoken
  =  LEFT  ROUND  <$ eqx #"(" one
 <|> LEFT  SQUARE <$ eqx #"[" one
 <|> LEFT  CURLY  <$ eqx #"{" one
 <|> RIGHT ROUND  <$ eqx #")" one
 <|> RIGHT SQUARE <$ eqx #"]" one
 <|> RIGHT CURLY  <$ eqx #"}" one
 <|> PRETOKEN <$> pretoken
(* Bracket tokens are added to a language-specific *)
(* ``pre-token'' type by using the type constructor *)
(* [[plus_brackets]].[*] Function [[bracketLexer]] takes *)
(* as an argument a lexer for pre-tokens, and it returns *)
(* a lexer for tokens:                          *)
(* <boxed values 144>=                          *)
type 'a plus_brackets = 'a plus_brackets
val _ = op bracketLexer : 'a lexer -> 'a plus_brackets lexer
(* [[bindList]] tried to                        *)
(*              extend an environment, but it passed *)
(*              two lists (names and values) of *)
(*              different lengths.              *)
(* RuntimeError    Something else went wrong during *)
(*              evaluation, i.e., during the    *)
(*              execution of [[eval]].          *)
(* \bottomrule                                  *)
(*                                              *)
(* Exceptions defined especially for this interpreter  *)
(* [*]                                          *)
(* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ *)
(*                                              *)
(* Abstract syntax and values                   *)
(*                                              *)
(* An abstract-syntax tree can contain a literal value. *)
(* A value, if it is a closure, can contain an  *)
(* abstract-syntax tree. These two types are therefore *)
(* mutually recursive, so I define them together, using *)
(* [[and]].                                     *)
(*                                              *)
(* These particular types use as complicated a nest of *)
(* definitions as you'll ever see. The keyword  *)
(* [[datatype]] defines a new algebraic datatype; the *)
(* keyword [[withtype]] introduces a new type   *)
(* abbreviation that is mutually recursive with the *)
(* [[datatype]]. The first group of [[and]] keywords *)
(* define additional algebraic datatypes, and the second *)
(* group of [[and]] keywords define additional type *)
(* abbreviations. Everything in the whole nest is *)
(* mutually recursive. [*] [*]                  *)

(* <support for lexical analysis>=              *)
fun leftString ROUND  = "("
  | leftString SQUARE = "["
  | leftString CURLY  = "{"
fun rightString ROUND  = ")"
  | rightString SQUARE = "]"
  | rightString CURLY = "}"

fun plusBracketsString _   (LEFT shape)  = leftString shape
  | plusBracketsString _   (RIGHT shape) = rightString shape
  | plusBracketsString pts (PRETOKEN pt)  = pts pt
(* For debugging and error messages, brackets and tokens *)
(* can be converted to strings.                 *)
(* <boxed values 145>=                          *)
val _ = op plusBracketsString : ('a -> string) -> ('a plus_brackets -> string)
(* <common parsing code>=                       *)
(* Parsing located, in-line tokens              *)
(*                                              *)
(* In each interpreter, a value of type \monobox'a *)
(* parser is a transformer that takes a stream of *)
(* located tokens set between end-of-line markers, and *)
(* it returns a value of type [['a]], plus any leftover *)
(* tokens. But each interpreter has its own token type, *)
(* and the infrastructure needs to work with all of *)
(* them. That is, it needs to be polymorphic. So a value *)
(* of type \monobox('t, 'a) polyparser is a parser that *)
(* takes tokens of some unknown type [['t]].    *)
(* <combinators and utilities for parsing located streams>= *)
type ('t, 'a) polyparser = ('t located eol_marked, 'a) xformer
(* <combinators and utilities for parsing located streams>= *)
fun token    stream = (snd <$> inline)      stream
fun noTokens stream = (notFollowedBy token) stream
(* When defining a parser, I want not to worry about the *)
(* [[EOL]] and [[INLINE]] constructors. These   *)
(* constructors are essential for error recovery, but *)
(* for parsing, they just get in the way. My first order *)
(* of business is therefore to define analogs of [[one]] *)
(* and [[eos]] that ignore [[EOL]]. Parser [[token]] *)
(* takes one token; parser [[srcloc]] looks at the *)
(* source-code location of a token, but leaves the token *)
(* in the input; and parser [[noTokens]] succeeds only *)
(* if there are no tokens left in the input. They are *)
(* built on top of ``utility'' parsers [[eol]] and *)
(* [[inline]]. The two utility parsers have different *)
(* contracts; [[eol]] succeeds only when at [[EOL]], but *)
(* [[inline]] scans past [[EOL]] to look for [[INLINE]]. *)
(* <boxed values 147>=                          *)
val _ = op token    : ('t, 't)   polyparser
val _ = op noTokens : ('t, unit) polyparser
(* <combinators and utilities for parsing located streams>= *)
fun @@ p = pair <$> srcloc <*> p
(* Parser [[noTokens]] is not that same as [[eos]]: *)
(* parser [[eos]] succeeds only when the input stream is *)
(* empty, but [[noTokens]] can succeed when the input *)
(* stream is not empty but contains only [[EOL]] *)
(* markers—as is likely on the last line of an input *)
(* file.                                        *)
(*                                              *)
(* Source-code locations are useful by themselves, but *)
(* they are also useful when paired with a result from a *)
(* parser. For example, when parsing a message send for *)
(* uSmalltalk, the source-code location of the send is *)
(* used when writing a stack trace. To make it easy to *)
(* add a source-code location to any result from any *)
(* parser, I define the [[@@]] function. (Associate the *)
(* word ``at'' with the idea of ``location.'') The code *)
(* uses a dirty trick: it works because [[srcloc]] looks *)
(* at the input but does not consume any tokens. *)
(* <boxed values 148>=                          *)
val _ = op @@ : ('t, 'a) polyparser -> ('t, 'a located) polyparser
(* <combinators and utilities for parsing located streams>= *)
fun asAscii p =
  let fun good c = Char.isPrint c andalso Char.isAscii c
      fun warn (loc, s) =
        case List.find (not o good) (explode s)
          of NONE => OK s
           | SOME c => 
               let val msg =
                     String.concat ["name \"", s, "\" contains the ",
                                    "non-ASCII or non-printing byte \"",
                                    Char.toCString c, "\""]
               in  synerrorAt msg loc
               end
  in  warn <$>! @@ p
  end
(* <combinators and utilities for parsing located streams>= *)
infix 0 <?>
fun p <?> what = p <|> synerrorAt ("expected " ^ what) <$>! srcloc
(* <boxed values 149>=                          *)
val _ = op asAscii : ('t, string) polyparser -> ('t, string) polyparser
(* Parsers that report errors                   *)
(*                                              *)
(* A typical syntactic form (expression, unit test, or *)
(* definition, for example) is parsed by a sequence of *)
(* alternatives separated with [[<|>]]. When no *)
(* alternative succeeds, the collective should usually *)
(* be reported as a syntax error. An error-reporting *)
(* parser can be created using the [[<?>]] function: *)
(* parser \monoboxp <?> what succeeds when [[p]] *)
(*  succeeds, but when [[p]] fails, parser \monoboxp <?> *)
(* what reports an error: it expected [[what]]. *)
(* The error says what the parser was expecting, and it *)
(* gives the source-code location of the unrecognized *)
(* token. If there is no token, there is no error—at end *)
(* of file, rather than signal an error, a parser made *)
(* using [[<?>]] fails. An example appears in the parser *)
(* for extended definitions in micro-Scheme (\chunkref *)
(* mlschemea.chunk.xdef). [*]                   *)
(* <boxed values 149>=                          *)
val _ = op <?> : ('t, 'a) polyparser * string -> ('t, 'a) polyparser
(* [[funty]] stand for \tau, [[actualtypes]]    *)
(* stand for \ldotsntau, and [[rettype]] stand for alpha *)
(* . The first premise is implemented by a call to *)
(* [[typesof]] and the second by a call to      *)
(* [[freshtyvar]]. The constraint is represented just as *)
(* written in the rule.                         *)

(* The [[<?>]] operator must not be used to define a *)
(* parser that is passed to [[many]], [[many1]], or *)
(* [[optional]] In that context, if parser [[p]] fails, *)
(* it must not signal an error; it must instead *)
(* propagate the failure to [[many]], [[many1]], or *)
(* [[optional]], so those combinators know there is not *)
(* a [[p]] there.                               *)

(* <combinators and utilities for parsing located streams>= *)
infix 4 <!>
fun p <!> msg =
  fn tokens => (case p tokens
                  of SOME (OK _, unread) =>
                       let val outcome =
                             case peek srcloc tokens
                              of SOME loc => synerrorAt msg loc
                               | NONE => ERROR msg
                                             
                       in  SOME (outcome, unread)
                       end
                   | _ => NONE)
(* Another common error-detecting technique is to use a *)
(* parser [[p]] to detect some input that shouldn't be *)
(* there. For example, a parser is just starting to read *)
(* a definition, the input shouldn't begin with a right *)
(* parenthesis. I can write a parser [[p]] that *)
(* recognizes a right parenthesis, but I can't simply *)
(* combine [[p]] with [[synerrorAt]] and [[srcloc]] in *)
(* the same way that [[<?>]] does, because I want my *)
(* combined parser to do two things: consume the tokens *)
(* recognized by [[p]], and also report the error at the *)
(* location of the first of those tokens. I can't use *)
(* [[synerrorAt]] until after [[p]] succeeds, but I have *)
(* to use [[srcloc]] on the input stream as it is before *)
(* [[p]] is run. I solve this problem by defining a *)
(* special combinator that keeps a copy of the tokens *)
(* inspected by [[p]]. If parser [[p]] succeeds, then *)
(* parser \monoboxp <!> msg consumes the tokens consumed *)
(* by [[p]] and reports error [[msg]] at the location of *)
(* [[p]]'s first token.                         *)
(* <boxed values 150>=                          *)
val _ = op <!> : ('t, 'a) polyparser * string -> ('t, 'b) polyparser
(* <combinators and utilities for parsing located streams>= *)
fun nodups (what, context) (loc, names) =
  let fun dup [] = OK names
        | dup (x::xs) =
            if List.exists (fn y => y = x) xs then
              synerrorAt (what ^ " " ^ x ^ " appears twice in " ^ context) loc
            else
              dup xs
  in  dup names
  end
(* \qbreak                                      *)
(*                                              *)
(* Detection of duplicate names                 *)
(*                                              *)
(* Most of the languages in this book allow you to *)
(* define functions or methods that take formal *)
(* parameters. It is never permissible to use the same *)
(* name for formal parameters in two different  *)
(* positions. There are surprisingly many other places *)
(* where it's not acceptable to have duplicates in a *)
(* list of strings. Function [[nodups]] takes two *)
(* Curried arguments: a pair saying what kind of thing *)
(* might be duplicated and where it appeared, followed *)
(* by a pair containing a list of names and the *)
(* source-code location of the list. If there are no *)
(* duplicates, it returns [[OK]] applied to the list of *)
(* names; otherwise it returns an [[ERROR]]. Function *)
(* [[nodups]] is typically applied to a pair of strings, *)
(* after which the result is applied to a parser using *)
(* the [[<>!]] function.                        *)
(*                                              *)
(* \qbreak                                      *)
(* <boxed values 159>=                          *)
val _ = op nodups : string * string -> srcloc * name list -> name list error
(* Function [[List.exists]] is like the micro-Scheme *)
(* [[exists?]]. It is in the initial basis for  *)
(* Standard ML.                                 *)

(* <combinators and utilities for parsing located streams>= *)
fun rejectReserved reserved x =
  if member x reserved then
    ERROR ("syntax error: " ^ x ^ " is a reserved word and " ^
           "may not be used to name a variable or function")
  else
    OK x
(* Detection of reserved words                  *)
(*                                              *)
(* To rule out such nonsense as ``\monobox(val if 3),'' *)
(* parsers use function [[rejectReserved]], which issues *)
(* a syntax-error message if a name is on a list of *)
(* reserved words.                              *)
(* <boxed values 160>=                          *)
val _ = op rejectReserved : name list -> name -> name error
(* <transformers for interchangeable brackets>= *)
fun left  tokens = ((fn (loc, LEFT  s) => SOME (loc, s) | _ => NONE) <$>? inline
                                                                        ) tokens
fun right tokens = ((fn (loc, RIGHT s) => SOME (loc, s) | _ => NONE) <$>? inline
                                                                        ) tokens
fun pretoken stream = ((fn PRETOKEN t => SOME t | _ => NONE) <$>? token) stream
(* Parsers that involve brackets                *)
(*                                              *)
(* Almost every language in this book uses a    *)
(* parenthesis-prefix syntax (Scheme syntax) in which *)
(* round and square brackets must match, but are *)
(* otherwise interchangeable. [I~have spent entirely too *)
(* much time working with Englishmen who call   *)
(* parentheses ``brackets.'' I~now find it hard even to *)
(* \emph{say} the word ``parenthesis,'' let alone *)
(* type~it. ] Brackets are treated specially by the *)
(* [[plus_brackets]] type (\cpageref            *)
(* lazyparse.plus-brackets), which identifies every *)
(* token as a left bracket, a right bracket, or a *)
(* ``pre-token.'' Each of these alternatives is *)
(* supported by its own parser. A parser that finds a *)
(* bracket returns the bracket's shape and location; *)
(* a parser the finds a pre-token returns the pre-token. *)
(* <boxed values 152>=                          *)
val _ = op left  : ('t plus_brackets, bracket_shape located) polyparser
val _ = op right : ('t plus_brackets, bracket_shape located) polyparser
val _ = op pretoken : ('t plus_brackets, 't) polyparser
(* <transformers for interchangeable brackets>= *)
fun badRight msg =
  (fn (loc, shape) => synerrorAt (msg ^ " " ^ rightString shape) loc) <$>! right
(* Every interpreter needs to be able to complain when *)
(* it encounters an unexpected right bracket.   *)
(* An interpreter can build a suitable parser by passing *)
(* a message to [[badRight]]. Since the parser never *)
(* succeeds, it can have any result type.       *)
(* <boxed values 153>=                          *)
val _ = op badRight : string -> ('t plus_brackets, 'a) polyparser
(* The [[xdeftable]] is shared with the Impcore parser. *)
(* Function [[reduce_to_xdef]] is almost shareable as *)
(* well, but not quite---the abstract syntax of *)
(* [[DEFINE]] is different.                     *)

(* <transformers for interchangeable brackets>= *)
fun notCurly (_, CURLY) = false
  | notCurly _          = true
fun leftCurly tokens = sat (not o notCurly) left tokens
(* <transformers for interchangeable brackets>= *)
(* <definition of function [[errorAtEnd]]>=     *)
infix 4 errorAtEnd
fun p errorAtEnd mkMsg =
  fn tokens => 
    (case (p <* rewind right) tokens
       of SOME (OK s, unread) =>
            let val outcome =
                  case peek srcloc tokens
                    of SOME loc => synerrorAt ((concat o mkMsg) s) loc
                     | NONE => ERROR ((concat o mkMsg) s)
            in  SOME (outcome, unread)
            end
        | _ => NONE)
(* Function [[<!>]] is adequate for simple cases, but to *)
(* produce a really good error message, I might wish to *)
(* use the result from [[p]] to build a message. *)
(* My interpreters produce such messages only for text *)
(* appearing in brackets, so [[errorAtEnd]] triggers *)
(* only when [[p]] parses tokens that are followed by a *)
(* right bracket. \nwcrazynarrowboxes           *)
(* <boxed values 151>=                          *)
val _ = op errorAtEnd : ('t plus_brackets, 'a) polyparser * ('a -> string list)
                                            -> ('t plus_brackets, 'b) polyparser
(* <transformers for interchangeable brackets>= *)
datatype right_result
  = FOUND_RIGHT      of bracket_shape located
  | SCANNED_TO_RIGHT of srcloc  (* location where scanning started *)
  | NO_RIGHT
(* In this book, round and square brackets are  *)
(* interchangeable, but curly brackets are special. *)
(* Predicate [[notCurly]] identifies those non-curly, *)
(* interchangeable bracket shapes. Parser [[leftCurly]] *)
(* is just like [[left]], except it recognizes only *)
(* curly left brackets.                         *)
(* <boxed values 154>=                          *)
val _ = op notCurly  : bracket_shape located -> bool
val _ = op leftCurly : ('t plus_brackets, bracket_shape located) polyparser
(* Brackets by themselves are all very well, but what I *)
(* really want is to parse syntax that is wrapped in *)
(* matching brackets. But what if something goes wrong *)
(* inside the brackets? In that case, I want each of my *)
(* parsers to skip tokens until it gets to the matching *)
(* right bracket, and I'll likely want it to report the *)
(* source-code location of the left bracket. To look *)
(* ahead for a right bracket is the job of parser *)
(* [[matchingRight]]. This parser is called when a left *)
(* bracket has already been consumed, and it searches *)
(* the input stream for a right bracket, skipping every *)
(* left/right pair that it finds in the interim. Because *)
(* it's meant for error handling, it always succeeds. *)
(* And to communicate its findings, it produces one of *)
(* three outcomes:                              *)
(*                                              *)
(*   • Result \monobox[[FOUND_RIGHT]] (loc, s) says, *)
(*  ``I found a right bracket exactly where     *)
(*  I expected to, and its shape and location are s *)
(*  and loc.''                                  *)
(*   • Result \monobox[[SCANNED_TO_RIGHT]] loc says, *)
(*  ``I didn't find a right bracket at loc, but *)
(*  I scanned to a matching right bracket       *)
(*  eventually.''                               *)
(*   • Result \monobox[[NO_RIGHT]] says, ``I scanned the *)
(*  entire input without finding a matching right *)
(*  bracket.''                                  *)
(*                                              *)
(* This result is defined as follows:           *)
(* <boxed values 154>=                          *)
type right_result = right_result
(* <transformers for interchangeable brackets>= *)
type ('t, 'a) pb_parser = ('t plus_brackets, 'a) polyparser
fun matchingRight tokens =
  let fun scanToClose tokens = 
        let val loc = getOpt (peek srcloc tokens, ("end of stream", 9999))
            fun scan nlp tokens =
              (* nlp is the number of unmatched left parentheses *)
              case tokens
                of EOL _                  ::: tokens => scan nlp tokens
                 | INLINE (_, PRETOKEN _) ::: tokens => scan nlp tokens
                 | INLINE (_, LEFT  _)    ::: tokens => scan (nlp+1) tokens
                 | INLINE (_, RIGHT _)    ::: tokens =>
                     if nlp = 0 then
                       pure (SCANNED_TO_RIGHT loc) tokens
                     else
                       scan (nlp-1) tokens
                 | EOS         => pure NO_RIGHT tokens
                 | SUSPENDED s => scan nlp (demand s)
        in  scan 0 tokens
        end
  in  (FOUND_RIGHT <$> right <|> scanToClose) tokens
  end
(* A value of type [[right_result]] is produced by *)
(* parser [[matchingRight]]. A right bracket in the *)
(* expected position is successfully found by the \ *)
(* qbreak [[right]] parser; when tokens have to be *)
(* skipped, they are skipped by parser [[scanToClose]]. *)
(* The ``matching'' is done purely by counting left and *)
(* right brackets; [[scanToClose]] does not look at *)
(* shapes.                                      *)
(* <boxed values 155>=                          *)
val _ = op matchingRight : ('t, right_result) pb_parser
(* <transformers for interchangeable brackets>= *)
fun matchBrackets _ (loc, left) a (FOUND_RIGHT (loc', right)) =
      if left = right then
        OK a
      else
        synerrorAt (rightString right ^ " does not match " ^ leftString left ^
                 (if loc <> loc' then " at " ^ srclocString loc else "")) loc'
  | matchBrackets _ (loc, left) _ NO_RIGHT =
      synerrorAt ("unmatched " ^ leftString left) loc
  | matchBrackets e (loc, left) _ (SCANNED_TO_RIGHT loc') =
      synerrorAt ("expected " ^ e) loc
(* <boxed values 156>=                          *)
val _ = op matchBrackets : string -> bracket_shape located -> 'a -> right_result
                                                                     -> 'a error
(* <transformers for interchangeable brackets>= *)

fun liberalBracket (expected, p) =
  matchBrackets expected <$> sat notCurly left <*> p <*>! matchingRight
fun bracket (expected, p) =
  liberalBracket (expected, p <?> expected)
fun curlyBracket (expected, p) =
  matchBrackets expected <$> leftCurly <*> (p <?> expected) <*>! matchingRight
fun bracketKeyword (keyword, expected, p) =
  liberalBracket (expected, keyword *> (p <?> expected))
(* \qbreak The bracket matcher is then used to help wrap *)
(* other parsers in brackets. A parser may be wrapped in *)
(* a variety of ways, depending on what may be allowed *)
(* to fail without causing an error.            *)
(*                                              *)
(*   • To wrap parser [[p]] in matching round or square *)
(*  brackets when [[p]] may fail: use           *)
(*  [[liberalBracket]]. If [[p]] succeeds but the *)
(*  brackets don't match, that's an error.      *)
(*   • To wrap parser [[p]] in matching round or square *)
(*  brackets when [[p]] must succeed: use       *)
(*  [[bracket]].                                *)
(*   • To wrap parser [[p]] in matching curly brackets *)
(*  when [[p]] must succeed: use [[curlyBracket]]. *)
(*   • To put parser [[p]] after a keyword, all wrapped *)
(*  in brackets: use [[bracketKeyword]]. Once the *)
(*  keyword is seen, [[p]] must not fail—if it does, *)
(*  that's an error.                            *)
(*                                              *)
(* Each of these functions takes a parameter    *)
(* [[expected]] of type [[string]]; when anything goes *)
(* wrong, this parameter says what the parser was *)
(* expecting. [*] \nwnarrowboxes                *)
(* <boxed values 157>=                          *)
val _ = op liberalBracket : string * ('t, 'a) pb_parser -> ('t, 'a) pb_parser
val _ = op bracket           : string * ('t, 'a) pb_parser -> ('t, 'a) pb_parser
val _ = op curlyBracket    : string * ('t, 'a) pb_parser -> ('t, 'a) pb_parser
(* <boxed values 157>=                          *)
val _ = op bracketKeyword : ('t, 'keyword) pb_parser * string * ('t, 'a)
                                                 pb_parser -> ('t, 'a) pb_parser
(* <transformers for interchangeable brackets>= *)
fun usageParser keyword =
  let val left = eqx #"(" one <|> eqx #"[" one
      val getkeyword = left *> (implode <$> many1 (sat (not o isDelim) one))
  in  fn (usage, p) =>
        case getkeyword (streamOfList (explode usage))
          of SOME (OK k, _) => bracketKeyword (keyword k, usage, p)
           | _ => raise InternalError ("malformed usage string: " ^ usage)
  end
(* The [[bracketKeyword]] function is what's used to *)
(* build parsers for [[if]], [[lambda]], and many other *)
(* syntactic forms. And if one of these parsers fails, *)
(* I want it to show the programmer what's expected, *)
(* like for example \monobox"(if e1 e2 e3)". The *)
(* expectation is represented by a usage string. A usage *)
(* string begins with a left bracket, which is followed *)
(* by its keyword. I want not to write the keyword *)
(* twice, so [[usageParser]] pulls the keyword out of *)
(* the usage string—using a parser. [*]       *)
(* <boxed values 158>=                          *)
val _ = op usageParser : (string -> ('t, string) pb_parser) ->
                               string * ('t, 'a) pb_parser -> ('t, 'a) pb_parser
(* [[bindList]] tried to                        *)
(*              extend an environment, but it passed *)
(*              two lists (names and values) of *)
(*              different lengths.              *)
(* RuntimeError    Something else went wrong during *)
(*              evaluation, i.e., during the    *)
(*              execution of [[eval]].          *)
(* \bottomrule                                  *)
(*                                              *)
(* Exceptions defined especially for this interpreter  *)
(* [*]                                          *)
(* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ *)
(*                                              *)
(* Abstract syntax and values                   *)
(*                                              *)
(* An abstract-syntax tree can contain a literal value. *)
(* A value, if it is a closure, can contain an  *)
(* abstract-syntax tree. These two types are therefore *)
(* mutually recursive, so I define them together, using *)
(* [[and]].                                     *)
(*                                              *)
(* These particular types use as complicated a nest of *)
(* definitions as you'll ever see. The keyword  *)
(* [[datatype]] defines a new algebraic datatype; the *)
(* keyword [[withtype]] introduces a new type   *)
(* abbreviation that is mutually recursive with the *)
(* [[datatype]]. The first group of [[and]] keywords *)
(* define additional algebraic datatypes, and the second *)
(* group of [[and]] keywords define additional type *)
(* abbreviations. Everything in the whole nest is *)
(* mutually recursive. [*] [*]                  *)

(* <code used to debug parsers>=                *)
fun safeTokens stream =
  let fun tokens (seenEol, seenSuspended) =
            let fun get (EOL _         ::: ts) = if seenSuspended then []
                                                 else tokens (true, false) ts
                  | get (INLINE (_, t) ::: ts) = t :: get ts
                  | get  EOS                   = []
                  | get (SUSPENDED (ref (PRODUCED ts))) = get ts
                  | get (SUSPENDED s) = if seenEol then []
                                        else tokens (false, true) (demand s)
            in   get
            end
  in  tokens (false, false) stream
  end
(* Code used to debug parsers                   *)
(*                                              *)
(* When debugging parsers, I often find it helpful to *)
(* dump out the tokens that a parser is looking at. *)
(* I want to dump only the tokens that are available *)
(* without triggering the action of reading another line *)
(* of input. To get those tokens, function      *)
(* [[safeTokens]] reads until it has got to both an *)
(* end-of-line marker and a suspension whose value has *)
(* not yet been demanded.                       *)
(* <boxed values 161>=                          *)
val _ = op safeTokens : 'a located eol_marked stream -> 'a list
(* <code used to debug parsers>=                *)
fun showErrorInput asString p tokens =
  case p tokens
    of result as SOME (ERROR msg, rest) =>
         if String.isSubstring " [input: " msg then
           result
         else
           SOME (ERROR (msg ^ " [input: " ^
                        spaceSep (map asString (safeTokens tokens)) ^ "]"),
               rest)
     | result => result
(* \qbreak Another way to debug is to show whatever *)
(* input tokens might cause an error. They can be shown *)
(* using function [[showErrorInput]], which transforms *)
(* an ordinary parser into a parser that, when it *)
(* errors, shows the input that caused the error. *)
(* It should be applied routinely to every parser you *)
(* build. \nwverynarrowboxes                    *)
(* <boxed values 162>=                          *)
val _ = op showErrorInput : ('t -> string) -> ('t, 'a) polyparser -> ('t, 'a)
                                                                      polyparser
(* <code used to debug parsers>=                *)
fun wrapAround tokenString what p tokens =
  let fun t tok = " " ^ tokenString tok
      val _ = app eprint ["Looking for ", what, " at"]
      val _ = app (eprint o t) (safeTokens tokens)
      val _ = eprint "\n"
      val answer = p tokens
      val _ = app eprint [ case answer of NONE => "Didn't find "
                                        | SOME _ => "Found "
                         , what, "\n"
                         ]
  in  answer
  end handle e =>
        ( app eprint ["Search for ", what, " raised ", exnName e, "\n"]
        ; raise e
        )
(* <boxed values 163>=                          *)
val _ = op wrapAround : ('t -> string) -> string -> ('t, 'a) polyparser -> ('t,
                                                                  'a) polyparser
(* <streams that issue two forms of prompts>=   *)
fun echoTagStream lines = 
  let fun echoIfTagged line =
        if (String.substring (line, 0, 2) = ";#" handle _ => false) then
          print line
        else
          ()
  in  postStream (lines, echoIfTagged)
  end
(* Support for testing                          *)
(*                                              *)
(* I begin with testing support. As in the C code, *)
(* I want each interpreter to print out any line read *)
(* that begins with the special string [[;#]]. This *)
(* string is a formal comment that helps test chunks *)
(* marked \LAtranscript\RA. The strings are printed in a *)
(* modular way: a post-stream action prints any line *)
(* meeting the criterion. Function [[echoTagStream]] *)
(* transforms a stream of lines to a stream of lines, *)
(* adding the behavior I want.                  *)
(* <boxed values 164>=                          *)
val _ = op echoTagStream : line stream -> line stream 
(* <streams that issue two forms of prompts>=   *)
fun stripAndReportErrors xs =
  let fun next xs =
        case streamGet xs
          of SOME (ERROR msg, xs) => (eprintln msg; next xs)
           | SOME (OK x, xs) => SOME (x, xs)
           | NONE => NONE
  in  streamOfUnfold next xs
  end
(* \qbreak                                      *)
(*                                              *)
(* Issuing messages for error values            *)
(*                                              *)
(* Next is error handling. A process that can detect *)
(* errors produces a stream of type \monobox'a error *)
(* stream, for some unspecified type [['a]]. The  *)
(* [[ERROR]] and [[OK]] tags can be removed by reporting *)
(* errors and passing on values tagged [[OK]], resulting *)
(* in a new stream of type \monobox'a stream. Values *)
(* tagged with [[OK]] are passed on to the output stream *)
(* unchanged; messages tagged with [[ERROR]] are printed *)
(* to standard error, using [[eprintln]].       *)
(* <boxed values 165>=                          *)
val _ = op stripAndReportErrors : 'a error stream -> 'a stream
(* <streams that issue two forms of prompts>=   *)
fun lexLineWith lexer =
  stripAndReportErrors o streamOfUnfold lexer o streamOfList o explode
(* Using [[stripAndReportErrors]], I can turn a lexical *)
(* analyzer into a function that takes an input line and *)
(* returns a stream of tokens. Any errors detected *)
(* during lexical analysis are printed without any *)
(* information about source-code locations. That's *)
(* because, to keep things somewhat simple, I've chosen *)
(* to do lexical analysis on one line at a time, and my *)
(* code doesn't keep track of the line's source-code *)
(* location.                                    *)
(* <boxed values 166>=                          *)
val _ = op lexLineWith : 't lexer -> line -> 't stream
(* [[funty]] stand for \tau, [[actualtypes]]    *)
(* stand for \ldotsntau, and [[rettype]] stand for alpha *)
(* . The first premise is implemented by a call to *)
(* [[typesof]] and the second by a call to      *)
(* [[freshtyvar]]. The constraint is represented just as *)
(* written in the rule.                         *)

(* <streams that issue two forms of prompts>=   *)
fun parseWithErrors parser =
  let fun adjust (SOME (ERROR msg, tokens)) =
            SOME (ERROR msg, drainLine tokens)
        | adjust other = other
  in  streamOfUnfold (adjust o parser)
  end
(* <boxed values 167>=                          *)
val _ = op parseWithErrors : ('t, 'a) polyparser ->                     't
                                    located eol_marked stream -> 'a error stream
(* <streams that issue two forms of prompts>=   *)
type prompts   = { ps1 : string, ps2 : string }
val stdPrompts = { ps1 = "-> ", ps2 = "   " }
val noPrompts  = { ps1 = "", ps2 = "" }
(* Prompts                                      *)
(*                                              *)
(* Each interpreter in this book issues prompts using *)
(* the model established by the Unix shell. This model *)
(* uses two prompt strings. The first prompt string, *)
(* called [[ps1]], is issued when starting to read a *)
(* definition. The second prompt string, called [[ps2]], *)
(* is issued when in the middle of reading a definition. *)
(* Prompting can be disabled by making both [[ps1]] and *)
(* [[ps2]] empty.                               *)
(* <boxed values 168>=                          *)
type prompts = prompts
val _ = op stdPrompts : prompts
val _ = op noPrompts  : prompts
(* <streams that issue two forms of prompts>=   *)
fun ('t, 'a) interactiveParsedStream (lexer, parser) (name, lines, prompts) =
  let val { ps1, ps2 } = prompts
      val thePrompt = ref ps1
      fun setPrompt ps = fn _ => thePrompt := ps

      val lines = preStream (fn () => print (!thePrompt), echoTagStream lines)

      fun lexAndDecorate (loc, line) =
        let val tokens = postStream (lexLineWith lexer line, setPrompt ps2)
        in  streamMap INLINE (streamZip (streamRepeat loc, tokens)) @@@
            streamOfList [EOL (snd loc)]
        end

      val xdefs_with_errors : 'a error stream = 
        (parseWithErrors parser o streamConcatMap lexAndDecorate o locatedStream
                                                                               )
        (name, lines)
(* Building a reader                            *)
(*                                              *)
(* All that is left is to combine lexer and parser. The *)
(* combination manages the flow of information from the *)
(* input through the lexer and parser, and by monitoring *)
(* the flow of tokens in and syntax out, it arranges *)
(* that the right prompts ([[ps1]] and [[ps2]]) are *)
(* printed at the right times. The flow of information *)
(* involves multiple steps:                     *)
(*                                              *)
(*  1. [*] The input is a stream of lines. The stream is *)
(*  transformed with [[preStream]] and          *)
(*  [[echoTagStream]], so that a prompt is printed *)
(*  before every line, and when a line contains the *)
(*  special tag, that line is echoed to the output. *)
(*  2. Each line is converted to a stream of tokens by *)
(*  function \monoboxlexLineWith lexer. Each token is *)
(*  then paired with a source-code location and, *)
(*  tagged with [[INLINE]], and the stream of tokens *)
(*  is followed by an [[EOL]] value. This extra *)
(*  decoration transforms the \monoboxtoken stream *)
(*  provided by the lexer to the \monoboxtoken  *)
(*  located [[eol_marked]] stream needed by the *)
(*  parser. The work is done by function        *)
(*  [[lexAndDecorate]], which needs a located line. *)
(*                                              *)
(*  The moment a token is successfully taken from the *)
(*  stream, a [[postStream]] action sets the prompt *)
(*  to [[ps2]].                                 *)
(*  3. A final stream of definitions is computed by *)
(*  composing [[locatedStream]] to add source-code *)
(*  locations, \monoboxstreamConcatMap lexAndDecorate *)
(*  to add decorations, and \monoboxparseWithErrors *)
(*  parser to parse. The entire composition is  *)
(*  applied to the stream of lines created in step  *)
(*  [<-].                                       *)
(*                                              *)
(* The composition is orchestrated by function  *)
(* [[interactiveParsedStream]].                 *)
(*                                              *)
(* To deliver the right prompt in the right situation, *)
(* [[interactiveParsedStream]] stores the current prompt *)
(* in a mutable cell called [[thePrompt]]. The prompt is *)
(* initially [[ps1]], and it stays [[ps1]] until a token *)
(* is delivered, at which point the [[postStream]] *)
(* action sets it to [[ps2]]. But every time a new *)
(* definition is demanded, a [[preStream]] action on the *)
(* syntax stream [[xdefs_with_errors]] resets the prompt *)
(* to [[ps1]]. \qbreak This combination of pre- and *)
(* post-stream actions, on different streams, ensures *)
(* that the prompt is always appropriate to the state of *)
(* the parser. [*] \nwnarrowboxes               *)
(* <boxed values 169>=                          *)
val _ = op interactiveParsedStream : 't lexer * ('t, 'a) polyparser ->
                                     string * line stream * prompts -> 'a stream
val _ = op lexAndDecorate : srcloc * line -> 't located eol_marked stream
  in  
      stripAndReportErrors (preStream (setPrompt ps1, xdefs_with_errors))
  end 
(* The functions defined in this appendix are useful for *)
(* reading all kinds of input, not just computer *)
(* programs, and I encourage you to use them in your own *)
(* projects. But here are two words of caution: with so *)
(* many abstractions in the mix, the parsers are tricky *)
(* to debug. And while some parsers built from  *)
(* combinators are very efficient, mine aren't. *)

(* <common parsing code ((elided))>=            *)
fun ('t, 'a) finiteStreamOfLine fail (lexer, parser) line =
  let val lines = streamOfList [line] @@@ streamOfEffects fail
      fun lexAndDecorate (loc, line) =
        let val tokens = lexLineWith lexer line
        in  streamMap INLINE (streamZip (streamRepeat loc, tokens)) @@@
            streamOfList [EOL (snd loc)]
        end

      val things_with_errors : 'a error stream = 
        (parseWithErrors parser o streamConcatMap lexAndDecorate o locatedStream
                                                                               )
        ("command line", lines)
  in  
      stripAndReportErrors things_with_errors
  end 
val _ = finiteStreamOfLine :
          (unit -> string option) -> 't lexer * ('t, 'a) polyparser -> line ->
                                                                       'a stream
(* \qbreak                                      *)
(*                                              *)
(* Interpreter setup and command-line \         *)
(* chaptocsplitprocessing                       *)
(*                                              *)
(* In each interpreter, something has to act like the *)
(* C function [[main]]. This code has to initialize the *)
(* interpreter and start evaluating extended    *)
(* definitions.                                 *)
(*                                              *)
(* Part of initialization is setting the global error *)
(* format. The reusable function [[setup_error_format]] *)
(* uses interactivity to set the error format, which, as *)
(* in the C versions, determines whether syntax-error *)
(* messages include source-code locations (see functions *)
(* [[synerrorAt]] and [[synerrormsg]] on \      *)
(* cpagerefmlinterps.synerrormsg,mlinterps.synerrorAt). *)
(* <shared utility functions for initializing interpreters>= *)
fun override_if_testing () =                           (*OMIT*)
  if isSome (OS.Process.getEnv "NOERRORLOC") then      (*OMIT*)
    toplevel_error_format := WITHOUT_LOCATIONS         (*OMIT*)
  else                                                 (*OMIT*)
    ()                                                 (*OMIT*)
fun setup_error_format interactivity =
  if prompts interactivity then
    toplevel_error_format := WITHOUT_LOCATIONS
    before override_if_testing () (*OMIT*)
  else
    toplevel_error_format := WITH_LOCATIONS
    before override_if_testing () (*OMIT*)
(* \qbreak                                      *)
(*                                              *)
(* Utility functions for limiting computation   *)
(*                                              *)
(* Each interpreter is supplied with two ways of *)
(* stopping a runaway computation:              *)
(*                                              *)
(*   • A recursion limit halts the computation if its *)
(*  call stack gets deeper than 6,000 calls.    *)
(*   • A supply of evaluation fuel halts the computation *)
(*  after a million calls to [[eval]]. That's enough *)
(*  to compute the 25th Catalan number in uSmalltalk, *)
(*  for example.                                *)
(*                                              *)
(* If environment variable [[BPCOPTIONS]] includes the *)
(* string [[nothrottle]], evaluation fuel is ignored. *)
(* <function application with overflow checking>= *)
local
  val defaultRecursionLimit = 6000
  val recursionLimit = ref defaultRecursionLimit
  datatype checkpoint = RECURSION_LIMIT of int

  val evalFuel = ref 1000000
  val throttleCPU = not (hasOption "nothrottle")
in
  (* manipulate recursion limit *)
  fun checkpointLimit () = RECURSION_LIMIT (!recursionLimit)
  fun restoreLimit (RECURSION_LIMIT n) = recursionLimit := n

  (* work with fuel *)
  val defaultEvalFuel = ref (!evalFuel)
  fun fuelRemaining () = !evalFuel
  fun withFuel n f x = 
    let val old = !evalFuel
        val _ = evalFuel := n
    in  (f x before evalFuel := old) handle e => (evalFuel := old; raise e)
    end
(* \qbreak                                      *)
(* <function application with overflow checking>= *)
  (* convert function `f` to respect computation limits *)
  fun applyWithLimits f =
    if !recursionLimit <= 0 then
      ( recursionLimit := defaultRecursionLimit
      ; raise RuntimeError "recursion too deep"
      )
    else if throttleCPU andalso !evalFuel <= 0 then
      ( evalFuel := !defaultEvalFuel
      ; raise RuntimeError "CPU time exhausted"
      )
    else
      let val _ = recursionLimit := !recursionLimit - 1
          val _ = evalFuel       := !evalFuel - 1
      in  fn arg => f arg before (recursionLimit := !recursionLimit + 1)
      end
  fun resetComputationLimits () = ( recursionLimit := defaultRecursionLimit
                                  ; evalFuel := !defaultEvalFuel
                                  )
end



(*****************************************************************)
(*                                                               *)
(*   TYPES FOR \TIMPCORE                                         *)
(*                                                               *)
(*****************************************************************)

(* <types for \timpcore>=                       *)
datatype ty    = INTTY | BOOLTY | UNITTY | ARRAYTY of ty
datatype funty = FUNTY of ty list * ty
(* <types for \timpcore>=                       *)
fun eqType (INTTY,      INTTY)      = true
  | eqType (BOOLTY,     BOOLTY)     = true
  | eqType (UNITTY,     UNITTY)     = true
  | eqType (ARRAYTY t1, ARRAYTY t2) = eqType (t1, t2)
  | eqType (_,          _)          = false
and eqTypes (ts1, ts2) = ListPair.allEq eqType (ts1, ts2)
(* <types for \timpcore ((elided))>=            *)
(* This code prints types.                      *)
(* <definitions of [[typeString]] and [[funtyString]] for \timpcore>= *)
fun typeString BOOLTY        = "bool"
  | typeString INTTY         = "int"
  | typeString UNITTY        = "unit"
  | typeString (ARRAYTY tau) = "(array " ^ typeString tau ^ ")"
(* <definitions of [[typeString]] and [[funtyString]] for \timpcore>= *)
fun funtyString (FUNTY (args, result)) =
  "(" ^ spaceSep (map typeString args) ^ " -> " ^ typeString result ^ ")"
(* <types for \timpcore>=                       *)
fun eqFunty (FUNTY (args, result), FUNTY (args', result')) =
  eqTypes (args, args') andalso eqType (result, result')



(*****************************************************************)
(*                                                               *)
(*   ABSTRACT SYNTAX AND VALUES FOR \TIMPCORE                    *)
(*                                                               *)
(*****************************************************************)

(* Chunks related to abstract syntax are collected here. *)
(* The definition of [[xdef]] is shared with    *)
(* micro-Scheme, and functions [[valueString]] and *)
(* [[expString]] are defined below.             *)
(* <abstract syntax and values for \timpcore>=  *)
(* Moving to run time, there are only two forms of *)
(* value. Values of integer, Boolean, or unit type are *)
(* represented using the [[NUM]] form; values of array *)
(* types are represented using the [[ARRAY]] form. *)
(* <definitions of [[exp]] and [[value]] for \timpcore>= *)
datatype value = NUM   of int
               | ARRAY of value array
(* [*] Horn clauses. In this exercise, you write Prolog *)
(* code to convert a Prolog clause into a Horn clause. *)
(* There are a lot of definitions.              *)
(*                                              *)
(* A literal is one of the following:           *)
(*                                              *)
(*   • An atom, which is called a positive literal *)
(*   • A term of the form \monoboxnot(a), where a is an *)
(*  atom, and which is called a negative literal *)
(*                                              *)
(* A formula is one of the following:           *)
(*                                              *)
(*   • A literal                              *)
(*   • A term of the form \monoboxnot(f), where f is a *)
(*  formula                                     *)
(*   • A term of the form \monoboxand(f_1, f_2), where *)
(*  f_1 and f_2 are formulas                    *)
(*   • A term of the form \monoboxor(f_1, f_2), where *)
(*  f_1 and f_2 are formulas                    *)
(*                                              *)
(* A Prolog clause is a term of the form \monobox(a_0 :- *)
(* a_1, ..., a_n), where each a_i is an atom.   *)
(*                                              *)
(* A disjunction is one of the following:       *)
(*                                              *)
(*   • A literal                              *)
(*   • A formula of the form \monoboxor(d_1, d_2), where *)
(*  d_1 and d_2 are disjunctions                *)
(*                                              *)
(* A Horn clause is a disjunction that contains at most *)
(* one positive literal.                        *)
(*                                              *)
(* Write a Prolog predicate [[is_horn/2]] that converts *)
(* between Prolog clauses and Horn clauses. It should *)
(* run both forward and backward.               *)
(*                                              *)
(* [*] Removing elements from a list. The chapter *)
(* defines [[member]], which says if a list contains an *)
(* element. To remove all copies of an element from a *)
(* list, define predicate [[stripped/3]], where \monobox *)
(* stripped(\listvX, X, \listvY) holds whenever \listvY *)
(* is the list obtained by removing all copies of X from *)
(* \listvX.                                     *)
(*                                              *)
(* [*] Splitting lists. To split a list into equal or *)
(* approximately equal parts, define and use these *)
(* predicates:                                  *)
(*                                              *)
(*  1. Define [[bigger/2]], where \monoboxbigger(\listv *)
(*  X, \listvY) holds if and only if \listv X is a *)
(*  list containing more elements than \listvY. *)
(*  2. Write a query that uses [[bigger/2]] and *)
(*  [[appended/3]] to split a list into two sublists *)
(*  of nearly equal lengths.                    *)
(*  3. Write a query that uses [[bigger/2]] and *)
(*  [[appended/3]] to split a list into two sublists *)
(*  whose lengths differ by at most 1.          *)
(*  4. To help you write unit tests for your work, *)
(*  define [[has_length/2]], where \monobox     *)
(*  [[has_length]](\listvX, N) holds if and only if \ *)
(*  listvX is a list of N elements. If \listvX is a *)
(*  logical variable, or if any tail of \listvX is a *)
(*  logical variable, the resulting proposition need *)
(*  not be provable. In other words, if somebody *)
(*  hands you an N, don't try to conjure a suitable \ *)
(*  listvX.                                     *)
(*                                              *)
(* [*] Conversions between S-expressions and lists. *)
(* For purposes of this exercise, let us say that an *)
(* S-expression is an atom, a number, or a list of zero *)
(* or more S-expressions.                       *)
(*                                              *)
(*  1. Define [[flattened/2]], such that \monobox *)
(*  flattened(SX, \listvA) holds whenever SX is an *)
(*  S-expression and \listvA is a list containing the *)
(*  same atoms as SX, in the same order. The problem *)
(*  is analogous to the Scheme [[flatten]] function *)
(*  described in Exercise [->] on \cpageref     *)
(*  scheme.ex.flatten.                          *)
(* <definitions of [[exp]] and [[value]] for \timpcore>= *)
datatype exp   = LITERAL of value
               | VAR     of name
               | SET     of name * exp
               | IFX     of exp * exp * exp
               | WHILEX  of exp * exp
               | BEGIN   of exp list
               | APPLY   of name * exp list
               (* <\timpcore\ syntax for equality and printing>= *)
               | EQ      of exp * exp
               | PRINTLN of exp
               | PRINT   of exp
               (* The [[array-at]] form operates on arrays of any type. *)
               (* As shown, it can index into an array of type \monobox *)
               (* (array int) and return a result of type [[int]]. It *)
               (* can also index into an array of type \monobox(array *)
               (* (array int)) and return a result of type \monobox *)
               (* (array int). Such behavior is polymorphic. Typed *)
               (* Impcore is monomorphic, which means that a function *)
               (* can be used for arguments and results of one and only *)
               (* one type. So like [[=]] and [[println]], [[array-at]] *)
               (* can't be implemented as a primitive function; it must *)
               (* be a syntactic form. In fact, every array operation *)
               (* is a syntactic form, defined as follows:     *)
               (* <array extensions to \timpcore's abstract syntax>= *)
               | AMAKE of exp * exp
               | AAT   of exp * exp
               | APUT  of exp * exp * exp
               | ASIZE of exp
(* In Typed Impcore, as in Impcore, a function is not an *)
(* ordinary value. A function takes one of two forms: *)
(* [[USERDEF]], which represents a user-defined *)
(* function, and [[PRIMITIVE]], which represents a *)
(* primitive function. Because the type system rules out *)
(* most errors in primitive operations, primitive *)
(* functions are represented more simply than in \cref *)
(* mlscheme.chap: in Typed Impcore, a primitive function *)
(* is represented by an ML function of type \monobox *)
(* value list -> value; there is no parameter of type  *)
(* [[exp]].                                     *)
(* <definition of type [[func]], to represent a \timpcore\ function>= *)
datatype func = USERDEF   of name list * exp
              | PRIMITIVE of value list -> value
(* A [[func]] contains no types; types are needed only *)
(* during type checking, and the [[func]] representation *)
(* is used at run time, after all types have been *)
(* checked.                                     *)

(* Similarly, as described in \creftypesys.array-ast *)
(* below, Typed Impcore's array operations also need *)
(* special-purpose syntax. Such special-purpose syntax *)
(* is typical; in many languages, array syntax is *)
(* written using square brackets. As another example, *)
(* a pointer in C is dereferenced by a syntactic form *)
(* written with [[*]] or [[->]].                *)
(*                                              *)
(* In Typed Impcore, the syntax for a function  *)
(* definition includes explicit parameter types and an *)
(* explicit result type. As is customary in formal *)
(* semantics and in Pascal-like and ML-like languages, *)
(* but not in C, the syntax places a formal parameter's *)
(* type to the right of its name. \timplabeldef *)
(* <definition of [[def]] for \timpcore>=       *)
type userfun = { formals : (name * ty) list, body : exp, returns : ty }
datatype def = VAL    of name * exp
             | EXP    of exp
             | DEFINE of name * userfun
(* Typed Impcore's unit tests include [[check-expect]] *)
(* and [[check-error]] from untyped Impcore and *)
(* micro-Scheme, plus two new unit tests related to *)
(* types: \timplabelunit_test                   *)
(* <definition of [[unit_test]] for \timpcore>= *)
datatype unit_test = CHECK_EXPECT        of exp * exp
                   | CHECK_ASSERT        of exp
                   | CHECK_ERROR         of exp
                   | CHECK_TYPE_ERROR    of def
                   | CHECK_FUNCTION_TYPE of name * funty
(* <definition of [[xdef]] (shared)>=           *)
datatype xdef = DEF    of def
              | USE    of name
              | TEST   of unit_test
              | DEFS   of def list  (*OMIT*)
(* String conversions                           *)
(*                                              *)
(* To enable the interpreter to issue error messages, *)
(* I define a string-conversion function for values, *)
(* plus one for each major syntactic category.  *)
(*                                              *)
(* To distinguish an array from a list, the elements of *)
(* an array are shown in square brackets.       *)
(* <definition of [[valueString]] for \timpcore>= *)
fun valueString (NUM n) = intString n
  | valueString (ARRAY a) =
      if Array.length a = 0 then
          "[]"
      else
          let val eltStrings = map valueString (Array.foldr op :: [] a)
          in  String.concat ["[", spaceSep eltStrings, "]"]
          end
(* And expressions.                             *)
(* <definition of [[expString]] for \timpcore>= *)
fun expString e =
  let fun bracket s = "(" ^ s ^ ")"
      val bracketSpace = bracket o spaceSep
      fun exps es = map expString es
  in  case e
        of LITERAL v => valueString v
         | VAR name => name
         | SET (x, e) => bracketSpace ["set", x, expString e]
         | IFX (e1, e2, e3) => bracketSpace ("if" :: exps [e1, e2, e3])
         | WHILEX (cond, body) =>
             bracketSpace ["while", expString cond, expString body]
         | BEGIN es => bracketSpace ("begin" :: exps es)
         | EQ (e1, e2) => bracketSpace ("=" :: exps [e1, e2])
         | PRINTLN e => bracketSpace ["println", expString e]
         | PRINT e => bracketSpace ["print", expString e]
         | APPLY (f, es) => bracketSpace (f :: exps es)
         | AAT (a, i) => bracketSpace ("array-at" :: exps [a, i])
         | APUT (a, i, e) => bracketSpace ("array-put" :: exps [a, i, e])
         | AMAKE (e, n) => bracketSpace ("make-array" :: exps [e, n])
         | ASIZE a => bracketSpace ("array-size" :: exps [a])
  end
(* And definitions.                             *)
(* <definitions of [[defString]] and [[defName]] for \timpcore>= *)
fun defString d =
  let fun bracket s = "(" ^ s ^ ")"
      val bracketSpace = bracket o spaceSep
      fun formal (x, t) = "[" ^ x ^ " : " ^ typeString t ^ "]"
  in  case d
        of EXP e => expString e
         | VAL (x, e) => bracketSpace ["val", x, expString e]
         | DEFINE (f, { formals, body, returns }) =>
             bracketSpace ["define", typeString returns, f,
                           bracketSpace (map formal formals), expString body]
  end
fun defName (VAL (x, _)) = x
  | defName (DEFINE (x, _)) = x
  | defName (EXP _) =
      raise InternalError "asked for name defined by expression"
(* <definitions of functions [[toArray]] and [[toInt]] for \timpcore>= *)
fun toArray (ARRAY a) = a
  | toArray _         = raise BugInTypeChecking "non-array value"
fun toInt   (NUM n)   = n
  | toInt _           = raise BugInTypeChecking "non-integer value"
(* <boxed values 100>=                          *)
val _ = op toArray : value -> value array
val _ = op toInt   : value -> int


(*****************************************************************)
(*                                                               *)
(*   UTILITY FUNCTIONS ON \TIMPCORE\ VALUES                      *)
(*                                                               *)
(*****************************************************************)

(* Unit testing                                 *)
(*                                              *)
(* In Typed Impcore, numbers can equal numbers and *)
(* arrays can equal arrays. Because arrays are mutable, *)
(* Typed Impcore defines equality as object identity, *)
(* which is implemented using ML's polymorphic [[=]] *)
(*  form                                        *)
(* <utility functions on \timpcore\ values>=    *)
fun testEquals (NUM n,   NUM n')   = n = n'
  | testEquals (ARRAY a, ARRAY a') = a = a'
  | testEquals (_,       _)        = false



(*****************************************************************)
(*                                                               *)
(*   TYPE CHECKING FOR \TIMPCORE                                 *)
(*                                                               *)
(*****************************************************************)

(* <type checking for \timpcore>=               *)
fun typeof (e, globals, functions, formals) =
  let (* <function [[ty]], checks type of expression given $\itenvs$>= *)
      fun ty (LITERAL v) = INTTY
      (* <function [[ty]], checks type of expression given $\itenvs$>= *)
        | ty (VAR x) = (find (x, formals) handle NotFound _ => find (x, globals)
                                                                               )
      (* An assignment \monobox(set x e) has a type if both x *)
      (*  and e have the same type, in which case the *)
      (* assignment has that type. \usetyFormalAssign \usety *)
      (* GlobalAssign The types of both x and e are found by *)
      (* recursive calls to [[ty]].                   *)
      (* <function [[ty]], checks type of expression given $\itenvs$>= *)
        | ty (SET (x, e)) =
               let val tau_x = ty (VAR x)
                   val tau_e = ty e
               in  if eqType (tau_x, tau_e) then tau_x
                   else (* <raise [[TypeError]] for an assignment>=     *)
                        raise TypeError ("Set variable " ^ x ^ " of type " ^
                                                              typeString tau_x ^
                                         " to value of type " ^ typeString tau_e
                                                                               )
               end
      (* A conditional has a type if its condition is Boolean *)
      (* and if both branches have the same type—in which case *)
      (* the conditional has that type. \usetyIf Again, most *)
      (* of the code is devoted to error messages.    *)
      (* <function [[ty]], checks type of expression given $\itenvs$>= *)
        | ty (IFX (e1, e2, e3)) =
            let val tau1 = ty e1
                val tau2 = ty e2
                val tau3 = ty e3
            in  if eqType (tau1, BOOLTY) then
                  if eqType (tau2, tau3) then
                    tau2
                  else
                    raise TypeError
                      ("In if expression, true branch has type " ^
                       typeString tau2 ^ " but false branch has type " ^
                       typeString tau3)
                else
                  raise TypeError
                    ("Condition in if expression has type " ^ typeString tau1 ^
                     ", which should be " ^ typeString BOOLTY)
            end
      (* A [[while]] loop has a type if its condition is *)
      (* Boolean and if its body has a type—we don't care what *)
      (* type. In that case the [[while]] loop has type *)
      (* [[unit]]. \usetyWhile                        *)
      (* <function [[ty]], checks type of expression given $\itenvs$>= *)
        | ty (WHILEX (e1, e2)) =
            let val tau1 = ty e1
                val tau2 = ty e2
            in  if eqType (tau1, BOOLTY) then
                  UNITTY
                else
                  raise TypeError ("Condition in while expression has type " ^
                                   typeString tau1 ^ ", which should be " ^
                                   typeString BOOLTY)
            end
      (* <function [[ty]], checks type of expression given $\itenvs$>= *)
        | ty (BEGIN es) =
             let val bodytypes = map ty es
             in  List.last bodytypes handle Empty => UNITTY
             end
      (* <function [[ty]], checks type of expression given $\itenvs$>= *)
        | ty (EQ (e1, e2)) =
             let val (tau1, tau2) = (ty e1, ty e2)
             in  if eqType (tau1, tau2) then
                   BOOLTY
                 else
                   raise TypeError ("Equality sees values of different types " ^
                                    typeString tau1 ^ " and " ^ typeString tau2)
             end
      (* A print expression has a type if its subexpression is *)
      (* well typed, in which case its type is [[unit]]. \ *)
      (* usetyPrintln                                 *)
      (* <function [[ty]], checks type of expression given $\itenvs$>= *)
        | ty (PRINTLN e) = (ty e; UNITTY)
        | ty (PRINT   e) = (ty e; UNITTY)
      (* <function [[ty]], checks type of expression given $\itenvs$>= *)
        | ty (APPLY (f, actuals)) =
             let val actualtypes                     = map ty actuals
                 val FUNTY (formaltypes, resulttype) = find (f, functions)
                 (* <definition of [[badParameter]]>=            *)
                 fun badParameter (n, atau::actuals, ftau::formals) =
                       if eqType (atau, ftau) then
                         badParameter (n+1, actuals, formals)
                       else
                         raise TypeError ("In call to " ^ f ^ ", parameter " ^
                                          intString n ^ " has type " ^
                                                               typeString atau ^
                                          " where type " ^ typeString ftau ^
                                                                 " is expected")
                   | badParameter _ =
                       raise TypeError ("Function " ^ f ^ " expects " ^
                                        countString formaltypes "parameter" ^
                                        " but got " ^ intString (length
                                                                   actualtypes))
                 (* The distinction between ``compile time,'' where the *)
                 (* interpreter runs the typing phase [[typdef]], and *)
                 (* ``run time,'' where the interpreter runs the *)
                 (* evaluator [[evaldef]], is sometimes called the phase *)
                 (* distinction. The phase distinction is easy to *)
                 (* overlook, especially when you're using an interactive *)
                 (* interpreter or compiler, but the code shows the phase *)
                 (* distinction is real.                         *)
                 (*                                              *)
                 (* Function [[typdef]] is defined in \creftypesys.chap, *)
                 (* and function [[evaldef]] is defined below. But one *)
                 (* part of [[typdef]] is defined here: function *)
                 (* [[badParameter]] is called when a function   *)
                 (* application fails to typecheck, in which case *)
                 (* [[badParameter]] formulates an informative error *)
                 (* message.                                     *)
                 (* <boxed values 105>=                          *)
                 val _ = op badParameter : int * ty list * ty list -> 'a
      (* A function application has a type if its function is *)
      (* defined in environment \fgam, and if the function is *)
      (* applied to the right number and types of arguments. *)
      (* In that case, the type of the application is the *)
      (* result type of the function type found in \fgam. \ *)
      (* usetyApply If the function is applied to the wrong *)
      (* number or types of arguments, function       *)
      (* [[badParameter]], which is defined in the Supplement, *)
      (* finds one bad parameter and builds an error message. *)
      (* <boxed values 98>=                           *)
      val _ = op badParameter : int * ty list * ty list -> 'a
      (* [[funty]] stand for \tau, [[actualtypes]]    *)
      (* stand for \ldotsntau, and [[rettype]] stand for alpha *)
      (* . The first premise is implemented by a call to *)
      (* [[typesof]] and the second by a call to      *)
      (* [[freshtyvar]]. The constraint is represented just as *)
      (* written in the rule.                         *)

             in  if eqTypes (actualtypes, formaltypes) then
                   resulttype
                 else
                   badParameter (1, actualtypes, formaltypes)
             end
      (* Rules for type constructors: Formation, introduction, *)
      (* and elimination                              *)
      (*                                              *)
      (* [*]                                          *)
      (*                                              *)
      (* In a monomorphic language, a new type constructor *)
      (* needs new syntax, and new syntactic forms need new *)
      (* typing rules. Like the operations described in \cref *)
      (* scheme.constructor-observer-mutator, syntax should *)
      (* include forms that create and observe, as well as *)
      (* forms that produce or mutate, or both. Rules have *)
      (* similar requirements.                        *)
      (*                                              *)
      (* Rules should say how to use the new type constructor *)
      (* to make new types. Such rules are called formation *)
      (* rules. Rules should also say what syntactic forms *)
      (* create new values that are described by the new type *)
      (* constructor. Such rules are called introduction rules *)
      (* ; an introduction rule describes a syntactic form *)
      (* that is analogous to a creator function as described *)
      (* in Section [->]. Finally, rules should say what *)
      (* syntactic forms use the values that are described by *)
      (* the new type constructor. Such rules are called *)
      (* elimination rules; an elimination rule describes *)
      (* a syntactic form that may be analogous to a mutator *)
      (* or observer function as described in Section [->]. \ *)
      (* qloosepar2                                   *)
      (*                                              *)
      (* \typesystemtemplates                         *)
      (*                                              *)
      (* \qbreak A rule can be recognized as a formation, *)
      (* introduction, or elimination rule by first drawing a *)
      (* box around the type of interest, then seeing if the *)
      (* rule matches any of these templates:         *)
      (*                                              *)
      (*   • A formation rule answers the question, ``what *)
      (*  types can I make?'' Below the line, it has the *)
      (*  judgment ``\mskip0.8mu\isatype\mytype,'' where \ *)
      (*  mytype is a type of interest: \punctrule. \tyrule *)
      (*  Formation template...\isatype\mytype        *)
      (*   • An introduction rule answers the question, ``how *)
      (*  do I make a value of the interesting type?'' *)
      (*  Below the line, it has a typing judgment that *)
      (*  ascribes the type of interest to an expression *)
      (*  whose form is somehow related to the type.  *)
      (*  To write that expression, I use a ? mark: \ *)
      (*  punctrule. \tyruleIntroduction template...Gamma\ *)
      (*  vdash? : \mytype                            *)
      (*   • An elimination rule answers the question, ``what *)
      (*  can I do with a value of the interesting type?'' *)
      (*  Above the line, it has a typing judgment that *)
      (*  ascribes the type of interest to an expression *)
      (*  whose form is unknown. Such an expression will be *)
      (*  written as e, e_1, e', or something similar: \ *)
      (*  punctrule. \tyruleElimination template...\qquad *)
      (*  Gamma\vdashe : \mytype\qquad......          *)
      (*                                              *)
      (* {sidebar}Understanding formation, introduction, and *)
      (* elimination \advanceby -0.3pt [*] Not all    *)
      (* syntactically correct types and expressions are *)
      (* acceptable in programs; acceptability is determined *)
      (* by formation, introduction, and elimination rules. *)
      (* Formation rules tell us what types are acceptable; *)
      (* for example, in Typed Impcore, [[int]], [[bool]], and *)
      (* \monobox(array int) are acceptable types, but \ *)
      (* monobox(int bool), [[array]], and \monobox(array *)
      (* array) are not. In C, [[unsigned]] and [[unsigned*]] *)
      (* are acceptable, but [[*]] and [[*unsigned]] are not. *)
      (* Type-formation rules are usually easy to write. *)
      (*                                              *)
      (* Introduction and elimination rules tell us what terms *)
      (* (expressions) are acceptable. The words      *)
      (* ``introduction'' and ``elimination'' come from formal *)
      (* logic; the ideas they represent have been adopted *)
      (* into programming languages via the principle of *)
      (* propositions as types. This principle says that a *)
      (* type constructor corresponds to a logical connective, *)
      (* a type corresponds to a proposition, and a term of *)
      (* the given type corresponds to a proof of the *)
      (* proposition. For example, logical implication *)
      (* corresponds to the function arrow; if type tau *)
      (* corresponds to proposition P, then the type tau-->tau *)
      (* corresponds to the proposition ``P implies P''; and *)
      (* the identity function of type tau-->tau corresponds *)
      (* to a proof of ``P implies P.''               *)
      (*                                              *)
      (* A term may inhabit a particular type ``directly'' or *)
      (* ``indirectly.'' Which is which depends on how the *)
      (* term relates to the type constructor used to make the *)
      (* type. For example, a term of type \monobox(array *)
      (* bool) might refer to the variable [[truth-vector]], *)
      (* might evaluate a conditional that returns an array, *)
      (* or might apply a function that returns an array. All *)
      (* these forms are indirect: variable reference, *)
      (* conditionals, and function application can produce *)
      (* results of any type and are not specific to arrays. *)
      (* But if the term has the [[make-array]] form, *)
      (* it builds an array directly; a [[make-array]] term *)
      (* always produces an array. Similar direct and indirect *)
      (* options are available in proofs.             *)
      (*                                              *)
      (* In both type theory and logic, the direct forms are *)
      (* the introduction forms, and their acceptable usage is *)
      (* described by introduction rules. The indirect forms *)
      (* are typically elimination forms, described by *)
      (* elimination rules. For example, the conditional is an *)
      (* elimination form for Booleans, and function  *)
      (* application is an elimination form for functions. *)
      (* In general, an introduction form puts new information *)
      (* into a proof or a term, whereas an elimination form *)
      (* extracts information that was put there by an *)
      (* introduction form. For example, if I get a Boolean *)
      (* using [[array-at]], I'm getting information that was *)
      (* in the array, so I'm using an elimination form for *)
      (* arrays, not an introduction form for Booleans. *)
      (*                                              *)
      (* An introduction or elimination form is a syntactic *)
      (* form of expression, and it is associated with a type *)
      (* (or type constructor) that appears in its typing *)
      (* rule. An introduction form for a type constructor µ\ *)
      (* notation[mew]µa type constructor will have a typing *)
      (* rule that has a µ type in the conclusion; types in *)
      (* premises are often arbitrary types tau. An   *)
      (* elimination form for the same µ will have a typing *)
      (* rule that has a µ type in a premise; the type in the *)
      (* conclusion is often an arbitrary type tau,   *)
      (* or sometimes a fixed type like bool. Identifying *)
      (* introduction and elimination forms is the topic of \ *)
      (* crefpage(typesys.ex.protocol-forms.          *)
      (*                                              *)
      (* In a good design, information created by any *)
      (* introduction form can be extracted by an elimination *)
      (* form, and vice versa. A design that has all the forms *)
      (* and rules it needs resembles as design that has all *)
      (* the algebraic laws it needs, as discussed in \ *)
      (* crefpage(scheme.constructor-observer-mutator. *)
      (* Introduction forms relate to algebraic laws' creators *)
      (* and producers, and elimination forms relate to *)
      (* observers. {sidebar}                         *)
      (*                                              *)
      (* These templates work perfectly with the formation, *)
      (* introduction, and elimination rules for arrays. *)
      (* To start, an array type is formed by supplying the *)
      (* type of its elements. In Typed Impcore, the length of *)
      (* an array is not part of its type. [Because the length *)
      (* of an array is not part of its type, \timpcore\ *)
      (* requires a run-time safety check for every array *)
      (* access. Such checks can be eliminated by a type *)
      (* system in which the length of an array \emph{is} part *)
      (* of its type \cite{xi:eliminating}, but these sorts of *)
      (* type systems are beyond the scope of this book.] \ *)
      (* tyrule ArrayFormation \isatypetau \isatype\arraytype( *)
      (* tau)                                         *)
      (*                                              *)
      (* An array is made using [[make-array]], which is *)
      (* described by an introduction rule. \tyrule MakeArray *)
      (* \twoquad \itypeise_1 \inttype \itypeise_2 tau \ *)
      (* itypeis\xarraymake(e_1, e_2) \arraytype(tau) The \ *)
      (* xarraymake form is definitely related to the array *)
      (* type, and this rule matches the introduction *)
      (* template.                                    *)
      (*                                              *)
      (* An array is used by indexing it, updating it, or *)
      (* taking its length. Each operation is described by an *)
      (* elimination rule. \tyrule ArrayAt \twoquad \itypeis *)
      (* e_1 \arraytype(tau) \itypeise_2 \inttype \itypeis\ *)
      (* xarrayget(e_1, e_2) tau                      *)
      (*                                              *)
      (* \tyrule ArrayPut \threequad \itypeise_1 \arraytype( *)
      (* tau) \itypeise_2 \inttype \itypeise_3 tau \itypeis\ *)
      (* xarrayset(e_1, e_2, e_3) tau                 *)
      (*                                              *)
      (* \tyrule ArraySize \itypeise \arraytype(tau) \itypeis\ *)
      (* xarraylength(e) \inttype                     *)
      (*                                              *)
      (* In each of these rules, an expression of array type ( *)
      (* e_1 or e) has an arbitrary syntactic form, which need *)
      (* not be related to arrays. These rules match the *)
      (* elimination template.                        *)
      (*                                              *)
      (* These rules can be turned into code for the type *)
      (* checker, which you can fill in (Exercise [->]): [*] *)

(* <function [[ty]], checks type of expression given $\itenvs$ ((prototype))>= *)
      | ty (AAT (a, i))        = raise LeftAsExercise "AAT"
      | ty (APUT (a, i, e))    = raise LeftAsExercise "APUT"
      | ty (AMAKE (len, init)) = raise LeftAsExercise "AMAKE"
      | ty (ASIZE a)           = raise LeftAsExercise "ASIZE"
(* A [[funty]] describes just one type; for example, \ *)
(* monoboxFUNTY ([INTTY, INTTY], BOOLTY) describes the *)
(* type of a function that takes two integer arguments *)
(* and returns a Boolean result. In Typed Impcore, a *)
(* function or variable has at most one type, which *)
(* makes Typed Impcore monomorphic.             *)
(*                                              *)
(* Types are printed with the help of functions *)
(* [[typeString]] and [[funtyString]], which are defined *)
(* in \crefapp:typesys.                         *)
(*                                              *)
(* Types are checked for equality by mutually recursive *)
(* functions [[eqType]] and [[eqTypes]]:        *)
(* <boxed values 97>=                           *)
val _ = op eqType  : ty      * ty      -> bool
val _ = op eqTypes : ty list * ty list -> bool
(* \timpflabeleqType                            *)

(* Types should always be checked for equality using *)
(* [[eqType]], not the built-in [[=]] operator. As shown *)
(* in \creftuscheme.type-equivalence below, a single *)
(* type can sometimes have multiple representations, *)
(* which [[=]] reports as different but should actually *)
(* be considered the same. Using [[eqType]] gets these *)
(* cases right; if you use [[=]], you risk introducing *)
(* bugs that will be hard to find.              *)
(*                                              *)
(* Function types are checked for equality using *)
(* function [[eqFunty]].                        *)
(* <boxed values 97>=                           *)
val _ = op eqFunty  : funty * funty -> bool
(* A \xwhile loop is well typed if the condition is *)
(* Boolean and the body is well typed. The tau that is *)
(* the type of the body e_2 is not used in the  *)
(* conclusion of the rule, because it matters only that *)
(* type tau exists, not what it is. \tyrule While \ *)
(* itypeise_1\booltype \qquad \itypeise_2tau \itypeis\ *)
(* xwhile(e_1, e_2) \unittype As explained above, *)
(* because a \xwhile loop is executed for its side *)
(* effect and does not produce a useful result, it is *)
(* given the unit type.                         *)
(*                                              *)
(* Like the \rulenameIf rule, the \rulenameWhile rule is *)
(* structured differently from the \xwhile rules in the *)
(* operational semantics. The operational semantics has *)
(* two rules: one corresponds to e_1 ==>\vtrue and *)
(* iterates the loop, and one corresponds to e_1 ==>\ *)
(* vfalse and terminates the loop. The type system needs *)
(* only one rule, which checks both types. \ifcutting *)
(* And the structure of this \rulenamewhile rule ensures *)
(* that during type checking every subexpression is *)
(* typechecked exactly once, even though during *)
(* evaluation every subexpression may well be executed a *)
(* different, even unbounded number of times, For most *)
(* reasonable type systems, then, type checking takes *)
(* time linear in the size of the program. In practice, *)
(* type checking is very fast indeed.           *)
(*                                              *)
(* A \xbegin expression is well typed if all of its *)
(* subexpressions are well typed. Because every *)
(* subexpression except the last is executed only for *)
(* its side effect, it could legitimately be required to *)
(* have type \unittype. But I want to allow \xset *)
(* expressions inside \xbegin expressions, so I permit a *)
(* subexpression in a \xbegin sequence to have any type. *)
(* \tyrule Begin \threequad \itypeise_1tau_1 ... \ *)
(* itypeise_ntau_n \itypeis\xbegin(\ldotsne)tau_n The *)
(* premises mentioning \ldotsnmoe are necessary because *)
(* although it doesn't matter what the types of \ *)
(* ldotsnmoe are, it does matter that they have types. *)
(*                                              *)
(* An empty \xbegin is always well typed and has type \ *)
(* unittype. \tyrule EmptyBegin \itypeis\xbegin()\ *)
(* unittype                                     *)
(*                                              *)
(* A function application is well typed if the function *)
(* is applied to the right number and types of  *)
(* arguments. A function's type is looked up in the *)
(* function-type environment \fgam. The type of the *)
(* application is the result type of the function. \ *)
(* tyrule Apply \twoquad \fgam(f) = \crossdotsntau-->tau *)
(* \itypeise_itau_i, 1 <=i <=n \itypeis\xapply(f, \ *)
(* ldotsne)tau                                  *)
(*                                              *)
(* As is typical for a monomorphic language, each *)
(* polymorphic operation has its own syntactic form and *)
(* its own typing rule. An equality test is well typed *)
(* if it tests two values of the same type. \tyrule Eq \ *)
(* twoquad \itypeise_1tau \itypeise_2tau \itypeis\asteq *)
(* (e_1, e_2)\booltype                          *)
(*                                              *)
(* A [[print]] or [[println]] expression is well typed *)
(* if its subexpression is well typed. \tyrule Println \ *)
(* itypeisetau \itypeis\astprintln(e)\unittype  *)
(*                                              *)
(* Typing judgment and typing rules for definitions *)
(*                                              *)
(* Like the corresponding rules of operational  *)
(* semantics, the typing rule for a definition may *)
(* produce type environments with new bindings. The *)
(* judgment has the form \itoptd -->\stwo\vgamp \fgamp,\ *)
(* notation -->relates type environments before and *)
(* after typing of definition which says that when *)
(* definition d is typed given type environments \vgam *)
(*  and \fgam, the new environments are \vgamp and \ *)
(* fgamp. \jlabeltimpcore.type.def\itoptd -->\stwo\vgamp *)
(* \fgamp                                       *)
(*                                              *)
(* If a variable x has not been bound before, its \xval *)
(* binding requires only that the right-hand side be *)
(* well typed. The newly bound x takes the type of its *)
(* right-hand side. \tyrule NewVal \twoquad \itypeis[\ *)
(* emptyenv] e tau x \notindom \vgam \itopt\xval(x, e) *)
(* -->\stwo\vgam{x |->tau} \fgam If x is already bound, *)
(* the \xval binding acts like a \xset. And just like a *)
(* \xset, the \xval must not change x's type (\cref *)
(* typesys.ex.timpcore-strong-update). \tyrule OldVal \ *)
(* twoquad \itypeis[\emptyenv] e tau \vgam(x) = tau \ *)
(* itopt\xval(x, e) -->\stwo\vgam\fgam          *)
(*                                              *)
(* A top-level expression is checked, but it doesn't *)
(* change the type environments. (In untyped Impcore, *)
(* the value of a top-level expression is bound to *)
(* global variable [[it]]. But in Typed Impcore, the *)
(* type of [[it]] can't be allowed to change, lest the *)
(* type system become unsound. So a top-level expression *)
(* doesn't create a binding.) \tyrule Exp \itypeis[\ *)
(* emptyenv] e tau \itopt\xexp(e) -->\stwo\vgam\fgam *)
(*                                              *)
(* A function definition updates the function   *)
(* environment. The definition gives the type tau_i of *)
(* each formal parameter x_i, and the type tau of the *)
(* result. In an environment where each x_i has type tau *)
(* _i, the function's body e must be well typed and have *)
(* type tau. In that case, function f is added to the *)
(* type environment \fgam with function type \  *)
(* nomathbreak\crossdotsntau-->tau. Because f could be *)
(* called recursively from e, f also goes into the type *)
(* environment used to typecheck e. \tyrule Define \ *)
(* fourline \aretypes\ldotsntau tau_f = \crossdotsntau *)
(* -->tau f \notindom \fgam \itypej \vgam, \fgam{f |-> *)
(* tau_f}, {x_1 |->tau_1, ..., x_n |->tau_n} e tau \ *)
(* itopt\xdefine(f, (<x_1 : tau_1, ..., x_n : tau_n>, e *)
(* : tau)) --> \stwo\vgam\fgam{f |->tau_f} In addition *)
(* to the typing judgment for e, the body of the *)
(* function, this rule also uses well-formedness *)
(* judgments for types tau_1 to tau_n. In general, when *)
(* a type appears in syntax, the rule for that syntax *)
(* may need a premise saying the type is well formed. *)
(* (The result type tau here does not need such a *)
(* premise, because when the judgment form ...\vdashe :  *)
(* tau is derivable, tau is guaranteed to be well *)
(* formed; see \cref                            *)
(* typesys.ex.well-typed-is-well-formed.)       *)
(*                                              *)
(* A function can be redefined, but the redefinition may *)
(* not change its type (\cref                   *)
(* typesys.ex.timpcore-strong-update). \tyrule Redefine *)
(* \threeline \aretypes\ldotsntau \fgam(f) = \crossdotsn *)
(* tau-->tau \itypej \vgam, \fgam{f |->\crossdotsntau--> *)
(* tau}, {x_1 |->tau_1, ..., x_n |->tau_n} e tau \itopt\ *)
(* xdefine(f, (<x_1 : tau_1, ..., x_n : tau_n>, e : tau *)
(* )) --> \stwo\vgam\fgam                       *)
(*                                              *)
(* A type-checking \chaptocsplitinterpreter \   *)
(* maintocsplit\chaptocsplitfor Typed Impcore   *)
(*                                              *)
(* [*] Typed Impcore is interpreted using the techniques *)
(* used to interpret micro-Scheme in \crefmlscheme.chap, *)
(* plus support for types: in addition to abstract *)
(* syntax for expressions and definitions, I define *)
(* abstract syntax for types, which is shown in the code *)
(* chunk [[]]. Because the                      *)
(* type system is so simple, the abstract syntax can *)
(* also serve as the internal representation of types. *)
(*                                              *)
(* Types are checked by new functions [[typeof]] and *)
(* [[typdef]], which are invoked by the read-eval-print *)
(* loop. The type checker I present handles only *)
(* integer, Boolean, and unit types; array types are *)
(* left for the exercises.                      *)
(*                                              *)
(* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ *)
(* \advanceby 0.8pt \newskip\myskip \myskip=6pt *)
(*                                              *)
(*  \addlinespace Concept           Interpreter *)
(*  [0.4pt] Type                                *)
(*     system                                   *)
(*        d       Definition        def, xdef, or [[unit_test]] (pages [->], [->] *)
(*                                  and [->])   *)
(*        e       Expression        \timptypeexp *)
(*      x, f      Name              \mlstypename *)
(*  [\myskip] tau Type              \timptypety *)
(*  \vgam, \rgam  Type environment  \monoty env (\cpageref *)
(*                                  typesys.type.ty,mlscheme.type.env) *)
(*                    Function-type \monofunty env (\cpageref *)
(*      \fgam         environment   typesys.type.funty,mlscheme.type.env) *)
(*                                              *)
(*   [\myskip] \  Typecheck e       \monoboxtypeof(e, \vgam, \fgam, \rgam) = tau, *)
(*  itypeise tau                    and often \monoboxty e = tau \timpfunpage *)
(*                                  typeof      *)
(*  \itoptd -->\  Typecheck d       \monoboxtypdef(d, \vgam, \fgam) = \monobox(\ *)
(*   stwo\vgamp\                    vgam', \fgam', s) \timpfunpagetypdef *)
(*      fgamp                                   *)
(*   [\myskip] x  Definedness       \monofind (x, Gamma) terminates without *)
(*  in dom Gamma                    raising an exception (\cpageref *)
(*                                  mlscheme.fun.find) *)
(*    Gamma(x)    Type lookup       \monofind (x, Gamma) (\cpageref *)
(*                                  mlscheme.fun.find) *)
(*   Gamma{x |->  Binding           \monobind (x, tau, Gamma) (\cpageref *)
(*      tau}                        mlscheme.fun.bind) *)
(*     Gamma{\    Binding           \monobindlist ([\ldotsnx], [\ldotsntau], *)
(*  ldotsmapstonx                   Gamma) (\cpagerefmlscheme.fun.bind) *)
(*      tau}                                    *)
(*    [\myskip]                                 *)
(*                                              *)
(* Correspondence between Typed Impcore's type system *)
(* and code [*]                                 *)
(* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ *)
(*                                              *)
(* Type checking                                *)
(*                                              *)
(* Given an expression e and a collection of type *)
(* environments \xgam, \fgam, and \rgam, calling typeof *)
(* (e, \xgam, \fgam, \rgam) returns a type tau such that *)
(* \itypeise tau. If no such type exists, [[typeof]] *)
(* raises the [[TypeError]] exception (or possibly *)
(* [[NotFound]]). Internal function [[ty]] computes the *)
(* type of e using the environments passed to   *)
(* [[typeof]]. \timpflabeltypeof                *)
(* <boxed values 97>=                           *)
val _ = op typeof  : exp * ty env * funty env * ty env -> ty
val _ = op ty      : exp -> ty
  in  ty e
  end
(* <type checking for \timpcore>=               *)
fun typdef (d, globals, functions) =
    case d
      of (* Each case of [[typdef]] implements one syntactic form *)
         (* of definition d. The first form is a variable *)
         (* definition, which may change a variable's value but *)
         (* not its type. Depending on whether the variable is *)
         (* already defined, there are two rules. \usetyNewVal \ *)
         (* usetyOldVal Which rule applies depends on whether x *)
         (* is already defined. [*]                      *)
         (* <cases for typing definitions in \timpcore>= *)
           VAL (x, e) =>
             if not (isbound (x, globals)) then
               let val tau  = typeof (e, globals, functions, emptyEnv)
               in  (bind (x, tau, globals), functions, typeString tau)
               end
             else
               let val tau' = find (x, globals)
                   val tau  = typeof (e, globals, functions, emptyEnv)
               in  if eqType (tau, tau') then
                     (globals, functions, typeString tau)
                   else

                    (* <raise [[TypeError]] with message about redefinition>= *)
                     raise TypeError ("Global variable " ^ x ^ " of type " ^
                                                               typeString tau' ^
                                      " may not be redefined with type " ^
                                                                 typeString tau)
               end
         (* A top-level expression must have a type, and it *)
         (* leaves the environments unchanged. \usetyExp *)
         (* <cases for typing definitions in \timpcore>= *)
         | EXP e =>
             let val tau = typeof (e, globals, functions, emptyEnv)
             in  (globals, functions, typeString tau)
             end
         (* Like a variable definition, a function definition has *)
         (* two rules, depending on whether the function is *)
         (* already defined. \usetyDefine \usetyRedefine The *)
         (* common parts of these rules are implemented first: *)
         (* build the function type, get the type of the body ( *)
         (* tau), and confirm that tau is equal to the   *)
         (* [[returns]] type in the syntax. Only then does the *)
         (* code check f in dom \fgam and finish accordingly. *)
         (* <cases for typing definitions in \timpcore>= *)
         | DEFINE (f, {returns, formals, body}) =>
             let val (fnames, ftys) = ListPair.unzip formals
                 val def's_type     = FUNTY (ftys, returns)
                 val functions'     = bind (f, def's_type, functions)
                 val formals        = mkEnv (fnames, ftys)
                 val tau            = typeof (body, globals, functions', formals
                                                                               )
             in  if eqType (tau, returns) then
                   if not (isbound (f, functions)) then
                      (globals, functions', funtyString def's_type)
                   else
                     let val env's_type = find (f, functions)
                     in  if eqFunty (env's_type, def's_type) then
                           (globals, functions, funtyString def's_type)
                         else
                           raise TypeError
                             ("Function " ^ f ^ " of type " ^ funtyString
                                                                      env's_type
                              ^ " may not be redefined with type " ^
                              funtyString def's_type)
                     end
                 else
                   raise TypeError ("Body of function has type " ^ typeString
                                                                           tau ^

                                ", which does not match declared result type " ^
                                    "of " ^ typeString returns)
             end
(* Typechecking definitions                     *)
(*                                              *)
(* The typing judgment for a definition d has the form \ *)
(* nomathbreak\itoptd -->\stwo\fgamp\vgamp. This *)
(* judgment is implemented by a static analysis that *)
(* I call typing the definition. Calling \monoboxtypdef *)
(* (d, \vgam, \fgam) returns a triple \monobox(\vgamp, \ *)
(* fgamp, s), where s is a string describing a type. \ *)
(* timpflabeltypdef \nwnarrowboxes              *)
(* <boxed values 99>=                           *)
val _ = op typdef : def * ty env * funty env -> ty env * funty env * string



(*****************************************************************)
(*                                                               *)
(*   LEXICAL ANALYSIS AND PARSING FOR \TIMPCORE, PROVIDING [[FILEXDEFS]] AND [[STRINGSXDEFS]] *)
(*                                                               *)
(*****************************************************************)

(* <lexical analysis and parsing for \timpcore, providing [[filexdefs]] and [[stringsxdefs]]>= *)
(* <lexical analysis for \uscheme\ and related languages>= *)
datatype pretoken = QUOTE
                  | INT     of int
                  | SHARP   of bool
                  | NAME    of string
type token = pretoken plus_brackets
(* <boxed values 23>=                           *)
type pretoken = pretoken
type token = token
(* <lexical analysis for \uscheme\ and related languages>= *)
fun pretokenString (QUOTE)     = "'"
  | pretokenString (INT  n)    = intString n
  | pretokenString (SHARP b)   = if b then "#t" else "#f"
  | pretokenString (NAME x)    = x
val tokenString = plusBracketsString pretokenString
(* For debugging, code in \creflazyparse.chap needs to *)
(* be able to render a [[token]] as a string.   *)
(* <boxed values 24>=                           *)
val _ = op pretokenString : pretoken -> string
val _ = op tokenString    : token    -> string
(* <lexical analysis for \uscheme\ and related languages>= *)
local
  (* <functions used in all lexers>=              *)
  fun noneIfLineEnds chars =
    case streamGet chars
      of NONE => NONE (* end of line *)
       | SOME (#";", cs) => NONE (* comment *)
       | SOME (c, cs) => 
           let val msg = "invalid initial character in `" ^
                         implode (c::listOfStream cs) ^ "'"
           in  SOME (ERROR msg, EOS)
           end
  (* <boxed values 26>=                           *)
  val _ = op noneIfLineEnds : 'a lexer
  (* The [[atom]] function identifies the special literals *)
  (* [[#t]] and [[#f]]; all other atoms are names. *)
  (* <functions used in the lexer for \uscheme>=  *)
  fun atom "#t" = SHARP true
    | atom "#f" = SHARP false
    | atom x    = NAME x
in
  val schemeToken =
    whitespace *>
    bracketLexer   (  QUOTE   <$  eqx #"'" one
                  <|> INT     <$> intToken isDelim
                  <|> (atom o implode) <$> many1 (sat (not o isDelim) one)
                  <|> noneIfLineEnds
                   )
(* <boxed values 25>=                           *)
val _ = op schemeToken : token lexer
val _ = op atom : string -> pretoken
(* [[checkExpectPasses]] runs a                 *)
(* [[check-expect]] test and tells if the test passes. *)
(* If the test does not pass, [[checkExpectPasses]] also *)
(* writes an error message. Error messages are written *)
(* using [[failtest]], which, after writing the error *)
(* message, indicates failure by returning [[false]]. *)

end
(* <parsers for single tokens for \uscheme-like languages>= *)
type 'a parser = (token, 'a) polyparser
val pretoken  = (fn (PRETOKEN t)=> SOME t  | _ => NONE) <$>? token : pretoken
                                                                          parser
val quote     = (fn (QUOTE)     => SOME () | _ => NONE) <$>? pretoken
val int       = (fn (INT   n)   => SOME n  | _ => NONE) <$>? pretoken
val booltok   = (fn (SHARP b)   => SOME b  | _ => NONE) <$>? pretoken
val namelike  = (fn (NAME  n)   => SOME n  | _ => NONE) <$>? pretoken
val namelike  = asAscii namelike
(* Parsers for micro-Scheme                     *)
(*                                              *)
(* A parser consumes a stream of tokens and produces an *)
(* abstract-syntax tree. My parsers begin with code for *)
(* parsing the smallest things and finish with the code *)
(* for parsing the biggest things. I define parsers for *)
(* tokens, literal S-expressions, micro-Scheme  *)
(* expressions, and finally micro-Scheme definitions. *)
(*                                              *)
(* Parsers for single tokens and common idioms  *)
(*                                              *)
(* Usually a parser knows what kind of token it is *)
(* looking for. To make such a parser easier to write, *)
(* I define a special parsing combinator for each kind *)
(* of token. Each one succeeds when given a token of the *)
(* kind it expects; when given any other token, it *)
(* fails.                                       *)
(* <boxed values 27>=                           *)
val _ = op booltok  : bool parser
val _ = op int      : int  parser
val _ = op namelike : name parser
(* [[bindList]] tried to                        *)
(*              extend an environment, but it passed *)
(*              two lists (names and values) of *)
(*              different lengths.              *)
(* RuntimeError    Something else went wrong during *)
(*              evaluation, i.e., during the    *)
(*              execution of [[eval]].          *)
(* \bottomrule                                  *)
(*                                              *)
(* Exceptions defined especially for this interpreter  *)
(* [*]                                          *)
(* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ *)
(*                                              *)
(* Abstract syntax and values                   *)
(*                                              *)
(* An abstract-syntax tree can contain a literal value. *)
(* A value, if it is a closure, can contain an  *)
(* abstract-syntax tree. These two types are therefore *)
(* mutually recursive, so I define them together, using *)
(* [[and]].                                     *)
(*                                              *)
(* These particular types use as complicated a nest of *)
(* definitions as you'll ever see. The keyword  *)
(* [[datatype]] defines a new algebraic datatype; the *)
(* keyword [[withtype]] introduces a new type   *)
(* abbreviation that is mutually recursive with the *)
(* [[datatype]]. The first group of [[and]] keywords *)
(* define additional algebraic datatypes, and the second *)
(* group of [[and]] keywords define additional type *)
(* abbreviations. Everything in the whole nest is *)
(* mutually recursive. [*] [*]                  *)

(* \qbreak                                      *)
(*                                              *)
(* Parsers for single tokens                    *)
(*                                              *)
(* Typed Impcore does need its own list of reserved *)
(* words.                                       *)
(* <parsers for single tokens for \timpcore>=   *)
val reserved = [ "if", "while", "set", "begin", "println", "print", "="
               , "array-at", "array-put", "make-array", "array-size"
               , "val", "define", "use"
               , "check-expect", "check-assert", "check-error"
               , "check-type-error", "check-function-type"
               ]
val name = rejectReserved reserved <$>! namelike
(* <parsers for single tokens for \timpcore>=   *)
val name  = sat (fn n => n <> "->") name
val arrow = (fn (NAME "->") => SOME () | _ => NONE) <$>? pretoken
(* <parsers and parser builders for formal parameters and bindings>= *)
fun formalsOf what name context = 
  nodups ("formal parameter", context) <$>! @@ (bracket (what, many name))

fun bindingsOf what name exp =
  let val binding = bracket (what, pair <$> name <*> exp)
  in  bracket ("(... " ^ what ^ " ...) in bindings", many binding)
  end
(* <parsers and parser builders for formal parameters and bindings>= *)
fun distinctBsIn bindings context =
  let fun check (loc, bs) =
        nodups ("bound name", context) (loc, map fst bs) >>=+ (fn _ => bs)
  in  check <$>! @@ bindings
  end
(* <boxed values 28>=                           *)
val _ = op formalsOf  : string -> name parser -> string -> name list parser
val _ = op bindingsOf : string -> 'x parser -> 'e parser -> ('x * 'e) list
                                                                          parser
(* <boxed values 28>=                           *)
val _ = op distinctBsIn : (name * 'e) list parser -> string -> (name * 'e) list
                                                                          parser
(* <parsers and parser builders for formal parameters and bindings>= *)
fun recordFieldsOf name =
  nodups ("record fields", "record definition") <$>!
                                    @@ (bracket ("(field ...)", many name))
(* <boxed values 30>=                           *)
val _ = op recordFieldsOf : name parser -> name list parser
(* [[funty]] stand for \tau, [[actualtypes]]    *)
(* stand for \ldotsntau, and [[rettype]] stand for alpha *)
(* . The first premise is implemented by a call to *)
(* [[typesof]] and the second by a call to      *)
(* [[freshtyvar]]. The constraint is represented just as *)
(* written in the rule.                         *)

(* <parsers and parser builders for formal parameters and bindings>= *)
fun kw keyword = 
  eqx keyword namelike
fun usageParsers ps = anyParser (map (usageParser kw) ps)
(* To define a parser for the bracketed expressions, *)
(* I deploy the ``usage parser'' described in \cref *)
(* lazyparse.chap. It enables me to define most of the *)
(* parser as a table containing usage strings and *)
(* functions. Function [[kw]] parses only the keyword *)
(* passed as an argument. Using it, function    *)
(* [[usageParsers]] strings together usage parsers. *)
(* <boxed values 32>=                           *)
val _ = op kw : string -> string parser
val _ = op usageParsers : (string * 'a parser) list -> 'a parser
(* <parser builders for typed languages>=       *)
fun typedFormalOf name colon ty =
      bracket ("[x : ty]", pair <$> name <* colon <*> ty)
fun typedFormalsOf name colon ty context = 
  let val formal = typedFormalOf name colon ty
  in  distinctBsIn (bracket("(... [x : ty] ...)", many formal)) context
  end                            
(* <boxed values 115>=                          *)
val _ = op typedFormalsOf : string parser -> 'b parser -> 'a parser  -> string
                                                    -> (string * 'a) list parser
(* <parsers and [[xdef]] streams for \timpcore>= *)
fun exptable exp = usageParsers
  [ ("(if e1 e2 e3)",      curry3 IFX     <$> exp <*> exp <*> exp)
  , ("(while e1 e2)",      curry  WHILEX  <$> exp <*> exp)
  , ("(set x e)",          curry  SET     <$> name <*> exp)
  , ("(begin e ...)",             BEGIN   <$> many exp)
  , ("(println e)",               PRINTLN <$> exp)
  , ("(print e)",                 PRINT   <$> exp)
  , ("(= e1 e2)",          curry  EQ      <$> exp <*> exp)
  , ("(array-at a i)",     curry  AAT     <$> exp <*> exp)
  , ("(array-put a i e)",  curry3 APUT    <$> exp <*> exp <*> exp)
  , ("(make-array n e)",   curry  AMAKE   <$> exp <*> exp)
  , ("(array-size a)",            ASIZE   <$> exp)
  ]
(* <parsers and [[xdef]] streams for \timpcore>= *)
val atomicExp =  VAR     <$> name
             <|> LITERAL <$> NUM <$> int
             <|> booltok <!> "Typed Impcore has no Boolean literals"
             <|> quote   <!> "Typed Impcore has no quoted literals"
(* <parsers and [[xdef]] streams for \timpcore>= *)
fun impcorefun what exp =  name 
                       <|> exp <!> ("only named functions can be " ^ what)
                       <?> "function name"
(* <parsers and [[xdef]] streams for \timpcore>= *)
fun exp tokens = (
     atomicExp
 <|> exptable exp
 <|> leftCurly <!> "curly brackets are not supported"
 <|> left *> right <!> "empty application"
 <|> bracket("function application",
             curry APPLY <$> impcorefun "applied" exp <*> many exp)
) tokens
(* Parsers for expressions                      *)
(*                                              *)
(* <boxed values 113>=                          *)
val _ = op exp      : exp parser
val _ = op exptable : exp parser -> exp parser
(* <parsers and [[xdef]] streams for \timpcore>= *)
fun badTypeName (loc, n) =
      synerrorAt ("Cannot recognize name " ^ n ^ " as a type") loc
fun repeatable_ty tokens = (
      BOOLTY <$ kw "bool"
  <|> UNITTY <$ kw "unit"
  <|> INTTY  <$ kw "int"
  <|> badTypeName <$>! @@ name 
  <|> usageParsers [("(array ty)", ARRAYTY <$> ty)]
  ) tokens
and ty tokens = (repeatable_ty <?> "int, bool, unit, or (array ty)") tokens

val funty = bracket ("function type",
                     curry FUNTY <$> many repeatable_ty <* arrow <*> ty)
(* Parsers for types and definitions            *)
(*                                              *)
(* Typed Impcore has only the three base types, plus *)
(* whatever types are formed using [[array]].   *)
(* <boxed values 114>=                          *)
val _ = op ty    : ty    parser
val _ = op funty : funty parser
(* The [[deftable]] parser parses the true definitions. *)
(* <parsers and [[xdef]] streams for \timpcore>= *)
fun define ty f formals body =
  DEFINE (f, { returns = ty, formals = formals, body = body })
val formals =
      typedFormalsOf name (kw ":") ty "formal parameters in 'define'"
val deftable = usageParsers
  [ ("(define ty f (args) body)",
         define <$> ty <*> name <*> formals <*> exp)
  , ("(val x e)",
         curry VAL <$> name <*> exp)
  ]
(* <parsers and [[xdef]] streams for \timpcore>= *)
val testtable = usageParsers
  [ ("(check-expect e1 e2)", curry CHECK_EXPECT <$> exp <*> exp)
  , ("(check-assert e)",           CHECK_ASSERT <$> exp)
  , ("(check-error e)",            CHECK_ERROR  <$> exp)
  , ("(check-type-error d)",
                CHECK_TYPE_ERROR    <$> (deftable <|> EXP <$> exp))
  , ("(check-function-type f (tau ... -> tau))", 
          curry CHECK_FUNCTION_TYPE <$> impcorefun "checked" exp <*> funty)
  ]
(* Function [[unit_test]] parses the unit tests. *)
(* <boxed values 116>=                          *)
val _ = op testtable : unit_test parser
(* CLOSING IN ON CHECK-PRINT:                   *)

(* And [[xdef]] parses all the extended definitions. *)
(* <parsers and [[xdef]] streams for \timpcore>= *)
val xdeftable = usageParsers
  [ ("(use filename)", USE <$> name)
  (* <rows added to \timpcore\ [[xdeftable]] in exercises>= *)
  (* add syntactic extensions here, each preceded by a comma *) 
  ]

val xdef =  DEF  <$> deftable 
        <|> TEST <$> testtable
        <|>          xdeftable
        <|> badRight "unexpected right bracket"
        <|> DEF <$> EXP <$> exp
        <?> "definition"
(* <parsers and [[xdef]] streams for \timpcore>= *)
val xdefstream = interactiveParsedStream (schemeToken, xdef)
(* <shared definitions of [[filexdefs]] and [[stringsxdefs]]>= *)
fun filexdefs (filename, fd, prompts) =
      xdefstream (filename, filelines fd, prompts)
fun stringsxdefs (name, strings) =
      xdefstream (name, streamOfList strings, noPrompts)
(* <boxed values 80>=                           *)
val _ = op xdefstream   : string * line stream     * prompts -> xdef stream
val _ = op filexdefs    : string * TextIO.instream * prompts -> xdef stream
val _ = op stringsxdefs : string * string list               -> xdef stream



(*****************************************************************)
(*                                                               *)
(*   EVALUATION, TESTING, AND THE READ-EVAL-PRINT LOOP FOR \TIMPCORE *)
(*                                                               *)
(*****************************************************************)

(* <evaluation, testing, and the read-eval-print loop for \timpcore>= *)
(* <definitions of [[eval]] and [[evaldef]] for \timpcore>= *)
val unitVal = NUM 1983
(* <definitions of [[eval]] and [[evaldef]] for \timpcore>= *)
fun projectBool (NUM 0) = false
  | projectBool _       = true
     
fun eval (e, globals, functions, formals) =
  let val go = applyWithLimits id in go end (* OMIT *)
  let val toBool = projectBool
      fun ofBool true    = NUM 1
        | ofBool false   = NUM 0
      fun eq (NUM n1,   NUM n2)   = (n1 = n2)
        | eq (ARRAY a1, ARRAY a2) = (a1 = a2)
        | eq _                    = false
      fun findVar v = find (v, formals)
                      handle NotFound _ => find (v, globals)
      fun ev (LITERAL n)          = n
        | ev (VAR x)              = !(findVar x)
        | ev (SET (x, e))         = let val v = ev e
                                    in  v before findVar x := v
                                    end
        | ev (IFX (cond, t, f))   = if toBool (ev cond) then ev t else ev f
        | ev (WHILEX (cond, exp)) =
            if toBool (ev cond) then
                (ev exp; ev (WHILEX (cond, exp)))
            else
                unitVal
        | ev (BEGIN es) =
            let fun b (e::es, lastval) = b (es, ev e)
                  | b (   [], lastval) = lastval
            in  b (es, unitVal)
            end
        | ev (EQ (e1, e2)) = ofBool (eq (ev e1, ev e2))
        | ev (PRINTLN e)   = (print (valueString (ev e)^"\n"); unitVal)
        | ev (PRINT   e)   = (print (valueString (ev e));      unitVal)
        | ev (APPLY (f, args)) =
            (case find (f, functions)
               of PRIMITIVE p  => p (map ev args)
                | USERDEF func =>
                       (* <apply user-defined function [[func]] to [[args]]>= *)
                                  let val (formals, body) = func
                                      val actuals         = map (ref o ev) args

                              (* <boxed values 111>=                          *)
                                  val _ = op formals : name      list
                                  val _ = op actuals : value ref list

                              (* [[funty]] stand for \tau, [[actualtypes]]    *)

                     (* stand for \ldotsntau, and [[rettype]] stand for alpha *)

                           (* . The first premise is implemented by a call to *)

                              (* [[typesof]] and the second by a call to      *)

                     (* [[freshtyvar]]. The constraint is represented just as *)

                              (* written in the rule.                         *)

                                  in  eval (body, globals, functions, mkEnv (
                                                              formals, actuals))
                                      handle BindListLength => 
                                          raise BugInTypeChecking
                                         "Wrong number of arguments to function"
                                  end)
        (* <more alternatives for [[ev]] for \timpcore>= *)
        | ev (AAT (a, i)) =
            Array.sub (toArray (ev a), toInt (ev i))
        | ev (APUT (e1, e2, e3)) =
            let val (a, i, v) = (ev e1, ev e2, ev e3)
            in  Array.update (toArray a, toInt i, v);
                v
            end
        | ev (AMAKE (len, init)) =
            ARRAY (Array.array (toInt (ev len), ev init))
        | ev (ASIZE a) =
            NUM   (Array.length (toArray (ev a)))
        (* Given [[toArray]] and [[toInt]], the array operations *)
        (* are implemented using the [[Array]] module from ML's *)
        (* Standard Basis Library. The library includes run-time *)
        (* checks for bad subscripts or array sizes; these *)
        (* checks are needed because Typed Impcore's type system *)
        (* is not powerful enough to preclude such errors. *)
        (* <boxed values 101>=                          *)
        val _ = op ev : exp -> value
(* In the evaluator, values of [[unit]] type need a *)
(* representation. And all values of unit type must test *)
(* equal with [[=]], so they must have the same *)
(* representation. Because that representation is the *)
(* result of evaluating a [[WHILE]] loop or an empty *)
(* [[BEGIN]], it is defined here.               *)
(* <boxed values 110>=                          *)
val _ = op ev : exp -> value
(* \qvfilbreak3in The implementation of the evaluator *)
(* uses the same techniques I use to implement  *)
(* micro-Scheme in Chapter [->]. Because of Typed *)
(* Impcore's many environments, Typed Impcore's *)
(* evaluator does more bookkeeping. \timpflabeleval *)
(* <boxed values 110>=                          *)
val _ = op eval : exp * value ref env * func env * value ref env -> value
  in  ev e
  end
(* <definitions of [[eval]] and [[evaldef]] for \timpcore>= *)
fun evaldef (d, globals, functions) =
  case d 
    of VAL (x, e) => (* <evaluate [[e]] and bind the result to [[x]]>= *)
                     let val v = eval (e, globals, functions, emptyEnv)
                     in  (bind (x, ref v, globals), functions, valueString v)
                     end
     | EXP e      => evaldef (VAL ("it", e), globals, functions)
     | DEFINE (f, { body = e, formals = xs, returns = rt }) =>
         (globals, bind (f, USERDEF (map #1 xs, e), functions), f)
(* Evaluating a definition produces two environments, *)
(* plus a string representing the thing defined. \ *)
(* timpflabelevaldef \nwnarrowboxes             *)
(* <boxed values 112>=                          *)
val _ = op evaldef : def * value ref env * func env -> value ref env * func env
                                                                        * string
(* <definitions of [[basis]] and [[processDef]] for \timpcore>= *)
type basis = ty env * funty env * value ref env * func env
fun processDef (d, (tglobals, tfuns, vglobals, vfuns), interactivity) =
  let val (tglobals, tfuns, tystring)  = typdef  (d, tglobals, tfuns)
      val (vglobals, vfuns, valstring) = evaldef (d, vglobals, vfuns)
      val _ = if echoes interactivity then println (valstring ^ " : " ^ tystring
                                                                               )
              else ()
(* For Typed Impcore to work with the reusable  *)
(* read-eval-print loop described in \crefpage  *)
(* (mlinterps.repl, I need to define the type [[basis]] *)
(* and function [[processDef]].                 *)
(*                                              *)
(* The [[processDef]] function for a dynamically typed *)
(* language such as Impcore or micro-Scheme can simply *)
(* evaluate a definition. But the [[processDef]] *)
(* function for a statically typed language such as *)
(* Typed Impcore also needs a typechecking step. *)
(* Function [[processDef]] needs not only the top-level *)
(* type environments \fgam and \vgam but also the *)
(* top-level value and function environments phi and xi. *)
(* These environments are put into a tuple whose type is *)
(* [[basis]]. Of the four environments, the value *)
(* environment xi is the only one that can be mutated *)
(* during evaluation, so it is the only one that has a *)
(* [[ref]] in its type.                         *)
(* <boxed values 104>=                          *)
type basis = basis
val _ = op processDef : def * basis * interactivity -> basis
  in  (tglobals, tfuns, vglobals, vfuns)
  end
fun dump_names (_, _, _, functions) = app (println o fst) functions  (*OMIT*)
(* <shared definition of [[withHandlers]]>=     *)
fun withHandlers f a caught =
  f a
  handle RuntimeError msg   => caught ("Run-time error <at loc>: " ^ msg)
       | NotFound x         => caught ("Name " ^ x ^ " not found <at loc>")
       | Located (loc, exn) =>
           withHandlers (fn _ => raise exn)
                        a
                        (fn s => caught (fillAtLoc (s, loc)))
       (* In addition to [[RuntimeError]], [[NotFound]], and *)
       (* [[Located]], [[withHandlers]] catches many exceptions *)
       (* that are predefined ML's Standard Basis Library. *)
       (* These exceptions signal things that can go wrong when *)
       (* evaluating an expression or reading a file.  *)

(* <other handlers that catch non-fatal exceptions and pass messages to [[caught]]>= *)
       | Div                => caught ("Division by zero <at loc>")
       | Overflow           => caught ("Arithmetic overflow <at loc>")
       | Subscript          => caught ("Array index out of bounds <at loc>")
       | Size               => caught (
                                "Array length too large (or negative) <at loc>")
       | IO.Io { name, ...} => caught ("I/O error <at loc>: " ^ name)
       (* These exception handlers are used in all the *)
       (* bridge-language interpreters.                *)

       (* Because [[badParameter]] is called only when the code *)
       (* fails to typecheck, it doesn't need for a base case *)
       (* in which both lists are empty.               *)
       (*                                              *)
       (* Function [[processDef]] is used in the       *)
       (* read-eval-print loop that is defined in \crefpage *)
       (* (mlinterps.repl. The code for the loop can be used *)
       (* unchanged except for one addition: Typed Impcore *)
       (* needs handlers for the new exceptions introduced in \ *)
       (* creftypesys.chap ([[TypeError]] and          *)
       (* [[BugInTypeChecking]]). [[TypeError]] is raised not *)
       (* at parsing time, and not at evaluation time, but at *)
       (* typechecking time (by [[typdef]]).           *)
       (* [[BugInTypeChecking]] should never be raised. *)

(* <other handlers that catch non-fatal exceptions and pass messages to [[caught]] ((type-checking))>= *)
       | TypeError         msg => caught ("type error <at loc>: " ^ msg)
       | BugInTypeChecking msg => caught ("bug in type checking: " ^ msg)
(* <shared unit-testing utilities>=             *)
fun failtest strings = 
  (app eprint strings; eprint "\n"; false)
(* <boxed values 60>=                           *)
val _ = op failtest : string list -> bool
(* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ *)
(*                                              *)
(*  {combinators} \theaderUnit-testing functions *)
(*  provided by each language \combinatoroutcomeexp *)
(*  -> value error \combinatortyexp -> ty error \ *)
(*  combinatortestEqualsvalue * value -> bool \ *)
(*  combinatorasSyntacticValueexp -> value option \ *)
(*  combinatorvalueStringvalue -> string \combinator *)
(*  expStringexp -> string \combinator          *)
(*  testIsGoodunit_test list * basis -> bool \theader *)
(*  Shared functions for unit testing \combinator *)
(*  whatWasExpectedexp * value error -> string \ *)
(*  combinatorcheckExpectPassesexp * exp -> bool \ *)
(*  combinatorcheckErrorPassesexp -> bool \combinator *)
(*  numberOfGoodTestsunit_test list * basis -> int \ *)
(*  combinatorprocessTestsunit_test list * basis -> *)
(*  unit {combinators}                          *)
(*                                              *)
(* Unit-testing functions                       *)
(* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ *)
(*                                              *)
(* In each bridge language, test results are reported *)
(* the same way. The report's format is stolen from the *)
(* DrRacket programming environment. If there are no *)
(* tests, there is no report.                   *)
(* <shared unit-testing utilities>=             *)
fun reportTestResultsOf what (npassed, nthings) =
  case (npassed, nthings)
    of (_, 0) => ()  (* no report *)
     | (0, 1) => println ("The only " ^ what ^ " failed.")
     | (1, 1) => println ("The only " ^ what ^ " passed.")
     | (0, 2) => println ("Both " ^ what ^ "s failed.")
     | (1, 2) => println ("One of two " ^ what ^ "s passed.")
     | (2, 2) => println ("Both " ^ what ^ "s passed.")
     | _ => if npassed = nthings then
              app print ["All ", intString nthings, " " ^ what ^ "s passed.\n"]
            else if npassed = 0 then
              app print ["All ", intString nthings, " " ^ what ^ "s failed.\n"]
            else
              app print [intString npassed, " of ", intString nthings,
                          " " ^ what ^ "s passed.\n"]
val reportTestResults = reportTestResultsOf "test"
(* <definition of [[testIsGood]] for \timpcore>= *)
fun testIsGood (test, (tglobals, tfuns, vglobals, vfuns)) =
  let fun ty e = typeof (e, tglobals, tfuns, emptyEnv)
                 handle NotFound x =>
                   raise TypeError ("name " ^ x ^ " is not defined")
      fun deftystring d =
        let val (_, _, t) = typdef (d, tglobals, tfuns)
        in  t
        end handle NotFound x =>
              raise TypeError ("name " ^ x ^ " is not defined")

    (* <shared [[check{Expect,Assert,Error,Type}Checks]], which call [[ty]]>= *)
      fun checkExpectChecks (e1, e2) = 
        let val tau1 = ty e1
            val tau2 = ty e2
        in  if eqType (tau1, tau2) then
              true
            else
              raise TypeError ("Expressions have types " ^ typeString tau1 ^
                                  " and " ^ typeString tau2)
        end handle TypeError msg =>
        failtest ["In (check-expect ", expString e1, " ", expString e2, "), ",
                                                                            msg]

    (* <shared [[check{Expect,Assert,Error,Type}Checks]], which call [[ty]]>= *)
      fun checkOneExpChecks inWhat e =
        let val tau1 = ty e
        in  true
        end handle TypeError msg =>
        failtest ["In (", inWhat, " ", expString e, "), ", msg]
      val checkAssertChecks = checkOneExpChecks "check-assert"
      val checkErrorChecks  = checkOneExpChecks "check-error"
      fun checks (CHECK_EXPECT (e1, e2)) = checkExpectChecks (e1, e2)
        | checks (CHECK_ASSERT e)        = checkAssertChecks e
        | checks (CHECK_ERROR e)         = checkErrorChecks e
        | checks (CHECK_TYPE_ERROR d)    = true
        | checks (CHECK_FUNCTION_TYPE (f, fty)) = true

      fun outcome e =
        withHandlers (fn () => OK (eval (e, vglobals, vfuns, emptyEnv)))
                     ()
                     (ERROR o stripAtLoc)
      (* <[[asSyntacticValue]] for \uscheme, \timpcore, \tuscheme, and \nml>= *)
      fun asSyntacticValue (LITERAL v) = SOME v
        | asSyntacticValue _           = NONE
      (* <boxed values 22>=                           *)
      val _ = op asSyntacticValue : exp -> value option

    (* <shared [[check{Expect,Assert,Error}Passes]], which call [[outcome]]>= *)
      (* <shared [[whatWasExpected]]>=                *)
      fun whatWasExpected (e, outcome) =
        case asSyntacticValue e
          of SOME v => valueString v
           | NONE =>
               case outcome
                 of OK v => valueString v ^ " (from evaluating " ^ expString e ^
                                                                             ")"
                  | ERROR _ =>  "the result of evaluating " ^ expString e
      (* These functions are used in parsing and elsewhere. *)
      (*                                              *)
      (* Unit testing                                 *)
      (*                                              *)
      (* When running a unit test, each interpreter has to *)
      (* account for the possibility that evaluating an *)
      (* expression causes a run-time error. Just as in *)
      (* Chapters [->] and [->], such an error shouldn't *)
      (* result in an error message; it should just cause the *)
      (* test to fail. (Or if the test expects an error, it *)
      (* should cause the test to succeed.) To manage errors *)
      (* in C, each interpreter had to fool around with *)
      (* [[set_error_mode]]. In ML, things are simpler: the *)
      (* result of an evaluation is converted either to [[OK]] *)
      (*  v, where v is a value, or to [[ERROR]] m, where m is *)
      (* an error message, as described above. To use this *)
      (* representation, I define some utility functions. *)
      (*                                              *)
      (* When a [[check-expect]] fails, function      *)
      (* [[whatWasExpected]] reports what was expected. If the *)
      (* thing expected was a syntactic value,        *)
      (* [[whatWasExpected]] shows just the value. Otherwise *)
      (* it shows the syntax, plus whatever the syntax *)
      (* evaluated to. The definition of [[asSyntacticValue]] *)
      (* is language-dependent.                       *)
      (* <boxed values 56>=                           *)
      val _ = op whatWasExpected  : exp * value error -> string
      val _ = op asSyntacticValue : exp -> value option
      (* <shared [[checkExpectPassesWith]], which calls [[outcome]]>= *)
      val cxfailed = "check-expect failed: "
      fun checkExpectPassesWith equals (checkx, expectx) =
        case (outcome checkx, outcome expectx)
          of (OK check, OK expect) => 
               equals (check, expect) orelse
               failtest [cxfailed, " expected ", expString checkx,
                         " to evaluate to ", whatWasExpected (expectx, OK expect
                                                                              ),
                         ", but it's ", valueString check, "."]
           | (ERROR msg, tried) =>
               failtest [cxfailed, " expected ", expString checkx,
                         " to evaluate to ", whatWasExpected (expectx, tried),
                         ", but evaluating ", expString checkx,
                         " caused this error: ", msg]
           | (_, ERROR msg) =>
               failtest [cxfailed, " expected ", expString checkx,
                         " to evaluate to ", whatWasExpected (expectx, ERROR msg
                                                                              ),
                         ", but evaluating ", expString expectx,
                         " caused this error: ", msg]
      (* \qbreak Function [[checkExpectPassesWith]] runs a *)
      (* [[check-expect]] test and uses the given [[equals]] *)
      (* to tell if the test passes. If the test does not *)
      (* pass, [[checkExpectPasses]] also writes an error *)
      (* message. Error messages are written using    *)
      (* [[failtest]], which, after writing the error message, *)
      (* indicates failure by returning [[false]].    *)
      (* <boxed values 57>=                           *)
      val _ = op checkExpectPassesWith : (value * value -> bool) -> exp * exp ->
                                                                            bool
      val _ = op outcome  : exp -> value error
      val _ = op failtest : string list -> bool

(* <shared [[checkAssertPasses]] and [[checkErrorPasses]], which call [[outcome]]>= *)
      val cafailed = "check-assert failed: "
      fun checkAssertPasses checkx =
            case outcome checkx
              of OK check =>
                   projectBool check orelse
                   failtest [cafailed, " expected assertion ", expString checkx,
                             " to hold, but it doesn't"]
               | ERROR msg =>
                   failtest [cafailed, " expected assertion ", expString checkx,
                             " to hold, but evaluating it caused this error: ",
                                                                            msg]
      (* \qtrim1 Function [[checkAssertPasses]] does the *)
      (* analogous job for [[check-assert]].          *)
      (* <boxed values 58>=                           *)
      val _ = op checkAssertPasses : exp -> bool

(* <shared [[checkAssertPasses]] and [[checkErrorPasses]], which call [[outcome]]>= *)
      val cefailed = "check-error failed: "
      fun checkErrorPasses checkx =
            case outcome checkx
              of ERROR _ => true
               | OK check =>
                   failtest [cefailed, " expected evaluating ", expString checkx
                                                                               ,
                             " to cause an error, but evaluation produced ",
                             valueString check]
      (* Function [[checkErrorPasses]] does the analogous job *)
      (* for [[check-error]].                         *)
      (* <boxed values 59>=                           *)
      val _ = op checkErrorPasses : exp -> bool
      fun checkExpectPasses (cx, ex) = checkExpectPassesWith testEquals (cx, ex)
      (* \qvfilbreak1in                               *)
      (*                                              *)

(* <shared [[checkTypePasses]] and [[checkTypeErrorPasses]], which call [[ty]]>= *)
      fun checkTypePasses (e, tau) =
        let val tau' = ty e
        in  if eqType (tau, tau') then
              true
            else
              failtest ["check-type failed: expected ", expString e,
                        " to have type ", typeString tau,
                        ", but it has type ", typeString tau']
        end handle TypeError msg =>
            failtest ["In (check-type ", expString e,
                      " " ^ typeString tau, "), ", msg]

(* <shared [[checkTypePasses]] and [[checkTypeErrorPasses]], which call [[ty]]>= *)
      fun checkTypeErrorPasses (EXP e) =
            (let val tau = ty e
             in  failtest ["check-type-error failed: expected ", expString e,
                       " not to have a type, but it has type ", typeString tau]
             end handle TypeError msg => true
                      | Located (_, TypeError _) => true)
        | checkTypeErrorPasses d =
            (let val t = deftystring d
             in  failtest ["check-type-error failed: expected ", defString d,

                         " to cause a type error, but it successfully defined ",
                           defName d, " : ", t
                          ] 
             end handle TypeError msg => true
                      | Located (_, TypeError _) => true)
      (* <definition of [[checkFunctionTypePasses]]>= *)
      fun checkFunctionTypePasses (f, tau as FUNTY (args, result)) =
        let val tau' as FUNTY (args', result') =
                  find (f, tfuns)
                  handle NotFound f =>
                    raise TypeError ("Function " ^ f ^ " is not defined")
        in  if eqTypes (args, args') andalso eqType (result, result') then
              true
            else
              failtest ["check-function-type failed: expected ", f,
              	  " to have type ", funtyString tau,
                        ", but it has type ", funtyString tau']
        end handle TypeError msg =>
              failtest ["In (check-function-type ", f,
                        " " ^ funtyString tau, "), ", msg]
      fun passes (CHECK_EXPECT (c, e))          = checkExpectPasses (c, e)
        | passes (CHECK_ASSERT c)               = checkAssertPasses c
        | passes (CHECK_ERROR c)                = checkErrorPasses c
        | passes (CHECK_FUNCTION_TYPE (f, fty)) = checkFunctionTypePasses (f,
                                                                            fty)
        | passes (CHECK_TYPE_ERROR c)           = checkTypeErrorPasses c

  in  checks test andalso passes test
  end
(* <shared definition of [[processTests]]>=     *)
fun processTests (tests, rho) =
      reportTestResults (numberOfGoodTests (tests, rho), length tests)
and numberOfGoodTests (tests, rho) =
      let val testIsGood = fn args => (resetComputationLimits (); testIsGood
                                                               args) in (*OMIT*)
      foldr (fn (t, n) => if testIsGood (t, rho) then n + 1 else n) 0 tests
      end
                                                                                
                                                                        (*OMIT*)
(* \qbreak Function [[processTests]] is shared among all *)
(* bridge languages. For each test, it calls the *)
(* language-dependent [[testIsGood]], adds up the number *)
(* of good tests, and reports the result. [*]   *)
(* <boxed values 61>=                           *)
val _ = op processTests : unit_test list * basis -> unit
(* <shared read-eval-print loop>=               *)
fun readEvalPrintWith errmsg (xdefs, basis, interactivity) =
  let val unitTests = ref []

(* <definition of [[processXDef]], which can modify [[unitTests]] and call [[errmsg]]>= *)
      fun processXDef (xd, basis) =
        let (* <definition of [[useFile]], to read from a file>= *)
            fun useFile filename =
              let val fd = TextIO.openIn filename
                  val (_, printing) = interactivity
                  val inter' = (NOT_PROMPTING, printing)
              in  readEvalPrintWith errmsg (filexdefs (filename, fd, noPrompts),
                                                                  basis, inter')
                  before TextIO.closeIn fd
              end
            fun try (USE filename) = useFile filename
              | try (TEST t)       = (unitTests := t :: !unitTests; basis)
              | try (DEF def)      = processDef (def, basis, interactivity)
              | try (DEFS ds)      = foldl processXDef basis (map DEF ds)
                                                                        (*OMIT*)
            fun caught msg = (errmsg (stripAtLoc msg); basis)
            val () = resetComputationLimits ()     (* OMIT *)
        in  withHandlers try xd caught
        end 
      (* The extended-definition forms [[USE]] and [[TEST]] *)
      (* are implemented in exactly the same way for every *)
      (* language: internal function [[try]] passes each *)
      (* [[USE]] to [[useFile]], and it adds each [[TEST]] to *)
      (* the mutable list [[unitTests]]—just as in the C code *)
      (* in \crefpage(impcore.readevalprint. Function [[try]] *)
      (* passes each true definition [[DEF]] to function *)
      (* [[processDef]], which does the language-dependent *)
      (* work.                                        *)
      (* <boxed values 88>=                           *)
      val _ = op errmsg     : string -> unit
      val _ = op processDef : def * basis * interactivity -> basis
      val basis = streamFold processXDef basis xdefs
      val _     = processTests (!unitTests, basis)
(* Function [[testIsGood]], which can be shared among *)
(* languages that share the same definition of  *)
(* [[unit_test]], says whether a test passes (or in a *)
(* typed language, whether the test is well-typed and *)
(* passes). Function [[testIsGood]] has a slightly *)
(* different interface from the corresponding C function *)
(* [[test_result]]. The reasons are discussed in \cref *)
(* mlschemea.chap on \cpagerefmlschemea.testIsGood. *)
(* These pieces can be used to define a single version *)
(* of [[processTests]] (\crefpage               *)
(* ,mlinterps.processTests) and a single read-eval-print *)
(* loop, each of which is shared among many bridge *)
(* languages. The pieces are organized as follows: \ *)
(* mdbusemlinterpsprocessTests                  *)
(* <boxed values 87>=                           *)
type basis = basis
val _ = op processDef   : def * basis * interactivity -> basis
val _ = op testIsGood   : unit_test      * basis -> bool
val _ = op processTests : unit_test list * basis -> unit
(* Given [[processDef]] and [[testIsGood]], function *)
(* [[readEvalPrintWith]] processes a stream of extended *)
(* definitions. As in the C version, a stream is created *)
(* using [[filexdefs]] or [[stringsxdefs]].     *)
(*                                              *)
(* Function [[readEvalPrintWith]] has a type that *)
(* resembles the type of the C function         *)
(* [[readevalprint]], but the ML version takes an extra *)
(* parameter [[errmsg]]. Using this parameter, I issue a *)
(* special error message when there's a problem in the *)
(* initial basis (see function [[predefinedError]] on \ *)
(* cpagerefmlinterps.predefinedError). \mdbuse  *)
(* mlinterpspredefinedError The special error message *)
(* helps with some of the exercises in \cref    *)
(* typesys.chap,ml.chap, where if something goes wrong *)
(* with the implementation of types, an interpreter *)
(* could fail while trying to read its initial basis. *)
(* (Failure while reading the basis can manifest in *)
(* mystifying ways; the special message demystifies the *)
(* failure.) \mlsflabelreadEvalPrintWith [*]    *)
(* <boxed values 87>=                           *)
val _ = op readEvalPrintWith : (string -> unit) ->                     xdef
                                         stream * basis * interactivity -> basis
val _ = op processXDef       : xdef * basis -> basis
(* The [[Located]] exception is raised by function *)
(* [[atLoc]]. Calling \monoboxatLoc f x applies [[f]] *)
(* to [[x]] within the scope of handlers that convert *)
(* recognized exceptions to the [[Located]] exception: *)

  in  basis
  end



(*****************************************************************)
(*                                                               *)
(*   IMPLEMENTATIONS OF \TIMPCORE\ PRIMITIVES AND DEFINITION OF [[INITIALBASIS]] *)
(*                                                               *)
(*****************************************************************)

(* <implementations of \timpcore\ primitives and definition of [[initialBasis]]>= *)
(* <functions for building primitives when types are checked>= *)
fun binaryOp f = (fn [a, b] => f (a, b) | _ => raise BugInTypeChecking "arity 2"
                                                                               )
fun unaryOp  f = (fn [a]    => f a      | _ => raise BugInTypeChecking "arity 1"
                                                                               )
(* Primitive functions, predefined functions, and the *)
(* initial basis                                *)
(*                                              *)
(* Code in this section defines Typed Impcore's *)
(* primitive functions and builds its initial basis. As *)
(* in Chapter [->], all primitives are either binary or *)
(* unary operators. But the code below should not reuse *)
(* functions [[unaryOp]] and [[binaryOp]] from \cref *)
(* mlscheme.chap, because when a primitive is called *)
(* with the wrong number of arguments, those versions *)
(* raise the [[RuntimeError]] exception. In a typed *)
(* language, it should not be possible to call a *)
(* primitive with the wrong number of arguments. If it *)
(* happens anyway, these versions of [[unaryOp]] and *)
(* [[binaryOp]] raise [[BugInTypeChecking]].    *)
(* <boxed values 106>=                          *)
val _ = op unaryOp  : (value         -> value) -> (value list -> value)
val _ = op binaryOp : (value * value -> value) -> (value list -> value)
(* <functions for building primitives when types are checked>= *)
fun arithOp f =
      binaryOp (fn (NUM n1, NUM n2) => NUM (f (n1, n2)) 
                 | _ => raise BugInTypeChecking "arithmetic on non-numbers")
(* Arithmetic primitives expect and return integers. *)
(* <boxed values 107>=                          *)
val _ = op arithOp : (int * int -> int) -> (value list -> value)
(* [[funty]] stand for \tau, [[actualtypes]]    *)
(* stand for \ldotsntau, and [[rettype]] stand for alpha *)
(* . The first premise is implemented by a call to *)
(* [[typesof]] and the second by a call to      *)
(* [[freshtyvar]]. The constraint is represented just as *)
(* written in the rule.                         *)

(* <utilities used to make \timpcore\ primitives>= *)
val arithtype = FUNTY ([INTTY, INTTY], INTTY)
(* <boxed values 108>=                          *)
val _ = op arithtype : funty
(* <utilities used to make \timpcore\ primitives>= *)
fun embedBool  b = NUM (if b then 1 else 0)
fun comparison f = binaryOp (embedBool o f)
fun intcompare f = 
      comparison (fn (NUM n1, NUM n2) => f (n1, n2)
                   | _ => raise BugInTypeChecking "comparing non-numbers")
val comptype = FUNTY ([INTTY, INTTY], BOOLTY)
(* Comparisons take two arguments. Most comparisons *)
(* (except for equality) apply only to integers. *)
(* <boxed values 109>=                          *)
val _ = op comparison : (value * value -> bool) -> (value list -> value)
val _ = op intcompare : (int   * int   -> bool) -> (value list -> value)
val _ = op comptype   : funty
val primitiveBasis : basis =
  let fun addPrim ((name, prim, funty), (tfuns, vfuns)) = 
        ( bind (name, funty, tfuns)
        , bind (name, PRIMITIVE prim, vfuns)
        )
      val (tfuns, vfuns)  = foldl addPrim (emptyEnv, emptyEnv)
                            ((* <primitive functions for \timpcore\ [[::]]>= *)
                             ("+", arithOp op +,   arithtype) :: 
                             ("-", arithOp op -,   arithtype) :: 
                             ("*", arithOp op *,   arithtype) :: 
                             ("/", arithOp op div, arithtype) ::
                             (* <primitive functions for \timpcore\ [[::]]>= *)
                             ("<", intcompare op <, comptype) :: 
                             (">", intcompare op >, comptype) ::

                           (* \qbreak Typed Impcore also has a primitive that *)

                       (* prints Unicode. (Unlike [[print]], [[printu]] works *)

                     (* only on integer arguments, so unlike [[print]] it can *)

                      (* be implemented as a primitive function rather than a *)
                             (* syntactic form.)                             *)
                             (* <primitive functions for \timpcore\ [[::]]>= *)
                             ("printu", unaryOp (fn (NUM n) => (printUTF8 n;
                                                                        unitVal)
                                                  | _ => raise BugInTypeChecking
                                                        "printu of non-number"),
                                           FUNTY ([INTTY], UNITTY)) :: nil)
  in  (emptyEnv, tfuns, emptyEnv, vfuns)
  end

val predefs = 
               [ ";  Predefined functions \\chaptocsplitof Typed Impcore "
               , ";                                               "
               , ";  The predefined functions of Typed Impcore do the same "
               , ";  work at run time as their counterparts in Chapter  "
               , ";  [->], but \\qbreak because they include explicit types "
               , ";  for arguments and results, their definitions look "
               , ";  different. And because Typed Impcore has no Boolean "
               , ";  literals, falsehood is written as \\monobox(= 1 0), "
               , ";  and truth as \\monobox(= 0 0). [*]            "
               , ";  <predefined {\\timpcore} functions>=          "
               , "(define bool and ([b : bool] [c : bool]) (if b c b))"
               , "(define bool or  ([b : bool] [c : bool]) (if b b c))"
               ,
              "(define bool not ([b : bool])            (if b (= 1 0) (= 0 0)))"
               , ";  The comparison functions accept integers and return "
               , ";  Booleans.                                    "
               , ";  <predefined {\\timpcore} functions>=          "
               , "(define bool <= ([m : int] [n : int]) (not (> m n)))"
               , "(define bool >= ([m : int] [n : int]) (not (< m n)))"
               , "(define bool != ([m : int] [n : int]) (not (= m n)))"
               , ";  Like Impcore, Typed Impcore predefines only about "
               , ";  half a dozen functions. Most are defined in \\cref "
               , ";  typesys.chap, but modulus and negation are defined "
               , ";  here.                                        "
               , ";  <predefined {\\timpcore} functions>=          "
               , "(define int mod ([m : int] [n : int]) (- m (* n (/ m n))))"
               , "(define int negated ([n : int]) (- 0 n))"
                ]

val initialBasis =
  let val xdefs = stringsxdefs ("predefined functions", predefs)
  in  readEvalPrintWith
        predefinedFunctionError
        (xdefs, primitiveBasis, noninteractive)
  end


(*****************************************************************)
(*                                                               *)
(*   FUNCTION [[RUNSTREAM]], WHICH EVALUATES INPUT GIVEN [[INITIALBASIS]] *)
(*                                                               *)
(*****************************************************************)

(* <function [[runStream]], which evaluates input given [[initialBasis]]>= *)
fun runStream inputName input interactivity basis = 
  let val _ = setup_error_format interactivity
      val prompts = if prompts interactivity then stdPrompts else noPrompts
      val xdefs = filexdefs (inputName, input, prompts)
  in  readEvalPrintWith eprintln (xdefs, basis, interactivity)
  end 
(* A last word about function [[readEvalPrintWith]]: you *)
(* might be wondering, ``where does it read, evaluate, *)
(* and print?'' It has helpers for that: reading is a *)
(* side effect of [[streamGet]], which is called by *)
(* [[streamFold]], and evaluating and printing are done *)
(* by [[processDef]]. But the function is called *)
(* [[readEvalPrintWith]] because when you want reading, *)
(* evaluating, and printing to happen, you call \monobox *)
(* readEvalPrintWith eprintln, passing your extended *)
(* definitions and your environments.           *)
(*                                              *)
(* Handling exceptions                          *)
(*                                              *)
(* When an exception is raised, a bridge-language *)
(* interpreter must ``catch'' or ``handle'' it. *)
(* An exception is caught using a syntactic form written *)
(* with the keyword [[handle]]. (This form resembles a *)
(* combination of a [[case]] expression with the *)
(* [[try-catch]] form from \crefschemes.chap.) Within *)
(* the [[handle]], every exception that the interpreter *)
(* recognizes is mapped to an error message tailored for *)
(* that exception. To be sure that every exception is *)
(* responded to in the same way, no matter where it is *)
(* handled, I write just a single [[handle]] form, and I *)
(* deploy it in a higher-order, continuation-passing *)
(* function: [[withHandlers]].                  *)
(*                                              *)
(* In normal execution, calling \monoboxwithHandlers f a *)
(* caught applies function [[f]] to argument [[a]] and *)
(* returns the result. But when the application f a *)
(* raises an exception, [[withHandlers]] uses [[handle]] *)
(* to recover from the exception and to pass an error *)
(* message to [[caught]], which acts as a failure *)
(* continuation (\crefpage,scheme.cps). Each error *)
(* message contains the string [["<at loc>"]], which can *)
(* be removed (by [[stripAtLoc]]) or can be filled in *)
(* with an appropriate source-code location (by  *)
(* [[fillAtLoc]]).                              *)
(*                                              *)
(* The most important exceptions are [[NotFound]], *)
(* [[RuntimeError]], and [[Located]]. Exception *)
(* [[NotFound]] is defined in \crefmlscheme.chap; the *)
(* others are defined in this appendix. Exceptions *)
(* [[NotFound]] and [[RuntimeError]] signal problems *)
(* with an environment or with evaluation, respectively. *)
(* Exception [[Located]] wraps another exception [[exn]] *)
(* in a source-code location. When [[Located]] is *)
(* caught, [[withHandlers]] calls itself recursively *)
(* with a function that ``re-raises'' exception [[exn]] *)
(* and with a failure continuation that fills in the *)
(* source location in [[exn]]'s error message.  *)
(* <boxed values 89>=                           *)
val _ = op withHandlers : ('a -> 'b) -> 'a -> (string -> 'b) -> 'b
(* A bridge-language interpreter can be run on standard *)
(* input or on a named file. Either one can be converted *)
(* to a stream, so the code that runs an interpreter is *)
(* defined on a stream, by function [[runStream]]. This *)
(* runs the code found in a given, named input, using a *)
(* given interactivity mode. The interactivity mode *)
(* determines both the error format and the prompts. *)
(* Function [[runStream]] then starts the       *)
(* read-eval-print loop, using the initial basis. [*] \ *)
(* nwnarrowboxes                                *)
(* <boxed values 89>=                           *)
val _ = op runStream : string -> TextIO.instream -> interactivity -> basis ->
                                                                           basis


(*****************************************************************)
(*                                                               *)
(*   LOOK AT COMMAND-LINE ARGUMENTS, THEN RUN                    *)
(*                                                               *)
(*****************************************************************)

(* <look at command-line arguments, then run>=  *)
fun runPathWith interactivity ("-", basis) =
      runStream "standard input" TextIO.stdIn interactivity basis
  | runPathWith interactivity (path, basis) =
      let val fd = TextIO.openIn path
      in  runStream path fd interactivity basis
          before TextIO.closeIn fd
      end 
(* <boxed values 90>=                           *)
val _ = op runPathWith : interactivity -> (string * basis -> basis)
(* <look at command-line arguments, then run>=  *)
val usage = ref (fn () => ())
(* If an interpreter doesn't recognize a command-line *)
(* option, it can print a usage message. A usage-message *)
(* function needs to know the available options, but *)
(* each available option is associated with a function *)
(* that performs an action, and if something goes wrong, *)
(* the action function might need to call the usage *)
(* function. I resolve this mutual recursion by first *)
(* allocating a mutual cell to hold the usage function, *)
(* then updating it later. This is also how [[letrec]] *)
(* is implemented in micro-Scheme.              *)
(* <boxed values 91>=                           *)
val _ = op usage : (unit -> unit) ref
(* \qbreak To represent actions that might be called for *)
(* by command-line options, I define type [[action]]. *)
(* <look at command-line arguments, then run>=  *)
datatype action
  = RUN_WITH of interactivity  (* call runPathWith on remaining arguments *)
  | DUMP     of unit -> unit   (* dump information *)
  | FAIL     of string         (* signal a bad command line *)
  | DEFAULT                    (* no command-line options were given *)
(* The default action is to run the interpreter in its *)
(* most interactive mode.                       *)
(* <look at command-line arguments, then run>=  *)
val default_action = RUN_WITH (PROMPTING, ECHOING)
(* <look at command-line arguments, then run>=  *)
fun perform (RUN_WITH interactivity, []) =
      perform (RUN_WITH interactivity, ["-"])
  | perform (RUN_WITH interactivity, args) =
      ignore (foldl (runPathWith interactivity) initialBasis args)
  | perform (DUMP go, [])     = go ()
  | perform (DUMP go, _ :: _) = perform (FAIL "Dump options take no files", [])
  | perform (FAIL msg, _)     = (eprintln msg; !usage())
  | perform (DEFAULT, args)   = perform (default_action, args)
(* Now micro-Scheme primitives like [[+]] and [[*]] can *)
(* be defined by applying first [[arithOp]] and then *)
(* [[inExp]] to their ML counterparts.          *)
(*                                              *)
(* The micro-Scheme primitives are organized into a list *)
(* of (name, function) pairs, in Noweb code chunk *)
(* [[]].                                        *)
(* Each primitive on the list has type \monoboxvalue *)
(* list -> value. In \chunkrefmlscheme.inExp-applied, *)
(* each primitive is passed to [[inExp]], and the *)
(* results are used build micro-Scheme's initial *)
(* environment. [Actually, the list contains all the *)
(* primitives except one: the [[error]] primitive, which *)
(* must not be wrapped in [[inExp]].] The list of *)
(* primitives begins with these four elements:  *)
(* <boxed values 92>=                           *)
val _ = op perform: action * string list -> unit
(* <look at command-line arguments, then run>=  *)
fun merge (_, a as FAIL _) = a
  | merge (a as FAIL _, _) = a
  | merge (DEFAULT, a) = a
  | merge (_, DEFAULT) = raise InternalError "DEFAULT on the right in MERGE"
  | merge (RUN_WITH _, right as RUN_WITH _) = right
  | merge (DUMP f, DUMP g) = DUMP (g o f)
  | merge (_, r) = FAIL "Interpret or dump, but don't try to do both"
(* <boxed values 93>=                           *)
val _ = op merge: action * action -> action
(* <look at command-line arguments, then run>=  *)
val actions =
  [ ("",    RUN_WITH (PROMPTING,     ECHOING))
  , ("-q",  RUN_WITH (NOT_PROMPTING, ECHOING))
  , ("-qq", RUN_WITH (NOT_PROMPTING, NOT_ECHOING))
  , ("-names",      DUMP (fn () => dump_names initialBasis))
  , ("-primitives", DUMP (fn () => dump_names primitiveBasis))
  , ("-help",       DUMP (fn () => !usage ()))
  ]
                                                          (*OMIT*)
val unusedActions =  (* reveals answers to homeworks *)   (*OMIT*)
  [ ("-predef",     DUMP (fn () => app println predefs))  (*OMIT*)
  ]                                                       (*OMIT*)
(* Each possible command-line option is associated with *)
(* an action. Options [[-q]] and [[-qq]] suppress *)
(* prompts and echos. Options [[-names]] and    *)
(* [[-primitives]] dump information found in the initial *)
(* basis.                                       *)
(* <boxed values 94>=                           *)
val _ = op actions : (string * action) list
(* The [[xdeftable]] is shared with the Impcore parser. *)
(* Function [[reduce_to_xdef]] is almost shareable as *)
(* well, but not quite---the abstract syntax of *)
(* [[DEFINE]] is different.                     *)

(* \qbreak Now that the available command-line options *)
(* are known, I can define a usage function. Function *)
(* [[CommandLine.name]] returns the name by which the *)
(* interpreter was invoked.                     *)
(* <look at command-line arguments, then run>=  *)
val _ = usage := (fn () =>
  ( app eprint ["Usage:\n"]
  ; app (fn (option, action) =>
         app eprint ["       ", CommandLine.name (), " ", option, "\n"]) actions
  ))
(* <look at command-line arguments, then run>=  *)
fun action option =
  case List.find (curry op = option o fst) actions
    of SOME (_, action) => action
     | NONE => FAIL ("Unknown option " ^ option)
(* Options are parsed by function [[action]].   *)
(* <boxed values 95>=                           *)
val _ = op action : string -> action
(* The [[xdeftable]] is shared with the Impcore parser. *)
(* Function [[reduce_to_xdef]] is almost shareable as *)
(* well, but not quite---the abstract syntax of *)
(* [[DEFINE]] is different.                     *)

(* <look at command-line arguments, then run>=  *)
fun strip_options a [] = (a, [])
  | strip_options a (arg :: args) =
      if String.isPrefix "-" arg andalso arg <> "-" then
          strip_options (merge (a, action arg)) args
      else
          (a, arg :: args)

val _ = if hasOption "NORUN" then ()
        else perform (strip_options DEFAULT (CommandLine.arguments ()))
(* <boxed values 96>=                           *)
val _ = op strip_options : action -> string list -> action * string list
