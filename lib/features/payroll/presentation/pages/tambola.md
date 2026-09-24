# HR MANAGEMENT — ENTERPRISE GAME ZONE & TAMBOLA MULTIPLAYER ENGINE

## 1. System Architecture & Overview

The **Enterprise Game Zone** is an extensible, modular in-app social and engagement platform built seamlessly into the existing HR Management application. It empowers organizations to foster workplace connection through real-time multiplayer games, backed by robust role-based access control, admin governance, and high-performance WebSocket messaging.

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           HR Management Application                             │
│                                                                                 │
│   ┌─────────────────────────────────────────────────────────────────────────┐   │
│   │                        Sidebar Navigation ("Game Zone")                 │   │
│   └────────────────────────────────────┬────────────────────────────────────┘   │
│                                        │                                        │
│                                        ▼                                        │
│   ┌─────────────────────────────────────────────────────────────────────────┐   │
│   │                       Game Directory (/games)                           │   │
│   │                                                                         │   │
│   │  • Extensible Card Catalog (Tambola Housie, Trivia, Chess, etc.)         │   │
│   │  • Super Admin / HR Controls: Enable/Disable Switch, Role Governance    │   │
│   │  • Employee Controls: Play Now (Enabled) / Disabled State + Toast       │   │
│   └────────────────────────────────────┬────────────────────────────────────┘   │
│                                        │                                        │
│                                        ▼                                        │
│   ┌─────────────────────────────────────────────────────────────────────────┐   │
│   │                       Tambola Multiplayer Hub                           │   │
│   │                                                                         │   │
│   │   [Create Room] ───► Host Lobby ───► Real-Time Game Board              │   │
│   │   [Join Room]   ───► Player Lobby ──► Ticket & Draw Matrix              │   │
│   └────────────────────────────────────┬────────────────────────────────────┘   │
│                                        │                                        │
│                                        ▼                                        │
│   ┌─────────────────────────────────────────────────────────────────────────┐   │
│   │                      Game Completion & Lifecycle                        │   │
│   │                                                                         │   │
│   │   All Houses Claimed ──► Game Over Modal (Podium & Winners List)         │   │
│   │                          ├── [Exit] ───► Return to Game Zone            │   │
│   │                          └── [Restart] ─► Reset Draws & Fresh Tickets   │   │
│   └─────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Database Schema & Models

### A. Company Games (`company_games`)
Stores metadata, global switch state, and role restrictions for all games in the platform.

| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | `BIGINT PRIMARY KEY` | Auto-increment identifier |
| `game_key` | `VARCHAR(64) UNIQUE` | Unique identifier (e.g. `TAMBOLA`) |
| `title` | `VARCHAR(128)` | User-facing display title |
| `description` | `TEXT` | Game summary and rules |
| `icon_name` | `VARCHAR(64)` | Material icon identifier |
| `route_path` | `VARCHAR(128)` | Frontend navigation route |
| `is_enabled` | `BOOLEAN` | Global active toggle |
| `allowed_roles` | `VARCHAR(255)` | Comma-separated list of permitted roles (`ALL`, `SUPER_ADMIN`, `HR_MANAGER`, `EMPLOYEE`) |
| `min_players` | `INT` | Minimum required players to start |
| `max_players` | `INT` | Maximum room capacity |

### B. Tambola Game Room (`tambola_game`)
| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | `BIGINT PRIMARY KEY` | Auto-increment identifier |
| `room_code` | `VARCHAR(16) UNIQUE` | 6-character unique join code |
| `host_id` | `BIGINT (FK)` | Host employee identifier |
| `company_id` | `BIGINT (FK)` | Multi-tenant organization reference |
| `status` | `VARCHAR(32)` | `WAITING`, `RUNNING`, `COMPLETED` |
| `draw_mode` | `VARCHAR(32)` | `MANUAL`, `AUTOMATIC` |
| `auto_draw_interval_seconds` | `INT` | Draw frequency in seconds |
| `current_number` | `INT` | Last drawn number (1-90) |

### C. Tambola Tickets (`tambola_ticket`)
| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | `BIGINT PRIMARY KEY` | Auto-increment identifier |
| `game_id` | `BIGINT (FK)` | Reference to game room |
| `player_id` | `BIGINT (FK)` | Player identifier |
| `ticket_index` | `INT` | Ticket order index |
| `matrix_json` | `TEXT` | 3x9 grid matrix stored as JSON array |

### D. Tambola Draws (`tambola_draw`)
| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | `BIGINT PRIMARY KEY` | Auto-increment identifier |
| `game_id` | `BIGINT (FK)` | Reference to game room |
| `number` | `INT` | Drawn number (1-90) |
| `sequence` | `INT` | Sequential draw order |
| `drawn_at` | `TIMESTAMP` | Timestamp of draw |

### E. Tambola Winners (`tambola_winner`)
| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | `BIGINT PRIMARY KEY` | Auto-increment identifier |
| `game_id` | `BIGINT (FK)` | Reference to game room |
| `player_id` | `BIGINT (FK)` | Winning player |
| `winning_category` | `VARCHAR(64)` | `FIRST_HOUSE`, `SECOND_HOUSE`, `THIRD_HOUSE`, `FULL_HOUSE` |
| `claimed_at` | `TIMESTAMP` | Timestamp of claim |

---

## 3. Real-Time Gameplay Features

### 1. Animated Number Display & Shuffling Box
- **Live Showcase Card**: Positioned prominently above the player's ticket, displaying the current active number with dynamic glowing gradients.
- **Roll Animation**: Clicking "Draw Next Number" triggers a high-speed slot-machine style number shuffle before revealing the server's drawn number.
- **Cooldown Protection**: Enforces a 4-second client and server cooldown between number draws to maintain suspense and pacing.

### 2. Interactive Ticket Grid & Strict Anti-Cheat
- **Marking Validation**: Players can only stamp/mark numbers on their ticket that have **already been drawn** by the server. Tapping undrawn numbers triggers a subtle rejection vibration.
- **Server-Side Claim Verification**: When a player claims a prize (First House, Second House, Third House, Full House), the backend validates all numbers in the claim against the room's draw history in a single ACID transaction.

### 3. Claim Categories (2x2 Grid with Gradient Styling)
- Formatted as a high-density 2x2 grid saving screen real estate:
  - **First House** (Top Row)
  - **Second House** (Middle Row)
  - **Third House** (Bottom Row)
  - **Full House** (All 15 Numbers)
- **Haptic & Visual Feedback**: Rejections wiggle the card with error haptics; successful claims trigger full-screen victory confetti and update the live winner board.

### 4. Game Over Modal & Instant Round Restart
- **Auto-Detection**: When all winning categories are claimed, the game transitions to `COMPLETED` and pops up the Game Over dialog across all connected clients.
- **Winner Podium**: Shows winner names and avatar badges for each category.
- **Action Buttons**:
  - **Exit**: Unsubscribes from WebSocket, leaves room, and routes back to `/games`.
  - **Restart**: Host or players can trigger a round restart. Backend clears previous draws and winners, regenerates fresh randomized tickets for all players in the room, resets room status to `RUNNING`, and broadcasts a `GAME_RESTARTED` event.

---

## 4. API & WebSocket Specification

### REST Endpoints

#### Game Directory & Governance
- `GET /api/games` — Fetch all company games and access permissions.
- `PATCH /api/games/{gameKey}/status?enabled={bool}` — (Admin only) Enable or disable game.
- `PATCH /api/games/{gameKey}/access?roles={roles}` — (Admin only) Update allowed role list.

#### Tambola Room & Lifecycle
- `POST /api/tambola/create` — Create a new room.
- `POST /api/tambola/join` — Join an existing room with 6-digit code.
- `POST /api/tambola/game/{roomCode}/start` — Start game and generate tickets.
- `POST /api/tambola/game/{roomCode}/draw` — Draw next random number (1-90).
- `POST /api/tambola/game/{roomCode}/claim` — Claim a prize category.
- `POST /api/tambola/game/{roomCode}/restart` — Reset round and generate fresh tickets for active room players.

### WebSocket Topics (`/topic/game/{roomCode}`)

| Event Type | Payload | Trigger |
| :--- | :--- | :--- |
| `PLAYER_JOINED` | `{ playerId, playerName, playerCount }` | When a player enters lobby |
| `GAME_STARTED` | `{ status: "RUNNING" }` | When host clicks Start |
| `NUMBER_DRAWN` | `{ number, drawSequence, totalDrawn }` | When a number is drawn |
| `PRIZE_CLAIMED` | `{ category, winnerName, prizeStatus }` | When a prize claim succeeds |
| `GAME_COMPLETED` | `{ winners: [...] }` | When all categories are claimed |
| `GAME_RESTARTED` | `{ status: "RUNNING", message }` | When a new round is started |

---

## 5. Security & System Design Best Practices

1. **Role-Based Access Control**:
   - Company game access is checked during room creation and join requests against JWT role claims (`SUPER_ADMIN`, `HR_MANAGER`, `EMPLOYEE`).
2. **Concurrency & Thread Safety**:
   - Room number draws utilize thread-safe collections and transactional isolation to avoid duplicate draws or race conditions.
3. **Database Query Optimization**:
   - Indexed lookups on `room_code`, `company_id`, and `player_id`.
   - Batch ticket insertion and cascade cleanup for round restarts.
