;; ============================================================
;; BOARD GENERATOR – PRODUCTION VERSION
;; Commit → Future Block Hash → Deterministic Mine Layout
;; ============================================================

;; ================= CONSTANTS =================

(define-constant ERR-NOT-AUTHORIZED (err u200))
(define-constant ERR-BOARD-NOT-FOUND (err u201))
(define-constant ERR-BOARD-ALREADY-EXISTS (err u202))
(define-constant ERR-BOARD-NOT-REVEALED (err u203))
(define-constant ERR-INVALID-PARAMETERS (err u204))
(define-constant ERR-TOO-EARLY (err u205))

;; ================= STATE =================

(define-data-var contract-owner principal tx-sender)
(define-data-var authorized-game principal tx-sender)

;; ================= MAPS =================

(define-map board-commitments
  { game-id: uint }
  {
    commit-hash: (buff 32),
    reveal-height: uint,
    revealed: bool,
    mine-count: uint,
    width: uint,
    height: uint,
    first-click-index: uint
  }
)

(define-map mine-cache
  { game-id: uint, cell-index: uint }
  { is-mine: bool }
)

;; ================= HELPERS =================

(define-private (assert-owner)
  (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
)

(define-private (assert-authorized)
  (asserts!
    (or
      (is-eq tx-sender (var-get contract-owner))
      (is-eq tx-sender (var-get authorized-game))
    )
    ERR-NOT-AUTHORIZED
  )
)

(define-private (coords-to-index (x uint) (y uint) (width uint))
  (+ (* y width) x)
)

(define-private (validate-board (width uint) (height uint) (mine-count uint))
  (begin
    (asserts! (> width u0) ERR-INVALID-PARAMETERS)
    (asserts! (> height u0) ERR-INVALID-PARAMETERS)
    (asserts! (> mine-count u0) ERR-INVALID-PARAMETERS)
    (asserts! (< mine-count (* width height)) ERR-INVALID-PARAMETERS)
    true
  )
)

;; ================= BOARD CREATION =================

(define-public (generate-board
  (game-id uint)
  (width uint)
  (height uint)
  (mine-count uint)
  (first-click-x uint)
  (first-click-y uint)
)
  (begin
    (assert-authorized)
    (validate-board width height mine-count)

    (asserts!
      (is-none (map-get? board-commitments { game-id: game-id }))
      ERR-BOARD-ALREADY-EXISTS
    )

    (let (
          (reveal-height (+ block-height u10))
          (first-click-index (coords-to-index first-click-x first-click-y width))
          (commit (sha256 (concat
              (unwrap-panic (to-consensus-buff? game-id))
              (unwrap-panic (to-consensus-buff? tx-sender))
          )))
         )

      (map-set board-commitments
        { game-id: game-id }
        {
          commit-hash: commit,
          reveal-height: reveal-height,
          revealed: false,
          mine-count: mine-count,
          width: width,
          height: height,
          first-click-index: first-click-index
        }
      )

      (print { event: "board-generated", game-id: game-id })
      (ok commit)
    )
  )
)

;; ================= RANDOMNESS =================

(define-private (compute-seed (game-id uint) (board tuple))
  (begin
    (asserts! (>= block-height (get reveal-height board)) ERR-TOO-EARLY)

    (let (
          (bh (unwrap-panic (get-block-info? id-header-hash (get reveal-height board))))
         )
      (sha256 (concat bh (get commit-hash board)))
    )
  )
)

(define-private (compute-is-mine (game-id uint) (cell-index uint) (board tuple))
  (let (
        (seed (compute-seed game-id board))
        (total (* (get width board) (get height board)))
        (cell-hash (sha256 (concat seed (unwrap-panic (to-consensus-buff? cell-index)))))
        (slice16 (unwrap-panic (slice? cell-hash u0 u16)))
        (rand (buff-to-uint-be slice16))
        (is-first (is-eq cell-index (get first-click-index board)))
       )
    (if is-first
        false
        (< (mod rand total) (get mine-count board))
    )
  )
)

;; ================= GAMEPLAY =================

(define-public (is-cell-mine (game-id uint) (cell-index uint))
  (let (
        (board (unwrap! (map-get? board-commitments { game-id: game-id }) ERR-BOARD-NOT-FOUND))
        (cached (map-get? mine-cache { game-id: game-id, cell-index: cell-index }))
       )
    (match cached
      cache (ok (get is-mine cache))
      (let (
            (result (compute-is-mine game-id cell-index board))
           )
        (map-set mine-cache
          { game-id: game-id, cell-index: cell-index }
          { is-mine: result }
        )
        (ok result)
      )
    )
  )
)

;; ================= REVEAL =================

(define-public (reveal-board (game-id uint))
  (let (
        (board (unwrap! (map-get? board-commitments { game-id: game-id }) ERR-BOARD-NOT-FOUND))
       )
    (asserts! (not (get revealed board)) ERR-INVALID-PARAMETERS)
    (asserts! (>= block-height (get reveal-height board)) ERR-TOO-EARLY)

    (map-set board-commitments
      { game-id: game-id }
      (merge board { revealed: true })
    )

    (print { event: "board-revealed", game-id: game-id })
    (ok true)
  )
)

;; ================= READ ONLY =================

(define-read-only (get-board (game-id uint))
  (map-get? board-commitments { game-id: game-id })
)

(define-read-only (verify-board (game-id uint))
  (let (
        (board (unwrap! (map-get? board-commitments { game-id: game-id }) ERR-BOARD-NOT-FOUND))
       )
    (if (< block-height (get reveal-height board))
        false
        true
    )
  )
)

;; ================= ADMIN =================

(define-public (set-authorized-game (game-contract principal))
  (begin
    (assert-owner)
    (var-set authorized-game game-contract)
    (ok true)
  )
)

(define-public (transfer-ownership (new-owner principal))
  (begin
    (assert-owner)
    (var-set contract-owner new-owner)
    (ok true)
  )
)
