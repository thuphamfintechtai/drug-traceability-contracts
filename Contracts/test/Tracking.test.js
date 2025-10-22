// test/Tracking.test.js

const { ethers } = require("hardhat");
const { expect } = require("chai");

describe("Hệ thống MyNFT và AccessControl (JavaScript)", function () {
  
  // Khai báo các biến
  let accessControl;
  let myNFT;
  let owner;
  let manufacturer;
  let distributor;
  let pharmacy;
  let randomUser;

  beforeEach(async function () {
    // Lấy danh sách các tài khoản test
    [owner, manufacturer, distributor, pharmacy, randomUser] = await ethers.getSigners();

    // 1. Deploy accessControlService
    const AccessControlFactory = await ethers.getContractFactory("accessControlService");
    // `factory.deploy()` trong Ethers v6/Hardhat mới sẽ tự động đợi deploy xong
    accessControl = await AccessControlFactory.deploy();
    
    // 2. Deploy MyNFT, truyền địa chỉ của accessControl vào constructor
    const MyNFTFactory = await ethers.getContractFactory("MyNFT");
    myNFT = await MyNFTFactory.deploy(accessControl.address);
  });

  // Test case 1: Kiểm tra deploy và owner
  it("Should deploy contracts and set the correct owner", async function () {
    // Kiểm tra owner của accessControl
    expect(await accessControl.isAdmin(owner.address)).to.be.true;
    expect(await accessControl.isAdmin(randomUser.address)).to.be.false;

    // Kiểm tra MyNFT đã liên kết đúng contract accessControl
    expect(await myNFT.accessControlServiceObj()).to.equal(accessControl.address);
  });

  // Nhóm các test case liên quan đến thiết lập và tracking thành công
  describe("Kịch bản thành công (Happy Path)", function () {
    
    let tokenId;
    const tokenURI = "ipfs://QmT...token1"; // URI mẫu

    // Thiết lập vai trò và quyền trước khi chạy các test trong nhóm này
    beforeEach(async function () {
      // 1. Owner thêm Manufacturer
      await accessControl.connect(owner).addManufacture(manufacturer.address);

      // 2. Manufacturer thêm Distributor
      await accessControl.connect(manufacturer).addDistributor(distributor.address);

      // 3. Distributor thêm Pharmacy
      await accessControl.connect(distributor).addPharmacy(pharmacy.address);

      // 4. Manufacturer ủy quyền cho Distributor
      await accessControl.connect(manufacturer).ManufactureAuthorityDistributorFun(distributor.address);

      // 5. Distributor ủy quyền cho Pharmacy
      await accessControl.connect(distributor).DistributorAuthorityPharmacyFun(pharmacy.address);

      // 6. Mint một NFT (cho Manufacturer) để test
      // Vì `_tokenIds++` rồi mới gán, token đầu tiên sẽ có ID là 1
      await myNFT.connect(manufacturer).mintNFT(manufacturer.address, tokenURI);
      tokenId = 1;
    });

    it("Should correctly set up roles and authorities", async function () {
      expect(await accessControl.checkIsManufactor(manufacturer.address)).to.be.true;
      expect(await accessControl.checkIsDistributor(distributor.address)).to.be.true;
      expect(await accessControl.checkIsPharmacy(pharmacy.address)).to.be.true;
      
      // Kiểm tra quyền (authority)
      expect(await accessControl.connect(manufacturer).checkManufactorAuthorityDistributor(distributor.address)).to.be.true;
      expect(await accessControl.connect(distributor).checkDistributorAuthorityPharmacy(pharmacy.address)).to.be.true;
    });

    it("Should allow Manufacturer to log transfer to Distributor", async function () {
      // Manufacturer gọi hàm tracking
      const tx = await myNFT.connect(manufacturer).manufactorToDistributorFun(tokenId, distributor.address);
      
      // Kiểm tra xem event có được emit với đúng tham số không
      const latestBlock = await ethers.provider.getBlock('latest');
      await expect(tx)
        .to.emit(myNFT, "manufactorToDistributorEvent")
        .withArgs(manufacturer.address, distributor.address, latestBlock.timestamp);

      // Kiểm tra dữ liệu đã được lưu
      const travelInfo = await myNFT.tokenIdTravelInfos(tokenId, 0); // Lấy phần tử đầu tiên
      expect(travelInfo.fromUserAddress).to.equal(manufacturer.address);
      expect(travelInfo.toUserAddress).to.equal(distributor.address);
      expect(travelInfo.fromUserType).to.equal(await myNFT.ManufactorByte());
    });

    it("Should allow Distributor to log transfer to Pharmacy", async function () {
      // Bước 1: Phải có state là Manufacturer đã chuyển cho Distributor
      await myNFT.connect(manufacturer).manufactorToDistributorFun(tokenId, distributor.address);

      // Bước 2: Distributor gọi hàm tracking
      const tx = await myNFT.connect(distributor).DistributorToPharmacyFun(tokenId, pharmacy.address);

      // Kiểm tra event
      const latestBlock = await ethers.provider.getBlock('latest');
      await expect(tx)
        .to.emit(myNFT, "distributorToPharmacyEvent")
        .withArgs(distributor.address, pharmacy.address, latestBlock.timestamp);

      // Kiểm tra dữ liệu đã lưu (phần tử thứ 2, index 1)
      const travelInfo = await myNFT.tokenIdTravelInfos(tokenId, 1); 
      expect(travelInfo.fromUserAddress).to.equal(distributor.address);
      expect(travelInfo.toUserAddress).to.equal(pharmacy.address);
      expect(travelInfo.fromUserType).to.equal(await myNFT.DistributorByte());
    });
  });

  // Nhóm các test case kiểm tra lỗi (revert)
  describe("Kịch bản thất bại (Reverts / Sad Path)", function () {
    
    let tokenId;

    beforeEach(async function () {
      // Chỉ setup vai trò, không setup quyền (authority)
      await accessControl.connect(owner).addManufacture(manufacturer.address);
      await accessControl.connect(manufacturer).addDistributor(distributor.address);

      // Mint NFT
      await myNFT.connect(manufacturer).mintNFT(manufacturer.address, "ipfs://token2");
      tokenId = 1;
    });

    it("Should REVERT if a non-manufacturer calls manufactorToDistributorFun", async function () {
      // `randomUser` gọi hàm
      await expect(
        myNFT.connect(randomUser).manufactorToDistributorFun(tokenId, distributor.address)
      ).to.be.revertedWith("Invalid Role");

      // `distributor` gọi hàm (cũng là sai vai trò)
      await expect(
        myNFT.connect(distributor).manufactorToDistributorFun(tokenId, distributor.address)
      ).to.be.revertedWith("Invalid Role");
    });

    it("Should REVERT if manufacturer calls for an UNAUTHORIZED distributor", async function () {
      // Trong `beforeEach` của nhóm này, chúng ta *chưa* gọi `ManufactureAuthorityDistributorFun`
      // Nên `distributor` chưa được `manufacturer` ủy quyền
      await expect(
        myNFT.connect(manufacturer).manufactorToDistributorFun(tokenId, distributor.address)
      ).to.be.revertedWith("Error Invalid Authority Wallet Address");
    });

    it("Should REVERT if a non-distributor calls DistributorToPharmacyFun", async function () {
      // `manufacturer` gọi hàm
      await expect(
        myNFT.connect(manufacturer).DistributorToPharmacyFun(tokenId, pharmacy.address)
      ).to.be.revertedWith("Invalid Role");
    });
    
    it("Should REVERT if distributor calls for an UNAUTHORIZED pharmacy", async function () {
      // `pharmacy` chưa được `distributor` add và ủy quyền
      await expect(
        myNFT.connect(distributor).DistributorToPharmacyFun(tokenId, pharmacy.address)
      ).to.be.revertedWith("Error Invalid Authority Wallet Address");
    });
  });
});