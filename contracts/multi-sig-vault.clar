
;; title: multi-sig-vault
;; version:
;; summary:
;; description:

;; traits
;;

;; token definitions
;;

;; constants
;;

;; Owner
(define-constant contract-owner tx-sender)

;; Errors
(define-constant err-owner-only (err u100))
(define-constant err-already-locked (err u101))
(define-constant err-more-votes-than-members-required (err u102))
(define-constant err-not-a-member (err u103))
(define-constant err-votes-required-not-met (err u104))


;; data vars
;;

;; Variables
(define-data-var members (list 100 principal) (list))
(define-data-var votes-required uint u1)



;; data maps
;;

(define-map votes {member: principal, recipient: principal} {decision: bool})



;; public functions
;;

(define-public (start (new-members (list 100 principal)) (new-votes-required uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (is-eq (len (var-get members)) u0) err-already-locked)
        (asserts! (>= (len new-members) new-votes-required) err-more-votes-than-members-required)
        (var-set members new-members)
        (var-set votes-required new-votes-required)
        (ok true)
    )
)


(define-public (vote (recipient principal) (decision bool))
    (begin
        (asserts! (is-some (index-of (var-get members) tx-sender)) err-not-a-member)
        (ok (map-set votes {member: tx-sender, recipient: recipient} {decision: decision}))
    )
)


(define-public (withdraw)
    (let
        (
            (recipient tx-sender)
            (total-votes (tally-votes))
        )
        (asserts! (>= total-votes (var-get votes-required)) err-votes-required-not-met)
        (try! (as-contract (stx-transfer? (stx-get-balance tx-sender) tx-sender recipient)))
        (ok total-votes)
    )
)

(define-public (deposit (amount uint))
    (stx-transfer? amount tx-sender (as-contract tx-sender))
)
;;Finally, we will add a convenience function to deposit tokens into the contract. It is definitely not required as users can transfer tokens to a contract principal directly. The function will be useful when writing unit tests later.

;; read only functions
;;

(define-read-only (get-vote (member principal) (recipient principal))
    (default-to false (get decision (map-get? votes {member: member, recipient: recipient})))
)


(define-read-only (tally-votes)
    (fold tally (var-get members) u0)
)


;; private functions
;;


;; (define-private (tally (member principal) (accumulator uint))
;;     (if (get-vote member tx-sender) (+ accumulator u1) accumulator)
;; )

(define-private (tally (member principal) (accumulator uint))
    (if 
    (get-vote member tx-sender)  ;; the condition
    (+ accumulator u1) ;; value to return if the condition is true
    accumulator ;; value to return if condition is false
    )
)
