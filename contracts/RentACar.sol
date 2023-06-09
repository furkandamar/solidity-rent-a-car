// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/*
    Author      :   Furkan Damar
    Website     :   https://furkandamar.net/
    Linkedin    :   https://www.linkedin.com/in/furkan-damar-2b96ab99/
    Github      :   https://github.com/furkandamar

    Description :   This project is a simple rent a car project.
                    We simply realized that the admin added cars and users rented cars daily.
*/
contract RentACar {
    //Create models
    struct Car {
        string CarCode;
        string CarName;
        uint8 Passengers;
        uint8 Doors;
        uint256 Price;
        bool isRented;
    }

    struct Renter {
        address RenterAddress;
        Car Car;
        uint8 Day;
        uint256 RentalTime;
        uint256 ReturnTime;
        bool IsReturned;
    }

    //Global Variables
    address private immutable owner;
    uint256 private carId;
    string[] private carCodes;
    uint256 rentIndex;
    mapping(string => Car) private cars;
    Renter[] private renters;

    //Events
    event CarAdded(string carCode,string carName,uint8 passenger,uint8 doors,uint256 price);
    event CarRented(string carCode, address renter, uint8 day);
    event CarReturned(string carCode, address renter);


    constructor() {
        owner = msg.sender;
    }

    //Define modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can do this.");
        _;
    }

    modifier checkCarExists(string memory carCode) {
        require(
            keccak256(abi.encodePacked(cars[carCode].CarCode)) ==
                keccak256(abi.encodePacked(carCode)),
            "There are no tools defined for this code"
        );
        _;
    }

    function addCar(
        string memory carCode,
        string memory carName,
        uint8 passenger,
        uint8 doors,
        uint256 price
    ) external onlyOwner {
        Car storage newCar = cars[carCode];
        newCar.CarCode = carCode;
        newCar.CarName = carName;
        newCar.Passengers = passenger;
        newCar.Doors = doors;
        newCar.Price = price;
        newCar.isRented = false;
        carCodes.push(carCode);
        carId++;
        emit CarAdded(carCode, carName, passenger, doors, price);
    }

    //All added tools are returned to the user for listing.
    function getCars() external view returns(string[] memory) {
        return carCodes;
    }

    //Details of the data sent to the car code are returned to the user.
    function getCarInfo(string memory carCode) external view returns(Car memory) {
        return cars[carCode];
    }

    //With the checkCarExists modifier, it is checked whether such a tool exists. If available, the daily price of the vehicle is multiplied by the number of days to be rented and returns
    function calculateTotalPrice(string memory carCode, uint8 day)
        external
        checkCarExists(carCode)
        view
        returns (uint256)
    {
 
        Car storage _car = cars[carCode];
        uint256 totalPrice = _car.Price * day;
        return totalPrice;
    }

    /*
        In the car rental function, some conditions are checked first.
        Is there such a car?
        Can the car be rented now?
        Has sufficient payment been received from the user?
    */
    function rentCar(string memory carCode, uint8 day) external checkCarExists(carCode) payable {
        Car memory _car = cars[carCode];
        require(!_car.isRented, "This car has not yet returned to the garage");
        uint256 totalPrice = _car.Price * day;
        require(msg.value >= totalPrice, "Insufficient payment");
        Renter memory _rent;
        _rent.Car = _car;
        _rent.Day = day;
        _rent.RentalTime = block.timestamp;
        _rent.RenterAddress = msg.sender;
        _rent.IsReturned = false;
        _car.isRented = true;
        cars[carCode] = _car;
        renters.push(_rent);
        emit CarRented(carCode, msg.sender, day);
    }

    function availableCars() external view returns (string[] memory) {
        //Since there is no array filtering on Solidity yet, 
        //we verify data with the flow control mechanism. We add the appropriate data to the _tempCars array.
         Car[] memory _tempCars = new Car[](carId);
         uint256 index = 0;
        for(uint256 i = 0; i < carId; i++) {
            if(cars[carCodes[i]].isRented == false) {
                _tempCars[index] = cars[carCodes[i]];
                index++;
            }
        }

        //We skip unnecessary data and smooth the array
        string[] memory _cars = new string[](index);
        uint k = 0;
        for(uint i = 0; i < _tempCars.length; i++) {
            //In blank data, the price is shown as 0. We don't want these.
            if(_tempCars[i].Price != 0) {
                _cars[k] = _tempCars[i].CarCode;
                k++;
            }
        }
        return _cars;
    }


    function carDelivery(string memory carCode) external checkCarExists(carCode) {
        for(uint i = renters.length; i >= 1; i--) {
            i = i -1;
            if(keccak256(abi.encodePacked(renters[i].Car.CarCode)) == keccak256(abi.encodePacked(carCode)) && renters[i].Car.isRented) {
                
                if(renters[i].RenterAddress == msg.sender) {
                    renters[i].Car.isRented = false;
                    renters[i].ReturnTime = block.timestamp;
                    renters[i].IsReturned = true;
                    cars[carCode].isRented = false;
                    emit CarReturned(carCode, msg.sender);
                    return;
                }
            }
        }
        revert("You do not own the car to be towed to the garage");
    }

    receive() external payable {}

}
