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

    const V3Token = await ethers.getContractFactory("V3Token");
    const v3Token = await V3Token.deploy("V3 Token", "V3T");

    console.log("Token deployed at: " + v3Token.address)

    const nonfungiblePositionManager = await hre.ethers.getContractAt(
      "INonfungiblePositionManager", "0xC36442b4a4522E871399CD717aBDD847Ab11FE88"
    );

    const weth = await hre.ethers.getContractAt(
      "IWETH", "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
    );

    const router = await hre.ethers.getContractAt(
      "ISwapRouter", "0xE592427A0AEce92De3Edee1F18E0157C05861564"
    );

    await weth.deposit({value: ethers.utils.parseEther("100")})
    await weth.connect(user1).deposit({value: ethers.utils.parseEther("100")})

    console.log()

    return { v3Token, nonfungiblePositionManager, router, weth, deployer, user1, user2, user3 };
  }

  describe("Deployment", function () {
    it("Massa", async function () {
      const { v3Token, nonfungiblePositionManager, router, weth, deployer, user1, user2, user3 } = await loadFixture(deployFixture);

      console.log("First we initialize the pool")
      if(v3Token.address < weth.address)
      {
        token0 = v3Token.address
        token1 = weth.address
      }else
      {
        token0 = weth.address
        token1 = v3Token.address
      }

      /*
      await nonfungiblePositionManager.createAndInitializePoolIfNecessary(
        token0,
        token1,
        3000.// fee
        calculateSqrtPriceX96(1, 18, 18).toFixed(0)//Math.sqrt("1") * 2 ** 96
      )
      */
      console.log()

      console.log("Preparing to add liquidity")
      console.log("Pool1: " + await v3Token.pool1())
      console.log("Pool2: " + await v3Token.pool2())
      console.log("Pool3: " + await v3Token.pool3())
      console.log("Pool4: " + await v3Token.pool4())

      console.log("We initialize the pool")
      const pool = await hre.ethers.getContractAt(
        "IUniswapV3Pool", await v3Token.pool4()
      );

      console.log("Adding liquidity requires a series of params")
      let slot0 = await pool.slot0()
      let tickSpacing = parseInt(await pool.tickSpacing())
      let nearestTick = getNearestUsableTick(parseInt(slot0.tick),tickSpacing)

      mintParams = {
          token0: token0,
          token1: token1,
          fee: await pool.fee(),
          tickLower: nearestTick - tickSpacing * 10,
          tickUpper: nearestTick + tickSpacing * 10,
          amount0Desired: ethers.utils.parseEther("1"),
          amount1Desired: ethers.utils.parseEther("1"),
          amount0Min: 0,
          amount1Min: 0,
          recipient: deployer.address,
          deadline: "2662503213"
      };

      console.log("We approve")
      await v3Token.approve(nonfungiblePositionManager.address, ethers.utils.parseEther("10"))
      await weth.approve(nonfungiblePositionManager.address, ethers.utils.parseEther("10"))
      console.log("Now we add liquidity")
      await nonfungiblePositionManager.connect(deployer).mint(
        mintParams
      );
      console.log()

      console.log("Deplyer balance: " + ethers.utils.formatEther(await v3Token.balanceOf(deployer.address)))
      console.log()
      console.log("Fee balance: " + ethers.utils.formatEther(await v3Token.balanceOf(v3Token.address)))

      console.log("Now we can swap")
      swapParams = {
          tokenIn: weth.address,
          tokenOut: v3Token.address,
          fee: await pool.fee(),
          recipient: user1.address,
          deadline: "2662503213",
          amountIn: ethers.utils.parseEther("0.1"),
          amountOutMinimum: 0,
          sqrtPriceLimitX96: 0
      }

      await weth.connect(user1).approve(router.address, ethers.utils.parseEther("10"))
      await router.connect(user1).exactInputSingle(swapParams)

console.log("User v3Token balance: " + ethers.utils.formatEther(await v3Token.balanceOf(user1.address)))

console.log("-----SELL-----")
      swapParams2 = {
        tokenIn: v3Token.address,
        tokenOut: weth.address,
        fee: await pool.fee(),
        recipient: user1.address,
        deadline: "2662503213",
        amountIn: ethers.utils.parseEther("0.00001"),
        amountOutMinimum: 0,
        sqrtPriceLimitX96: 0
    }

    await v3Token.transfer(user2.address, ethers.utils.parseEther("100.0"))

    await v3Token.connect(user2).approve(router.address, ethers.utils.parseEther("0.01"))
    await v3Token.connect(deployer).approve(router.address, ethers.utils.parseEther("0.01"))
    await router.connect(deployer).exactInputSingle(swapParams2)

    console.log("pre")
    await v3Token.swap()
    console.log("post")
    //await v3Token.liquidity()
    console.log("posta")

console.log(nearestTick - tickSpacing * 10)
console.log(nearestTick + tickSpacing * 10)
    mintParams = {
      token0: token0,
      token1: token1,
      fee: await pool.fee(),
      tickLower: nearestTick - tickSpacing * 10,
      tickUpper: nearestTick + tickSpacing * 10,
      amount0Desired: ethers.utils.parseEther("1"),
      amount1Desired: ethers.utils.parseEther("1"),
      amount0Min: 0,
      amount1Min: 0,
      recipient: deployer.address,
      deadline: "2662503213"
  };

  console.log("We approve")
  await v3Token.approve(nonfungiblePositionManager.address, ethers.utils.parseEther("10"))
  await weth.approve(nonfungiblePositionManager.address, ethers.utils.parseEther("10"))
  console.log("Now we add liquidity")
  await nonfungiblePositionManager.connect(deployer).mint(
    mintParams
  );
    


      console.log("User1 balance: " + ethers.utils.formatEther(await v3Token.balanceOf(user1.address)))
      console.log("Fee balance: " + ethers.utils.formatEther(await v3Token.balanceOf(v3Token.address)))
      console.log("Weth balance: " + ethers.utils.formatEther(await weth.balanceOf(v3Token.address)))
    });
  });
});
