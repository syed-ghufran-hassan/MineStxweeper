;; ================================================================
;; ACHIEVEMENT NFT CONTRACT (PRODUCTION SIP-009 SOULBOUND)
;; ================================================================

;; Uncomment for mainnet
;; (impl-trait 'SP2PABAF9FTAJYNFZH93XENAJ8FVY99RRM50D2JG9.nft-trait.nft-trait)

;; ================================================================
;; CONSTANTS
;; ================================================================

(define-constant ERR-NOT-AUTHORIZED (err u600))
(define-constant ERR-NOT-FOUND (err u601))
(define-constant ERR-ALREADY-MINTED (err u602))
(define-constant ERR-INVALID-ACHIEVEMENT (err u603))

;; ================================================================
;; DATA VARS
;; ================================================================

(define-data-var contract-owner principal tx-sender)
(define-data-var last-token-id uint u0)

;; ================================================================
;; DATA MAPS
;; ================================================================

(define-map token-owners
  { token-id: uint }
  { owner: principal }
)

(define-map player-achievements
  { player: principal, achievement-id: uint }
  {
    token-id: uint,
    earned-at: uint,
    game-id: (optional uint)
  }
)

(define-map achievement-metadata
  { achievement-id: uint }
  {
    name: (string-ascii 50),
    description: (string-ascii 200),
    rarity: (string-ascii 20),
    category: (string-ascii 20),
    image-uri: (string-ascii 256)
  }
)

;; ================================================================
;; PRIVATE HELPERS
;; ================================================================

(define-private (assert-owner)
  (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
)

(define-private (validate-achievement (achievement-id uint))
  (asserts!
    (is-some (map-get? achievement-metadata {achievement-id: achievement-id}))
    ERR-INVALID-ACHIEVEMENT
  )
)

(define-private (mint-achievement (player principal) (achievement-id uint) (game-id (optional uint)))
  (let (
        (existing (map-get? player-achievements {player: player, achievement-id: achievement-id}))
        (new-token-id (+ (var-get last-token-id) u1))
       )
    (asserts! (is-none existing) ERR-ALREADY-MINTED)

    (map-set token-owners
      {token-id: new-token-id}
      {owner: player}
    )

    (map-set player-achievements
      {player: player, achievement-id: achievement-id}
      {
        token-id: new-token-id,
        earned-at: block-height,
        game-id: game-id
      }
    )

    (var-set last-token-id new-token-id)

    (print {
      event: "achievement-awarded",
      player: player,
      achievement-id: achievement-id,
      token-id: new-token-id
    })

    (ok new-token-id)
  )
)

;; ================================================================
;; SIP-009 IMPLEMENTATION
;; ================================================================

(define-read-only (get-last-token-id)
  (ok (var-get last-token-id))
)

(define-read-only (get-token-uri (token-id uint))
  (match (map-get? token-owners {token-id: token-id})
    owner-data
      (ok (some "ipfs://QmAchievementMetadata/{id}"))
    (ok none)
  )
)

(define-read-only (get-owner (token-id uint))
  (match (map-get? token-owners {token-id: token-id})
    owner-data (ok (some (get owner owner-data)))
    (ok none)
  )
)

;; Soulbound — permanently non-transferable
(define-public (transfer (token-id uint) (sender principal) (recipient principal))
  ERR-NOT-AUTHORIZED
)

;; ================================================================
;; ACHIEVEMENT AWARDING
;; ================================================================

;; Only authorized game contracts OR owner may award
(define-public (award-achievement (player principal) (achievement-id uint) (game-id (optional uint)))
  (begin
    (assert-owner)
    (validate-achievement achievement-id)

    (mint-achievement player achievement-id game-id)
  )
)

;; Safe external-triggered achievement check
(define-public (check-and-award (player principal) (achievement-id uint) (game-id (optional uint)))
  (begin
    (assert-owner)
    (validate-achievement achievement-id)

    (mint-achievement player achievement-id game-id)
  )
)

;; ================================================================
;; READ-ONLY
;; ================================================================

(define-read-only (has-achievement (player principal) (achievement-id uint))
  (is-some (map-get? player-achievements {player: player, achievement-id: achievement-id}))
)

(define-read-only (get-achievement-info (achievement-id uint))
  (ok (map-get? achievement-metadata {achievement-id: achievement-id}))
)

;; ================================================================
;; ADMIN
;; ================================================================

(define-public (set-metadata
  (achievement-id uint)
  (name (string-ascii 50))
  (description (string-ascii 200))
  (rarity (string-ascii 20))
  (category (string-ascii 20))
  (image-uri (string-ascii 256))
)
  (begin
    (assert-owner)

    (map-set achievement-metadata
      {achievement-id: achievement-id}
      {
        name: name,
        description: description,
        rarity: rarity,
        category: category,
        image-uri: image-uri
      }
    )

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
