// SPDX-License-Identifier: MIT
// File: math/SafeMath.sol

pragma solidity ^0.8.2;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a, "SafeMath: addition overflow");
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }

        c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Since Solidity automatically asserts when dividing by 0,
        // but we only need it to revert.
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Same reason as `div`.
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// File: token/erc20/IERC20.sol

interface IERC20 {
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    function totalSupply() external view returns (uint256 _supply);

    function balanceOf(address _owner) external view returns (uint256 _balance);

    function approve(address _spender, uint256 _value)
        external
        returns (bool _success);

    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256 _value);

    function transfer(address _to, uint256 _value)
        external
        returns (bool _success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool _success);
}

// File: token/erc20/ERC20.sol

contract ERC20 is IERC20 {
    using SafeMath for uint256;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) internal _allowance;

    function approve(address _spender, uint256 _value) public returns (bool) {
        _approve(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256)
    {
        return _allowance[_owner][_spender];
    }

    function increaseAllowance(address _spender, uint256 _value)
        public
        returns (bool)
    {
        _approve(
            msg.sender,
            _spender,
            _allowance[msg.sender][_spender].add(_value)
        );
        return true;
    }

    function decreaseAllowance(address _spender, uint256 _value)
        public
        returns (bool)
    {
        _approve(
            msg.sender,
            _spender,
            _allowance[msg.sender][_spender].sub(_value)
        );
        return true;
    }

    function transfer(address _to, uint256 _value)
        public
        returns (bool _success)
    {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool _success) {
        _transfer(_from, _to, _value);
        _approve(_from, msg.sender, _allowance[_from][msg.sender].sub(_value));
        return true;
    }

    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    ) internal {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");

        _allowance[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal {
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(
            _to != address(this),
            "ERC20: transfer to this contract address"
        );

        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
    }
}

// File: token/erc20/IERC20Detailed.sol

interface IERC20Detailed {
    function name() external view returns (string memory _name);

    function symbol() external view returns (string memory _symbol);

    function decimals() external view returns (uint8 _decimals);
}

contract Denarius is ERC20, IERC20Detailed {
    string public name;
    string public symbol;
    uint8 public decimals;
    address payable public owner;
    uint256 private seed;
    uint256 public gameIdCounter;

    constructor() {
        string memory _name = "Denarius";
        string memory _symbol = "DNR";
        uint8 _decimals = 18;
        uint256 _initialSupply = 1000000000;
        totalSupply = _initialSupply * 10**uint256(_decimals);
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        owner = payable(msg.sender);
        seed = uint256(keccak256(abi.encodePacked(block.timestamp)));
        gameIdCounter = 1;
    }

    struct Game {
        bytes32 gameId;
        address creator;
        uint256 blockId;
        bool generated;
        uint256 smallestNumber;
        uint256 biggerNumber;
        uint256 totalNumbers;
        string additionalInformation;
        uint256[] drawnNumber;
    }

    event eventGenerateNumberGame(
        bytes32 indexed gameId,
        uint256 indexed blockId,
        uint256[] drawnNumber
    );

    event eventCreateGame(
        bytes32 indexed gameId,
        address indexed creator,
        string additionalInformation
    );

    event eventGetGameInformation(
        bytes32 indexed gameId,
        uint256[] drawnNumber
    );

    mapping(bytes32 => Game) public games;

    function createGame(
        uint256 smallestNumber,
        uint256 biggerNumber,
        uint256 totalNumbers,
        string memory additionalInformation
    ) public returns (bytes32) {
        require(
            biggerNumber > smallestNumber &&
                totalNumbers > 0 &&
                totalNumbers <= (biggerNumber - smallestNumber + 1),
            "Invalid input parameters"
        );

        if (msg.sender != owner) {
            require(balanceOf[msg.sender] >= 1, "Insufficient balance");
            balanceOf[msg.sender] -= 1;
            balanceOf[owner] += 1;
        }

        bytes32 gameId = keccak256(abi.encodePacked(block.number, msg.sender));
        Game storage game = games[gameId];
        game.gameId = gameId;
        game.blockId = block.number;
        game.creator = msg.sender;
        game.generated = false;
        game.smallestNumber = smallestNumber;
        game.biggerNumber = biggerNumber;
        game.totalNumbers = totalNumbers;
        game.additionalInformation = additionalInformation;
        emit eventCreateGame(gameId, msg.sender, additionalInformation);
        return gameId;
    }

    function generateNumberGame(bytes32 gameId)
        public
        returns (uint256[] memory)
    {
        Game storage game = games[gameId];

        require(
            msg.sender == game.creator,
            "Only the game owner can generate the numbers"
        );
        require(!game.generated, "This game has already generated the numbers");

        uint256[] memory numbers = new uint256[](game.totalNumbers);

        uint256[] memory allNumbers = new uint256[](
            game.biggerNumber - game.smallestNumber + 1
        );
        for (uint256 i = 0; i < allNumbers.length; i++) {
            allNumbers[i] = game.smallestNumber + i;
        }
        uint256 lastIndex = allNumbers.length - 1;
        for (uint256 i = 0; i < game.totalNumbers; i++) {
            uint256 randomIndex = uint256(
                keccak256(abi.encodePacked(block.timestamp, gameId, i))
            ) % (lastIndex + 1);
            numbers[i] = allNumbers[randomIndex];
            allNumbers[randomIndex] = allNumbers[lastIndex];
            lastIndex--;
        }

        game.generated = true;
        game.drawnNumber = numbers;

        emit eventGenerateNumberGame(gameId, game.blockId, numbers);
        return numbers;
    }

    function gameInformation(bytes32 gameId) public view returns (Game memory) {
        Game storage game = games[gameId];
        return game;
    }
}
