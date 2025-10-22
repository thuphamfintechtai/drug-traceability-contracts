# drug-traceability-contracts

# HƯỚNG DẪN TẠO PROJECT HARDHAT 

## Trước tiên vào terminal nhập lệnh 

```shell

npm install hardhat

```

## Sau đó tiếp tục nhập lệnh 

```shell

npx hardhat --init

```

## Sau đó Làm theo các bước như sau 

```shell

 npx hardhat --init

 █████  █████                         ███  ███                  ███      ██████
░░███  ░░███                         ░███ ░███                 ░███     ███░░███
 ░███   ░███   ██████  ████████   ███████ ░███████    ██████  ███████  ░░░  ░███
 ░██████████  ░░░░░███░░███░░███ ███░░███ ░███░░███  ░░░░░███░░░███░      ████░
 ░███░░░░███   ███████ ░███ ░░░ ░███ ░███ ░███ ░███   ███████  ░███      ░░░░███
 ░███   ░███  ███░░███ ░███     ░███ ░███ ░███ ░███  ███░░███  ░███ ███ ███ ░███
 █████  █████░░███████ █████    ░░███████ ████ █████░░███████  ░░█████ ░░██████
░░░░░  ░░░░░  ░░░░░░░ ░░░░░      ░░░░░░░ ░░░░ ░░░░░  ░░░░░░░    ░░░░░   ░░░░░░
 
👷 Welcome to Hardhat v3.0.8 👷

? Which version of Hardhat would you like to use? … 
  Hardhat 3 Beta (recommended for new projects)
▸ Hardhat 2 (older version)

```

## Sau đó ấn Enter để chọn sau khi ấn nó sẽ hiển thị như này 

```shell

Which version of Hardhat would you like to use? · hardhat-2
✔ Where would you like to initialize the project?

Please provide either a relative or an absolute path: · .


```

### TIPS : Có thể để absolute path là null không cần nhập gì hết nó sẽ tự động trỏ Folder mà bạn trỏ tới khi chạy lệnh npm , npx 

## Sau đó nó sẽ hiển thị ra như này 

```shell
Please provide either a relative or an absolute path: · .
? What type of project would you like to initialize? … 
  A Javascript project using Mocha and Ethers.js 
▸ A Javascript project using Mocha and Ethers.js (ESM)
  A Typescript project using Mocha and Ethers.js
  A Typescript project using Mocha and Viem
  An empty config file (hardhat.config.js)

```

## Nếu bạn dùng TS và EtherJs bạn sẽ chọn A Typescript project using Mocha and Ethers.js còn nếu bạn dùng JS và ETHERJs bạn có thể chọn A Javascript project using Mocha and Ethers.js (ESM) 

## Sau khi chọn bạn ấn enter nó sẽ tải Project cho bạn 


# CÁCH CHẠY CONTRACT 

## Trước tiên bạn hãy tạo File .env các bước làm như sau 

```shell
cd Contracts 
sudo nano .env or touch .env
```

## Template File .env sẽ như sau 

```env

PRIVATE_ADDRESS = "YOUR PRIVATE ADDRESS"
RPC_URL = "YOUR RPC_URL"

```

## WARNING : Bạn bắt buộc phải có file env và nội dung trong đó như trên thì mới deploy được contracts 

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
