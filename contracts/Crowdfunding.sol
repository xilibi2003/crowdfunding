pragma solidity >=0.6.0 <0.7.0;


contract Crowdfunding {
    // 创作者
    address public author;

    // 参与金额
    mapping(address => uint) public joined;

    // 众筹目标
    uint constant Target = 10 ether;

    // 众筹截止时间
    uint public endTime;

    // 记录当前众筹价格
    uint public price  = 0.02 ether ;

    // 作者提取资金之后，关闭众筹
    bool public closed = false;

    // address[] joinAccouts;
    event Join(address indexed user, uint price);

    // 部署合约时调用，初始化作者以及众筹结束时间
    constructor() public {
        author = msg.sender;
        endTime = block.timestamp + 30 days;
    }

    // 更新价格，这是一个内部函数
    function updatePrice() internal {
        uint rise = address(this).balance / 1 ether * 0.002 ether;
        price = 0.02 ether + rise;
    }

    // 用户向合约转账时 触发的回调函数
    receive() external payable {
        require(block.timestamp < endTime && !closed  , "众筹已结束");
        require(joined[msg.sender] == 0 , "你已经参与过众筹");

        require (msg.value >= price, "出价太低了");
        joined[msg.sender] = msg.value;
        
        updatePrice();
        
        emit Join(msg.sender, msg.value);     //  48820  gas
        // joinAccouts.push(msg.sender);      //  88246  gas 
    } 

    // 作者提取资金
    function withdrawFund() external {
        require(msg.sender == author, "你不是作者");
        require(address(this).balance >= Target, "未达到众筹目标");
        closed = true;   
        msg.sender.transfer(address(this).balance);
    }

    // 读者赎回资金
    function withdraw() external {
        require(block.timestamp > endTime, "还未到众筹结束时间");
        require(!closed, "众筹达标，众筹资金已提取");
        require(Target > address(this).balance, "众筹达标，你没法提取资金");
        
        msg.sender.transfer(joined[msg.sender]);
    }

}