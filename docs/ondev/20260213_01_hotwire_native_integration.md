# Hotwire Native Integration Documentation

**Date:** 2026-02-13
**Feature:** Native mobile app navigation structure

---

## Overview

The meppi-rails dashboard integrates with Hotwire Native for iOS and Android mobile applications. This enables native mobile apps to display the web-based dashboard with native navigation and performance.

---

## API Endpoint

**GET** `/api/v1/navigation`

Returns the navigation structure for native mobile apps.

### Response Format

```json
{
  "tabs": [
    {
      "id": "channel",
      "label": "Channel Price",
      "path": "/channel-comparison"
    },
    {
      "id": "competition",
      "label": "Competition",
      "path": "/competition"
    },
    {
      "id": "promotion",
      "label": "Promotion",
      "path": "/promotion"
    },
    {
      "id": "regional",
      "label": "Regional",
      "path": "/regional-price"
    }
  ]
}
```

---

## Native Navigation Structure

### Tab-Based Navigation

1. **Channel Price** - Compare prices across retail channels
2. **Competition** - Compare competing devices side by side
3. **Promotion** - Brand promotion timeline and discounts
4. **Regional** - Cross-country price comparison

### Navigation Features

- **Pull-to-refresh** on all list views
- **Native alerts** for price updates and errors
- **Offline caching** for recent data (30 days)
- **Deep linking** to specific features via URL paths

---

## Implementation

### Controller

`app/controllers/api/v1/native_bridge_controller.rb`

```ruby
class NativeBridgeController < ApplicationController
  def navigation
    render json: {
      tabs: [
        { id: 'channel', label: 'Channel Price', path: channel_comparison_path },
        { id: 'competition', label: 'Competition', path: competition_path },
        { id: 'promotion', label: 'Promotion', path: promotion_path },
        { id: 'regional', label: 'Regional', path: regional_price_path }
      ]
    }
  end
end
```

### Routes

`config/routes.rb`

```ruby
namespace :api do
  namespace :v1 do
    get '/navigation', to: 'native_bridge#navigation'
  end
end
```

---

## Mobile App Integration

### iOS (Swift)

```swift
struct NavigationTab: Codable {
  let id: String
  let label: String
  let path: String
}

struct NavigationResponse: Codable {
  let tabs: [NavigationTab]
}

// Fetch navigation
func loadNavigation() async throws -> NavigationResponse {
  let url = URL(string: "\(baseURL)/api/v1/navigation")!
  let (data, _) = try await URLSession.shared.data(from: url)

  return try JSONDecoder().decode(NavigationResponse.self, from: data)
}
```

### Android (Kotlin)

```kotlin
data class NavigationTab(
  val id: String,
  val label: String,
  val path: String
)

data class NavigationResponse(
  val tabs: List<NavigationTab>
)

// Fetch navigation
suspend fun loadNavigation(): NavigationResponse {
  val url = URL("$baseURL/api/v1/navigation")
  val json = url.readText()
  return Json { decodeFromString(json, NavigationResponse::class.java }
}
```

---

## Testing

Run native bridge tests:

```bash
bundle exec rspec spec/requests/native_bridge_spec.rb
```

Expected output: All tests pass

---

## Future Enhancements

1. **Push Notifications** - Notify native apps of price drops
2. **Biometric Auth** - Secure native authentication
3. **Offline Mode** - Detect network state and show cached data
4. **Native Analytics** - Track feature usage in native apps
