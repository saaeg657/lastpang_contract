contract Ownable {
    address public owner;

    function Ownable() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function changeOwner(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        owner = newOwner;
    }
}

contract test is Ownable {
  struct Game {
    address winner;
    address[] participants;
    uint prize;
    bool status;
    uint startAt;
    uint expiredAt;
  }
  
  mapping(uint32 => Game) games;
  uint32 public gameId;
  uint32 public period;
  uint public ticketPrice;
  uint16 public feePercentage = 5;
  uint accumulativeFee;

  function setTicketPrice(uint _ticketPrice)
    external
  {
      ticketPrice = _ticketPrice;
  }

  function test()
    public
  {
    gameId = 0;
    period = 3600;
  }

  function withdrawEth(uint value)
    onlyOwner
    public
  {
    require(accumulativeFee >= value);
    msg.sender.transfer(value);
  }

  function initializeGame()
    internal
  {
    games[gameId].status = true;
    games[gameId].startAt = block.timestamp;
    games[gameId].expiredAt = block.timestamp + period;
  }

  function finishGame()
    internal
  {
    games[gameId].winner = games[gameId].participants[games[gameId].participants.length - 1];
    games[gameId].winner.transfer(games[gameId].prize);
    ++gameId;
    initializeGame();
  }

  function provideEth()
    payable
    public
  {
    games[gameId].prize += msg.value;
  }

  function purchaseTicket()
    payable
    public
  {
    require(block.timestamp <= games[gameId].expiredAt);
    require(msg.value >= ticketPrice);
    uint fee = ticketPrice * feePercentage / 100;
    accumulativeFee += fee;
    games[gameId].prize += ticketPrice - fee;
    games[gameId].participants.push(msg.sender);
    // Trigger finishiGame when call purchaseTicket after expiredAt.
    // Unless no one call purchaseTicket after expiredAt, the game wouldn't finish.
    // This can be replaced with 'Orcalize', being scheduled strictly.
    if (block.timestamp >= games[gameId].expiredAt) {
      finishGame();
    }
  }
}