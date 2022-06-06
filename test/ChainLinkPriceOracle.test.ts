import { assertEvent, bn, deploy, fp, getSigners, ZERO_ADDRESS } from '@mimic-fi/v1-helpers'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { expect } from 'chai'
import { Contract } from 'ethers'

describe('ChainLinkPriceOracle', () => {
  let oracle: Contract
  let tokenA: Contract, tokenB: Contract, tokenC: Contract, tokenD: Contract
  let feedTokenA: Contract, feedTokenC: Contract, feedTokenD: Contract
  let admin: SignerWithAddress, other: SignerWithAddress

  const PRICE_ONE_FEED = '0x1111111111111111111111111111111111111111'

  beforeEach('create oracle', async () => {
    // eslint-disable-next-line prettier/prettier
    [admin, other] = await getSigners()

    tokenA = await deploy('TokenMock', ['TokenA', 18])
    tokenB = await deploy('TokenMock', ['TokenB', 18])
    tokenC = await deploy('TokenMock', ['TokenC', 6])
    tokenD = await deploy('TokenMock', ['TokenD', 8])

    feedTokenA = await deploy('ChainLinkAggregatorV3', [18])
    feedTokenC = await deploy('ChainLinkAggregatorV3', [18])
    feedTokenD = await deploy('ChainLinkAggregatorV3', [18])

    const tokens = [tokenA.address, tokenB.address, tokenC.address, tokenD.address]
    // Token B price is always 1
    const feeds = [feedTokenA.address, PRICE_ONE_FEED, feedTokenC.address, feedTokenD.address]

    oracle = await deploy('ChainLinkPriceOracle', [tokens, feeds])
  })

  describe('deploy', () => {
    it('valid tokens have a feed', async () => {
      expect(await oracle.hasPriceFeed(tokenA.address)).to.be.true
      expect(await oracle.hasPriceFeed(tokenB.address)).to.be.true
      expect(await oracle.hasPriceFeed(tokenC.address)).to.be.true
      expect(await oracle.hasPriceFeed(tokenD.address)).to.be.true

      const feedA = await oracle.getPriceFeed(tokenA.address)
      expect(feedA.feed).to.be.equal(feedTokenA.address)
      expect(feedA.tokenDecimals).to.be.equal(await tokenA.decimals())

      const feedB = await oracle.getPriceFeed(tokenB.address)
      expect(feedB.feed).to.be.equal(PRICE_ONE_FEED)
      expect(feedB.tokenDecimals).to.be.equal(await tokenB.decimals())

      const feedC = await oracle.getPriceFeed(tokenC.address)
      expect(feedC.feed).to.be.equal(feedTokenC.address)
      expect(feedC.tokenDecimals).to.be.equal(await tokenC.decimals())

      const feedD = await oracle.getPriceFeed(tokenD.address)
      expect(feedD.feed).to.be.equal(feedTokenD.address)
      expect(feedD.tokenDecimals).to.be.equal(await tokenD.decimals())
    })

    it('invalid token has no feed', async () => {
      expect(await oracle.hasPriceFeed(ZERO_ADDRESS)).to.be.false
    })
  })

  describe('getTokenPrice', () => {
    const priceA = fp(2)

    beforeEach('set prices', async () => {
      await feedTokenA.setPrice(priceA)
    })

    it('token A & base B', async () => {
      const price = await oracle.getTokenPrice(tokenA.address, tokenB.address)
      const calcPrice = fp(1).mul(fp(1)).div(priceA)

      expect(price).to.be.equal(calcPrice)
    })

    it('token B & base A', async () => {
      const price = await oracle.getTokenPrice(tokenB.address, tokenA.address)

      expect(price).to.be.equal(priceA)
    })

    it('fails when invalid token', async () => {
      await expect(oracle.getTokenPrice(ZERO_ADDRESS, tokenA.address)).to.be.revertedWith('TOKEN_WITH_NO_FEED')
    })

    it('fails when invalid base', async () => {
      await expect(oracle.getTokenPrice(tokenA.address, ZERO_ADDRESS)).to.be.revertedWith('TOKEN_WITH_NO_FEED')
    })
  })

  describe('decimals', () => {
    const priceA = fp(2)
    const priceC = fp(3)
    const priceD = fp(5)

    beforeEach('set prices', async () => {
      await feedTokenA.setPrice(priceA)
      await feedTokenC.setPrice(priceC)
      await feedTokenD.setPrice(priceD)
    })

    it('token A & base C', async () => {
      const price = await oracle.getTokenPrice(tokenA.address, tokenC.address)

      const oneInBaseDecimals = bn(10).pow(await tokenC.decimals())
      const unscaledBasePrice = price.mul(oneInBaseDecimals).div(fp(1))

      const calcPrice = fp(1).mul(priceC).div(priceA)

      expect(unscaledBasePrice).to.be.equal(calcPrice)
    })

    it('token C & base A', async () => {
      const price = await oracle.getTokenPrice(tokenC.address, tokenA.address)

      const calcPrice = fp(1).mul(priceA).div(priceC)
      const oneInTokenDecimals = bn(10).pow(await tokenC.decimals())
      const scaledTokenCalcPrice = calcPrice.mul(oneInTokenDecimals).div(fp(1))

      expect(scaledTokenCalcPrice).to.be.equal(price)
    })

    it('token C & base D', async () => {
      const price = await oracle.getTokenPrice(tokenC.address, tokenD.address)

      const oneInBaseDecimals = bn(10).pow(await tokenD.decimals())
      const unscaledBasePrice = price.mul(oneInBaseDecimals).div(fp(1))

      const calcPrice = fp(1).mul(priceD).div(priceC)
      const oneInTokenDecimals = bn(10).pow(await tokenC.decimals())
      const scaledTokenCalcPrice = calcPrice.mul(oneInTokenDecimals).div(fp(1))

      expect(unscaledBasePrice).to.be.equal(scaledTokenCalcPrice)
    })

    it('token D & base C', async () => {
      const price = await oracle.getTokenPrice(tokenD.address, tokenC.address)

      const oneInBaseDecimals = bn(10).pow(await tokenC.decimals())
      const unscaledBasePrice = price.mul(oneInBaseDecimals).div(fp(1))

      const calcPrice = fp(1).mul(priceC).div(priceD)
      const oneInTokenDecimals = bn(10).pow(await tokenD.decimals())
      const scaledTokenCalcPrice = calcPrice.mul(oneInTokenDecimals).div(fp(1))

      expect(unscaledBasePrice).to.be.equal(scaledTokenCalcPrice)
    })
  })

  describe('set price feed', () => {
    let from: SignerWithAddress

    context('when the sender is the admin', () => {
      beforeEach('set sender', async () => {
        from = admin
      })

      context('when the feed is not set', () => {
        it('updates the price oracle', async () => {
          const newToken = await deploy('TokenMock', ['TokenE', 18])
          const newFeed = await deploy('ChainLinkAggregatorV3', [18])

          const feedBefore = await oracle.getPriceFeed(newToken.address)
          expect(feedBefore.feed).to.be.equal(ZERO_ADDRESS)

          await oracle.connect(from).setPriceFeeds([newToken.address], [newFeed.address])

          const feedAfter = await oracle.getPriceFeed(newToken.address)
          expect(feedAfter.feed).to.be.equal(newFeed.address)
          expect(feedAfter.tokenDecimals).to.be.equal(await newToken.decimals())
        })

        it('reverts if feed decimals is not 18', async () => {
          const newFeed = await deploy('ChainLinkAggregatorV3', [10])
          await expect(oracle.connect(from).setPriceFeeds([tokenA.address], [newFeed.address])).to.be.revertedWith(
            'INVALID_FEED_DECIMALS'
          )
        })
      })

      context('when the feed is already set', () => {
        it('updates the price oracle', async () => {
          const feedBefore = await oracle.getPriceFeed(tokenA.address)
          expect(feedBefore.feed).to.be.equal(feedTokenA.address)
          expect(feedBefore.tokenDecimals).to.be.equal(await tokenA.decimals())

          const newFeed = await deploy('ChainLinkAggregatorV3', [18])

          await oracle.connect(from).setPriceFeeds([tokenA.address], [newFeed.address])

          const feedAfter = await oracle.getPriceFeed(tokenA.address)
          expect(feedAfter.feed).to.be.equal(newFeed.address)
          expect(feedAfter.tokenDecimals).to.be.equal(await tokenA.decimals())
        })

        it('emits an event', async () => {
          const newFeed = await deploy('ChainLinkAggregatorV3', [18])

          const tx = await oracle.connect(from).setPriceFeeds([tokenA.address], [newFeed.address])
          await assertEvent(tx, 'PriceFeedSet', { token: tokenA.address, feed: newFeed.address })
        })

        it('unsets the price oracle', async () => {
          await oracle.connect(from).setPriceFeeds([tokenA.address], [ZERO_ADDRESS])

          const feedAfter = await oracle.getPriceFeed(tokenA.address)
          expect(feedAfter.feed).to.be.equal(ZERO_ADDRESS)
        })

        it('can be re set', async () => {
          await expect(oracle.connect(from).setPriceFeeds([tokenA.address], [feedTokenA.address])).not.to.be.reverted
        })
      })
    })

    context('when the sender is not the admin', () => {
      beforeEach('set sender', async () => {
        from = other
      })

      it('reverts', async () => {
        await expect(oracle.connect(from).setPriceFeeds([tokenA.address], [feedTokenA.address])).to.be.revertedWith(
          'Ownable: caller is not the owner'
        )
      })
    })
  })
})
