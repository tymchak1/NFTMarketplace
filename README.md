## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

# 🛒 NFT Marketplace

A basic NFT marketplace smart contract built with Solidity and Foundry. This project enables users to list, buy, and manage NFTs, incorporating standard best practices such as fee handling, owner access control, and marketplace pausing.

## 🧱 Tech Stack

- [Solidity](https://soliditylang.org/)
- [Foundry](https://book.getfoundry.sh/)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts)

## ✨ Features

- List NFTs for sale
- Purchase listed NFTs
- Cancel listings
- Update listing prices
- Customizable fee rate (set by owner)
- Withdraw marketplace balance
- Listing timestamps
- Pausable marketplace (emergency stop)
- Unit tests using Foundry

## 🚀 Getting Started

### 1. Clone the repo

```bash
git clone https://github.com/yourusername/nft-marketplace.git
cd nft-marketplace
```

### 2. Install dependencies

```bash
forge install
```

### 3. Build the contracts

```bash
forge build
```

### 4. Run tests

```bash
forge test
```

## 🧪 Testing

This project uses Foundry for testing. Tests cover:

- Successful listing and purchase
- Reverts for unapproved NFTs
- Insufficient payments
- Edge cases and custom errors

## 🔐 Deployment (example)

```bash
forge script script/Deploy.s.sol:DeployScript --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
```

## 📂 Structure

```
.
├── src                # Contracts
├── test               # Unit tests
├── script             # Deployment scripts
├── lib                # External dependencies
├── foundry.toml       # Foundry config
```

## 📜 License

MIT

---

Built with 💙 using Foundry.