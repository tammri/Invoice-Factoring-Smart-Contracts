;; title: Invoice-Factoring-Smart-Contracts

(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVOICE-NOT-FOUND (err u101))
(define-constant ERR-INVALID-AMOUNT (err u102))
(define-constant ERR-INVOICE-ALREADY-FACTORED (err u103))
(define-constant ERR-INVOICE-NOT-FACTORED (err u104))
(define-constant ERR-INVOICE-ALREADY-PAID (err u105))
(define-constant ERR-INVOICE-NOT-PAID (err u106))
(define-constant ERR-ALREADY-CLAIMED (err u107))
(define-constant ERR-INSUFFICIENT-FUNDS (err u108))
(define-constant ERR-INVOICE-EXPIRED (err u109))
(define-constant ERR-INVALID-FACTORING-RATE (err u110))

(define-data-var invoice-id-nonce uint u0)
(define-data-var platform-fee-rate uint u200)
(define-data-var max-factoring-rate uint u8000)

(define-map invoices
  uint
  {
    business: principal,
    client: principal,
    amount: uint,
    factored-amount: uint,
    due-block: uint,
    created-block: uint,
    status: (string-ascii 20),
    factor: (optional principal),
    factoring-rate: uint,
    paid: bool,
    claimed: bool
  }
)

(define-map business-stats
  principal
  {
    total-invoices: uint,
    total-factored: uint,
    total-repaid: uint
  }
)

(define-map factor-stats
  principal
  {
    total-invested: uint,
    total-returns: uint,
    active-investments: uint
  }
)

(define-map pending-withdrawals
  principal
  uint
)

(define-read-only (get-invoice (invoice-id uint))
  (map-get? invoices invoice-id)
)

(define-read-only (get-business-stats (business principal))
  (default-to 
    {total-invoices: u0, total-factored: u0, total-repaid: u0}
    (map-get? business-stats business)
  )
)

(define-read-only (get-factor-stats (factor principal))
  (default-to 
    {total-invested: u0, total-returns: u0, active-investments: u0}
    (map-get? factor-stats factor)
  )
)

(define-read-only (get-pending-withdrawal (user principal))
  (default-to u0 (map-get? pending-withdrawals user))
)

(define-read-only (get-platform-fee-rate)
  (var-get platform-fee-rate)
)

(define-read-only (calculate-factoring-amount (amount uint) (rate uint))
  (ok (/ (* amount (- u10000 rate)) u10000))
)

(define-read-only (calculate-platform-fee (amount uint))
  (/ (* amount (var-get platform-fee-rate)) u10000)
)

(define-public (create-invoice (client principal) (amount uint) (blocks-until-due uint))
  (let
    (
      (new-id (+ (var-get invoice-id-nonce) u1))
      (due-block (+ stacks-block-height blocks-until-due))
      (business-data (get-business-stats tx-sender))
    )
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (map-set invoices new-id
      {
        business: tx-sender,
        client: client,
        amount: amount,
        factored-amount: u0,
        due-block: due-block,
        created-block: stacks-block-height,
        status: "active",
        factor: none,
        factoring-rate: u0,
        paid: false,
        claimed: false
      }
    )
    (map-set business-stats tx-sender
      (merge business-data {total-invoices: (+ (get total-invoices business-data) u1)})
    )
    (var-set invoice-id-nonce new-id)
    (ok new-id)
  )
)

(define-public (factor-invoice (invoice-id uint) (rate uint))
  (let
    (
      (invoice (unwrap! (get-invoice invoice-id) ERR-INVOICE-NOT-FOUND))
      (factoring-amount (unwrap! (calculate-factoring-amount (get amount invoice) rate) ERR-INVALID-AMOUNT))
      (platform-fee (calculate-platform-fee factoring-amount))
      (net-amount (- factoring-amount platform-fee))
      (business-data (get-business-stats (get business invoice)))
      (factor-data (get-factor-stats tx-sender))
    )
    (asserts! (is-none (get factor invoice)) ERR-INVOICE-ALREADY-FACTORED)
    (asserts! (not (get paid invoice)) ERR-INVOICE-ALREADY-PAID)
    (asserts! (<= rate (var-get max-factoring-rate)) ERR-INVALID-FACTORING-RATE)
    (asserts! (< stacks-block-height (get due-block invoice)) ERR-INVOICE-EXPIRED)
    
    (try! (stx-transfer? factoring-amount tx-sender (as-contract tx-sender)))
    
    (map-set invoices invoice-id
      (merge invoice {
        status: "factored",
        factor: (some tx-sender),
        factoring-rate: rate,
        factored-amount: factoring-amount
      })
    )
    
    (map-set pending-withdrawals (get business invoice)
      (+ (get-pending-withdrawal (get business invoice)) net-amount)
    )
    
    (map-set pending-withdrawals CONTRACT-OWNER
      (+ (get-pending-withdrawal CONTRACT-OWNER) platform-fee)
    )
    
    (map-set business-stats (get business invoice)
      (merge business-data {total-factored: (+ (get total-factored business-data) net-amount)})
    )
    
    (map-set factor-stats tx-sender
      (merge factor-data {
        total-invested: (+ (get total-invested factor-data) factoring-amount),
        active-investments: (+ (get active-investments factor-data) u1)
      })
    )
    
    (ok net-amount)
  )
)

(define-public (pay-invoice (invoice-id uint))
  (let
    (
      (invoice (unwrap! (get-invoice invoice-id) ERR-INVOICE-NOT-FOUND))
      (payment-amount (get amount invoice))
    )
    (asserts! (or (is-eq tx-sender (get client invoice)) (is-eq tx-sender (get business invoice))) ERR-NOT-AUTHORIZED)
    (asserts! (not (get paid invoice)) ERR-INVOICE-ALREADY-PAID)
    
    (try! (stx-transfer? payment-amount tx-sender (as-contract tx-sender)))
    
    (map-set invoices invoice-id
      (merge invoice {
        status: "paid",
        paid: true
      })
    )
    
    (if (is-some (get factor invoice))
      (let
        (
          (factor-principal (unwrap-panic (get factor invoice)))
          (business-data (get-business-stats (get business invoice)))
        )
        (map-set pending-withdrawals factor-principal
          (+ (get-pending-withdrawal factor-principal) payment-amount)
        )
        (map-set business-stats (get business invoice)
          (merge business-data {total-repaid: (+ (get total-repaid business-data) payment-amount)})
        )
        (ok true)
      )
      (begin
        (map-set pending-withdrawals (get business invoice)
          (+ (get-pending-withdrawal (get business invoice)) payment-amount)
        )
        (ok true)
      )
    )
  )
)

(define-public (claim-repayment (invoice-id uint))
  (let
    (
      (invoice (unwrap! (get-invoice invoice-id) ERR-INVOICE-NOT-FOUND))
      (factor-principal (unwrap! (get factor invoice) ERR-INVOICE-NOT-FACTORED))
    )
    (asserts! (is-eq tx-sender factor-principal) ERR-NOT-AUTHORIZED)
    (asserts! (get paid invoice) ERR-INVOICE-NOT-PAID)
    (asserts! (not (get claimed invoice)) ERR-ALREADY-CLAIMED)
    
    (map-set invoices invoice-id
      (merge invoice {
        status: "completed",
        claimed: true
      })
    )
    
    (let
      (
        (factor-data (get-factor-stats tx-sender))
      )
      (map-set factor-stats tx-sender
        (merge factor-data {
          total-returns: (+ (get total-returns factor-data) (get amount invoice)),
          active-investments: (- (get active-investments factor-data) u1)
        })
      )
    )
    
    (ok true)
  )
)

(define-public (withdraw)
  (let
    (
      (amount (get-pending-withdrawal tx-sender))
    )
    (asserts! (> amount u0) ERR-INSUFFICIENT-FUNDS)
    
    (map-set pending-withdrawals tx-sender u0)
    
    (as-contract (stx-transfer? amount tx-sender tx-sender))
  )
)

(define-public (set-platform-fee-rate (new-rate uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (<= new-rate u1000) ERR-INVALID-AMOUNT)
    (var-set platform-fee-rate new-rate)
    (ok true)
  )
)

(define-public (set-max-factoring-rate (new-rate uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (<= new-rate u10000) ERR-INVALID-AMOUNT)
    (var-set max-factoring-rate new-rate)
    (ok true)
  )
)
