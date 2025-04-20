;; Property Verification Contract
;; Validates ownership and property details

(define-data-var contract-owner principal tx-sender)

;; Property data structure
(define-map properties
  { property-id: (string-ascii 36) }
  {
    owner: principal,
    address: (string-ascii 100),
    square-footage: uint,
    property-type: (string-ascii 20),
    verified: bool
  }
)

;; Register a new property
(define-public (register-property
    (property-id (string-ascii 36))
    (address (string-ascii 100))
    (square-footage uint)
    (property-type (string-ascii 20)))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u1))
    (asserts! (is-none (map-get? properties { property-id: property-id })) (err u2))
    (ok (map-set properties
      { property-id: property-id }
      {
        owner: tx-sender,
        address: address,
        square-footage: square-footage,
        property-type: property-type,
        verified: false
      }
    ))
  )
)

;; Transfer property ownership
(define-public (transfer-ownership
    (property-id (string-ascii 36))
    (new-owner principal))
  (let ((property (unwrap! (map-get? properties { property-id: property-id }) (err u3))))
    (asserts! (is-eq tx-sender (get owner property)) (err u4))
    (ok (map-set properties
      { property-id: property-id }
      (merge property { owner: new-owner })
    ))
  )
)

;; Verify property details
(define-public (verify-property (property-id (string-ascii 36)))
  (let ((property (unwrap! (map-get? properties { property-id: property-id }) (err u3))))
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u1))
    (ok (map-set properties
      { property-id: property-id }
      (merge property { verified: true })
    ))
  )
)

;; Get property details
(define-read-only (get-property (property-id (string-ascii 36)))
  (map-get? properties { property-id: property-id })
)
