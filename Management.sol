// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; 
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

    //**** Interfaces ****//

    interface IBatteriesLOT{
    function mint(string memory, uint256[3] memory, address) external returns(uint256, string memory);
    function transferFrom(address from, address to, uint256 tokenId) external;


    }

    interface IMotorsLOT{
    function mint(string memory, uint256[3] memory, address) external returns(uint256, string memory);
    function transferFrom(address from, address to, uint256 tokenId) external;
  
    }   

    interface IPropellersLOT{
    function mint(string memory, uint256[3] memory, address) external returns(uint256, string memory);
    function transferFrom(address from, address to, uint256 tokenId) external;
        
    }

    interface IFcontrollersLOT{
    function mint(string memory, uint256[3] memory, address) external returns(uint256, string memory);
    function transferFrom(address from, address to, uint256 tokenId) external;
        
    }

    interface IEScontrollersLOT{
    function mint(string memory, uint256[3] memory, address) external returns(uint256, string memory);
    function transferFrom(address from, address to, uint256 tokenId) external;
       
    }

    interface IDrone{
    function mint(string memory, address) external returns(uint256, string memory);
    function transferFrom(address from, address to, uint256 tokenId) external;
       
    }
contract Management is ReentrancyGuard{

    //**** State Variables ****//

    // Interfaces with the ERC721 smart contracts for each component
    IERC721 public batteriesSC;
    IERC721 public motorsSC;
    IERC721 public propellersSC;
    IERC721 public fcontrollerSC; //Flight Controller
    IERC721 public escontrollerSC; //Electronic Speed Controller

    //Interfaces with the LOTs smart contracts, Can they be IERC721??
    IBatteriesLOT public BatteriesLOT;
    IMotorsLOT public MotorsLOT;
    IPropellersLOT public PropellersLOT;
    IFcontrollersLOT public FcontrollersLOT;
    IEScontrollersLOT public EScontrollersLOT;
    IDrone public Drone;

    address public manager; //The entity responsible for deploying the smart contract, registering users, and managing the smart contract
    uint256 public batteriesCount; //A counter for battery components
    uint256 public batteriesLotCount; //A counter for battery LOTs
    uint256 public motorsCount; 
    uint256 public motorsLotCount;
    uint256 public propellersCount;
    uint256 public propellersLotCount;
    uint256 public fControllersCount;
    uint256 public fControllersLotCount;
    uint256 public esControllersCount;
    uint256 public esControllersLotCount;
    uint256 public dronesCount;

    mapping(address => bool) public Supplier;
    mapping(address => bool) public Manufacturer;
    mapping(address => bool) public Distributor;
    mapping(address => bool) public Retailer;
    mapping(address => bool) public AuthorizedSC;


    struct ComponentDetails{
        uint256 componentCount;
        uint256 componentID; 
        IERC721 componentSC; 
        address payable Owner;
    }

    struct LotDetails{
        uint256 LotCount; //This is the number within the Management SC
        uint256 LotID; //This is the ID within the NFT smart contract
        address LotSC; 
        uint256 price;
        address payable Owner;
    }

    struct DroneDetails{
        uint256 DroneCount;
        uint256 DroneID;
        string DroneURI;
        address DroneSC;
        uint256 batteryID;
        uint256 motorID;
        uint256 propellerID;
        uint256 fcontrollerID;
        uint256 escontrollerID;
        address payable Owner;
    }

    //componentCount => ComponentDetails [Not needed because only LOTs are listed in this SC, single components are not listed]

    mapping(uint256 => ComponentDetails) public batteriesMapping;
    mapping(uint256 => ComponentDetails) public motorsMapping;
    mapping(uint256 => ComponentDetails) public propellersMapping;
    mapping(uint256 => ComponentDetails) public fControllersMapping;
    mapping(uint256 => ComponentDetails) public esControllersMapping;

    //LotCount => LotDetails

    mapping(uint256 => LotDetails) public batteriesLotMapping;
    mapping(uint256 => LotDetails) public motorsLotMapping;
    mapping(uint256 => LotDetails) public propellersLotMapping;
    mapping(uint256 => LotDetails) public fControllersLotMapping;
    mapping(uint256 => LotDetails) public esControllersLotMapping;

    //DroneCount => Drone Details

    mapping(uint256 => DroneDetails) public DronesMapping;


    //** NFT Composability Mappings **//

    //ComponentSC ==> LotSC
    //mapping(address => address) public parentToChildAddress; //Maps the SC address of the parent LOT to child Component

    //LotID => componentID[i] (assuming each LOT contains up to 3 components)
    mapping(uint256 => uint256[3]) public linkBatterytoLot;
    mapping(uint256 => uint256[3]) public linkMotortoLot;
    mapping(uint256 => uint256[3]) public linkPropellertoLot;
    mapping(uint256 => uint256[3]) public linkFControllertoLot;
    mapping(uint256 => uint256[3]) public linkESControllertoLot;

    // DroneID => (componentSC => componentID)
    mapping(uint256 => mapping(address => uint256)) public linkComponenttoDrone;


    //**** Events ****//

    //Lot Creation Events
    event BatteryLotCreated (address indexed owner, uint256 tokenID, string tokenURI);
    event MotorLotCreated (address indexed owner, uint256 tokenID, string tokenURI);
    event PropellerLotCreated (address indexed owner, uint256 tokenID, string tokenURI);
    event FControllerLotCreated (address indexed owner, uint256 tokenID, string tokenURI);
    event ESControllerLotCreated (address indexed owner, uint256 tokenID, string tokenURI);

    //Lot listing events
    event BatteryLOTListed(uint256 lotcount, address SCaddress, uint256 tokenID, uint256 listingprice, address lister);
    event MotorLOTListed(uint256 lotcount, address SCaddress, uint256 tokenID, uint256 listingprice, address lister);
    event PropellerLOTListed(uint256 lotcount, address SCaddress, uint256 tokenID, uint256 listingprice, address lister);
    event FControllerLOTListed(uint256 lotcount, address SCaddress, uint256 tokenID, uint256 listingprice, address lister);
    event ESControllerLOTListed(uint256 lotcount, address SCaddress, uint256 tokenID, uint256 listingprice, address lister);

    //Lot Purchasing events
    event BatteryLOTPurchased(uint256 lotCount, address SCaddress, uint256 tokenID, address purchaser, address seller);
    event MotorLOTPurchased(uint256 lotCount, address SCaddress, uint256 tokenID, address purchaser, address seller);
    event PropellerLOTPurchased(uint256 lotCount, address SCaddress, uint256 tokenID, address purchaser, address seller);
    event FControllerLOTPurchased(uint256 lotCount, address SCaddress, uint256 tokenID, address purchaser, address seller);
    event ESControllerLOTPurchased(uint256 lotCount, address SCaddress, uint256 tokenID, address purchaser, address seller);

    //Drone Assembly 
    event DroneAssembled(uint256 dronecount, uint256 droneID, string droneURI, uint256 batteryid, uint256 motorid, uint256 propellerid, uint256 fcontrollerid, uint256 escontrollerid, address owner);

    
    //**** Constructor ****//

    constructor(address _batteriesSC,  address _motorsSC, address _propellersSC, address _fcontrollerSC, address _escontrollerSC, address _batteriesLOTSC,  address _motorsLOTSC, address _propellersLOTSC, address _fcontrollerLOTSC, address _escontrollerLOTSC, address _droneSC){
        batteriesSC = IERC721(_batteriesSC);
        motorsSC = IERC721(_motorsSC);
        propellersSC = IERC721(_propellersSC);
        fcontrollerSC = IERC721(_fcontrollerSC);
        escontrollerSC = IERC721(_escontrollerSC);
        BatteriesLOT = IBatteriesLOT(_batteriesLOTSC);  
        MotorsLOT = IMotorsLOT(_motorsLOTSC);  
        PropellersLOT = IPropellersLOT (_propellersLOTSC);  
        FcontrollersLOT = IFcontrollersLOT(_fcontrollerLOTSC);  
        EScontrollersLOT  = IEScontrollersLOT (_escontrollerLOTSC);
        Drone = IDrone(_droneSC);
        AuthorizedSC[_batteriesLOTSC] = true; 
        AuthorizedSC[_motorsLOTSC] = true; 
        AuthorizedSC[_propellersLOTSC] = true; 
        AuthorizedSC[_fcontrollerLOTSC] = true; 
        AuthorizedSC[_escontrollerLOTSC] = true; 
        manager = msg.sender;
    }

    //**** Modifiers ****//
    modifier onlyManager{
        require(msg.sender == manager, "Only the manager of this smart contract can run this function");
        _;
    }

    modifier onlySupplier{
        require(Supplier[msg.sender], "Only authorized suppliers are allowed to run this function");
        _;
    }

    modifier onlyManufacturer{
        require(Manufacturer[msg.sender], "Only authorized manufacturers are allowed to run this function");
        _;
    }

    modifier onlyDistributor{
        require(Distributor[msg.sender], "Only authorized distributors are allowed to run this function");
        _;
    }

    modifier onlyRetailer{
        require(Retailer[msg.sender], "Only authorized retailers are allowed to run this function");
        _;
    }

    modifier onlyBatteryLOTSmartContract{
         require(msg.sender == address(BatteriesLOT), "Only the batteries Lot smart contract can run this function");
        _;
    }

    modifier onlyMotorLOTSmartContract{
         require(msg.sender == address(MotorsLOT), "Only the motors Lot smart contract can run this function");
        _;
    }

    modifier onlyPropellersLOTSmartContract{
         require(msg.sender == address(PropellersLOT), "Only the propellers Lot smart contract can run this function");
        _;
    }

    modifier onlyFControllersLOTSmartContract{
         require(msg.sender == address(FcontrollersLOT), "Only the flight controllers Lot smart contract can run this function");
        _;
    }

    modifier onlyESControllerLOTSmartContract{
         require(msg.sender == address(EScontrollersLOT), "Only the electronic speed controllers Lot smart contract can run this function");
        _;
    }

    modifier onlyAuthorizedSC{
        require(AuthorizedSC[msg.sender], "Only authorized smart contracts can run this function");
        _;
    }

                            //**** Registration Functions ****//

    function registerSupplier(address _supplier) external onlyManager{
        Supplier[_supplier] = true;
    }

    function registerManufacturer(address _manufacturer) external onlyManager{
        Manufacturer[_manufacturer] = true;
    }

    function registerDistributor(address _distributor) external onlyManager{
        Distributor[_distributor] = true;
    }

    function RegisterRetailer(address _retailer) external onlyManager{
        Retailer[_retailer] = true;
    }    

                            //************Linking Functions************//

    //This function links each component (child) to its Lot (Parent) for batteries
    function linkBatteriestoLot (uint256 _parentID, uint256[3] memory _childIDs) external onlyAuthorizedSC{
        for(uint256 i = 0; i < _childIDs.length; i++ ){
            linkBatterytoLot[_parentID][i] = _childIDs[i];
        }
    }

    function linkMotorstoLot (uint256 _parentID, uint256[3] memory _childIDs) external onlyAuthorizedSC{
        for(uint256 i = 0; i < _childIDs.length; i++ ){
            linkMotortoLot[_parentID][i] = _childIDs[i];
        }
    }    

    function linkPropellerstoLot (uint256 _parentID, uint256[3] memory _childIDs) external onlyAuthorizedSC{
        for(uint256 i = 0; i < _childIDs.length; i++ ){
            linkPropellertoLot[_parentID][i] = _childIDs[i];
        }
    }

    function linkFControllerstoLot (uint256 _parentID, uint256[3] memory _childIDs) external onlyAuthorizedSC{
        for(uint256 i = 0; i < _childIDs.length; i++ ){
            linkFControllertoLot[_parentID][i] = _childIDs[i];
        }
    }

    function linkESControllerstoLot (uint256 _parentID, uint256[3] memory _childIDs) external onlyAuthorizedSC{
        for(uint256 i = 0; i < _childIDs.length; i++ ){
            linkESControllertoLot[_parentID][i] = _childIDs[i];
        }
    }


    function linkComponentstoDrone(address _componentSC, uint256 _parentID, uint256 _childID) external onlyAuthorizedSC{
            linkComponenttoDrone[_parentID][_componentSC] = _childID;
        }        

                                //************LOT Creation Functions************//

    //This function allows the supplier to create Batteries LOT by providing 3 battery NFTs 
    function createBatteryLot(uint256[3] memory _tokenIDs, string memory _tokenURI) external onlySupplier{
        for(uint256 i = 0; i < _tokenIDs.length; i++){
            require(batteriesSC.ownerOf(_tokenIDs[i]) == msg.sender,"The token ID does not belong to the caller");
        }

        for(uint256 i = 0; i < _tokenIDs.length; i++){
            batteriesSC.transferFrom(msg.sender, address(this), _tokenIDs[i]);
            batteriesCount++;
            batteriesMapping[batteriesCount] = ComponentDetails(batteriesCount, _tokenIDs[i], IERC721(batteriesSC), payable(msg.sender));
        }

        (uint256 tokenID, string memory tokenURI) = BatteriesLOT.mint(_tokenURI, _tokenIDs, msg.sender);

        emit BatteryLotCreated (msg.sender, tokenID, tokenURI);

    }

    function createMotorLot(uint256[3] memory _tokenIDs, string memory _tokenURI) external onlySupplier{
        for(uint256 i = 0; i < _tokenIDs.length; i++){
            require(motorsSC.ownerOf(_tokenIDs[i]) == msg.sender,"The token ID does not belong to the caller");
        }

        for(uint256 i = 0; i < _tokenIDs.length; i++){
            motorsSC.transferFrom(msg.sender, address(this), _tokenIDs[i]);
            motorsCount++;
            motorsMapping[motorsCount] = ComponentDetails(motorsCount, _tokenIDs[i], IERC721(motorsSC), payable(msg.sender));            
        }

         (uint256 tokenID, string memory tokenURI) = MotorsLOT.mint(_tokenURI, _tokenIDs, msg.sender);

        emit MotorLotCreated (msg.sender, tokenID, tokenURI);

    }

    function createPropellerLot(uint256[3] memory _tokenIDs, string memory _tokenURI) external onlySupplier{
        for(uint256 i = 0; i < _tokenIDs.length; i++){
            require(propellersSC.ownerOf(_tokenIDs[i]) == msg.sender,"The token ID does not belong to the caller");
        }

        for(uint256 i = 0; i < _tokenIDs.length; i++){
            propellersSC.transferFrom(msg.sender, address(this), _tokenIDs[i]);
            propellersCount++;
            propellersMapping[propellersCount] = ComponentDetails(propellersCount, _tokenIDs[i], IERC721(propellersSC), payable(msg.sender));            
        }            
        

         (uint256 tokenID, string memory tokenURI) = PropellersLOT.mint(_tokenURI, _tokenIDs, msg.sender);

        emit PropellerLotCreated (msg.sender, tokenID, tokenURI);

    }
    
    function createFControllerLot(uint256[3] memory _tokenIDs, string memory _tokenURI) external onlySupplier{
        for(uint256 i = 0; i < _tokenIDs.length; i++){
            require(fcontrollerSC.ownerOf(_tokenIDs[i]) == msg.sender,"The token ID does not belong to the caller");
        }

        for(uint256 i = 0; i < _tokenIDs.length; i++){
            fcontrollerSC.transferFrom(msg.sender, address(this), _tokenIDs[i]);
            fControllersCount++;
            fControllersMapping[fControllersCount] = ComponentDetails(fControllersCount, _tokenIDs[i], IERC721(fcontrollerSC), payable(msg.sender));               
        }

         (uint256 tokenID, string memory tokenURI) = FcontrollersLOT.mint(_tokenURI, _tokenIDs, msg.sender);

        emit FControllerLotCreated (msg.sender, tokenID, tokenURI);

    }

    function createESControllerLot(uint256[3] memory _tokenIDs, string memory _tokenURI) external onlySupplier{
        for(uint256 i = 0; i < _tokenIDs.length; i++){
            require(escontrollerSC.ownerOf(_tokenIDs[i]) == msg.sender,"The token ID does not belong to the caller");
        }

        for(uint256 i = 0; i < _tokenIDs.length; i++){
            escontrollerSC.transferFrom(msg.sender, address(this), _tokenIDs[i]);
            esControllersCount++;
            esControllersMapping[esControllersCount] = ComponentDetails(esControllersCount, _tokenIDs[i], IERC721(escontrollerSC), payable(msg.sender));            
        }

         (uint256 tokenID, string memory tokenURI) = EScontrollersLOT.mint(_tokenURI, _tokenIDs, msg.sender);

        emit ESControllerLotCreated (msg.sender, tokenID, tokenURI);

    }


                                //************LOT Listing, Purchasing, and Redemption Functions************//
    //The supplier lists the LOT for manufacturers, NOTE: Withdrawing the listed LOT is not included for simplicity
    function listBatteryLot(uint256 _tokenID, uint256 _listingprice) external nonReentrant onlySupplier{
        BatteriesLOT.transferFrom(msg.sender, address(this), _tokenID); //The execution will revert if the caller is not the owner of the NFT
        batteriesLotCount++;
        batteriesLotMapping[batteriesLotCount] = LotDetails(batteriesLotCount, _tokenID, address(BatteriesLOT), _listingprice * 1 ether, payable(msg.sender));

        emit BatteryLOTListed(batteriesLotCount, address(BatteriesLOT), _tokenID, _listingprice, msg.sender);

    }


    function purchaseBatteryLot(uint256 _LotCount) external payable  nonReentrant onlyManufacturer{
        LotDetails storage BLot = batteriesLotMapping[_LotCount];

        require(_LotCount > 0 && _LotCount <= batteriesLotCount, "The requested LOT is invalid" );
        require(msg.value == BLot.price, "The transferred value is invalid");

        BatteriesLOT.transferFrom(address(this), msg.sender, BLot.LotID);

        emit BatteryLOTPurchased(batteriesLotCount, address(BatteriesLOT), BLot.LotID, msg.sender, BLot.Owner );

        BLot.Owner = payable(msg.sender);

    }

    function redeemBatteries(uint256 _LotCount) external nonReentrant {
        LotDetails storage BLot = batteriesLotMapping[_LotCount];
        require(msg.sender == BLot.Owner, "Only the current owner of the LOT can execute this function");
        BatteriesLOT.transferFrom(msg.sender, address(this), BLot.LotID); //The Lot NFT is transferred back to the SC
        for(uint256 i = 0; i < linkBatterytoLot[BLot.LotID].length; i++ ){
            batteriesSC.safeTransferFrom(address(this), msg.sender, linkBatterytoLot[BLot.LotID][i]);
            batteriesMapping[linkBatterytoLot[BLot.LotID][i]].Owner = payable(msg.sender);
        }
    }

    function listMotorLot(uint256 _tokenID, uint256 _listingprice) external nonReentrant onlySupplier{
        MotorsLOT.transferFrom(msg.sender, address(this), _tokenID); //The execution will revert if the caller is not the owner of the NFT
        motorsLotCount++;
        motorsLotMapping[motorsLotCount] = LotDetails(motorsLotCount, _tokenID, address(MotorsLOT), _listingprice * 1 ether, payable(msg.sender));

        emit MotorLOTListed(motorsLotCount, address(MotorsLOT), _tokenID, _listingprice, msg.sender);

    }


    function purchaseMotorLot(uint256 _LotCount) external payable  nonReentrant onlyManufacturer{
        LotDetails storage MLot = motorsLotMapping[_LotCount];

        require(_LotCount > 0 && _LotCount <= motorsLotCount, "The requested LOT is invalid" );
        require(msg.value == MLot.price, "The transferred value is invalid");

        MotorsLOT.transferFrom(address(this), msg.sender, MLot.LotID);

        emit MotorLOTPurchased(motorsLotCount, address(MotorsLOT), MLot.LotID, msg.sender, MLot.Owner );

        MLot.Owner = payable(msg.sender);
    }

    function redeemMotors(uint256 _LotCount) external nonReentrant {
        LotDetails storage MLot = motorsLotMapping[_LotCount];
        require(msg.sender == MLot.Owner, "Only the current owner of the LOT can execute this function");
        MotorsLOT.transferFrom(msg.sender, address(this), MLot.LotID); //The Lot NFT is transferred back to the SC
        for(uint256 i = 0; i < linkMotortoLot[MLot.LotID].length; i++ ){
            motorsSC.safeTransferFrom(address(this), msg.sender, linkMotortoLot[MLot.LotID][i]);
            motorsMapping[linkMotortoLot[MLot.LotID][i]].Owner = payable(msg.sender);
        }
    }    

    function listPropellerLot(uint256 _tokenID, uint256 _listingprice) external nonReentrant onlySupplier{
        PropellersLOT.transferFrom(msg.sender, address(this), _tokenID); //The execution will revert if the caller is not the owner of the NFT
        propellersLotCount++;
        propellersLotMapping[propellersLotCount] = LotDetails(propellersLotCount, _tokenID, address(PropellersLOT), _listingprice  * 1 ether, payable(msg.sender));

        emit PropellerLOTListed(propellersLotCount, address(PropellersLOT), _tokenID, _listingprice, msg.sender);

    }


    function purchasePropellerLot(uint256 _LotCount) external payable  nonReentrant onlyManufacturer{
        LotDetails storage PLot = propellersLotMapping[_LotCount];

        require(_LotCount > 0 && _LotCount <= propellersLotCount, "The requested LOT is invalid" );
        require(msg.value == PLot.price, "The transferred value is invalid");

        PropellersLOT.transferFrom(address(this), msg.sender, PLot.LotID);

        emit PropellerLOTPurchased(propellersLotCount, address(PropellersLOT), PLot.LotID, msg.sender, PLot.Owner );

        PLot.Owner = payable(msg.sender);

    }

    function redeemPropellers(uint256 _LotCount) external nonReentrant {
        LotDetails storage PLot = propellersLotMapping[_LotCount];
        require(msg.sender == PLot.Owner, "Only the current owner of the LOT can execute this function");
        PropellersLOT.transferFrom(msg.sender, address(this), PLot.LotID); //The Lot NFT is transferred back to the SC
        for(uint256 i = 0; i < linkPropellertoLot[PLot.LotID].length; i++ ){
            propellersSC.safeTransferFrom(address(this), msg.sender, linkPropellertoLot[PLot.LotID][i]);
            propellersMapping[linkPropellertoLot[PLot.LotID][i]].Owner = payable(msg.sender);
        }
    }    

    function listFControllerLot(uint256 _tokenID, uint256 _listingprice) external nonReentrant onlySupplier{
        FcontrollersLOT.transferFrom(msg.sender, address(this), _tokenID); //The execution will revert if the caller is not the owner of the NFT
        fControllersLotCount++;
        fControllersLotMapping[fControllersLotCount] = LotDetails(fControllersLotCount, _tokenID, address(FcontrollersLOT), _listingprice * 1 ether, payable(msg.sender));

        emit FControllerLOTListed(fControllersLotCount, address(FcontrollersLOT), _tokenID, _listingprice, msg.sender);

    }


    function purchaseFControllerLot(uint256 _LotCount) external payable  nonReentrant onlyManufacturer{
        LotDetails storage FCLot = fControllersLotMapping[_LotCount];

        require(_LotCount > 0 && _LotCount <= fControllersLotCount, "The requested LOT is invalid" );
        require(msg.value == FCLot.price, "The transferred value is invalid");

        FcontrollersLOT.transferFrom(address(this), msg.sender, FCLot.LotID);

        emit FControllerLOTPurchased(fControllersLotCount, address(FcontrollersLOT), FCLot.LotID, msg.sender, FCLot.Owner );
        
        FCLot.Owner = payable(msg.sender);

    }

    function redeemFControllers(uint256 _LotCount) external nonReentrant {
        LotDetails storage FCLot = fControllersLotMapping[_LotCount];
        require(msg.sender == FCLot.Owner, "Only the current owner of the LOT can execute this function");
        FcontrollersLOT.transferFrom(msg.sender, address(this), FCLot.LotID); //The Lot NFT is transferred back to the SC
        for(uint256 i = 0; i < linkFControllertoLot[FCLot.LotID].length; i++ ){
            fcontrollerSC.safeTransferFrom(address(this), msg.sender, linkFControllertoLot[FCLot.LotID][i]);
            fControllersMapping[linkFControllertoLot[FCLot.LotID][i]].Owner = payable(msg.sender);
        }
    }   

    function listESControllerLot(uint256 _tokenID, uint256 _listingprice) external nonReentrant onlySupplier{
        EScontrollersLOT.transferFrom(msg.sender, address(this), _tokenID); //The execution will revert if the caller is not the owner of the NFT
        esControllersLotCount++;
        esControllersLotMapping[esControllersLotCount] = LotDetails(esControllersLotCount, _tokenID, address(EScontrollersLOT), _listingprice * 1 ether, payable(msg.sender));

        emit ESControllerLOTListed(esControllersLotCount, address(EScontrollersLOT), _tokenID, _listingprice, msg.sender);

    }


    function purchaseESControllerLot(uint256 _LotCount) external payable  nonReentrant onlyManufacturer{
        LotDetails storage ESCLot = esControllersLotMapping[_LotCount];

        require(_LotCount > 0 && _LotCount <= esControllersLotCount, "The requested LOT is invalid" );
        require(msg.value == ESCLot.price, "The transferred value is invalid");

        EScontrollersLOT.transferFrom(address(this), msg.sender, ESCLot.LotID);

        emit ESControllerLOTPurchased(esControllersLotCount, address(EScontrollersLOT), ESCLot.LotID, msg.sender, ESCLot.Owner );
        ESCLot.Owner = payable(msg.sender);

    }
    
    function redeemESControllers(uint256 _LotCount) external nonReentrant {
        LotDetails storage ESCLot = esControllersLotMapping[_LotCount];
        require(msg.sender == ESCLot.Owner, "Only the current owner of the LOT can execute this function");
        EScontrollersLOT.transferFrom(msg.sender, address(this), ESCLot.LotID); //The Lot NFT is transferred back to the SC
        for(uint256 i = 0; i < linkESControllertoLot[ESCLot.LotID].length; i++ ){
            escontrollerSC.safeTransferFrom(address(this), msg.sender, linkESControllertoLot[ESCLot.LotID][i]);
            esControllersMapping[linkESControllertoLot[ESCLot.LotID][i]].Owner = payable(msg.sender);
        }
    }                   

                                //************Drones Assemble************//
                                
    //Double-check if the linkage for drones should be done through the drone SC like the LOT smart contracts
    function assembleDrone(uint256 _batteryID, uint256 _motorID, uint256 _propellerID, uint256 _fcontrollerID, uint256 _escontrollerID, string memory _tokenURI) external nonReentrant onlyManufacturer{
        //uint256[5] memory _tokenIDs = [_batteryID, _motorID, _propellerID, _fcontrollerID, _escontrollerID];
        ComponentDetails storage battery = batteriesMapping[_batteryID];
        ComponentDetails storage motor = motorsMapping[_motorID];
        ComponentDetails storage propeller = propellersMapping[_propellerID];
        ComponentDetails storage fcontroller = fControllersMapping[_fcontrollerID];
        ComponentDetails storage escontroller = esControllersMapping[_escontrollerID];

        require(battery.Owner == msg.sender && motor.Owner == msg.sender && propeller.Owner == msg.sender && fcontroller.Owner == msg.sender && escontroller.Owner == msg.sender, "One or more of the inserted components are not owned by the caller");
        batteriesSC.transferFrom(msg.sender, address(this), battery.componentID);
        motorsSC .transferFrom(msg.sender, address(this), motor.componentID);
        propellersSC .transferFrom(msg.sender, address(this), propeller.componentID);
        fcontrollerSC .transferFrom(msg.sender, address(this), fcontroller.componentID);
        escontrollerSC .transferFrom(msg.sender, address(this), escontroller.componentID);

        dronesCount++;

        (uint256 tokenID, string memory tokenURI) = Drone.mint(_tokenURI, msg.sender);

        DronesMapping[dronesCount] = DroneDetails(dronesCount, tokenID, tokenURI, address(Drone), _batteryID, _motorID, _propellerID, _fcontrollerID, _escontrollerID, payable(msg.sender));
        linkComponenttoDrone[dronesCount][address(batteriesSC)] = battery.componentID;
        linkComponenttoDrone[dronesCount][address(motorsSC)] = motor.componentID;
        linkComponenttoDrone[dronesCount][address(propellersSC)] = propeller.componentID;
        linkComponenttoDrone[dronesCount][address(fcontrollerSC)] = fcontroller.componentID;
        linkComponenttoDrone[dronesCount][address(escontrollerSC)] = escontroller.componentID;

        emit DroneAssembled(dronesCount, tokenID, tokenURI, battery.componentID, motor.componentID, propeller.componentID, fcontroller.componentID, escontroller.componentID, msg.sender);
    
    }

                                //************Drones Delivery************//


}

