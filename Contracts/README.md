# Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a Hardhat Ignition module that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat ignition deploy ./ignition/modules/Lock.ts
```

## Cách compile Contract

```shell
cd Contracts 
npx hardhat compile
```

## Cách test contract 

```shell
cd Contracts 
npx hardhat test
```


## Cách Deploy Contract lên mạng của Pione zero Chain 


```shell
cd Contracts 
npx hardhat ignition deploy ./ignition/modules/deploy.ts --network pione
```




