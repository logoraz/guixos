# gubar Custom Blocks

Custom gubar blocks developed as enhancements to the upstream
`gubar` project. Both blocks replace interval-based polling with
event-driven updates using `guile-fibers` and the self-signal
pattern, eliminating unnecessary CPU wakeups.

---

## Design Pattern: Event-Driven Blocks

Upstream gubar blocks use `#:interval N` to poll for state changes
every N seconds. The blocks here instead use `#:interval 'persistent`
combined with a dedicated fiber that signals the block only when
state actually changes.

The pattern:

1. Spawn a fiber that watches an event source (external process or
   timer boundary)
2. On each event, send `SIGRTMIN+N` to self via `(kill pid (+ signal SIGRTMIN))`
3. The gublock's signal handler fires `do-procedure`, updating the
   bar only when needed

This matches the pattern already used by `volume-pipewire` and
`brightness` for keybind-triggered updates, extended here to
process-driven event sources.

---

## `network-manager` — Network Status Block

Replaces `network-manager-wifi` with a unified block that detects
ethernet, wifi, and disconnected states. Updates are driven by
`nmcli monitor` — a persistent subprocess that emits a line
whenever NetworkManager detects a connection change.

### Features

- Detects active ethernet connection (shown as `󰈀`)
- Falls back to wifi with signal strength icon when no ethernet
- Shows disconnected icon `󰤭` when neither is active
- Optionally displays SSID alongside signal icon
- Event-driven via `nmcli monitor` — zero polling

### Usage

```scheme
(use-modules (gubar blocks network-manager))

;; Icon only (default)
(network-manager)

;; Show SSID alongside signal icon
(network-manager #:ssid #t)

;; Custom signal number (default: 5)
(network-manager #:ssid #t #:signal 5)
```

### Icons

| State        | Icon |
|--------------|------|
| Ethernet     | 󰈀    |
| Wifi (weak)  | 󰤟    |
| Wifi (low)   | 󰤢    |
| Wifi (good)  | 󰤥    |
| Wifi (full)  | 󰤨    |
| Disconnected | 󰤭    |

### Implementation Notes

- `get-ethernet-status` runs `nmcli -t -f TYPE,STATE device status`
  and matches on `ethernet:connected`
- `get-wifi-status` runs `nmcli -t -f SSID,IN-USE,SIGNAL device wifi list`
  and matches the active entry (`*` in `IN-USE` field)
- Ethernet takes priority over wifi in `get-status`
- The monitor fiber runs `nmcli monitor` as a persistent pipe and
  self-signals on each output line

---

## `date-time-2` — Drift-Free Clock Block

Replaces the interval-based `date-time` block with a boundary-aligned
clock that wakes up precisely at each second boundary rather than
every N seconds from an arbitrary start time.

### Problem with Interval Polling

The upstream `date-time` block uses `#:interval 1` which fires every
1 second from whenever gubar started. This drifts over time and
causes redundant updates mid-second when a sub-second interval is
used for smooth display.

### Solution: Second Boundary Alignment

A fiber computes the time remaining until the next whole second using
`gettimeofday`, sleeps exactly that duration via `fsleep`, then
self-signals. This ensures the clock updates exactly at the second
boundary with zero drift.

### Usage

```scheme
(use-modules (gubar blocks date-time-2))

;; Default format
(date-time-2)

;; Custom format
(date-time-2 #:format "%a %b %d %Y %-I:%M:%S %p")

;; Custom signal number (default: 6)
(date-time-2 #:format "%H:%M" #:signal 6)
```

### Implementation Notes

- `(gettimeofday)` returns `(seconds . microseconds)`
- Remaining time to next boundary: `(- 1.0 (/ microseconds 1000000.0))`
- `fsleep` from `(fibers timers)` yields the fiber without blocking
  the scheduler
- No sub-second interval needed — updates land exactly on the second

---

## Signal Number Convention

Default signal assignments to avoid conflicts:

| Block             | Default Signal |
|-------------------|----------------|
| `network-manager` | 5              |
| `date-time-2`     | 6              |

Override via `#:signal N` if these conflict with other blocks in
your config.
