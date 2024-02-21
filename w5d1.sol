pragma solidity ^0.8.13;

contract duoqian {
    // 实现简单的多签钱包：
    // 多签持有人可提交交易
    // 其他多签人确认交易（使用交易的方式确认即可）
    // 达到多签门槛、任何人都可以执行交易
    // Owners
    address[] public owners;
    // 签名数
    uint256 public signCount;
    // 要求签名人数
    uint256 public requireSiger;
    // 是否owner
    mapping(address => bool) isOwner;
    // 交易
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool excuted;
        uint256 numConfirmations;
    }

    Transaction[] public transactions;

    event SubmitTransaction(
        address _to,
        uint256 _value,
        bytes _data,
        uint256 txIndex
    );

    constructor(address[] memory _owners, uint256 _requireSiger) {
        requireSiger = _requireSiger;

        require(
            requireSiger <= _owners.length,
            "owners length must longer than requireSiger!"
        );
        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            owners.push(owner);
            isOwner[owner] = true;
        }
    }

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Only owner can handle!");
        _;
    }

    modifier notExcuted(Transaction memory ta) {
        require(!ta.excuted, "Transaction has been done!");
        _;
    }

      receive() external payable {
    }


    // 初始化交易
    function submitTransaction(
        address _to,
        uint256 _value,
        string memory _data
    ) public onlyOwner {
        uint256 txIndex = transactions.length + 1;
        bytes memory dataT = abi.encodeWithSignature(_data);
        Transaction memory ta = Transaction({
            to: _to,
            value: _value,
            data: dataT,
            excuted: false,
            numConfirmations: 0
        });
        transactions.push(ta);
        emit SubmitTransaction(_to, _value, dataT, txIndex);
    }

    // 确认交易
    function confirmTransaction(uint256 _txIndex) public  onlyOwner notExcuted(transactions[_txIndex]){
        require(_txIndex < transactions.length, "ConfirmTransaction: Invalid index!!!");
        Transaction storage ta = transactions[_txIndex];
        require(!ta.excuted, "Transaction has been done!");
        ta.numConfirmations += 1;
    }

    function getTxIndex(uint256 _txIndex) public view returns (Transaction memory){
        Transaction memory ta = transactions[_txIndex];
        return ta;
    }

    // 实行交易
    function excuteTransaction(uint256 _txIndex) public onlyOwner notExcuted(transactions[_txIndex]) {
        Transaction storage ta = transactions[_txIndex];
        require(ta.numConfirmations>= requireSiger, "Not enough singer!");
        // call后面跟{}表示静态调用
        //  (bool success, ) = transaction.to.call{value: transaction.value}(
        //     transaction.data
        // );
        (bool success, ) = ta.to.call{value: ta.value}(ta.data);
        ta.excuted = true;
        require(success, "tx failed");
    }

    
}
