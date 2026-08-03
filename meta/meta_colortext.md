# Apex Outlaw Commander Color Code Matrix

Apex Outlaw's social layer natively utilizes the `^1` color-coding prefix system. Players can assign powerful glowing hex colors to their Commander Names and Chat Messages by typing a caret (`^`) followed immediately by a number `0-9`.

When the C# Engine `PlayFabManager` receives string data from the server, it preserves the raw character blocks (`^1Darth ^4Vader`) inside the master JSON. However, directly before pushing that string to `TextMeshPro` displays (like the Top Navigation Bar, the Chat Pane, or the Global Leaderboard), it natively strips the caret codes and intercepts them into accurate Unity `<color=#HEX>` rich-text rendering wrappers.

### Official Color Code Mappings:

*   **`^0` - Stealth Black / Dark Grey** (`#2E2E2E`)
*   **`^1` - Outlaw Red** (`#FF3333`)
*   **`^2` - Neon Green** (`#33FF33`)
*   **`^3` - Gold / Yellow** (`#FFD700`)
*   **`^4` - Federation Blue** (`#3388FF`)
*   **`^5` - Void Cyan** (`#00FFFF`)
*   **`^6` - Magenta / Deep Purple** (`#FF00FF`)
*   **`^7` - Default Pure White** (`#FFFFFF`)
*   **`^8` - Gunmetal Grey** (`#808080`)
*   **`^9` - Solar Orange** (`#FFA500`)

### Formatting Examples:

*   `^1Ghost` renders identically as: **(Red) Ghost**
*   `^4Captain ^7America` renders identically as: **(Blue) Captain (White) America**
*   `^5Rogue^9Squadron` renders identically as: **(Cyan) Rogue (Orange) Squadron**

*Developer Note: This array will be actively referenced in the upcoming Dashboard UI engine scripts specifically handling text normalization during deserialization.*

