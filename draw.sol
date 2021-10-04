pragma solidity ^0.4.24;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

library AddressUtils {
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    
    assembly { size := extcodesize(addr) }
    return size > 0;
  }
}

contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
        newOwner = address(0);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    modifier onlyNewOwner() {
        require(msg.sender != address(0));
        require(msg.sender == newOwner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        newOwner = _newOwner;
    }

    function acceptOwnership() public onlyNewOwner returns(bool) {
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract ERC721Receiver {
  bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

  function onERC721Received(address _from, uint256 _tokenId, bytes _data) public returns(bytes4);
}

contract ERC721Interface {
    // events
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    // interface
    function balanceOf(address _owner) public view returns (uint256);
    function ownerOf(uint256 _tokenId) public view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) public;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;
    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function approve(address _approved, uint256 _tokenId) public;
    function setApprovalForAll(address _operator, bool _approved) public;
    function getApproved(uint256 _tokenId) public view returns (address);
    function isApprovedForAll(address _owner, address _operator) public view returns (bool);
}

contract ERC721 is ERC721Interface {
    using SafeMath for uint256;
    using AddressUtils for address;

    bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

    mapping(uint256 => address) internal tokenOwner;

    mapping (address => uint256) internal ownedTokensCount;

    mapping (uint256 => address) internal tokenApprovals;

    mapping (address => mapping (address => bool)) internal operatorApprovals;


    modifier canTransfer(uint256 _tokenId) {
        require(isApprovedOrOwner(msg.sender, _tokenId));
        _;
    }

    function isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
        address owner = ownerOf(_tokenId);
        return _spender == owner || getApproved(_tokenId) == _spender || isApprovedForAll(owner, _spender);
    }

    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0));
        return ownedTokensCount[_owner];
    }

    function ownerOf(uint256 _tokenId) public view returns (address) {
        address owner = tokenOwner[_tokenId];
        require(owner != address(0));
        return owner;
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) public {
        if (_to.isContract()) {
            bytes4 retval = ERC721Receiver(_to).onERC721Received(_from, _tokenId, data);
            require(retval == ERC721_RECEIVED);
        }
        transferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    function clearApproval(address _owner, uint256 _tokenId) internal {
        require(ownerOf(_tokenId) == _owner);
        if (tokenApprovals[_tokenId] != address(0)) {
            tokenApprovals[_tokenId] = address(0);
            emit Approval(_owner, address(0), _tokenId);
        }
    }

    function removeTokenFrom(address _from, uint256 _tokenId) internal {
        require(ownerOf(_tokenId) == _from);
        ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
        tokenOwner[_tokenId] = address(0);
    }

    function addTokenTo(address _to, uint256 _tokenId) internal {
        require(tokenOwner[_tokenId] == address(0));
        tokenOwner[_tokenId] = _to;
        ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public canTransfer(_tokenId) {
        require(_from != address(0));
        require(_to != address(0));

        clearApproval(_from, _tokenId);
        removeTokenFrom(_from, _tokenId);
        addTokenTo(_to, _tokenId);

        emit Transfer(_from, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) public {
        address owner = ownerOf(_tokenId);
        require(_approved != owner);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

        if (getApproved(_tokenId) != address(0) || _approved != address(0)) {
            tokenApprovals[_tokenId] = _approved;
            emit Approval(owner, _approved, _tokenId);
        }
    }

    function setApprovalForAll(address _operator, bool _approved) public {
        require(_operator != msg.sender);
        operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function getApproved(uint256 _tokenId) public view returns (address) {
        return tokenApprovals[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return operatorApprovals[_owner][_operator];
    }

    function onERC721Received(address, uint256, bytes) public returns (bytes4) {
        return ERC721_RECEIVED;
    }
}


contract RandomEngine is Ownable {
    using SafeMath for uint256;
    using AddressUtils for address;
    
    event AuctionCreated(uint256 _index, address _creator, address _asset);
    event AuctionBid(uint256 _index, address _bidder, uint256 amount);
    event AuctionLucky(uint256 _index, address _bidder);
    event Claim(uint256 auctionIndex, address claimer);

    enum Status { pending, active, finished }
    struct Auction {
        address assetAddress;
        uint256 assetId;

        address creator;

        uint256 betPrice;
        uint256 percentage;
        uint256 increasePercentage;
        
        uint256 bidCount;
        bool status;
    }
    
    Auction[] private auctions;
    
    function createRandom (address _assetAddress,
                           uint256 _assetId,
                           uint256 _betPrice, 
                           uint256 _percentage,
                           uint256 _increasePercentage) public onlyOwner returns (uint256) {
        
        require(_assetAddress.isContract());
        ERC721 asset = ERC721(_assetAddress);
        require(asset.ownerOf(_assetId) == msg.sender);
        require(asset.getApproved(_assetId) == address(this));
        
        Auction memory auction = Auction({
            creator: msg.sender,
            assetAddress: _assetAddress,
            assetId: _assetId,
            betPrice: _betPrice,
            percentage: _percentage,
            increasePercentage: _increasePercentage,
            bidCount: 0,
            status: true
        });
        uint256 index = auctions.push(auction) - 1;

        emit AuctionCreated(index, auction.creator, auction.assetAddress);
        
        return index;
    }
    
    function bid(uint256 auctionIndex) public payable returns (bool) {
        Auction storage auction = auctions[auctionIndex];
        require(auction.creator != address(0));
        require(auction.status);
        require(auction.betPrice <= msg.value);
        ERC721 asset = ERC721(auction.assetAddress);
        require(asset.ownerOf(auction.assetId) == auction.creator);
        require(asset.getApproved(auction.assetId) == address(this));
        
        auction.bidCount = auction.bidCount.add(1);
        uint randomHash = uint(keccak256(block.difficulty, now)) % 100;
        
        if (auction.bidCount.mul(auction.percentage) > 100) {
            uint256 overLucky = auction.bidCount.mul(auction.percentage).sub(100);
            if (randomHash < auction.percentage.add(overLucky)) {
                asset.transferFrom(auction.creator, msg.sender, auction.assetId);
                auction.status = false;
                emit AuctionLucky(auctionIndex, msg.sender);
                return true;
            }
        } else {
            if (randomHash < auction.percentage) {
                asset.transferFrom(auction.creator, msg.sender, auction.assetId);
                auction.status = false;
                emit AuctionLucky(auctionIndex, msg.sender);
                return true;
            }
        }
        

        emit AuctionBid(auctionIndex, msg.sender, msg.value);
        return false;
    }
    
    function claimBalance(uint256 amount) public onlyOwner returns (bool) {
        msg.sender.transfer(amount);
        return true;
    }

    function getTotal() public view returns (uint256) { return auctions.length; }
    function getNowPercentage(uint256 index) public view returns (uint256) {
        Auction storage auction = auctions[index];
        if (auction.bidCount.mul(auction.percentage) > 100) {
            uint256 overLucky = auction.bidCount.mul(auction.percentage).sub(100);
            return overLucky;
        }
        return auction.percentage;
    }
    function getDefaultPercentage(uint256 index) public view returns (uint256) { return auctions[index].percentage; }
    function getIncreasePercentage(uint256 index) public view returns (uint256) { return auctions[index].increasePercentage; }
    function getAssetAddress(uint256 index) public view returns (address) { return auctions[index].assetAddress; }
    function getAssetId(uint256 index) public view returns (uint256) { return auctions[index].assetId; }
    function getStatus(uint256 index) public view returns (bool) { return auctions[index].status; }
    function getBidCount(uint256 index) public view returns (uint256) { return auctions[index].bidCount; }
}
