;; CodeCoffee - A Tipping Service for Open-Source Developers and Tutorial Creators
;; Built on Stacks Blockchain using Clarity

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-OWNER-ONLY (err u100))
(define-constant ERR-INVALID-AMOUNT (err u101))
(define-constant ERR-INSUFFICIENT-BALANCE (err u102))
(define-constant ERR-CREATOR-NOT-FOUND (err u103))
(define-constant ERR-NOT-REGISTERED (err u104))
(define-constant ERR-ALREADY-REGISTERED (err u105))

;; Data Maps

;; Store creator information
(define-map creators
  { creator: principal }
  {
    name: (string-ascii 50),
    description: (string-ascii 200),
    total-tips: uint,
    tip-count: uint,
    registered-at: uint,
    active: bool
  }
)

;; Store individual tips/donations
(define-map tips
  { tip-id: uint }
  {
    from: principal,
    to: principal,
    amount: uint,
    message: (string-ascii 100),
    timestamp: uint
  }
)

;; Track user balances
(define-map balances
  { user: principal }
  { balance: uint }
)

;; Data Variables

;; Global tip counter
(define-data-var tip-counter uint u0)

;; Platform fee percentage (in basis points, e.g., 500 = 5%)
(define-data-var platform-fee-percentage uint u250)

;; Platform balance
(define-data-var platform-balance uint u0)

;; Private Functions

;; Helper function to get or initialize balance
(define-private (get-balance (user principal))
  (default-to u0 (get balance (map-get? balances { user: user })))
)

;; Helper function to update balance
(define-private (update-balance (user principal) (new-balance uint))
  (map-set balances { user: user } { balance: new-balance })
)

;; Public Functions

;; Register as a creator
(define-public (register-creator (name (string-ascii 50)) (description (string-ascii 200)))
  (let
    (
      (caller tx-sender)
    )
    (asserts! (is-eq (map-get? creators { creator: caller }) none) ERR-ALREADY-REGISTERED)
    (map-set creators
      { creator: caller }
      {
        name: name,
        description: description,
        total-tips: u0,
        tip-count: u0,
        registered-at: burn-block-height,
        active: true
      }
    )
    (ok true)
  )
)

;; Send a tip to a creator
(define-public (send-tip (to principal) (amount uint) (message (string-ascii 100)))
  (let
    (
      (caller tx-sender)
      (creator-info (map-get? creators { creator: to }))
      (current-tip-id (var-get tip-counter))
      (fee (/ (* amount (var-get platform-fee-percentage)) u10000))
      (creator-amount (- amount fee))
    )
    ;; Validate inputs
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (asserts! (is-some creator-info) ERR-CREATOR-NOT-FOUND)
    (asserts! (get active (unwrap-panic creator-info)) ERR-CREATOR-NOT-FOUND)
    
    ;; Transfer STX from sender
    (try! (stx-transfer? amount caller to))
    
    ;; Record the tip
    (map-set tips
      { tip-id: current-tip-id }
      {
        from: caller,
        to: to,
        amount: amount,
        message: message,
        timestamp: burn-block-height
      }
    )
    
    ;; Update creator stats
    (let
      (
        (updated-creator (unwrap-panic creator-info))
      )
      (map-set creators
        { creator: to }
        (merge updated-creator
          {
            total-tips: (+ (get total-tips updated-creator) amount),
            tip-count: (+ (get tip-count updated-creator) u1)
          }
        )
      )
    )
    
    ;; Update platform balance with fee
    (var-set platform-balance (+ (var-get platform-balance) fee))
    
    ;; Increment tip counter
    (var-set tip-counter (+ current-tip-id u1))
    
    (ok current-tip-id)
  )
)

;; Get creator profile
(define-public (get-creator-profile (creator principal))
  (ok (map-get? creators { creator: creator }))
)

;; Get tip details
(define-public (get-tip-details (tip-id uint))
  (ok (map-get? tips { tip-id: tip-id }))
)

;; Update creator profile (by creator)
(define-public (update-creator-profile (name (string-ascii 50)) (description (string-ascii 200)))
  (let
    (
      (caller tx-sender)
      (creator-info (map-get? creators { creator: caller }))
    )
    (asserts! (is-some creator-info) ERR-NOT-REGISTERED)
    (let
      (
        (updated (unwrap-panic creator-info))
      )
      (map-set creators
        { creator: caller }
        (merge updated
          {
            name: name,
            description: description
          }
        )
      )
      (ok true)
    )
  )
)

;; Deactivate creator account
(define-public (deactivate-creator)
  (let
    (
      (caller tx-sender)
      (creator-info (map-get? creators { creator: caller }))
    )
    (asserts! (is-some creator-info) ERR-NOT-REGISTERED)
    (let
      (
        (updated (unwrap-panic creator-info))
      )
      (map-set creators
        { creator: caller }
        (merge updated { active: false })
      )
      (ok true)
    )
  )
)

;; Reactivate creator account
(define-public (reactivate-creator)
  (let
    (
      (caller tx-sender)
      (creator-info (map-get? creators { creator: caller }))
    )
    (asserts! (is-some creator-info) ERR-NOT-REGISTERED)
    (let
      (
        (updated (unwrap-panic creator-info))
      )
      (map-set creators
        { creator: caller }
        (merge updated { active: true })
      )
      (ok true)
    )
  )
)

;; Admin: Update platform fee percentage (owner only)
(define-public (update-platform-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
    (asserts! (<= new-fee u1000) ERR-INVALID-AMOUNT)
    (var-set platform-fee-percentage new-fee)
    (ok true)
  )
)

;; Admin: Withdraw platform balance (owner only)
(define-public (withdraw-platform-balance (amount uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
    (asserts! (<= amount (var-get platform-balance)) ERR-INSUFFICIENT-BALANCE)
    (try! (stx-transfer? amount (as-contract tx-sender) CONTRACT-OWNER))
    (var-set platform-balance (- (var-get platform-balance) amount))
    (ok true)
  )
)

;; Read-only Functions

;; Get platform fee percentage
(define-read-only (get-platform-fee)
  (var-get platform-fee-percentage)
)

;; Get platform balance
(define-read-only (get-platform-balance)
  (var-get platform-balance)
)

;; Get total tips counter
(define-read-only (get-total-tips-count)
  (var-get tip-counter)
)

;; Check if user is registered as creator
(define-read-only (is-creator (user principal))
  (is-some (map-get? creators { creator: user }))
)