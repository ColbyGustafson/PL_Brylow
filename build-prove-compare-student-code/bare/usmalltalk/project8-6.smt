(class Rand
   [subclass-of Object]
   [ivars seed]
   ;; no additional representation
   (class-method new: (s)   ;;;;;; Initialization
      ((self new) initializeSeed: s)
      self)
   (method initializeSeed: (s)
      (set seed s)
      self)

   (method seed () seed)

   (method next ()
      (((9 * seed) + 5) mod: 1024)
      (set seed (seed + 1)))

)