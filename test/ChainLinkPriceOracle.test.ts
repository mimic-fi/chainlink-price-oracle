import { bn, deploy } from '@mimic-fi/v1-helpers'
import { expect } from 'chai'
import { Contract } from 'ethers'

describe('ChainLinkPriceOracle', () => {
  let oracle: Contract, registry: Contract, base: Contract, quote: Contract

  const PRICE = bn(3)

  beforeEach('deploy oracle', async () => {
    registry = await deploy('RegistryMock', [])
    oracle = await deploy('ChainLinkPriceOracle', [registry.address])
  })

  const itReverts = (baseDecimals: number, quoteDecimals: number) => {
    beforeEach('deploy tokens', async () => {
      base = await deploy('TokenMock', ['BASE', baseDecimals])
      quote = await deploy('TokenMock', ['QUOTE', quoteDecimals])
    })

    it('reverts', async () => {
      await expect(oracle.getTokenPrice(base.address, quote.address)).to.be.revertedWith('QUOTE_DECIMALS_TOO_BIG')
    })
  }

  const itQuotesThePriceCorrectly = (baseDecimals: number, quoteDecimals: number, feedDecimals: number) => {
    const reportedPrice = PRICE.mul(bn(10).pow(feedDecimals))
    const resultDecimals = baseDecimals + 18 - quoteDecimals
    const expectedPrice = PRICE.mul(bn(10).pow(resultDecimals))

    beforeEach('deploy tokens', async () => {
      base = await deploy('TokenMock', ['BASE', baseDecimals])
      quote = await deploy('TokenMock', ['QUOTE', quoteDecimals])
    })

    context('when no custom feed is set', () => {
      beforeEach('mock price', async () => {
        await registry.mockPrice(reportedPrice, feedDecimals)
      })

      it(`expresses the price with ${resultDecimals} decimals`, async () => {
        expect(await oracle.getTokenPrice(base.address, quote.address)).to.be.equal(expectedPrice)
      })
    })

    context('when a custom feed is set', () => {
      beforeEach('set custom feed', async () => {
        const feed = await deploy('FeedMock', [reportedPrice, feedDecimals])
        await oracle.setCustomFeed(base.address, quote.address, feed.address)
      })

      it(`expresses the price with ${resultDecimals} decimals`, async () => {
        expect(await oracle.getTokenPrice(base.address, quote.address)).to.be.equal(expectedPrice)
      })
    })
  }

  context('when the base has 6 decimals', () => {
    const baseDecimals = 6

    context('when the quote has 6 decimals', () => {
      const quoteDecimals = 6

      context('when the feed has 6 decimals', () => {
        const feedDecimals = 6

        itQuotesThePriceCorrectly(baseDecimals, quoteDecimals, feedDecimals)
      })

      context('when the feed has 18 decimals', () => {
        const feedDecimals = 18

        itQuotesThePriceCorrectly(baseDecimals, quoteDecimals, feedDecimals)
      })

      context('when the feed has 20 decimals', () => {
        const feedDecimals = 20

        itQuotesThePriceCorrectly(baseDecimals, quoteDecimals, feedDecimals)
      })
    })

    context('when the quote has 18 decimals', () => {
      const quoteDecimals = 18

      context('when the feed has 6 decimals', () => {
        const feedDecimals = 6

        itQuotesThePriceCorrectly(baseDecimals, quoteDecimals, feedDecimals)
      })

      context('when the feed has 18 decimals', () => {
        const feedDecimals = 18

        itQuotesThePriceCorrectly(baseDecimals, quoteDecimals, feedDecimals)
      })

      context('when the feed has 20 decimals', () => {
        const feedDecimals = 20

        itQuotesThePriceCorrectly(baseDecimals, quoteDecimals, feedDecimals)
      })
    })

    context('when the quote has 20 decimals', () => {
      const quoteDecimals = 20

      context('when the feed has 6 decimals', () => {
        const feedDecimals = 6

        itQuotesThePriceCorrectly(baseDecimals, quoteDecimals, feedDecimals)
      })

      context('when the feed has 18 decimals', () => {
        const feedDecimals = 18

        itQuotesThePriceCorrectly(baseDecimals, quoteDecimals, feedDecimals)
      })

      context('when the feed has 20 decimals', () => {
        const feedDecimals = 20

        itQuotesThePriceCorrectly(baseDecimals, quoteDecimals, feedDecimals)
      })
    })

    context('when the quote has 38 decimals', () => {
      const quoteDecimals = 38

      itReverts(baseDecimals, quoteDecimals)
    })
  })

  context('when the base has 18 decimals', () => {
    const baseDecimals = 18

    context('when the quote has 6 decimals', () => {
      const quoteDecimals = 6

      context('when the feed has 6 decimals', () => {
        const feedDecimals = 6

        itQuotesThePriceCorrectly(baseDecimals, quoteDecimals, feedDecimals)
      })

      context('when the feed has 18 decimals', () => {
        const feedDecimals = 18

        itQuotesThePriceCorrectly(baseDecimals, quoteDecimals, feedDecimals)
      })

      context('when the feed has 20 decimals', () => {
        const feedDecimals = 20

        itQuotesThePriceCorrectly(baseDecimals, quoteDecimals, feedDecimals)
      })
    })

    context('when the quote has 18 decimals', () => {
      const quoteDecimals = 18

      context('when the feed has 6 decimals', () => {
        const feedDecimals = 6

        itQuotesThePriceCorrectly(baseDecimals, quoteDecimals, feedDecimals)
      })

      context('when the feed has 18 decimals', () => {
        const feedDecimals = 18

        itQuotesThePriceCorrectly(baseDecimals, quoteDecimals, feedDecimals)
      })

      context('when the feed has 20 decimals', () => {
        const feedDecimals = 20

        itQuotesThePriceCorrectly(baseDecimals, quoteDecimals, feedDecimals)
      })
    })

    context('when the quote has 20 decimals', () => {
      const quoteDecimals = 20

      context('when the feed has 6 decimals', () => {
        const feedDecimals = 6

        itQuotesThePriceCorrectly(baseDecimals, quoteDecimals, feedDecimals)
      })

      context('when the feed has 18 decimals', () => {
        const feedDecimals = 18

        itQuotesThePriceCorrectly(baseDecimals, quoteDecimals, feedDecimals)
      })

      context('when the feed has 20 decimals', () => {
        const feedDecimals = 20

        itQuotesThePriceCorrectly(baseDecimals, quoteDecimals, feedDecimals)
      })
    })

    context('when the quote has 38 decimals', () => {
      const quoteDecimals = 38

      itReverts(baseDecimals, quoteDecimals)
    })
  })

  context('when the base has 20 decimals', () => {
    const baseDecimals = 20

    context('when the quote has 6 decimals', () => {
      const quoteDecimals = 6

      context('when the feed has 6 decimals', () => {
        const feedDecimals = 6

        itQuotesThePriceCorrectly(baseDecimals, quoteDecimals, feedDecimals)
      })

      context('when the feed has 18 decimals', () => {
        const feedDecimals = 18

        itQuotesThePriceCorrectly(baseDecimals, quoteDecimals, feedDecimals)
      })

      context('when the feed has 20 decimals', () => {
        const feedDecimals = 20

        itQuotesThePriceCorrectly(baseDecimals, quoteDecimals, feedDecimals)
      })
    })

    context('when the quote has 18 decimals', () => {
      const quoteDecimals = 18

      context('when the feed has 6 decimals', () => {
        const feedDecimals = 6

        itQuotesThePriceCorrectly(baseDecimals, quoteDecimals, feedDecimals)
      })

      context('when the feed has 18 decimals', () => {
        const feedDecimals = 18

        itQuotesThePriceCorrectly(baseDecimals, quoteDecimals, feedDecimals)
      })

      context('when the feed has 20 decimals', () => {
        const feedDecimals = 20

        itQuotesThePriceCorrectly(baseDecimals, quoteDecimals, feedDecimals)
      })
    })

    context('when the quote has 20 decimals', () => {
      const quoteDecimals = 20

      context('when the feed has 6 decimals', () => {
        const feedDecimals = 6

        itQuotesThePriceCorrectly(baseDecimals, quoteDecimals, feedDecimals)
      })

      context('when the feed has 18 decimals', () => {
        const feedDecimals = 18

        itQuotesThePriceCorrectly(baseDecimals, quoteDecimals, feedDecimals)
      })

      context('when the feed has 20 decimals', () => {
        const feedDecimals = 20

        itQuotesThePriceCorrectly(baseDecimals, quoteDecimals, feedDecimals)
      })
    })

    context('when the quote has 38 decimals', () => {
      const quoteDecimals = 38

      context('when the feed has 6 decimals', () => {
        const feedDecimals = 6

        itQuotesThePriceCorrectly(baseDecimals, quoteDecimals, feedDecimals)
      })

      context('when the feed has 18 decimals', () => {
        const feedDecimals = 18

        itQuotesThePriceCorrectly(baseDecimals, quoteDecimals, feedDecimals)
      })

      context('when the feed has 20 decimals', () => {
        const feedDecimals = 20

        itQuotesThePriceCorrectly(baseDecimals, quoteDecimals, feedDecimals)
      })
    })
  })
})
