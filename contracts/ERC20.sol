// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

contract ERC20 {
    uint256 public totalSupply;
    string public name;
    string public symbol;

    bool internal locked;

    modifier noReentrant() {
        require(!locked, "ERC20: No re-entrancy.");
        locked = true;
        _;
        locked = false;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Redeem(address indexed from, uint256 amount);

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance; 

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;

        _mint(msg.sender, 100e18);
    }

    function decimals() external pure returns(uint8) {
        return 18;
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        return _transfer(msg.sender, recipient, amount);
    } 

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        uint256 currentAllowance = allowance[sender][msg.sender];

        require(currentAllowance >= amount, "ERC20: Amount exceeded the allowance value.");

        allowance[sender][msg.sender] -= amount;

        return _transfer(sender, recipient, amount);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        require(spender != address(0), "ERC20: Approve to the zero address.");

        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) private returns (bool) {
        require(recipient != address(0), "ERC20: Transfer to the zero address.");
        
        uint256 senderBalance = balanceOf[sender];

        require(senderBalance >= amount, "ERC20: Transfer amount exceeded.");

        balanceOf[sender] = senderBalance - amount;
        balanceOf[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        return true;
    }

    function _mint(address to, uint256 amount) internal {
        require(to != address(0), "ERC20: Mint to the zero address.");

        totalSupply += amount;
        balanceOf[to] += amount;

        emit Transfer(address(0), to, amount);
    }

    function deposit() external payable {
        uint256 tokensToMint = msg.value;

        _mint(msg.sender, tokensToMint);
    }

    function redeem(uint256 amount) external noReentrant{
        require(allowance[msg.sender][address(this)] >= amount, "ERC20: Redeem amount exceeded.");

        transferFrom(msg.sender, address(this), amount);

        _burn(amount);

        uint256 etherValue = amount;

        (bool sent,) = payable(msg.sender).call{value: amount}("");

        require(sent, "ERC20: Failed to send Ether.");

        emit Redeem(msg.sender, etherValue);
    }

    function _burn(uint256 amount) private {
        require(balanceOf[address(this)] >= amount, "ERC20: Insufficient balance for burning.");

        balanceOf[address(this)] -= amount;
        totalSupply -= amount;

        emit Transfer(address(this), address(0), amount);
    }

}