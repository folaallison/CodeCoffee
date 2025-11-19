# CodeCoffee - Smart Contract Documentation

## Overview

**CodeCoffee** is a decentralized tipping service built on the Stacks blockchain using Clarity. It enables users to show appreciation for open-source developers and tutorial creators by sending STX (Stacks native token) tips directly to their wallets.

The contract manages creator profiles, tracks donations, handles platform fees, and provides a transparent record of all contributions on an immutable blockchain.

## Features

### 🎯 Creator Management
- **Easy Registration**: Developers and creators can register their profiles with a name and description
- **Profile Updates**: Update your information at any time
- **Account Control**: Activate or deactivate your account as needed
- **Statistics**: Track total tips received and number of contributions

### 💰 Tipping System
- **Direct Transfers**: Send STX directly to creators instantly
- **Custom Messages**: Include optional messages (up to 100 characters) with your tip
- **Automatic Fee Handling**: Platform fees are automatically deducted and tracked
- **Tip History**: Complete immutable record of all transactions with unique IDs
- **Transparent Pricing**: No hidden fees; know exactly what creators receive

### 🔐 Security & Admin
- **Owner Controls**: Admin-only functions to manage platform parameters
- **Fee Management**: Adjust platform fees (capped at 10%) as needed
- **Earnings Withdrawal**: Secure withdrawal of platform balance
- **Input Validation**: Comprehensive checks prevent invalid transactions

## Installation & Setup

### Prerequisites
- Stacks CLI installed ([Installation Guide](https://docs.stacks.co/docs/build-apps/cli))
- STX testnet tokens (for testing)
- A Stacks wallet (e.g., Hiro Wallet)

### Deployment

1. **Save the contract** as `CodeCoffee.clar` in your project

2. **Deploy to testnet**:
   ```bash
   stx deploy contracts/CodeCoffee.clar
   ```

3. **Deploy to mainnet** (production):
   ```bash
   stx deploy --mainnet contracts/CodeCoffee.clar
   ```

## Contract Functions

### Creator Functions

#### `register-creator (name: string) (description: string) -> ok | err`
Register as a creator to receive tips.

**Parameters:**
- `name`: Creator name (max 50 characters)
- `description`: Brief bio/description (max 200 characters)

**Returns:**
- `ok true` on success
- `ERR-ALREADY-REGISTERED` if already registered

**Example:**
```clarity
(contract-call? .CodeCoffee register-creator 
  "Alice Developer" 
  "Open-source contributor and tutorial creator")
```

#### `update-creator-profile (name: string) (description: string) -> ok | err`
Update your creator profile information.

**Parameters:**
- `name`: New creator name (max 50 characters)
- `description`: New description (max 200 characters)

**Returns:**
- `ok true` on success
- `ERR-NOT-REGISTERED` if not registered

#### `deactivate-creator -> ok | err`
Deactivate your creator account (stops receiving tips).

**Returns:**
- `ok true` on success
- `ERR-NOT-REGISTERED` if not registered

#### `reactivate-creator -> ok | err`
Reactivate a deactivated creator account.

**Returns:**
- `ok true` on success
- `ERR-NOT-REGISTERED` if not registered

### Tipping Functions

#### `send-tip (to: principal) (amount: uint) (message: string) -> ok(tip-id) | err`
Send a tip/donation to a creator.

**Parameters:**
- `to`: Creator's principal/wallet address
- `amount`: Amount in STX (in microSTX, so multiply by 1,000,000 for whole STX)
- `message`: Optional tip message (max 100 characters)

**Returns:**
- `ok tip-id` with unique tip identifier
- `ERR-INVALID-AMOUNT` if amount is zero or negative
- `ERR-CREATOR-NOT-FOUND` if recipient is not registered
- `ERR-INSUFFICIENT-BALANCE` if insufficient STX balance

**Example:**
```clarity
(contract-call? .CodeCoffee send-tip 
  'SP2JXKMH002UYL67Q4Z5X5PGG3JBRX540WQ6NGQE1
  5000000  ;; 5 STX in microSTX
  "Great tutorial, thanks!")
```

### Query Functions

#### `get-creator-profile (creator: principal) -> ok(creator-info) | err`
Retrieve a creator's profile information.

**Returns:**
- `ok` with creator details (name, description, total-tips, tip-count, registration date, active status)
- `ok none` if creator not found

#### `get-tip-details (tip-id: uint) -> ok(tip-info) | err`
Get details about a specific tip/donation.

**Returns:**
- `ok` with tip details (from, to, amount, message, timestamp)
- `ok none` if tip ID not found

#### `is-creator (user: principal) -> bool`
Check if a wallet address is registered as a creator.

**Returns:**
- `true` if registered as creator
- `false` otherwise

#### `get-platform-fee -> uint`
Get the current platform fee percentage (in basis points).

**Returns:**
- Fee percentage (e.g., 250 = 2.5%)

#### `get-platform-balance -> uint`
Get the current accumulated platform balance (admin only).

**Returns:**
- Platform balance in microSTX

#### `get-total-tips-count -> uint`
Get the total number of tips sent through the platform.

**Returns:**
- Total tip count

### Admin Functions

#### `update-platform-fee (new-fee: uint) -> ok | err`
Update the platform fee percentage. **Owner only.**

**Parameters:**
- `new-fee`: Fee in basis points (max 1000, which is 10%)

**Returns:**
- `ok true` on success
- `ERR-OWNER-ONLY` if not called by contract owner
- `ERR-INVALID-AMOUNT` if fee exceeds 1000

#### `withdraw-platform-balance (amount: uint) -> ok | err`
Withdraw accumulated platform fees. **Owner only.**

**Parameters:**
- `amount`: Amount in microSTX to withdraw

**Returns:**
- `ok true` on success
- `ERR-OWNER-ONLY` if not called by contract owner
- `ERR-INSUFFICIENT-BALANCE` if amount exceeds platform balance

## Error Codes

| Code | Name | Description |
|------|------|-------------|
| 100 | ERR-OWNER-ONLY | Function requires contract owner access |
| 101 | ERR-INVALID-AMOUNT | Invalid or zero amount provided |
| 102 | ERR-INSUFFICIENT-BALANCE | Insufficient STX balance for transaction |
| 103 | ERR-CREATOR-NOT-FOUND | Creator not found or not active |
| 104 | ERR-NOT-REGISTERED | Caller is not registered as creator |
| 105 | ERR-ALREADY-REGISTERED | Caller already registered as creator |

## Usage Examples

### 1. Register as a Creator
```clarity
(contract-call? .CodeCoffee register-creator 
  "John Dev" 
  "React tutorials and open-source libraries")
```

### 2. Send a Tip
```clarity
(contract-call? .CodeCoffee send-tip 
  'SP2JXKMH002UYL67Q4Z5X5PGG3JBRX540WQ6NGQE1
  2500000  ;; 2.5 STX
  "Amazing work on the tutorial!")
```

### 3. Check Creator Profile
```clarity
(contract-call? .CodeCoffee get-creator-profile 
  'SP2JXKMH002UYL67Q4Z5X5PGG3JBRX540WQ6NGQE1)
```

### 4. Get Tip Details
```clarity
(contract-call? .CodeCoffee get-tip-details u0)
```

## Fee Structure

The platform takes a small fee on each tip to maintain the service. The default fee is **2.5%** (250 basis points).

**Example:**
- Tip amount: 100 STX
- Platform fee (2.5%): 2.5 STX
- Creator receives: 97.5 STX

Fees are accumulated and can be withdrawn by the contract owner to fund platform operations.

## Gas Considerations

Typical transaction costs on Stacks:
- **Register as creator**: ~5,000 - 10,000 uSTX
- **Send tip**: ~10,000 - 15,000 uSTX
- **Update profile**: ~5,000 - 8,000 uSTX

Actual costs depend on network congestion and transaction complexity.

## Security Considerations

### Best Practices
1. **Verify addresses**: Always double-check creator addresses before sending tips
2. **Use testnets first**: Test your integration on testnet before mainnet
3. **Check creator status**: Verify a creator is active before tipping
4. **Secure your wallet**: Use hardware wallets for large transactions

### Contract Security
- All financial transactions use Clarity's built-in STX transfer functions
- Input validation prevents invalid amounts and operations
- Owner-only functions have proper access controls
- Read-only functions don't modify state
- No reentrancy vulnerabilities

## Deployed Contracts

### Testnet
- **Network**: Stacks Testnet
- **Status**: Ready for testing

### Mainnet
- **Status**: Not yet deployed
- Coming soon!

## FAQ

**Q: Is there a minimum tip amount?**
A: No, but 1 STX = 1,000,000 microSTX. Transactions must be at least 1 microSTX.

**Q: Can I cancel a tip?**
A: No, tips are permanent once sent. This ensures transparency and immutability.

**Q: What if a creator becomes inactive?**
A: Inactive creators cannot receive tips until they reactivate their account.

**Q: How are fees handled?**
A: Fees are automatically deducted from each tip and accumulated in the platform balance for withdrawal by the contract owner.

**Q: Can I tip anonymously?**
A: No, all transactions on the blockchain are publicly visible, including sender and receiver addresses.

## Support & Contributing

For issues, questions, or contributions:
1. Check existing documentation
2. Test on testnet first
3. Report bugs with detailed information
4. Suggest improvements via pull requests

## License

This smart contract is provided as-is for educational and production use. Use at your own risk.

## Disclaimer

CodeCoffee is a blockchain-based service. Users are responsible for:
- Maintaining control of their private keys
- Verifying recipient addresses before sending tips
- Understanding transaction costs and fees
- Complying with local regulations regarding cryptocurrency

The developers and maintainers are not liable for lost funds or unauthorized transactions.