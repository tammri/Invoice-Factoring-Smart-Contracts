# 💼 Invoice Factoring Smart Contracts

> Transform unpaid invoices into instant liquidity with blockchain-powered factoring

## 🎯 Overview

This smart contract enables businesses to tokenize unpaid invoices and receive immediate liquidity by selling them to factors at a discounted rate. When clients pay the invoice, the factor receives the full payment amount, earning the difference as profit.

## ✨ Key Features

- 📄 **Invoice Tokenization** - Convert unpaid invoices into on-chain assets
- 💰 **Instant Liquidity** - Get immediate cash flow by factoring invoices
- 🔒 **Trustless Settlement** - Automated repayment when clients pay
- 📊 **Performance Tracking** - Monitor business and factor statistics
- 🛡️ **Secure Withdrawals** - Safe fund management system
- ⚙️ **Configurable Fees** - Adjustable platform and factoring rates

## 🏗️ Contract Architecture

### Core Components

**Data Structures:**
- `invoices` - Stores invoice details, status, and factoring information
- `business-stats` - Tracks business metrics (total invoices, factored amounts, repayments)
- `factor-stats` - Tracks factor metrics (investments, returns, active positions)
- `pending-withdrawals` - Manages withdrawable balances for all parties

**Key Functions:**
- `create-invoice` - Business creates a new invoice
- `factor-invoice` - Factor provides liquidity for an invoice
- `pay-invoice` - Client pays the invoice amount
- `claim-repayment` - Factor claims payment after invoice is paid
- `withdraw` - Users withdraw their available balance

## 🚀 Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Stacks wallet for testing

### Installation

```bash
git clone https://github.com/tammri/Invoice-Factoring-Smart-Contracts.git
cd Invoice-Factoring-Smart-Contracts
clarinet check
```

## 📖 Usage Guide

### 1️⃣ Create an Invoice

```clarity
(contract-call? .Invoice-Factoring-Smart-Contracts create-invoice 
  'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7    ;; client address
  u1000000                                         ;; amount in micro-STX
  u1440)                                           ;; blocks until due (~10 days)
```

### 2️⃣ Factor an Invoice

```clarity
(contract-call? .Invoice-Factoring-Smart-Contracts factor-invoice 
  u1                                               ;; invoice ID
  u500)                                            ;; factoring rate (5%)
```

This provides the business with 95% of the invoice value immediately (minus platform fee).

### 3️⃣ Pay an Invoice

```clarity
(contract-call? .Invoice-Factoring-Smart-Contracts pay-invoice 
  u1)                                              ;; invoice ID
```

Client pays the full invoice amount to the contract.

### 4️⃣ Claim Repayment

```clarity
(contract-call? .Invoice-Factoring-Smart-Contracts claim-repayment 
  u1)                                              ;; invoice ID
```

Factor marks the invoice as completed and their stats are updated.

### 5️⃣ Withdraw Funds

```clarity
(contract-call? .Invoice-Factoring-Smart-Contracts withdraw)
```

Withdraw your available balance to your wallet.

## 📊 Read-Only Functions

### Get Invoice Details
```clarity
(contract-call? .Invoice-Factoring-Smart-Contracts get-invoice u1)
```

### Check Business Statistics
```clarity
(contract-call? .Invoice-Factoring-Smart-Contracts get-business-stats 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

### Check Factor Statistics
```clarity
(contract-call? .Invoice-Factoring-Smart-Contracts get-factor-stats 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

### Check Pending Withdrawal
```clarity
(contract-call? .Invoice-Factoring-Smart-Contracts get-pending-withdrawal 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

### Calculate Factoring Amount
```clarity
(contract-call? .Invoice-Factoring-Smart-Contracts calculate-factoring-amount u1000000 u500)
```

Returns the amount the business receives after applying the factoring rate.

## 🔢 Rate Configuration

- **Factoring Rate**: Basis points (e.g., 500 = 5%)
- **Platform Fee**: Default 2% (200 basis points)
- **Max Factoring Rate**: Default 80% (8000 basis points)

### Admin Functions

```clarity
;; Update platform fee (owner only)
(contract-call? .Invoice-Factoring-Smart-Contracts set-platform-fee-rate u250)

;; Update max factoring rate (owner only)
(contract-call? .Invoice-Factoring-Smart-Contracts set-max-factoring-rate u9000)
```

## 💡 Example Workflow

1. **Business** creates invoice for 10,000 STX due in 10 days
2. **Factor** provides liquidity at 5% discount → Business receives 9,310 STX (95% - 2% platform fee)
3. **Client** pays 10,000 STX when invoice is due
4. **Factor** claims repayment and withdraws → Receives 10,000 STX (500 STX profit)
5. **Platform** collects 190 STX fee

## 🎮 Testing

```bash
clarinet test
```

## 🔒 Security Considerations

- Only authorized parties can pay/claim invoices
- Funds are held in contract escrow until withdrawal
- Platform fees are capped at 10%
- Factoring rates are capped at configurable maximum
- Invoice expiration checks prevent stale factoring

## 🛣️ Roadmap

- [ ] Multi-factor support for single invoices
- [ ] Secondary market for factored invoices
- [ ] Credit scoring system for businesses
- [ ] Automated matching between businesses and factors
- [ ] Insurance pool for defaults

## 📝 License

MIT

## 🤝 Contributing

Contributions welcome! Please open an issue or PR.

## 📞 Contact

Project Link: [https://github.com/tammri/Invoice-Factoring-Smart-Contracts](https://github.com/tammri/Invoice-Factoring-Smart-Contracts)
