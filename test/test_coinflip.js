const CoinFlip = artifacts.require("CoinFlip");
const truffleAssert = require("truffle-assertions");

contract("CoinFlip", async function(accounts){

    let instance;

    //Initialize the contract depositing 1 ether
    before(async () => {
        instance = await CoinFlip.deployed();
        await instance.deposit({from: accounts[0], value: web3.utils.toWei("1", "ether")});
    })

    it("constructor(): 1 - should initialize correctly", async () => {
        let balance = await instance.balance();
        balance = parseFloat(balance);
        assert(balance == web3.utils.toWei("1", "ether"), "Balance should be set to 0");
    });


    it("deposit(): 1 - should let anyone deposit funds in the contract", async () => {
        //assuming accounts[0] is the owner
        await truffleAssert.passes(instance.deposit({from: accounts[1], value: web3.utils.toWei("0.5", "ether")}));
    });

    it("deposit(): 2 - should correctly update the balance after a deposit", async () =>{
        //calling the function on the same instance of previous tests, balance should be 1.5 eth 
        let balance = await instance.balance();
        balance = parseFloat(balance);
        assert(balance ==  web3.utils.toWei("1.5", "ether"));
    })
    
    // it("withdrawAll(): 1 - should allow the owner to withdraw balance", async function(){
    //     let tempInstance = await CoinFlip.new({from: accounts[0], value: web3.utils.toWei("1", "ether")});
    //     await truffleAssert.passes(tempInstance.withdrawAll({from: accounts[0]}));
    // });

    // it("withdrawAll(): 2 - should not allow non-owner to withdraw the balance", async () =>{
    //     let tempInstance = await CoinFlip.new({from: accounts[0], value: web3.utils.toWei("1", "ether")});
    //     await truffleAssert.fails(tempInstance.withdrawAll({from: accounts[1]}), truffleAssert.ErrorType.REVERT);
    // });
    
    // it("withdrawAll(): 3 - should update the owner balance after withdrawal", async () =>{
    //     let tempInstance = await CoinFlip.new({from: accounts[0], value: web3.utils.toWei("1", "ether")});

    //     let prevBalance = parseFloat(await web3.eth.getBalance(accounts[0]));
    //     await tempInstance.withdrawAll({from: accounts[0]});
    //     let curBalance = parseFloat(await web3.eth.getBalance(accounts[0]));

    //     assert(curBalance > prevBalance, "Not updating balance");
    // });

    it("bet(): 1 - should respect the minimum bet amount", async () =>{
        await truffleAssert.fails(instance.bet(0, {from: accounts[1], value: web3.utils.toWei("0.001", "ether")}), truffleAssert.ErrorType.REVERT);
    })

    it("bet(): 2 - should limit bet amount up to the total contract balance", async () => {
        await truffleAssert.fails(instance.bet(0, {value: web3.utils.toWei("10", "ether"), from: accounts[1]}), truffleAssert.ErrorType.REVERT);
    });

});