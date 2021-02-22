let web3 = new Web3(Web3.givenProvider);
let contractInstance;
let minAmount;

$(document).ready(function() {
    window.ethereum.enable().then(function(accounts){ //bring up a box that ask user to connect Metamask
        //abi can be taken by contractname.json in the build folder
        //address can be taken by typing migrate --reset in the truffle console and take the contract address
        //3rd arg needed to set the metamask account as the default one
        contractInstance = new web3.eth.Contract(abi, "0xffbB511D575d10D7E8dD10EC2E39360dE3D4a839", {from: accounts[0]});    
        console.log(contractInstance);
        console.log(accounts);
    }).then(() => {
        getMinimumBetAmount();
        getContractBalance();
        getPlayerBalance();

        contractInstance.once('ClosedBet', {}, (error, event) => {
            
            if (error) throw("Error");

            getContractBalance();
            getPlayerBalance();

            let amount = Web3.utils.fromWei(event.returnValues[4], 'ether');
        
            if(event.returnValues[3] == true){
                alert("You won " + amount*2 + " Ether!");
            } else alert("You lost " + amount + " Ether. Try again!");
        })

    }); 

    $("#betBtn").click(placeBet);
    $("#depositBtn").click(deposit);
    $("#withdrawBtn").click(withdrawFunds);

    $("#betAmount").change(checkMinAmount);

});

// GETTERS 

function getMinimumBetAmount () {
    contractInstance.methods.minimumBetAmount().call().then(function(res){
        minAmount = Web3.utils.fromWei(res, 'ether');
        $("#minAmountOut").text(minAmount);
        $("#betAmount").val(minAmount);
    })
}

function getContractBalance () {
    contractInstance.methods.balance().call().then(function(res){
        $("#contractBalanceOut").text(Web3.utils.fromWei(res, 'ether'));
    })
}

function getPlayerBalance(){
    contractInstance.methods.getPlayerBalance(window.ethereum.selectedAddress).call().then(function(res){
        console.log(res);
        $("#playerBalanceOut").text(Web3.utils.fromWei(res, 'ether') );
    })
}

// ACTIONS

function placeBet(){
    let amount = $("#betAmount").val();
    let choice = $("#betChoice").val();

    var config = {
        value: web3.utils.toWei(amount, "ether")
    }

    contractInstance.methods.placeBet(choice).send(config)
    .on("transactionHash", function(hash){
        console.log(hash);
    })
    .on("confirmation", function(confirmationNr){ //most important
        console.log(confirmationNr);
    })
    .on("receipt", function(receipt){   //when tx is put inside a block and confirmed
        console.log(receipt);
    })
}

function deposit(){
    let amount = $("#depositAmount").val();
    
    var config = {
        value: web3.utils.toWei(amount, "ether")
    }
    
    contractInstance.methods.deposit().send(config)
    .on("transactionHash", function(hash){
        console.log(hash);
    })
    .on("confirmation", function(confirmationNr){ //most important
        console.log(confirmationNr);
    })
    .on("receipt", function(receipt){   //when tx is put inside a block
        console.log(receipt);
        getContractBalance();
        alert("Deposited " + amount + " eth in the contract!");
    })
}

function withdrawFunds(){

    contractInstance.methods.withdrawFunds().send()
    .on("transactionHash", function(hash){
        console.log(hash);
    })
    .on("confirmation", function(confirmationNr){ //most important
        console.log(confirmationNr);
    })
    .on("receipt", function(receipt){   //when tx is put inside a block
        console.log(receipt);
        let amt = receipt.events.WithdrownFundsFromPlayer.returnValues["amount"];
        getPlayerBalance();
        alert("You received " + web3.utils.fromWei(amt, "ether") + " eth! Check your Metamask wallet");
    })

}


// CONTROLS 

function checkMinAmount() {
    if ($("#betAmount").val() < minAmount){
        $("#betAmount").val(minAmount);
    }
}