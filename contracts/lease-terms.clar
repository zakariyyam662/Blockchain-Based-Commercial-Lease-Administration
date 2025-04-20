;; Lease Terms Contract
;; Manages critical dates and obligations

(define-data-var contract-owner principal tx-sender)

;; Lease data structure
(define-map leases
  { lease-id: (string-ascii 36) }
  {
    property-id: (string-ascii 36),
    tenant: principal,
    landlord: principal,
    start-date: uint,
    end-date: uint,
    renewal-option: bool,
    renewal-notice-period: uint,
    security-deposit: uint,
    active: bool
  }
)

;; Critical dates for lease obligations
(define-map critical-dates
  { lease-id: (string-ascii 36), date-type: (string-ascii 20) }
  {
    date: uint,
    description: (string-ascii 100),
    completed: bool
  }
)

;; Create a new lease
(define-public (create-lease
    (lease-id (string-ascii 36))
    (property-id (string-ascii 36))
    (tenant principal)
    (start-date uint)
    (end-date uint)
    (renewal-option bool)
    (renewal-notice-period uint)
    (security-deposit uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u1))
    (asserts! (is-none (map-get? leases { lease-id: lease-id })) (err u2))
    (ok (map-set leases
      { lease-id: lease-id }
      {
        property-id: property-id,
        tenant: tenant,
        landlord: tx-sender,
        start-date: start-date,
        end-date: end-date,
        renewal-option: renewal-option,
        renewal-notice-period: renewal-notice-period,
        security-deposit: security-deposit,
        active: true
      }
    ))
  )
)

;; Add a critical date to a lease
(define-public (add-critical-date
    (lease-id (string-ascii 36))
    (date-type (string-ascii 20))
    (date uint)
    (description (string-ascii 100)))
  (let ((lease (unwrap! (map-get? leases { lease-id: lease-id }) (err u3))))
    (asserts! (is-eq tx-sender (get landlord lease)) (err u4))
    (ok (map-set critical-dates
      { lease-id: lease-id, date-type: date-type }
      {
        date: date,
        description: description,
        completed: false
      }
    ))
  )
)

;; Mark a critical date as completed
(define-public (complete-critical-date
    (lease-id (string-ascii 36))
    (date-type (string-ascii 20)))
  (let (
    (lease (unwrap! (map-get? leases { lease-id: lease-id }) (err u3)))
    (date-entry (unwrap! (map-get? critical-dates { lease-id: lease-id, date-type: date-type }) (err u5)))
  )
    (asserts! (or (is-eq tx-sender (get landlord lease)) (is-eq tx-sender (get tenant lease))) (err u4))
    (ok (map-set critical-dates
      { lease-id: lease-id, date-type: date-type }
      (merge date-entry { completed: true })
    ))
  )
)

;; Terminate a lease
(define-public (terminate-lease (lease-id (string-ascii 36)))
  (let ((lease (unwrap! (map-get? leases { lease-id: lease-id }) (err u3))))
    (asserts! (is-eq tx-sender (get landlord lease)) (err u4))
    (ok (map-set leases
      { lease-id: lease-id }
      (merge lease { active: false })
    ))
  )
)

;; Get lease details
(define-read-only (get-lease (lease-id (string-ascii 36)))
  (map-get? leases { lease-id: lease-id })
)

;; Get critical date
(define-read-only (get-critical-date (lease-id (string-ascii 36)) (date-type (string-ascii 20)))
  (map-get? critical-dates { lease-id: lease-id, date-type: date-type })
)
