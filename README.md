# SynthMint Protocol

A decentralized protocol for creating and trading synthetic assets that track real-world prices without requiring ownership of the underlying assets. Built on the Stacks blockchain using Clarity smart contracts.

## Contract Address

ST2GVG4N2NREJFN8RGEPARFHCR4N07HZ96R1TJ7DN.SynthMintProtocol

<img width="1919" height="832" alt="{3B7622A0-4712-46F6-95D5-EB7903117806}" src="https://github.com/user-attachments/assets/9c4e2df4-ca41-4621-a92b-6ea56d74ca53" />


## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [Smart Contract Functions](#smart-contract-functions)
- [Oracle Integration](#oracle-integration)
- [Testing](#testing)
- [Deployment](#deployment)
- [Security Considerations](#security-considerations)
- [Contributing](#contributing)
- [License](#license)

## 🌟 Overview

SynthMint Protocol enables users to mint synthetic tokens that represent real-world assets like stocks, commodities, currencies, and indices. These synthetic assets maintain their value correlation with the underlying assets through oracle price feeds, while users provide STX tokens as collateral to maintain system stability.

### Key Benefits

- **No Direct Ownership Required**: Trade exposure to assets without owning them
- **24/7 Trading**: Synthetic assets can be traded anytime
- **Global Access**: Access to international markets through blockchain
- **Collateralized System**: Over-collateralized positions ensure system stability
- **Decentralized Oracles**: Multiple oracle sources for price reliability

## ✨ Features

### Core Functionality
- **Synthetic Asset Creation**: Create tokens representing any real-world asset
- **Collateralized Minting**: Mint synthetic tokens with STX collateral
- **Price Oracle Integration**: Real-time price updates from authorized oracles
- **Trading System**: Exchange between different synthetic assets
- **Position Management**: Full control over collateral and token positions

### Administrative Features
- **Oracle Management**: Authorize and revoke oracle access
- **Collateral Ratio Control**: Adjust system-wide collateralization requirements
- **Asset Management**: Create, activate, or deactivate synthetic assets

### Security Features
- **Over-collateralization**: Default 150% collateral ratio
- **Oracle Authorization**: Only trusted oracles can update prices
- **Owner Controls**: Administrative functions restricted to contract owner
- **Input Validation**: Comprehensive checks on all user inputs

## 🏗 Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Price Oracles │    │  SynthMint Core  │    │  Synthetic      │
│                 │────│                  │────│  Assets         │
│ - Stock APIs    │    │ - Collateral     │    │ - sAAPL         │
│ - Commodity     │    │ - Minting        │    │ - sGOLD         │
│ - Forex         │    │ - Trading        │    │ - sOIL          │
└─────────────────┘    └──────────────────┘    └─────────────────┘
        │                        │                        │
        │                        │                        │
        ▼                        ▼                        ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   STX Blockchain│    │  User Interface  │    │  Trading        │
│                 │    │                  │    │  Platform       │
│ - Transactions  │    │ - Portfolio      │    │ - DEX           │
│ - Smart Contract│    │ - Analytics      │    │ - AMM           │
│ - Consensus     │    │ - Trading        │    │ - Liquidity     │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## 📋 Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) - Stacks smart contract development tool
- [Node.js](https://nodejs.org/) (v16 or higher)
- [Git](https://git-scm.com/)
- Basic understanding of Clarity programming language
- STX tokens for testing and deployment

## 🚀 Installation

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/synthmint-protocol.git
cd synthmint-protocol
```

### 2. Install Clarinet

```bash
# macOS
brew install clarinet

# Or download from GitHub releases
# https://github.com/hirosystems/clarinet/releases
```

### 3. Initialize the Project

```bash
clarinet new synthmint-protocol
cd synthmint-protocol
```

### 4. Add the Smart Contract

Copy the `synthmint-protocol.clar` file to the `contracts/` directory.

### 5. Configure Clarinet.toml

```toml
[project]
name = "synthmint-protocol"
description = "Synthetic asset protocol on Stacks"
authors = ["Your Name <your.email@example.com>"]
telemetry = false
cache_dir = "./.clarinet"

[contracts.synthmint-protocol]
path = "contracts/synthmint-protocol.clar"
depends_on = []

[repl]
costs_version = 2
parser_version = 2

[[repl.analysis.check_checker]]
strict = false
trusted_sender = false
trusted_caller = false
callee_filter = false
```

## 💻 Usage

### Starting the Development Environment

```bash
# Start Clarinet console
clarinet console

# Run tests
clarinet test

# Check contract syntax
clarinet check
```

### Basic Operations

#### 1. Create a Synthetic Asset (Owner Only)

```clarity
;; Create synthetic Apple stock
(contract-call? .synthmint-protocol create-synthetic-asset "Synthetic Apple" "sAAPL" u150000000)

;; Create synthetic Gold
(contract-call? .synthmint-protocol create-synthetic-asset "Synthetic Gold" "sGOLD" u2000000000)
```

#### 2. Authorize Price Oracle (Owner Only)

```clarity
;; Authorize an oracle
(contract-call? .synthmint-protocol authorize-oracle 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE)
```

#### 3. Update Asset Price (Oracle Only)

```clarity
;; Update Apple stock price to $150
(contract-call? .synthmint-protocol update-price u1 u150000000)
```

#### 4. Mint Synthetic Tokens

```clarity
;; Mint 100 sAAPL tokens (requires STX collateral)
(contract-call? .synthmint-protocol mint-synthetic u1 u100000000)
```

#### 5. Trade Synthetic Assets

```clarity
;; Trade 50 sAAPL for sGOLD
(contract-call? .synthmint-protocol trade-synthetic u1 u2 u50000000)
```

#### 6. Burn Tokens and Reclaim Collateral

```clarity
;; Burn 50 sAAPL tokens
(contract-call? .synthmint-protocol burn-synthetic u1 u50000000)
```

## 📚 Smart Contract Functions

### Public Functions

| Function | Description | Parameters | Returns |
|----------|-------------|------------|---------|
| `create-synthetic-asset` | Create new synthetic asset | `name`, `symbol`, `initial-price` | `asset-id` |
| `mint-synthetic` | Mint synthetic tokens with collateral | `asset-id`, `amount` | `bool` |
| `burn-synthetic` | Burn tokens and reclaim collateral | `asset-id`, `amount` | `bool` |
| `trade-synthetic` | Trade between synthetic assets | `from-asset`, `to-asset`, `amount` | `uint` |
| `update-price` | Update asset price (oracle only) | `asset-id`, `new-price` | `bool` |
| `transfer` | Transfer tokens between users | `amount`, `sender`, `recipient`, `memo` | `bool` |
| `authorize-oracle` | Authorize price oracle (owner only) | `oracle` | `bool` |
| `set-collateral-ratio` | Set collateralization ratio (owner only) | `new-ratio` | `bool` |

### Read-Only Functions

| Function | Description | Returns |
|----------|-------------|---------|
| `get-balance` | Get user's token balance | `uint` |
| `get-synthetic-asset` | Get asset information | `asset-data` |
| `get-asset-price` | Get current asset price | `price-data` |
| `get-user-position` | Get user's position details | `position-data` |
| `get-total-supply` | Get total token supply | `uint` |
| `get-collateral-ratio` | Get current collateral ratio | `uint` |

## 🔮 Oracle Integration

### Oracle Requirements

Oracles must be authorized by the contract owner and are responsible for:
- Providing accurate, real-time price data
- Regular price updates to prevent stale data
- Maintaining high availability and reliability

### Price Update Format

```clarity
;; Price should be in micro-units (6 decimals)
;; Example: $150.50 = 150500000 micro-units
(contract-call? .synthmint-protocol update-price u1 u150500000)
```

### Oracle Authorization

```bash
# Only contract owner can authorize oracles
clarinet console
>>> (contract-call? .synthmint-protocol authorize-oracle 'ST1ORACLE_ADDRESS)
```

## 🧪 Testing

### Running Tests

```bash
# Run all tests
clarinet test

# Run specific test file
clarinet test tests/synthmint_test.ts
```

### Sample Test Structure

```typescript
import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can create synthetic asset",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('synthmint-protocol', 'create-synthetic-asset', [
                types.ascii("Synthetic Apple"),
                types.ascii("sAAPL"),
                types.uint(150000000)
            ], deployer.address)
        ]);
        
        assertEquals(block.receipts.length, 1);
        assertEquals(block.receipts[0].result.expectOk(), types.uint(1));
    },
});
```

## 🚀 Deployment

### Testnet Deployment

```bash
# Deploy to testnet
clarinet deploy --testnet

# Verify deployment
clarinet console --testnet
```

### Mainnet Deployment

```bash
# Deploy to mainnet (requires STX)
clarinet deploy --mainnet

# Monitor deployment
stacks-cli status
```

### Post-Deployment Setup

1. **Authorize Oracles**: Add trusted oracle addresses
2. **Create Initial Assets**: Set up synthetic assets for trading
3. **Set Parameters**: Configure collateral ratios and fees
4. **Test Functionality**: Verify all functions work correctly

## 🔒 Security Considerations

### Smart Contract Security

- **Over-collateralization**: Maintains 150% collateral ratio to prevent undercollateralized positions
- **Oracle Security**: Only authorized oracles can update prices
- **Access Control**: Administrative functions restricted to contract owner
- **Input Validation**: All inputs are validated for type and range
- **Reentrancy Protection**: Uses Clarity's built-in protections

### Operational Security

- **Oracle Reliability**: Use multiple oracle sources for price feeds
- **Price Staleness**: Monitor oracle updates for freshness
- **Collateral Monitoring**: Track collateral ratios across all positions
- **Emergency Controls**: Implement circuit breakers for unusual conditions

### Risk Management

- **Liquidation Mechanisms**: Consider implementing automatic liquidations
- **Price Volatility**: Monitor for rapid price changes
- **Oracle Failures**: Plan for oracle outages or incorrect data
- **Market Risks**: Understand correlation risks between synthetic and real assets

## 🤝 Contributing

### Development Process

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Write** comprehensive tests for your changes
4. **Commit** your changes (`git commit -m 'Add amazing feature'`)
5. **Push** to the branch (`git push origin feature/amazing-feature`)
6. **Open** a Pull Request

### Code Standards

- Follow Clarity best practices and conventions
- Write comprehensive tests for all new functionality
- Include documentation for new features
- Ensure all tests pass before submitting PR

### Areas for Contribution

- **Liquidation System**: Implement automatic liquidations for undercollateralized positions
- **Governance**: Add DAO governance for protocol parameters
- **Advanced Trading**: Implement limit orders and advanced trading features
- **UI/UX**: Build user-friendly interfaces for the protocol
- **Oracle Integration**: Add more oracle providers and aggregation logic

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🚧 Roadmap

### Phase 1 (Current)
- [x] Basic synthetic asset creation
- [x] Collateralized minting system
- [x] Oracle price feeds
- [x] Basic trading functionality

### Phase 2 (Q2 2024)
- [ ] Liquidation system
- [ ] Advanced trading features
- [ ] Multi-oracle price aggregation
- [ ] Governance token and DAO

### Phase 3 (Q3 2024)
- [ ] Cross-chain integration
- [ ] Derivatives and options
- [ ] Institutional features
- [ ] Mobile application

---

**⚠️ Disclaimer**: This protocol is experimental software. Use at your own risk. Always conduct thorough testing and audits before deploying to mainnet or using with real funds.
