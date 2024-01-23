# MassDropERC721

## Overview

MassDropERC721 is a modern, minimalist, and gas-efficient ERC-721 implementation that introduces a novel design allowing creators to mass mint tokens to specified addresses at deployment time. This eliminates the need to call the contract to mint, and mutate storage, for each token, making the distribution process vastly more efficient.

Creators can leverage the mass minting feature by providing a list of addresses during contract deployment. Each address in the list will receive a unique token.

## Features

- **Mass Minting:** The contract supports mass minting of tokens to specified addresses during deployment.
- **Gas Efficiency:** The implementation focuses on minimizing gas consumption for improved cost-effectiveness.

## License

This contract is licensed under the [GNU General Public License v3.0](https://opensource.org/licenses/GPL-3.0).

## Credits

This ERC-721 implementation is modified from Solmate (https://github.com/transmissions11/solmate) to incorporate mass minting functionality. Additionally, some hyper-optimized code snippets are adapted from Solady (https://github.com/vectorized/solady).
