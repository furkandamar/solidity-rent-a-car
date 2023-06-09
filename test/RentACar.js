const { ethers } = require("hardhat");
const provider = ethers.provider;

describe("Rent A Car", () => {
    let owner, renter1, renter2, renter3, renter4;
    let contractFactory, _contract;
    let userBalances = {};

    describe("Initial test", () => {
        async function getBalance(address) {
            return await ethers.provider.getBalance(address);
        }

        before(async () => {
            [owner, renter1, renter2, renter3, renter4] = await ethers.getSigners();
            contractFactory = await ethers.getContractFactory("RentACar");
            _contract = await contractFactory.connect(owner).deploy();
        });

        beforeEach(async () => {
            userBalances = {
                "renter1": await getBalance(renter1.address),
                "renter2": await getBalance(renter2.address),
                "renter3": await getBalance(renter3.address),
                "renter4": await getBalance(renter4.address),
            };
        })



        it("Add cars", async () => {
            await _contract.addCar("MG63", "Mercedes G 63", 4, 5, ethers.utils.parseEther("0.05"));
            await _contract.addCar("BMW5", "BMW 520 i", 4, 5, ethers.utils.parseEther("0.025"));
            await _contract.addCar("TRAN", "Wolkswagen Transporter", 9, 4, ethers.utils.parseEther("0.007"));

        });

    });

    describe("Process", () => {
        it("Available Cars", async () => {
            let cars = await _contract.availableCars();
            console.log(cars);
        })

        it("Get MG63 detail", async () => {
            let carInfo = await _contract.getCarInfo("MG63");
            console.log(carInfo);
        })

        it("User 1 Rent MG63", async () => {
            //We buy the vehicle with a daily price of 0.05 eth for 4 days. (0.05 * 4) = 2 ether
            let rent = await _contract.connect(renter1).rentCar("MG63", 4, { value: ethers.utils.parseEther("2") });
            await rent.wait();
            console.log(rent);
        })

        it("After rent available cars", async () => {
            let cars = await _contract.availableCars();
            console.log(cars);
        })

        it("User 2 try to buy the car with code MG63", async () => {
            let rent = await _contract.connect(renter2).rentCar("MG63", 2, { value: ethers.utils.parseEther("1") });
            await rent.wait();
            console.log(rent);
        })

        it("A different user tries to deliver a car they haven't rented", async () => {
            let delivery = await _contract.connect(renter3).carDelivery("MG63");
            await delivery.wait();
            console.log(delivery);
        })

        it("User 1 pulls the MG63 it brought into the garage", async () => {
            let delivery = await _contract.connect(renter1).carDelivery("MG63");
            await delivery.wait();
            console.log(delivery);
        })
    })
})