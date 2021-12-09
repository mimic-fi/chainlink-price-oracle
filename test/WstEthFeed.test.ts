import { deploy } from '@mimic-fi/v1-helpers'
import { expect } from 'chai'
import { Contract } from 'ethers'

describe('WstEthFeed', () => {
  //let admin: SignerWithAddress
  let feed: Contract

  beforeEach('create feed', async () => {
    feed = await deploy('WstEthFeed', [])
  })

  describe('rate', () => {
    it('must be greater then one', async () => {
      const result = await feed.latestRoundData()
      expect(result.answer.gt(1)).to.be.true
    })
  })
})
