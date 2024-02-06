(class BST
    [subclass-of KeyedCollection]
    [ivars left right root] ;; left and right are BSTs root is an association
    (class-method new ()      ((super new) initBST))
    (method initBST ()                                  ;; private
        (set root (Association new)) 
        (set left (nil))
        (set right (nil))
        self
    )

    ;;(method associationsDo: (aBlock)
    ;;    (self do: aBlock)
    ;;    (((left isNil) not) ifTrue: (left associationDo: aBlock))
    ;;    (((right isNil) not) ifTrue: (right associationDo: aBlock))
    ;;)

    (method associationsDo: (aBlock)
        (((root key) notNil) ifTrue: {(aBlock value: root)})
        ((left notNil) ifTrue: {(left associationsDo: aBlock)})
        ((right notNil) ifTrue: {(right associationsDo: aBlock)})
    )

 ;;   (method at:put: (key value) [locals tempassoc]
 ;;       (set tempassoc (self associationAt:ifAbsent: key {}))
 ;;       ((tempassoc isNil) ifTrue:ifFalse:
 ;;            {(table add: (Association withKey:value: key value))}
 ;;            {(tempassoc setValue: value)})
 ;;       self)

(method at:put: (key value)
    (self insert: root withKey: key andValue: value)
)

(method insert: (node withKey: key andValue: value)
    ((node isNil) ifTrue:ifFalse:
        { ;; if the current spot empty, insert new node here
        (set root (Association key: key value: value))
        self}

        { ;; if spot not empty, determine whether left or right
        ((key < (node key)) ifTrue:ifFalse:
            { ;; go left
            (node left: (self insert: (node left) withKey: key andValue: value))}
            { ;; go right
            (node right: (self insert: (node right) withKey: key andValue: value))})
        ;; if key == update value
        ((key = (node key)) ifTrue: [(node value: value)])
        self}
    )
)

(method removeKey:ifAbsent: (key exnBlock)
    ;; Check if the root is nil, which means the tree is empty
    ((root isNil) ifTrue: [^exnBlock value])

    ;; If the key is in the root node
    ((key = (root key)) ifTrue: [
        ;; Call a method to handle the removal and get the new tree
        (set root (self removeRootNode))
    ] ifFalse: [
        ;; Recursively remove the key from either the left or right subtree
        (set left (left removeKey:ifAbsent: key exnBlock))
        ;; The above line should actually check if the key is less than the root key
        ;; and only then set the left or right accordingly. The same applies below for right.
        (set right (right removeKey:ifAbsent: key exnBlock))
    ])
    self
)

;; Helper method to remove the root node and reorganize the BST
(method removeRootNode []
    ((left isNil) ifTrue: [^right])  ;; If there's no left child, promote the right child
    ((right isNil) ifTrue: [^left])  ;; If there's no right child, promote the left child

    ;; If the node has two children, find the in-order successor
    ;; (the smallest node in the right subtree), use it to replace the root,
    ;; and then remove the in-order successor from the right subtree.
    [locals successor successorParent]
    (set successorParent self)
    (set successor right)
    ((successor left notNil) whileTrue: [
        (set successorParent successor)
        (set successor (successor left))
    ])
    ;; Set the root's key and value to the successor's key and value
    (root key: (successor key))
    (root value: (successor value))

    ;; Remove the successor node from the tree
    (set successor (successor removeRootNode))

    ;; If the successor had a right child, attach it to the successor's parent
    ((successorParent = self) ifTrue: [
        (set right successor)
    ] ifFalse: [
        (successorParent left: successor)
    ])
    root
)


    (method removeKey:ifAbsent: (key exnBlock)
       [locals value-removed] ;; value found if not absent
       (set value-removed (self at:ifAbsent: key {(return (exnBlock value))}))
       (set table (table reject: [block (assn) (key = (assn key))])) ;; remove assoc
       value-removed)

    (method remove:ifAbsent: (value exnBlock)
       (self error: 'Dictionary-uses-remove:key:-not-remove: ))

    (method add: (anAssociation)
      (self at:put: (anAssociation key) (anAssociation value)))

    (method print () [locals print-comma]
        (set print-comma false)
        (self printName)
        (left-round print)
        (self associationsDo:
            [block (x) (space print)
                       (print-comma ifTrue: {(', print) (space print)})
                       (set print-comma true)
                       ((x key) print)   (space print)
                       ('|--> print)     (space print)
                       ((x value) print)])
        (space print)
        (right-round print)
        self)
)