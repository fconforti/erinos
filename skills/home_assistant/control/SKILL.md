---
name: ha-control
description: "Home Assistant: Control devices, check states, call services."
---

# Home Assistant

Control Home Assistant via its REST API using curl. The base URL and long-lived access token are available as `$HA_URL` and `$HA_TOKEN`.

## Setup

If not connected, guide the user through these steps:

1. Ask the user for their Home Assistant URL (e.g. `http://192.168.1.100:8123`).
2. Ask them to create a long-lived access token:
   - Go to their HA profile page (click username bottom-left)
   - Scroll to "Long-Lived Access Tokens"
   - Click "Create Token", name it "erinos", copy the token
3. Store both using store_credential with `{"url": "...", "token": "..."}`.

## Common Headers

```bash
-H "Authorization: Bearer $HA_TOKEN" -H "Content-Type: application/json"
```

## Endpoints

### Check API

```bash
curl -s -H "Authorization: Bearer $HA_TOKEN" "$HA_URL/api/"
```

### List all entity states

```bash
curl -s -H "Authorization: Bearer $HA_TOKEN" "$HA_URL/api/states"
```

Returns a large JSON array. Pipe through `jq` to filter:

```bash
curl -s -H "Authorization: Bearer $HA_TOKEN" "$HA_URL/api/states" | jq '[.[] | {entity_id, state}]'
```

### Get a specific entity state

```bash
curl -s -H "Authorization: Bearer $HA_TOKEN" "$HA_URL/api/states/light.living_room"
```

### Call a service

This is the main way to control devices.

```bash
curl -s -X POST -H "Authorization: Bearer $HA_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"entity_id": "light.living_room"}' \
  "$HA_URL/api/services/light/turn_on"
```

Common services:

| Domain | Service | Description |
|--------|---------|-------------|
| `light` | `turn_on` | Turn on (optional: `brightness` 0-255, `color_name`, `rgb_color`) |
| `light` | `turn_off` | Turn off |
| `switch` | `turn_on` | Turn on |
| `switch` | `turn_off` | Turn off |
| `climate` | `set_temperature` | Set target temp (`temperature` field) |
| `climate` | `set_hvac_mode` | Set mode: `heat`, `cool`, `auto`, `off` |
| `cover` | `open_cover` | Open blinds/garage |
| `cover` | `close_cover` | Close blinds/garage |
| `media_player` | `media_play` | Play |
| `media_player` | `media_pause` | Pause |
| `media_player` | `volume_set` | Set volume (`volume_level` 0.0-1.0) |
| `lock` | `lock` | Lock |
| `lock` | `unlock` | Unlock |
| `scene` | `turn_on` | Activate a scene |
| `automation` | `trigger` | Trigger an automation |

### Turn on a light with brightness and color

```bash
curl -s -X POST -H "Authorization: Bearer $HA_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"entity_id": "light.bedroom", "brightness": 200, "color_name": "blue"}' \
  "$HA_URL/api/services/light/turn_on"
```

### List available services

```bash
curl -s -H "Authorization: Bearer $HA_TOKEN" "$HA_URL/api/services"
```

### Fire an event

```bash
curl -s -X POST -H "Authorization: Bearer $HA_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}' \
  "$HA_URL/api/events/custom_event"
```

### Render a template

```bash
curl -s -X POST -H "Authorization: Bearer $HA_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"template": "{{ states.light.living_room.state }}"}' \
  "$HA_URL/api/template"
```

### History

```bash
curl -s -H "Authorization: Bearer $HA_TOKEN" \
  "$HA_URL/api/history/period/2024-01-01T00:00:00?filter_entity_id=light.living_room"
```
