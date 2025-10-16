# Nifty - Advanced NFT Smart Contract Suite

A comprehensive, NFT implementation featuring crowdsale mechanics, upgradeable
architecture, and extensive functionality built on Ethereum.

## 🌟 Key Features

### Core NFT Implementation (`Nifty.sol`)

- **Full ERC721 Compliance**: Complete implementation of the ERC721 standard with metadata and enumerable extensions
- **Advanced Minting**: Flexible minting system with controlled supply management  
- **Burnable Tokens**: Secure token burning functionality with proper event emission
- **Pausable Operations**: Emergency pause functionality for security and maintenance
- **Revealable Metadata**: Support for hidden/revealed NFT mechanics common in modern drops
- **2-Step Ownership**: Enhanced ownership transfer security using OpenZeppelin's 2-step pattern
- **ERC165 Introspection**: Full interface detection support for maximum compatibility

### Crowdsale System (`Crowdsale.sol`)

- **Flexible Sale Mechanics**: Configurable pricing, timing, and allocation limits
- **Multi-phase Sales**: Support for different sale phases with varying conditions
- **Whitelist Support**: Built-in allowlist functionality for exclusive access
- **Payment Processing**: Secure ETH handling with withdrawal mechanisms
- **Supply Management**: Automatic tracking and enforcement of mint limits
- **Event Logging**: Comprehensive event system for transparency and indexing

### Upgradeable Architecture

- **Transparent Proxy Pattern**: Implementation of OpenZeppelin's transparent upgradeable proxy
- **Secure Upgrades**: Admin-controlled upgrade mechanism with role separation
- **Storage Safety**: Careful storage layout management to prevent upgrade conflicts
- **Initialization Support**: Proper initialization patterns for proxy deployments

## 🏗️ Architecture

The project follows a modular architecture with clear separation of concerns:

```
src/
├── Nifty.sol                  # Main NFT contract
├── Crowdsale.sol              # Sale management contract
├── Ownable2Steps.sol          # Enhanced ownership pattern
├── interfaces/                # Contract interfaces
│   ├── INifty.sol             # Main contract interface
│   ├── ICrowdsaleable.sol     # Crowdsale interface
│   ├── IRevealable.sol        # Metadata reveal interface
│   └── token/                 # ERC721 related interfaces
├── proxy/                     # Proxy implementation
│   └── TransparentUpgradeableProxy.sol
└── introspection/             # ERC165 implementation
    └── ERC165.sol
```

## 🧪 Testing & Coverage

The project maintains **100% test coverage** across all critical components:

- **14 comprehensive test suites** covering every contract function
- **100% line coverage** on core contracts (Nifty.sol: 151/151 lines, Crowdsale.sol: 58/58 lines)
- **100% branch coverage** ensuring all conditional paths are tested  
- **100% function coverage** validating every public/external function
- **Edge case testing** including overflow, underflow, and boundary conditions
- **Access control testing** verifying proper permission management
- **Integration tests** ensuring contracts work together seamlessly

### Test Categories

- ERC721 compliance tests
- Minting and burning functionality
- Crowdsale mechanics and edge cases
- Proxy upgrade scenarios
- Access control and permissions
- Pausable functionality
- Metadata reveal mechanics
- Token enumeration features

## 🛠️ OpenZeppelin Integration

The project leverages battle-tested OpenZeppelin primitives:

- **ERC721**: Foundation for NFT functionality
- **Ownable**: Access control with 2-step transfer enhancement
- **Pausable**: Emergency stop mechanism
- **ReentrancyGuard**: Protection against reentrancy attacks
- **Proxy Patterns**: Upgradeable contract architecture
- **AccessControl**: Role-based permission management
- **SafeMath**: Automatic overflow protection (Solidity 0.8+)

## 🚀 Deployment & Usage

### Prerequisites

- [Foundry](https://getfoundry.sh/) installed
- Ethereum wallet with testnet ETH for Sepolia deployment
- Environment variables configured (see `.env.sample`)

### Local Development

```bash
# Compile contracts
make build

# Run full test suite
make test

# Generate coverage report
make coverage

# Deploy locally
make local_deploy
```

### Sepolia Testnet Deployment

```bash
# Deploy to Sepolia testnet
make sepolia_deploy
```

### Available Make Commands

- `make build` - Compile all contracts
- `make test` - Run complete test suite
- `make coverage` - Generate detailed coverage report
- `make local_deploy` - Deploy to local Anvil network
- `make sepolia_deploy` - Deploy to Sepolia testnet

## 📁 Project Structure

```
├── src/                    # Smart contracts source code
├── test/                   # Comprehensive test suites  
├── script/                 # Deployment scripts
│   ├── LocalDeploy.s.sol  # Local deployment script
│   └── SepoliaDeploy.s.sol # Sepolia deployment script
├── lib/                    # External dependencies (OpenZeppelin)
├── Makefile               # Build and deployment automation
├── foundry.toml           # Foundry configuration
└── README.md              # This file
```

## 🔧 Configuration

The project uses Foundry's configuration system with sensible defaults:

- Solidity version: 0.8.30
- Optimizer: Enabled
- Gas reporting: Enabled
- Coverage: Comprehensive reporting
- Remappings: Configured for OpenZeppelin imports

## 📈 Contract Metrics

- **Gas Optimized**: Efficient implementations minimizing deployment and transaction costs
- **Security Focused**: Comprehensive access controls and safety mechanisms
- **Upgrade Safe**: Proper storage layouts and initialization patterns
- **Event Rich**: Detailed event emission for off-chain indexing and monitoring

## 🛡️ Security Features

- **Reentrancy Protection**: Guards against reentrancy attacks through battle-tested patterns
- **Access Control**: Multi-level permission system
- **Integer Overflow Protection**: Built-in Solidity 0.8+ protections
- **Pausable Operations**: Emergency stop functionality
- **Upgrade Safety**: Transparent proxy pattern with admin controls
- **Input Validation**: Comprehensive parameter checking

## 🎯 Use Cases

This NFT suite is ideal for:

- **Art Collections**: High-quality NFT drops with reveal mechanics
- **Gaming Assets**: In-game items with upgrade capabilities  
- **Membership Tokens**: Access control and utility tokens
- **Collectibles**: Trading cards, sports memorabilia, etc.
- **Utility NFTs**: Tokens providing real-world benefits

## 🤝 Contributing

Contributions should maintain the high standards of:

- 100% test coverage
- Comprehensive documentation
- Gas optimization
- Security best practices

---

Built with ❤️ using Foundry, OpenZeppelin, and modern Solidity practices.

