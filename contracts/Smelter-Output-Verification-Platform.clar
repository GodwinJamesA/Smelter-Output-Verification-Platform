(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_SMELTER_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_REGISTERED (err u102))
(define-constant ERR_INVALID_OUTPUT (err u103))
(define-constant ERR_SENSOR_NOT_AUTHORIZED (err u104))
(define-constant ERR_INVALID_TAX_RATE (err u105))
(define-constant ERR_REPORT_ALREADY_SUBMITTED (err u106))
(define-constant ERR_DISPUTE_NOT_FOUND (err u107))

(define-data-var contract-admin principal CONTRACT_OWNER)
(define-data-var global-tax-rate uint u10)
(define-data-var global-royalty-rate uint u5)

(define-map smelters
  { smelter-id: uint }
  {
    owner: principal,
    name: (string-ascii 100),
    location: (string-ascii 100),
    license-number: (string-ascii 50),
    tax-rate: uint,
    royalty-rate: uint,
    total-actual-output: uint,
    total-reported-output: uint,
    total-tax-owed: uint,
    total-royalty-owed: uint,
    active: bool
  }
)

(define-map authorized-sensors
  { sensor-id: (string-ascii 50) }
  {
    smelter-id: uint,
    sensor-type: (string-ascii 50),
    calibration-date: uint,
    active: bool
  }
)

(define-map output-logs
  { log-id: uint }
  {
    smelter-id: uint,
    sensor-id: (string-ascii 50),
    timestamp: uint,
    metal-type: (string-ascii 20),
    weight-kg: uint,
    purity-percentage: uint,
    batch-id: (string-ascii 50),
    verified: bool
  }
)

(define-map reported-outputs
  { report-id: uint }
  {
    smelter-id: uint,
    reporting-period: uint,
    metal-type: (string-ascii 20),
    claimed-weight-kg: uint,
    claimed-purity: uint,
    timestamp: uint,
    verified: bool
  }
)

(define-map verification-results
  { verification-id: uint }
  {
    smelter-id: uint,
    period: uint,
    actual-output: uint,
    reported-output: uint,
    discrepancy-percentage: uint,
    tax-calculated: uint,
    royalty-calculated: uint,
    penalty-applied: uint,
    status: (string-ascii 20)
  }
)

(define-map disputes
  { dispute-id: uint }
  {
    verification-id: uint,
    smelter-id: uint,
    reason: (string-ascii 200),
    timestamp: uint,
    resolved: bool
  }
)

(define-data-var next-smelter-id uint u1)
(define-data-var next-log-id uint u1)
(define-data-var next-report-id uint u1)
(define-data-var next-verification-id uint u1)
(define-data-var next-dispute-id uint u1)

(define-read-only (get-smelter (smelter-id uint))
  (map-get? smelters { smelter-id: smelter-id })
)

(define-read-only (get-sensor (sensor-id (string-ascii 50)))
  (map-get? authorized-sensors { sensor-id: sensor-id })
)

(define-read-only (get-output-log (log-id uint))
  (map-get? output-logs { log-id: log-id })
)

(define-read-only (get-verification-result (verification-id uint))
  (map-get? verification-results { verification-id: verification-id })
)

(define-read-only (get-dispute (dispute-id uint))
  (map-get? disputes { dispute-id: dispute-id })
)

(define-read-only (calculate-tax (weight uint) (tax-rate uint))
  (* weight tax-rate)
)

(define-read-only (calculate-royalty (weight uint) (royalty-rate uint))
  (* weight royalty-rate)
)

(define-read-only (calculate-discrepancy (actual uint) (reported uint))
  (if (> actual u0)
    (/ (* (if (> reported actual) (- reported actual) (- actual reported)) u100) actual)
    u0
  )
)

(define-public (register-smelter
  (name (string-ascii 100))
  (location (string-ascii 100))
  (license-number (string-ascii 50)))
  (begin
    (try! (assert-not-paused))
    (let ((smelter-id (var-get next-smelter-id)))
      (asserts! (is-none (map-get? smelters { smelter-id: smelter-id })) ERR_ALREADY_REGISTERED)
      (map-set smelters
        { smelter-id: smelter-id }
        {
          owner: tx-sender,
          name: name,
          location: location,
          license-number: license-number,
          tax-rate: (var-get global-tax-rate),
          royalty-rate: (var-get global-royalty-rate),
          total-actual-output: u0,
          total-reported-output: u0,
          total-tax-owed: u0,
          total-royalty-owed: u0,
          active: true
        }
      )
      (var-set next-smelter-id (+ smelter-id u1))
      (ok smelter-id)
    )
  )
)

(define-public (authorize-sensor
  (sensor-id (string-ascii 50))
  (smelter-id uint)
  (sensor-type (string-ascii 50)))
  (begin
    (try! (assert-not-paused))
    (let ((smelter (unwrap! (map-get? smelters { smelter-id: smelter-id }) ERR_SMELTER_NOT_FOUND)))
      (asserts! (or (is-eq tx-sender (get owner smelter)) (is-eq tx-sender (var-get contract-admin))) ERR_UNAUTHORIZED)
      (map-set authorized-sensors
        { sensor-id: sensor-id }
        {
          smelter-id: smelter-id,
          sensor-type: sensor-type,
          calibration-date: stacks-block-height,
          active: true
        }
      )
      (ok true)
    )
  )
)

(define-public (log-output
  (sensor-id (string-ascii 50))
  (metal-type (string-ascii 20))
  (weight-kg uint)
  (purity-percentage uint)
  (batch-id (string-ascii 50)))
  (begin
    (try! (assert-not-paused))
    (let (
      (sensor (unwrap! (map-get? authorized-sensors { sensor-id: sensor-id }) ERR_SENSOR_NOT_AUTHORIZED))
      (log-id (var-get next-log-id))
      (smelter-id (get smelter-id sensor))
    )
      (asserts! (get active sensor) ERR_SENSOR_NOT_AUTHORIZED)
      (asserts! (> weight-kg u0) ERR_INVALID_OUTPUT)
      (asserts! (<= purity-percentage u100) ERR_INVALID_OUTPUT)

      (map-set output-logs
        { log-id: log-id }
        {
          smelter-id: smelter-id,
          sensor-id: sensor-id,
          timestamp: stacks-block-height,
          metal-type: metal-type,
          weight-kg: weight-kg,
          purity-percentage: purity-percentage,
          batch-id: batch-id,
          verified: true
        }
      )

      (let ((smelter (unwrap! (map-get? smelters { smelter-id: smelter-id }) ERR_SMELTER_NOT_FOUND)))
        (map-set smelters
          { smelter-id: smelter-id }
          (merge smelter { total-actual-output: (+ (get total-actual-output smelter) weight-kg) })
        )
      )

      (var-set next-log-id (+ log-id u1))
      (ok log-id)
    )
  )
)

(define-public (submit-reported-output
  (smelter-id uint)
  (reporting-period uint)
  (metal-type (string-ascii 20))
  (claimed-weight-kg uint)
  (claimed-purity uint))
  (begin
    (try! (assert-not-paused))
    (let (
      (smelter (unwrap! (map-get? smelters { smelter-id: smelter-id }) ERR_SMELTER_NOT_FOUND))
      (report-id (var-get next-report-id))
    )
      (asserts! (is-eq tx-sender (get owner smelter)) ERR_UNAUTHORIZED)
      (asserts! (> claimed-weight-kg u0) ERR_INVALID_OUTPUT)
      (asserts! (<= claimed-purity u100) ERR_INVALID_OUTPUT)

      (map-set reported-outputs
        { report-id: report-id }
        {
          smelter-id: smelter-id,
          reporting-period: reporting-period,
          metal-type: metal-type,
          claimed-weight-kg: claimed-weight-kg,
          claimed-purity: claimed-purity,
          timestamp: stacks-block-height,
          verified: false
        }
      )

      (map-set smelters
        { smelter-id: smelter-id }
        (merge smelter { total-reported-output: (+ (get total-reported-output smelter) claimed-weight-kg) })
      )

      (var-set next-report-id (+ report-id u1))
      (ok report-id)
    )
  )
)

(define-public (verify-output
  (smelter-id uint)
  (period uint))
  (begin
    (try! (assert-not-paused))
    (let (
      (smelter (unwrap! (map-get? smelters { smelter-id: smelter-id }) ERR_SMELTER_NOT_FOUND))
      (verification-id (var-get next-verification-id))
      (actual-output (get total-actual-output smelter))
      (reported-output (get total-reported-output smelter))
      (discrepancy (calculate-discrepancy actual-output reported-output))
      (tax-amount (calculate-tax actual-output (get tax-rate smelter)))
      (royalty-amount (calculate-royalty actual-output (get royalty-rate smelter)))
      (penalty (if (> discrepancy u10) (* tax-amount u2) u0))
    )
      (asserts! (or (is-eq tx-sender (var-get contract-admin)) (is-eq tx-sender (get owner smelter))) ERR_UNAUTHORIZED)

      (map-set verification-results
        { verification-id: verification-id }
        {
          smelter-id: smelter-id,
          period: period,
          actual-output: actual-output,
          reported-output: reported-output,
          discrepancy-percentage: discrepancy,
          tax-calculated: tax-amount,
          royalty-calculated: royalty-amount,
          penalty-applied: penalty,
          status: (if (> discrepancy u10) "DISCREPANCY" "VERIFIED")
        }
      )

      (map-set smelters
        { smelter-id: smelter-id }
        (merge smelter {
          total-tax-owed: (+ (get total-tax-owed smelter) tax-amount penalty),
          total-royalty-owed: (+ (get total-royalty-owed smelter) royalty-amount)
        })
      )

      (var-set next-verification-id (+ verification-id u1))
      (ok verification-id)
    )
  )
)

(define-public (submit-dispute
  (verification-id uint)
  (reason (string-ascii 200)))
  (begin
    (try! (assert-not-paused))
    (let (
      (verification (unwrap! (map-get? verification-results { verification-id: verification-id }) ERR_DISPUTE_NOT_FOUND))
      (smelter-id (get smelter-id verification))
      (smelter (unwrap! (map-get? smelters { smelter-id: smelter-id }) ERR_SMELTER_NOT_FOUND))
      (dispute-id (var-get next-dispute-id))
    )
      (asserts! (is-eq tx-sender (get owner smelter)) ERR_UNAUTHORIZED)
      (map-set disputes
        { dispute-id: dispute-id }
        {
          verification-id: verification-id,
          smelter-id: smelter-id,
          reason: reason,
          timestamp: stacks-block-height,
          resolved: false
        }
      )
      (map-set verification-results
        { verification-id: verification-id }
        (merge verification { status: "DISPUTED" })
      )
      (var-set next-dispute-id (+ dispute-id u1))
      (ok dispute-id)
    )
  )
)

(define-public (set-tax-rates (new-tax-rate uint) (new-royalty-rate uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-admin)) ERR_UNAUTHORIZED)
    (asserts! (<= new-tax-rate u100) ERR_INVALID_TAX_RATE)
    (asserts! (<= new-royalty-rate u100) ERR_INVALID_TAX_RATE)
    (var-set global-tax-rate new-tax-rate)
    (var-set global-royalty-rate new-royalty-rate)
    (ok true)
  )
)

(define-public (update-smelter-rates
  (smelter-id uint)
  (tax-rate uint)
  (royalty-rate uint))
  (let ((smelter (unwrap! (map-get? smelters { smelter-id: smelter-id }) ERR_SMELTER_NOT_FOUND)))
    (asserts! (is-eq tx-sender (var-get contract-admin)) ERR_UNAUTHORIZED)
    (asserts! (<= tax-rate u100) ERR_INVALID_TAX_RATE)
    (asserts! (<= royalty-rate u100) ERR_INVALID_TAX_RATE)
    
    (map-set smelters
      { smelter-id: smelter-id }
      (merge smelter {
        tax-rate: tax-rate,
        royalty-rate: royalty-rate
      })
    )
    (ok true)
  )
)

(define-public (deactivate-smelter (smelter-id uint))
  (let ((smelter (unwrap! (map-get? smelters { smelter-id: smelter-id }) ERR_SMELTER_NOT_FOUND)))
    (asserts! (is-eq tx-sender (var-get contract-admin)) ERR_UNAUTHORIZED)
    (map-set smelters
      { smelter-id: smelter-id }
      (merge smelter { active: false })
    )
    (ok true)
  )
)

(define-public (deactivate-sensor (sensor-id (string-ascii 50)))
  (let ((sensor (unwrap! (map-get? authorized-sensors { sensor-id: sensor-id }) ERR_SENSOR_NOT_AUTHORIZED)))
    (asserts! (is-eq tx-sender (var-get contract-admin)) ERR_UNAUTHORIZED)
    (map-set authorized-sensors
      { sensor-id: sensor-id }
      (merge sensor { active: false })
    )
    (ok true)
  )
)

(define-public (reset-smelter-totals (smelter-id uint))
  (let ((smelter (unwrap! (map-get? smelters { smelter-id: smelter-id }) ERR_SMELTER_NOT_FOUND)))
    (asserts! (is-eq tx-sender (var-get contract-admin)) ERR_UNAUTHORIZED)
    (map-set smelters
      { smelter-id: smelter-id }
      (merge smelter {
        total-actual-output: u0,
        total-reported-output: u0,
        total-tax-owed: u0,
        total-royalty-owed: u0
      })
    )
    (ok true)
  )
)

(define-public (bulk-log-outputs
  (sensor-id (string-ascii 50))
  (outputs (list 20 {metal-type: (string-ascii 20), weight-kg: uint, purity-percentage: uint, batch-id: (string-ascii 50)})))
  (begin
    (try! (assert-not-paused))
    (let ((sensor (unwrap! (map-get? authorized-sensors { sensor-id: sensor-id }) ERR_SENSOR_NOT_AUTHORIZED)))
      (asserts! (get active sensor) ERR_SENSOR_NOT_AUTHORIZED)
      (fold log-single-output outputs sensor-id)
      (ok true)
    )
  )
)

(define-private (log-single-output
  (output {metal-type: (string-ascii 20), weight-kg: uint, purity-percentage: uint, batch-id: (string-ascii 50)})
  (sensor-id (string-ascii 50)))
  (let (
    (sensor (unwrap-panic (map-get? authorized-sensors { sensor-id: sensor-id })))
    (log-id (var-get next-log-id))
    (smelter-id (get smelter-id sensor))
  )
    (map-set output-logs
      { log-id: log-id }
      {
        smelter-id: smelter-id,
        sensor-id: sensor-id,
        timestamp: stacks-block-height,
        metal-type: (get metal-type output),
        weight-kg: (get weight-kg output),
        purity-percentage: (get purity-percentage output),
        batch-id: (get batch-id output),
        verified: true
      }
    )
    
    (let ((smelter (unwrap-panic (map-get? smelters { smelter-id: smelter-id }))))
      (map-set smelters
        { smelter-id: smelter-id }
        (merge smelter { total-actual-output: (+ (get total-actual-output smelter) (get weight-kg output)) })
      )
    )
    
    (var-set next-log-id (+ log-id u1))
    sensor-id
  )
)

(define-read-only (get-smelter-summary (smelter-id uint))
  (match (map-get? smelters { smelter-id: smelter-id })
    smelter (ok {
      name: (get name smelter),
      location: (get location smelter),
      total-actual: (get total-actual-output smelter),
      total-reported: (get total-reported-output smelter),
      tax-owed: (get total-tax-owed smelter),
      royalty-owed: (get total-royalty-owed smelter),
      active: (get active smelter)
    })
    ERR_SMELTER_NOT_FOUND
  )
)

(define-read-only (get-global-rates)
  {
    tax-rate: (var-get global-tax-rate),
    royalty-rate: (var-get global-royalty-rate)
  }
)

(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-admin)) ERR_UNAUTHORIZED)
    (var-set contract-admin new-admin)
    (ok true)
  )
)

(define-public (pay-taxes-and-royalties (smelter-id uint))
  (begin
    (try! (assert-not-paused))
    (let (
      (smelter (unwrap! (map-get? smelters { smelter-id: smelter-id }) ERR_SMELTER_NOT_FOUND))
      (tax-owed (get total-tax-owed smelter))
      (royalty-owed (get total-royalty-owed smelter))
      (total-payment (+ tax-owed royalty-owed))
    )
      (asserts! (is-eq tx-sender (get owner smelter)) ERR_UNAUTHORIZED)
      (asserts! (> total-payment u0) ERR_INVALID_OUTPUT)
      (try! (stx-transfer? total-payment tx-sender (var-get contract-admin)))
      (map-set smelters
        { smelter-id: smelter-id }
        (merge smelter {
          total-tax-owed: u0,
          total-royalty-owed: u0
        })
      )
      (ok total-payment)
    )
  )
)

(define-map audit-trail
  { audit-id: uint }
  {
    smelter-id: uint,
    action: (string-ascii 50),
    timestamp: uint,
    details: (string-ascii 200)
  }
)

(define-data-var next-audit-id uint u1)

(define-data-var contract-paused bool false)

(define-read-only (get-audit-entry (audit-id uint))
  (map-get? audit-trail { audit-id: audit-id })
)

(define-private (log-audit (smelter-id uint) (action (string-ascii 50)) (details (string-ascii 200)))
  (let ((audit-id (var-get next-audit-id)))
    (map-set audit-trail
      { audit-id: audit-id }
      {
        smelter-id: smelter-id,
        action: action,
        timestamp: stacks-block-height,
        details: details
      }
    )
    (var-set next-audit-id (+ audit-id u1))
  )
)

(define-public (register-smelter-with-audit
  (name (string-ascii 100))
  (location (string-ascii 100))
  (license-number (string-ascii 50)))
  (let ((result (register-smelter name location license-number)))
    (match result
      smelter-id (begin
        (log-audit smelter-id "REGISTER_SMELTER" (concat "Registered smelter: " name))
        result
      )
      error result
    )
  )
)

(define-public (log-output-with-audit
  (sensor-id (string-ascii 50))
  (metal-type (string-ascii 20))
  (weight-kg uint)
  (purity-percentage uint)
  (batch-id (string-ascii 50)))
  (let ((result (log-output sensor-id metal-type weight-kg purity-percentage batch-id)))
    (match result
      log-id (begin
        (let ((sensor (unwrap-panic (map-get? authorized-sensors { sensor-id: sensor-id }))))
          (log-audit (get smelter-id sensor) "LOG_OUTPUT" (concat "Logged output for batch: " batch-id))
        )
        result
      )
      error result
    )
  )
)

(define-public (submit-reported-output-with-audit
  (smelter-id uint)
  (reporting-period uint)
  (metal-type (string-ascii 20))
  (claimed-weight-kg uint)
  (claimed-purity uint))
  (let ((result (submit-reported-output smelter-id reporting-period metal-type claimed-weight-kg claimed-purity)))
    (match result
      report-id (begin
        (log-audit smelter-id "SUBMIT_REPORT" "Submitted reported output")
        result
      )
      error result
    )
  )
)

(define-public (verify-output-with-audit
  (smelter-id uint)
  (period uint))
  (let ((result (verify-output smelter-id period)))
    (match result
      verification-id (begin
        (log-audit smelter-id "VERIFY_OUTPUT" "Verified output")
        result
      )
      error result
    )
  )
)

(define-public (pay-taxes-and-royalties-with-audit (smelter-id uint))
  (let ((result (pay-taxes-and-royalties smelter-id)))
    (match result
      payment-amount (begin
        (log-audit smelter-id "PAY_TAXES_ROYALTIES" "Paid taxes and royalties")
        result
      )
      error result
    )
  )
)

(define-public (pause-contract)
  (begin
    (asserts! (is-eq tx-sender (var-get contract-admin)) ERR_UNAUTHORIZED)
    (var-set contract-paused true)
    (ok true)
  )
)

(define-public (unpause-contract)
  (begin
    (asserts! (is-eq tx-sender (var-get contract-admin)) ERR_UNAUTHORIZED)
    (var-set contract-paused false)
    (ok true)
  )
)

(define-private (assert-not-paused)
  (ok (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED))
)

(define-read-only (is-contract-paused)
  (var-get contract-paused)
)
