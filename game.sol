pragma solidity ^0.4.16;

interface token {
    function transfer(address receiver, uint amount);
}

contract Crowdsale {


    address public beneficiary; 
    uint public amountRaised; 
    uint public addressCount = 0;
    uint public isAuto = 1;
    uint public luckDayBlance;
    uint public luckDayRound;
    uint public luckEndTime = 1568044800;
    uint public top1Balance;
    uint public top4Balance;
    uint public luck30Balance;
    uint public quarterBalance;
    uint public quarterRound;
    uint public quarterEndTime = 1568908800;
    uint public vip1Count;
    uint public vip2Count;
    uint public vip3Count;
    uint public vip4Count;

    uint private vip1Condition = 150000000000000000000;
    uint private vip2Condition = 500000000000000000000;
    uint private vip3Condition = 1500000000000000000000;
    uint private vip4Condition = 3000000000000000000000;
    uint private vip1UpCondition = 350000000000000000000;
    uint private vip2UpCondition = 1000000000000000000000;
    uint private vip3UpCondition = 3500000000000000000000;
    uint private vip4UpCondition = 7000000000000000000000;


    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public intoBalanceOf;
    mapping(address => uint256) public allBalanceOf;
    mapping(uint256 => address) public noToAddress;
    mapping(address => AddressData) public addressDataOf;
    mapping(address => AddressVipPerformance) public addressVipPerformanceOf;
    mapping(uint => address) public performanceTopList;
    mapping(uint => address) public luckTopList;
    mapping(uint => AddressPerformance) public quarterTop;
    mapping(uint256 => uint256) public unfreezeNumber;//用户当前的ETH余额

    struct AddressPerformance{
        address userAddress;
        uint directInvitQuarterPerformance;
    }


    struct AddressData
        {
            uint no;
            uint vip;
            address pAddress;//上级地址
            uint sonAddressNum; //下级数量
            uint allSonAddressNum;//所有的下级
            uint performance; // 业绩
            uint directInvitPerformance;//直推奖
            uint indirectInvitPerformance;
            uint allInvitPerformance;//直推奖
            uint luck30;///幸运30名的奖励
            uint roundIntoPerformance;//当前局入金的量
            uint luckDayPerformance;//每天幸运奖的奖励数量
            uint freezeBalance;//冻结的奖励
            uint freezeAllBalance;//冻结的总量
        }
    struct AddressVipPerformance{
            uint littleVip1Performance;//小区的业绩
            uint littleVip2Performance;//小区的业绩
            uint littleVip3Performance;//小区的业绩
            uint littleVip4Performance;//小区的业绩
            uint topPerformance;//大区的业绩（暂时无用，为了不影响前端，暂时保留）
            uint vipPerformance;  // VIP的业绩
            uint top1Performance; // 委托的投票代表
            uint top4Performance;   // 投票选择的提案索引号
            uint directInvitQuarterPerformance;//季度的直推奖
    }

    /**
    * 事件可以用来跟踪信息
    **/
    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);
    event AdminTransfer(address backer, uint amount, bool isContribution);
    event QuarterWin(address backer, uint amount);

    /**
     * 构造函数, 设置相关属性，当部署合约的时候执行
     */
    function Crowdsale(address adminAddress) {
        beneficiary = adminAddress;//成功之后提现ETH到的地址
    }

    /**
     * 无函数名的Fallback函数，
     * 在向合约转账时，这个函数会被调用
     */
    function () payable {
        uint amount = msg.value;//转账的数量
        intoBalanceOf[msg.sender] += amount;//该变量用来记录用户入金总量
        amountRaised += amount;//整个合约入金总额
        bool ifFirst = false;
        if(addressDataOf[msg.sender].no == 0){//第一次加入初始化数据
            addressCount ++;//当用户第一次入金的时候给用户添加编号
            addressDataOf[msg.sender].no = addressCount;
            noToAddress[addressCount] = msg.sender;//增加一个编号查找用户
            address pAddress = bytesToAddress(msg.data);
            if(pAddress == msg.sender){//如果出现自己填自己邀请码的时候就强制转换成管理员账号为上级ID
                pAddress = beneficiary;
            }
            addressDataOf[msg.sender].pAddress = pAddress;//记录上级地址
            addressDataOf[addressDataOf[msg.sender].pAddress].sonAddressNum ++;//给上级增加记录
            ifFirst = true;
        }

        //给每日奖励添加奖励
        luckDayBlance += amount * 5/100;
        top1Balance += amount * 3/100;
        top4Balance += amount * 3/100;
        luck30Balance += amount * 3/100;
        quarterBalance += amount * 15/100;

        uint multiple = 3;
        if(amount >= 210000000000000000000){
            multiple = 5;
        }
        addressDataOf[msg.sender].roundIntoPerformance = amount;//添加开始释放的奖金
        addressDataOf[msg.sender].freezeBalance = amount * multiple;//入金
        addressDataOf[msg.sender].freezeAllBalance = amount * multiple;//添加冻结的币总量
        addressDataOf[addressDataOf[msg.sender].pAddress].directInvitPerformance += amount;//记录直推业绩indirectInvitPerformance
        addressVipPerformanceOf[addressDataOf[msg.sender].pAddress].directInvitQuarterPerformance += amount;//记录季度直推业绩
        if(addressDataOf[msg.sender].no > 1){//当不是第一个用户入金的时候特殊处理
            if( addressDataOf[addressDataOf[msg.sender].pAddress].freezeBalance > amount*10/100){
                balanceOf[addressDataOf[msg.sender].pAddress] += amount*10/100;//添加奖励
                allBalanceOf[addressDataOf[msg.sender].pAddress] += amount*10/100;//添加奖励
                addressDataOf[addressDataOf[msg.sender].pAddress].freezeBalance -= amount*10/100;//解冻
            }else{//解冻完
                balanceOf[addressDataOf[msg.sender].pAddress] += addressDataOf[addressDataOf[msg.sender].pAddress].freezeBalance;//添加奖励
                allBalanceOf[addressDataOf[msg.sender].pAddress] += addressDataOf[addressDataOf[msg.sender].pAddress].freezeBalance;//添加奖励
                addressDataOf[addressDataOf[msg.sender].pAddress].freezeBalance = 0;//解冻完
                addressDataOf[addressDataOf[msg.sender].pAddress].freezeAllBalance = 0;//解冻完
            }
        }

        indirectReward(addressDataOf[msg.sender].pAddress,amount,1);
        updateVipAndPerformance(addressDataOf[msg.sender].pAddress,msg.sender);
        
        FundTransfer(msg.sender, amount, true);
    }


    function indirectReward(address myAddress,uint myAmount,uint pNo) private {
        if(addressDataOf[myAddress].sonAddressNum >= pNo && pNo > 1){
            if( addressDataOf[myAddress].freezeBalance > myAmount*1/100){
                balanceOf[myAddress] += myAmount*1/100;
                allBalanceOf[myAddress] += myAmount*1/100;
                addressDataOf[myAddress].freezeBalance -= myAmount*1/100;
                addressDataOf[myAddress].indirectInvitPerformance += myAmount*1/100;
            }else{
                balanceOf[myAddress] += addressDataOf[myAddress].freezeBalance;
                allBalanceOf[myAddress] += addressDataOf[myAddress].freezeBalance;
                addressDataOf[myAddress].freezeBalance = 0;
                addressDataOf[myAddress].freezeAllBalance = 0;
                addressDataOf[myAddress].indirectInvitPerformance += addressDataOf[myAddress].freezeBalance;
            }
        }
        pNo++;
        
        //判断是否继续
        if(pNo > 11 || addressDataOf[myAddress].no == 2){
            return;
        }else{
            indirectReward(addressDataOf[myAddress].pAddress,myAmount,pNo);
        }
    }




    //
    function quarterStart() {
        if (beneficiary == msg.sender) {
            quarterRound++;
            for(uint x = 1; x <= addressCount; x++){//遍历一遍所有人
                quarterTop[x].userAddress = noToAddress[x];
                quarterTop[x].directInvitQuarterPerformance = addressVipPerformanceOf[noToAddress[x]].directInvitQuarterPerformance;
                addressVipPerformanceOf[noToAddress[x]].directInvitQuarterPerformance = 0;
            }

            uint temp;
            address tempAddress;

            //选择排序
            for (uint i = 1; i < addressCount; i++) {
                for (uint j = 1; j < addressCount - 1 - i; j++) {
                    if (quarterTop[j].directInvitQuarterPerformance <  quarterTop[j+1].directInvitQuarterPerformance) {//相邻元素两两对比
                        temp = quarterTop[j+1].directInvitQuarterPerformance;
                        tempAddress = quarterTop[j+1].userAddress;
                        quarterTop[j+1].directInvitQuarterPerformance = quarterTop[j].directInvitQuarterPerformance;
                        quarterTop[j+1].userAddress = quarterTop[j].userAddress;
                        quarterTop[j].directInvitQuarterPerformance = temp;
                        quarterTop[j].userAddress = tempAddress;
                    }
                }
            }
            uint minAddressCount;
            minAddressCount = 40;//变量回收利用
            if(addressCount < minAddressCount){
                minAddressCount = addressCount;
            }
            for(uint y=1;y <= minAddressCount; y ++){
                if(addressDataOf[quarterTop[y].userAddress].no > 1 && quarterTop[y].directInvitQuarterPerformance > 0){
                    if(y <= 4){
                        balanceOf[quarterTop[y].userAddress] += quarterBalance * 3/30;
                        allBalanceOf[quarterTop[y].userAddress] += quarterBalance * 3/30;//添加所有的奖励
                        addressVipPerformanceOf[quarterTop[y].userAddress].top1Performance += quarterBalance * 3/30;
                        QuarterWin(quarterTop[y].userAddress,quarterBalance * 3/30);
                    }else if(y>4 && y <= 11){
                        balanceOf[quarterTop[y].userAddress] += quarterBalance * 3/70;
                        allBalanceOf[quarterTop[y].userAddress] += quarterBalance * 3/70;//添加所有的奖励
                        addressVipPerformanceOf[quarterTop[y].userAddress].top4Performance += quarterBalance * 3/70;
                        QuarterWin(quarterTop[y].userAddress,quarterBalance * 3/70);
                    }else if(y>11 && y <= 41){
                        balanceOf[quarterTop[y].userAddress] += quarterBalance * 4/300;
                        allBalanceOf[quarterTop[y].userAddress] += quarterBalance * 4/300;//添加所有的奖励
                        addressDataOf[quarterTop[y].userAddress].luck30 += quarterBalance * 4/300;
                        QuarterWin(quarterTop[y].userAddress,quarterBalance * 4/300);
                    }
                }

                //所有用户的当前季度的直推奖清零
                addressVipPerformanceOf[noToAddress[y]].directInvitQuarterPerformance = 0;
            }

            //季度奖励归零
            quarterBalance=0;
            quarterEndTime += 864000;
        }
    }

    function updateVipAndPerformance(address pAddress,address myAddress) private {

        uint myVipUpPerformance;
        if(pAddress == myAddress){
            myVipUpPerformance = addressDataOf[myAddress].performance;
        }else{
            myVipUpPerformance = addressDataOf[myAddress].performance + intoBalanceOf[myAddress];
        }
        if(myVipUpPerformance >= vip1Condition){
            if(addressVipPerformanceOf[pAddress].littleVip1Performance == 0){
                addressVipPerformanceOf[pAddress].littleVip1Performance = myVipUpPerformance;
            }else{
                if(myVipUpPerformance <= addressVipPerformanceOf[pAddress].littleVip1Performance){
                    addressVipPerformanceOf[pAddress].littleVip1Performance = myVipUpPerformance;
                }
            }
        }
        if(myVipUpPerformance >= vip2Condition){
            if(addressVipPerformanceOf[pAddress].littleVip2Performance == 0){
                addressVipPerformanceOf[pAddress].littleVip2Performance = myVipUpPerformance;
            }else{
                if(myVipUpPerformance < addressVipPerformanceOf[pAddress].littleVip2Performance){
                    addressVipPerformanceOf[pAddress].littleVip2Performance = myVipUpPerformance;
                }
            }
        }

        //vip3
        if(myVipUpPerformance >= vip3Condition){
            if(addressVipPerformanceOf[pAddress].littleVip3Performance == 0){
                addressVipPerformanceOf[pAddress].littleVip3Performance = myVipUpPerformance;
            }else{
                if(myVipUpPerformance < addressVipPerformanceOf[pAddress].littleVip3Performance){
                    addressVipPerformanceOf[pAddress].littleVip3Performance = myVipUpPerformance;
                }
            }
        }
        if(myVipUpPerformance >= vip4Condition){
            if(addressVipPerformanceOf[pAddress].littleVip4Performance == 0){
                addressVipPerformanceOf[pAddress].littleVip4Performance = myVipUpPerformance;
            }else{
                if(myVipUpPerformance < addressVipPerformanceOf[pAddress].littleVip4Performance){
                    addressVipPerformanceOf[pAddress].littleVip4Performance = myVipUpPerformance;
                }
            }
        }

        uint oldVip = 0;
        uint pAddressPerformance = addressDataOf[pAddress].performance;
        if(pAddressPerformance >= addressVipPerformanceOf[pAddress].littleVip1Performance){
            if(addressDataOf[pAddress].vip < 1){//VIP1
                if(addressVipPerformanceOf[pAddress].littleVip1Performance >= vip1Condition && pAddressPerformance - addressVipPerformanceOf[pAddress].littleVip1Performance >= vip1UpCondition){
                    addressDataOf[pAddress].vip = 1;
                    vip1Count ++;//统计
                }
            }
            if(addressDataOf[pAddress].vip < 2){//VIP2
                if(addressVipPerformanceOf[pAddress].littleVip2Performance >= vip2Condition && pAddressPerformance - addressVipPerformanceOf[pAddress].littleVip2Performance >= vip2UpCondition){
                    oldVip = addressDataOf[pAddress].vip;
                    addressDataOf[pAddress].vip = 2;
                    vip2Count ++;//统计
                }
            }
            if(addressDataOf[pAddress].vip < 3){//VIP3
                if(addressVipPerformanceOf[pAddress].littleVip3Performance >= vip3Condition && pAddressPerformance - addressVipPerformanceOf[pAddress].littleVip3Performance >= vip3UpCondition){
                    oldVip = addressDataOf[pAddress].vip;
                    addressDataOf[pAddress].vip = 3;
                    vip3Count ++;//统计
                }
            }
            if(addressDataOf[pAddress].vip < 4){//VIP4
                if(addressVipPerformanceOf[pAddress].littleVip4Performance >= vip4Condition && pAddressPerformance- addressVipPerformanceOf[pAddress].littleVip4Performance >= vip4UpCondition){
                    oldVip = addressDataOf[pAddress].vip;
                    addressDataOf[pAddress].vip = 4;
                    vip4Count ++;//统计
                }
            }
        }
        if(oldVip > 0){//修改数据统计，在原来的数量上减少
            if(oldVip == 1){
                vip1Count --;
            }else if(oldVip == 2){
                vip2Count --;
            }else if(oldVip == 3){
                vip3Count --;
            }
        }

        if(addressDataOf[pAddress].no == 1 || addressDataOf[pAddress].no == 0){
            return;
        }else{
            updateVipAndPerformance(addressDataOf[pAddress].pAddress,pAddress);
        }
    }

  function bytesToAddress(bytes _address) private returns (address) {
    uint160 m = 0;
    uint160 b = 0;

    for (uint8 i = 0; i < 20; i++) {
      m *= 256;
      b = uint160(_address[i]);
      m += (b);
    }

    return address(m);
  }


    function rand(uint range,uint key) private returns(uint256) {
        uint256 random = uint256(keccak256(block.difficulty,now,key));
        return  random%range;
    }
}
