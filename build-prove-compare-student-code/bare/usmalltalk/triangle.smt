(use shapes.smt)

(class Triangle
    [subclass-of Shape]
    ;; no additional representation
    (method drawOn: (canvas)
        (canvas drawPolygon:
                (self locations: '(North Southwest Southeast))))
)

(val c ((Circle new) scale: 10))
(val s ((Square new) scale: 10))

(s adjustPoint:to: 'West (c location: 'East))

(val t (((Triangle new) scale: 10) adjustPoint:to: 'Southwest (s location: 'East)))

(val pic (Picture empty))

(pic add: c)
(pic add: s)
(pic add: t)

(val canvas (TikzCanvas new))
(pic renderUsing: canvas)