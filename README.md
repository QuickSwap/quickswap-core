# QuickSwap

QuickSwap core contracts are the fork of [Uniswap V2](https://github.com/Uniswap/uniswap-v2-core)

In-depth documentation on Uniswap V2 is available at [uniswap.org](https://uniswap.org/docs).

The built contract artifacts can be browsed via [unpkg.com](https://unpkg.com/browse/@uniswap/v2-core@latest/).

# Addresses and Verified Source Code:

- QUICK token: https://explorer-mainnet.maticvigil.com/address/0x831753DD7087CaC61aB5644b308642cc1c33Dc13/contracts
- QuickSwapRouter: https://explorer-mainnet.maticvigil.com/address/0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff/contracts
- QuickSwapFactory: https://explorer-mainnet.maticvigil.com/address/0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32/contracts
- Pair Contract: https://explorer-mainnet.maticvigil.com/address/0xadbF1854e5883eB8aa7BAf50705338739e558E5b/contracts

# Local Development

The following assumes the use of `node@>=10`.

## Install Dependencies

`yarn`

## Compile Contracts

`yarn compile`

## Run Tests

`yarn test`

## Add To Your Site

To include a QuickSwap iframe within your site just add an iframe element within your website code and link to the QuickSwap frontent.

Linking to a MATIC <-> QUICK swap page would look something like this. To link to a token of your choice replace the address after “outputCurrency” with the token address of the token you want to link to.

`<iframe
  src="https://quickswap.exchange/#/swap?outputCurrency=0x831753dd7087cac61ab5644b308642cc1c33dc13"
  height="660px"
  width="100%"
  style="
    border: 0;
    margin: 0 auto;
    display: block;
    border-radius: 10px;
    max-width: 600px;
    min-width: 300px;
  "
  id="myId"
/>`
