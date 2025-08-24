;; SynthMint Protocol - Create and trade synthetic assets tracking real-world prices
;; This contract allows users to mint synthetic tokens that track real-world asset prices

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_OWNER_ONLY (err u100))
(define-constant ERR_NOT_TOKEN_OWNER (err u101))
(define-constant ERR_INSUFFICIENT_BALANCE (err u102))
(define-constant ERR_ASSET_NOT_FOUND (err u103))
(define-constant ERR_INVALID_AMOUNT (err u104))
(define-constant ERR_ORACLE_NOT_AUTHORIZED (err u105))
(define-constant ERR_STALE_PRICE (err u106))
(define-constant ERR_INSUFFICIENT_COLLATERAL (err u107))
(define-constant ERR_ASSET_EXISTS (err u108))

;; Data Variables
(define-data-var token-name (string-ascii 32) "SynthMint")
(define-data-var token-symbol (string-ascii 10) "SYNTH")
(define-data-var token-decimals uint u6)
(define-data-var token-uri (optional (string-utf8 256)) none)
(define-data-var collateral-ratio uint u150) ;; 150% collateralization ratio
(define-data-var next-asset-id uint u1)

;; Data Maps
(define-map token-balances principal uint)
(define-map token-supplies uint uint) ;; asset-id -> total supply
(define-map synthetic-assets 
  uint 
  {
    name: (string-ascii 32),
    symbol: (string-ascii 10), 
    price: uint,
    last-updated: uint,
    active: bool
  }
)
(define-map user-positions 
  {user: principal, asset-id: uint}
  {
    synthetic-tokens: uint,
    collateral-locked: uint
  }
)
(define-map authorized-oracles principal bool)
(define-map asset-prices 
  uint 
  {
    price: uint,
    timestamp: uint,
    oracle: principal
  }
)

;; Authorization Functions
(define-public (set-contract-owner (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_OWNER_ONLY)
    (var-set token-name "SynthMint")
    (ok true)
  )
)

(define-public (authorize-oracle (oracle principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_OWNER_ONLY)
    (map-set authorized-oracles oracle true)
    (ok true)
  )
)

(define-public (revoke-oracle (oracle principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_OWNER_ONLY)
    (map-delete authorized-oracles oracle)
    (ok true)
  )
)

;; SIP-010 Standard Functions
(define-public (transfer (amount uint) (sender principal) (recipient principal) (memo (optional (buff 34))))
  (begin
    (asserts! (or (is-eq tx-sender sender) (is-eq contract-caller sender)) ERR_NOT_TOKEN_OWNER)
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (let ((sender-balance (ft-get-balance synthmint-token sender)))
      (asserts! (>= sender-balance amount) ERR_INSUFFICIENT_BALANCE)
      (try! (ft-transfer? synthmint-token amount sender recipient))
      (print {action: "transfer", sender: sender, recipient: recipient, amount: amount, memo: memo})
      (ok true)
    )
  )
)

(define-read-only (get-name)
  (ok (var-get token-name))
)

(define-read-only (get-symbol)
  (ok (var-get token-symbol))
)

(define-read-only (get-decimals)
  (ok (var-get token-decimals))
)

(define-read-only (get-balance (user principal))
  (ok (ft-get-balance synthmint-token user))
)

(define-read-only (get-total-supply)
  (ok (ft-get-supply synthmint-token))
)

(define-read-only (get-token-uri)
  (ok (var-get token-uri))
)

;; Define the fungible token
(define-fungible-token synthmint-token)

;; Oracle Functions
(define-public (update-price (asset-id uint) (new-price uint))
  (let ((oracle-authorized (default-to false (map-get? authorized-oracles tx-sender))))
    (asserts! oracle-authorized ERR_ORACLE_NOT_AUTHORIZED)
    (asserts! (> new-price u0) ERR_INVALID_AMOUNT)
    (map-set asset-prices asset-id {
      price: new-price,
      timestamp: stacks-block-height,
      oracle: tx-sender
    })
    (match (map-get? synthetic-assets asset-id)
      asset-data (begin
        (map-set synthetic-assets asset-id (merge asset-data {
          price: new-price,
          last-updated: stacks-block-height
        }))
        (print {action: "price-update", asset-id: asset-id, price: new-price, oracle: tx-sender})
        (ok true)
      )
      ERR_ASSET_NOT_FOUND
    )
  )
)

(define-read-only (get-asset-price (asset-id uint))
  (map-get? asset-prices asset-id)
)

;; Asset Management Functions
(define-public (create-synthetic-asset (name (string-ascii 32)) (symbol (string-ascii 10)) (initial-price uint))
  (let ((asset-id (var-get next-asset-id)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_OWNER_ONLY)
    (asserts! (> initial-price u0) ERR_INVALID_AMOUNT)
    (asserts! (is-none (map-get? synthetic-assets asset-id)) ERR_ASSET_EXISTS)
    
    (map-set synthetic-assets asset-id {
      name: name,
      symbol: symbol,
      price: initial-price,
      last-updated: stacks-block-height,
      active: true
    })
    
    (map-set asset-prices asset-id {
      price: initial-price,
      timestamp: stacks-block-height,
      oracle: tx-sender
    })
    
    (map-set token-supplies asset-id u0)
    (var-set next-asset-id (+ asset-id u1))
    
    (print {action: "asset-created", asset-id: asset-id, name: name, symbol: symbol, price: initial-price})
    (ok asset-id)
  )
)

(define-read-only (get-synthetic-asset (asset-id uint))
  (map-get? synthetic-assets asset-id)
)

;; Position Management Functions
(define-public (mint-synthetic (asset-id uint) (amount uint))
  (let (
    (asset-data (unwrap! (map-get? synthetic-assets asset-id) ERR_ASSET_NOT_FOUND))
    (asset-price (get price (unwrap! (map-get? asset-prices asset-id) ERR_ASSET_NOT_FOUND)))
    (required-collateral (/ (* amount asset-price (var-get collateral-ratio)) u100))
    (current-position (default-to {synthetic-tokens: u0, collateral-locked: u0} 
                                (map-get? user-positions {user: tx-sender, asset-id: asset-id})))
  )
    (asserts! (get active asset-data) ERR_ASSET_NOT_FOUND)
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (asserts! (>= (stx-get-balance tx-sender) required-collateral) ERR_INSUFFICIENT_COLLATERAL)
    
    ;; Transfer collateral to contract
    (try! (stx-transfer? required-collateral tx-sender (as-contract tx-sender)))
    
    ;; Mint synthetic tokens
    (try! (ft-mint? synthmint-token amount tx-sender))
    
    ;; Update position
    (map-set user-positions {user: tx-sender, asset-id: asset-id} {
      synthetic-tokens: (+ (get synthetic-tokens current-position) amount),
      collateral-locked: (+ (get collateral-locked current-position) required-collateral)
    })
    
    ;; Update total supply for this asset
    (let ((current-supply (default-to u0 (map-get? token-supplies asset-id))))
      (map-set token-supplies asset-id (+ current-supply amount))
    )
    
    (print {action: "mint", user: tx-sender, asset-id: asset-id, amount: amount, collateral: required-collateral})
    (ok true)
  )
)

(define-public (burn-synthetic (asset-id uint) (amount uint))
  (let (
    (asset-data (unwrap! (map-get? synthetic-assets asset-id) ERR_ASSET_NOT_FOUND))
    (asset-price (get price (unwrap! (map-get? asset-prices asset-id) ERR_ASSET_NOT_FOUND)))
    (current-position (unwrap! (map-get? user-positions {user: tx-sender, asset-id: asset-id}) ERR_INSUFFICIENT_BALANCE))
    (collateral-to-return (/ (* amount (get collateral-locked current-position)) (get synthetic-tokens current-position)))
  )
    (asserts! (>= (get synthetic-tokens current-position) amount) ERR_INSUFFICIENT_BALANCE)
    (asserts! (>= (ft-get-balance synthmint-token tx-sender) amount) ERR_INSUFFICIENT_BALANCE)
    
    ;; Burn synthetic tokens
    (try! (ft-burn? synthmint-token amount tx-sender))
    
    ;; Return collateral
    (try! (as-contract (stx-transfer? collateral-to-return tx-sender tx-sender)))
    
    ;; Update position
    (let ((remaining-tokens (- (get synthetic-tokens current-position) amount))
          (remaining-collateral (- (get collateral-locked current-position) collateral-to-return)))
      (if (is-eq remaining-tokens u0)
        (map-delete user-positions {user: tx-sender, asset-id: asset-id})
        (map-set user-positions {user: tx-sender, asset-id: asset-id} {
          synthetic-tokens: remaining-tokens,
          collateral-locked: remaining-collateral
        })
      )
    )
    
    ;; Update total supply
    (let ((current-supply (default-to u0 (map-get? token-supplies asset-id))))
      (map-set token-supplies asset-id (- current-supply amount))
    )
    
    (print {action: "burn", user: tx-sender, asset-id: asset-id, amount: amount, collateral-returned: collateral-to-return})
    (ok true)
  )
)

;; Trading Functions
(define-public (trade-synthetic (from-asset uint) (to-asset uint) (amount uint))
  (let (
    (from-asset-data (unwrap! (map-get? synthetic-assets from-asset) ERR_ASSET_NOT_FOUND))
    (to-asset-data (unwrap! (map-get? synthetic-assets to-asset) ERR_ASSET_NOT_FOUND))
    (from-price (get price (unwrap! (map-get? asset-prices from-asset) ERR_ASSET_NOT_FOUND)))
    (to-price (get price (unwrap! (map-get? asset-prices to-asset) ERR_ASSET_NOT_FOUND)))
    (trade-value (* amount from-price))
    (to-amount (/ trade-value to-price))
  )
    (asserts! (get active from-asset-data) ERR_ASSET_NOT_FOUND)
    (asserts! (get active to-asset-data) ERR_ASSET_NOT_FOUND)
    (asserts! (>= (ft-get-balance synthmint-token tx-sender) amount) ERR_INSUFFICIENT_BALANCE)
    (asserts! (> to-amount u0) ERR_INVALID_AMOUNT)
    
    ;; This is a simplified trading mechanism - in practice you'd want more sophisticated logic
    ;; For now, we'll burn the from-asset tokens and mint to-asset tokens
    (try! (ft-burn? synthmint-token amount tx-sender))
    (try! (ft-mint? synthmint-token to-amount tx-sender))
    
    (print {action: "trade", user: tx-sender, from-asset: from-asset, to-asset: to-asset, 
            from-amount: amount, to-amount: to-amount})
    (ok to-amount)
  )
)

;; Query Functions
(define-read-only (get-user-position (user principal) (asset-id uint))
  (map-get? user-positions {user: user, asset-id: asset-id})
)

(define-read-only (get-asset-supply (asset-id uint))
  (default-to u0 (map-get? token-supplies asset-id))
)

(define-read-only (get-collateral-ratio)
  (var-get collateral-ratio)
)

(define-read-only (is-oracle-authorized (oracle principal))
  (default-to false (map-get? authorized-oracles oracle))
)

;; Administrative Functions
(define-public (set-collateral-ratio (new-ratio uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_OWNER_ONLY)
    (asserts! (>= new-ratio u100) ERR_INVALID_AMOUNT) ;; Minimum 100% collateralization
    (var-set collateral-ratio new-ratio)
    (print {action: "collateral-ratio-updated", new-ratio: new-ratio})
    (ok true)
  )
)

(define-public (toggle-asset-status (asset-id uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_OWNER_ONLY)
    (match (map-get? synthetic-assets asset-id)
      asset-data (begin
        (map-set synthetic-assets asset-id (merge asset-data {
          active: (not (get active asset-data))
        }))
        (print {action: "asset-status-toggled", asset-id: asset-id, active: (not (get active asset-data))})
        (ok true)
      )
      ERR_ASSET_NOT_FOUND
    )
  )
)