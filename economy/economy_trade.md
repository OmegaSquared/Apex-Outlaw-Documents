# MMO Economy & Trade Systems TDD

## 1. Core Economic Philosophy
The game does not force players into every activity. The economy is structured to create extreme inter-dependency between player roles:
- **Researchers** find Blueprints but need raw materials.
- **Miners** gather raw materials but need protection and hauling.
- **Transporters** move goods from cheap sectors to expensive Hubs but need escorts.
- **Pirates/Privateers** force the need for escorts by taking cargo by force.

---

## 2. Hub Cities & Dynamic Pricing
Every sector has a neutral Federation or Mars hub functioning as a marketplace. The Hub does not have infinite money or static item values.

- **The Scarcity Formula:** 
  `SalePrice = BaseValue * (CurrentStock / TargetStock)`
- **Logic:** If a Hub wants 10,000 units of Iron, the first 1,000 units delivered will pay a massive premium. As the stock fills, the purchase price drops to pennies. Players must use the Nav-Computer to haul ore to distant Hubs that are starving for resources.

---

## 3. Taxation & Sinks
To combat MMO inflation, currency must constantly be destroyed.

- **The 3% Universal Escrow:** All market transactions, direct P2P trades, and contract postings incur a permanent 3% fee deleted from the game.
- **The 35% Federation Hub Tax:** Using a public City refining lab or crafting table strips 35% of the efficiency away globally (compared to owning a private Alliance Citadel).

---

## 4. Private Contracts (P2P Board)
Players can post jobs with Escrow guarantees.
- **Courier Run:** Player A places an item in Escrow, sets a destination, and offers 10,000 credits. Player B assigns themselves to the contract. If Player B dies to pirates, they forfeit a collateral fee to Player A. If they succeed, they get the 10,000 credits.
- **Bounty Systems:** Hired hits on Outlaw players with High Wanted Levels.

---

## 5. Alliance Diplomacy & Tariffs
Alliance Citadels feature their own markets. Leaders can set diplomatic standings with outsiders that dynamically affect the economy:
- **Ally:** 0% Premium overhead on market items.
- **Neutral:** 15% Premium overhead.
- **Rival:** 100%+ Premium overhead.
- **Hostile:** Embargoed (Market access completely denied).
All Premium overheads collected are deposited entirely into the Alliance Vault to fund Citadel upgrades and NPC defense fleets.
