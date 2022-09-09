const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { ethers } = require("hardhat");

const { BigNumber } = require('bignumber.js')
const Q192 = BigNumber(2).exponentiatedBy(192)

function calculateSqrtPriceX96(price, token0Dec, token1Dec)
{
  price = BigNumber(price).shiftedBy(token1Dec - token0Dec)
  ratioX96 = price.multipliedBy(Q192)
  sqrtPriceX96 = ratioX96.sqrt()
  return sqrtPriceX96
}

function getNearestUsableTick(currentTick,space) {
  // 0 is always a valid tick
  if(currentTick == 0){
      return 0
  }
  // Determines direction
  direction = (currentTick >= 0) ? 1 : -1
  // Changes direction
  currentTick *= direction
  // Calculates nearest tick based on how close the current tick remainder is to space / 2
  nearestTick = (currentTick%space <= space/2) ? currentTick - (currentTick%space) : currentTick + (space-(currentTick%space))
  // Changes direction back
  nearestTick *= direction
  
  return nearestTick
}

describe("Lock", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployFixture() {
    const [deployer, user1, user2, user3] = await ethers.getSigners();

    const V3Fees = await ethers.getContractFactory("V3Fees");
    const v3Fees = await V3Fees.deploy("V3 Fees", "V3F");

    console.log("Token deployed at: " + v3Fees.address)

    const nonfungiblePositionManager = await hre.ethers.getContractAt(
      "INonfungiblePositionManager", "0xC36442b4a4522E871399CD717aBDD847Ab11FE88"
    );

    const weth = await hre.ethers.getContractAt(
      "IWETH", "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
    );

    const router = await hre.ethers.getContractAt(
      "ISwapRouter", "0xE592427A0AEce92De3Edee1F18E0157C05861564"
    );

    await weth.deposit({value: ethers.utils.parseEther("200")})
    await weth.connect(user1).deposit({value: ethers.utils.parseEther("200")})

    console.log()

    return { v3Fees, nonfungiblePositionManager, router, weth, deployer, user1, user2, user3 };
  }

  describe("Deployment", function () {
    it("Massa", async function () {
      const { v3Fees, nonfungiblePositionManager, router, weth, deployer, user1, user2, user3 } = await loadFixture(deployFixture);

      console.log("1. Add liquidity")
      const pool = await hre.ethers.getContractAt(
        "IUniswapV3Pool", await v3Fees.pool4()
      );

      let slot0 = await pool.slot0()
      let tickSpacing = parseInt(await pool.tickSpacing())
      let nearestTick = getNearestUsableTick(parseInt(slot0.tick),tickSpacing)

      if(v3Fees.address < weth.address)
      {
        token0 = v3Fees.address
        token1 = weth.address
        amount0Desired = "1000000"
        amount1Desired = "100"
      }else
      {
        token0 = weth.address
        token1 = v3Fees.address
        amount0Desired = "100"
        amount1Desired = "1000000"
      }

      mintParams = {
          token0: token0,
          token1: token1,
          fee: await pool.fee(),
          tickLower: nearestTick - tickSpacing * 10,
          tickUpper: nearestTick + tickSpacing * 10,
          amount0Desired: ethers.utils.parseEther(amount0Desired),
          amount1Desired: ethers.utils.parseEther(amount1Desired),
          amount0Min: 0,
          amount1Min: 0,
          recipient: deployer.address,
          deadline: "2662503213"
      };

      await v3Fees.approve(nonfungiblePositionManager.address, ethers.utils.parseEther("1000000"))
      await weth.approve(nonfungiblePositionManager.address, ethers.utils.parseEther("100"))
      await nonfungiblePositionManager.connect(deployer).mint(
        mintParams
        );
      console.log()

      console.log("2. User1 buys 1 eth worth of tokens")
      buyParams = {
          tokenIn: weth.address,
          tokenOut: v3Fees.address,
          fee: await pool.fee(),
          recipient: user1.address,
          deadline: "2662503213",
          amountIn: ethers.utils.parseEther("1"),
          amountOutMinimum: 0,
          sqrtPriceLimitX96: 0
      }

      await weth.connect(user1).approve(router.address, ethers.utils.parseEther("1"))
      await router.connect(user1).exactInputSingle(buyParams)

      console.log("User1 token balance: " + ethers.utils.formatEther(await v3Fees.balanceOf(user1.address)))
      console.log("Vault balance: " + ethers.utils.formatEther(await v3Fees.balanceOf(await v3Fees.vaultWallet())))
      console.log()
      
      console.log("3. User1 sells 900 tokens")
      sellParams = {
        tokenIn: v3Fees.address,
        tokenOut: weth.address,
        fee: await pool.fee(),
        recipient: user1.address,
        deadline: "2662503213",
        amountIn: ethers.utils.parseEther("900"),
        amountOutMinimum: 0,
        sqrtPriceLimitX96: 0
      }

      await v3Fees.connect(user1).approve(router.address, ethers.utils.parseEther("900"))
      await router.connect(user1).exactInputSingle(sellParams)

      console.log("User1 token balance: " + ethers.utils.formatEther(await v3Fees.balanceOf(user1.address)))
      console.log("Vault balance: " + ethers.utils.formatEther(await v3Fees.balanceOf(await v3Fees.vaultWallet())))
      console.log()

      console.log("4. User1 sends 10 tokens via p2p")

      await v3Fees.connect(user1).transfer(user2.address, ethers.utils.parseEther("10"))

      console.log("User1 token balance: " + ethers.utils.formatEther(await v3Fees.balanceOf(user1.address)))
      console.log("User2 token balance: " + ethers.utils.formatEther(await v3Fees.balanceOf(user2.address)))
      console.log("Vault balance: " + ethers.utils.formatEther(await v3Fees.balanceOf(await v3Fees.vaultWallet())))
      console.log()

    });
  });
});
