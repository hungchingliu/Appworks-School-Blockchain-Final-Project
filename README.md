# Appworks-School-Blockchain-Final-Project
- Description
    - The IRouterExample and RouterExample contract serve as a comprehensive demonstration of the core interactions with Uniswap V4-core, showcasing how to interact with Uniswap v4-core.
    - The primary goal of this project is for learning and understanding Uniswap V4-core codebase.
    - Uniswap/v4-core architecture
      ![UniswapV4 drawio](https://github.com/hungchingliu/Appworks-School-Blockchain-Final-Project/assets/22343567/c4bd9070-e820-43e9-814f-2ec746720195)
    - Uniswap/v4-core interaction sequence diagram
       ![UniswapV4-Page-2 drawio](https://github.com/hungchingliu/Appworks-School-Blockchain-Final-Project/assets/22343567/792bb02f-180b-446e-b534-ef8998f2181e)
      
- Framework
    - Foundry
    - Libraries
        - Uniswap/periphery-next(v4-core, v4-periphery)
        - openzeppelin

- Development
    - `git clone git@github.com:hungchingliu/Appworks-School-Blockchain-Final-Project.git`
    - `forge install`
    - `forge remappings > remappings.txt`

- Testing
    - `forge test`

- IRouterExample
```solidity
interface IRouterExample is IERC1155Receiver {
   function swap(
        IPoolManager.PoolKey memory key,
        IPoolManager.SwapParams memory params
    ) external payable returns (BalanceDelta delta);

    function modifyPosition(
        IPoolManager.PoolKey memory key, 
        IPoolManager.ModifyPositionParams memory params
    ) external payable returns (BalanceDelta delta); 

    function donate(
        IPoolManager.PoolKey memory key,
        uint256 amount0,
        uint256 amount1
    ) external payable returns (BalanceDelta delta);

    function mint(Currency currency, uint256 amount) external returns (BalanceDelta delta);
    
    function burn(Currency currency, uint256 amount) external returns (BalanceDelta delta);
}
```
- Usage
    - IRouterExample shows the core interactions with uniswap v4-core contracts. Other developers could use this contract as an reference to build more functionalities on top of it.
    - Example usage is in `RouterExample.t.sol/RouterExampleTest`
    
- Learning Efforts
    - Notion Link: https://peppermint-shrimp-418.notion.site/Uniswap-V4-57946223d6ef46139f2f6d093b9e7357?pvs=4
