(use shapes.smt)

;; 1st picture
(val a (Circle new))
(val b (Circle new))
(val c (Circle new))
(val d (Circle new))

(b adjustPoint:to: 'East (a location: 'West))
(c adjustPoint:to: 'North (a location: 'South))
(d adjustPoint:to: 'North (b location: 'South))

(val pic1 (Picture empty))
(pic1 add: a)
(pic1 add: b)
(pic1 add: c)
(pic1 add: d)
(val canvas1 (TikzCanvas new))
(pic1 renderUsing: canvas1)

;; 2nd picture
(val e (Square new))
(val f (Square new))
(val g (Square new))
(val h (Square new))
(val i (Square new))

(f adjustPoint:to: 'Southeast (e location: 'Northwest))
(g adjustPoint:to: 'Northeast (e location: 'Southwest))
(h adjustPoint:to: 'Southwest (e location: 'Northeast))
(i adjustPoint:to: 'Northwest (e location: 'Southeast))

(val pic2 (Picture empty))
(pic2 add: e)
(pic2 add: f)
(pic2 add: g)
(pic2 add: h)
(pic2 add: i)
(val canvas2 (TikzCanvas new))
(pic2 renderUsing: canvas2)

;; 3rd picture
(val j ((Circle new) scale: 9))
(val k ((Circle new) scale: 6))
(val l ((Circle new) scale: 4))

(k adjustPoint:to: 'West (j location: 'East))
(l adjustPoint:to: 'West (k location: 'East))

(val pic3 (Picture empty))
(pic3 add: j)
(pic3 add: k)
(pic3 add: l)
(val canvas3 (TikzCanvas new))
(pic3 renderUsing: canvas3)