pragma solidity ^0.4.18;
pragma experimental ABIEncoderV2;

import "zeppelin-solidity/contracts/token/ERC20/StandardToken.sol";
import "./OldReversi.sol";
// import "./oraclizeAPI.sol";


contract OldToken is StandardToken {

  // Token Contract

  uint256 public decimals = 0;
  uint256 public INITIAL_SUPPLY = 0; // zero decimals
  uint256 payMultiplier = 100;
  uint256 Symmetricals;
  uint256 RotSym;
  uint256 Y0Sym;
  uint256 X0Sym;
  uint256 XYSym;
  uint256 XnYSym;
  uint256 nameLength = 21;
  address public owner;
  string public name = "ClubToken";
  string public symbol = "♧";



  function OldToken() {
    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    admins[msg.sender] = true;
    adminKeys.push(msg.sender);
    owner = msg.sender;
  }


  // Modifiers

  modifier onlyOwner { if (msg.sender != owner) revert(); _; }
  modifier onlyAdmin { if (!admins[msg.sender]) revert(); _; }
  modifier doesNotExist(bytes16 b) { if (clovers[b].exists) revert(); _; }
  modifier exists(bytes16 b) { if (!clovers[b].exists) revert(); _; }



  // Events

  event newUserName(address player, string name);
  event newCloverName(bytes16 board, string name);
  event Registered(address newOwner, uint256 lastPaidAmount, bytes16 board, bool newBoard, bytes28 first32Moves, bytes28 lastMoves, uint256 modified, uint256 findersFee);



  // Contract Administration

  mapping(address => bool) admins;
  address[] public adminKeys;

  function getBalance(address someone) public constant returns(uint) {
    return balances[someone];
  }

  function myAddress () public constant returns (address) {
    return msg.sender;
  }

  function isAdmin () public constant returns (bool) {
    return admins[msg.sender];
  }  

  function adminLen () public constant returns (uint256) {
    return adminKeys.length;
  } 

  function adminAt (uint256 key) public constant returns (address) {
    return adminKeys[key];
  }

  function getTallys() public constant returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
    return (Symmetricals, RotSym, Y0Sym, X0Sym, XYSym, XnYSym, payMultiplier);
  }

  function changeNameLength (uint256 len) public onlyAdmin() {
    nameLength = len;
  }

  function addAdmin (address newbie) public onlyAdmin() {
    if (!admins[msg.sender]) revert();
    admins[newbie] = true;
    adminKeys.push(newbie);
  }

  function updateMultiplier(uint256 multiplier) public onlyAdmin(){
    payMultiplier = multiplier;
  }




  // Player Management

  struct Player {
    bool exists;
    uint currentCount;
    bytes16[] cloverKeys;
    mapping(bytes16 => bool) clovers;
  }

  mapping(address => Player) public players;
  address[] public playerKeys;

  function changeName (string name) {
    if (bytes(name).length > nameLength) revert();
    newUserName(msg.sender, name);
  }

  function listPlayerCount() public constant returns(uint) {
    return playerKeys.length;
  }

  function playerAddressByKey(uint playerKey) public constant returns(address) {
    return playerKeys[playerKey];
  }

  function playerExists(address player) public constant returns(bool) {
    return players[player].exists;
  }

  function playerCurrentCount(address player) public constant returns(uint) {
    return players[player].currentCount;
  }

  function playerAllCount(address player) public constant returns(uint) {
    return players[player].cloverKeys.length;
  }

  function playerCloverByKey(address player, uint cloverKey) public constant returns(bytes16) {
    return players[player].cloverKeys[cloverKey];
  }

  function playerOwnsClover(address player, bytes16 board) public constant returns (bool) {
    return players[player].clovers[board];
  }

  function addCloverToPlayer (bytes16 board) internal {
    if (!players[msg.sender].clovers[board]) {
      players[msg.sender].clovers[board] = true;
      players[msg.sender].cloverKeys.push(board);
    }
    players[msg.sender].currentCount += 1;
  }

  function registerPlayer() internal {
    if (!players[msg.sender].exists) {
      players[msg.sender].exists = true;
      playerKeys.push(msg.sender);
    }
  }



  // Clover Management

  struct Clover {
    bool exists;
    bytes28 first32Moves;
    bytes28 lastMoves;
    uint256 lastPaidAmount;
    uint256 findersFee;
    uint256 created;
    uint256 modified;
    address[] previousOwners;
    // bool validated;
  }

  mapping (bytes16 => Clover) public clovers;
  bytes16[] public cloverKeys;

  function cloverExists(bytes16 b) public constant returns(bool){
    return clovers[b].exists;
  }

  function getCloversCount() public constant returns(uint) {
    return cloverKeys.length;
  }

  function getCloverByKey (uint boardKey) public constant returns(bytes16, uint lastPaidAmount, uint owners, address lastOwner, bytes28 first32Moves, bytes28 lastMoves) {
    bytes16 board = cloverKeys[boardKey];
    return getClover(board);
  }

  function getClover (bytes16 board) public exists(board) constant returns(bytes16, uint lastPaidAmount, uint ownersLength, address lastOwner, bytes28 first32Moves, bytes28 lastMoves) {
    return (board, clovers[board].lastPaidAmount, clovers[board].previousOwners.length, clovers[board].previousOwners[clovers[board].previousOwners.length - 1], clovers[board].first32Moves, clovers[board].lastMoves);
  }

  function getCloverOwnersLength(bytes16 board) public exists(board) constant returns(uint256) {
    return clovers[board].previousOwners.length;
  }

  function getCloverOwner(bytes16 board) public exists(board) constant returns(bytes16, address previousOwner) {
    return (board, clovers[board].previousOwners[ clovers[board].previousOwners.length - 1 ] );
  }

  function getCloverOwnerAtKeyByBoard(bytes16 board, uint ownerKey) public exists(board) constant returns(bytes16, address previousOwner) {
    return (board, clovers[board].previousOwners[ownerKey]);
  }

  function getCloverOwnerAtKeyByBoardKey(uint boardKey, uint ownerKey) public constant returns(bytes16, address previousOwner) {
    bytes16 board = cloverKeys[boardKey];
    if(!clovers[board].exists) revert();
    return (board, clovers[board].previousOwners[ownerKey]);
  }

  function renameClover(bytes16 board, string name) public exists(board) {
    if (bytes(name).length > nameLength) revert();
    if (clovers[board].previousOwners[clovers[board].previousOwners.length - 1] != msg.sender) revert();
    newCloverName(board, name);
  }

  function changeStartPrice(bytes16 board, uint256 startPrice) public exists(board) {
    if(clovers[board].previousOwners[0] != msg.sender) revert();
    if(clovers[board].previousOwners.length > 1) revert();
    Registered(msg.sender, startPrice, board, true, clovers[board].first32Moves, clovers[board].lastMoves, now, clovers[board].findersFee);
    clovers[board].lastPaidAmount = startPrice;
  }

  function mineClover(bytes28 first32Moves, bytes28 lastMoves, uint256 startPrice) public {
    Reversi.Game memory game = Reversi.playGame(first32Moves, lastMoves);
    // Game memory game = playGame(first32Moves, lastMoves);
    saveGame(game, startPrice);
  }

  function adminMineClover (bytes28 first32Moves, bytes28 lastMoves, bytes16 board, uint startPrice) public doesNotExist(board) onlyAdmin() returns(uint boardKey) {
    registerPlayer();
    addCloverToPlayer(game.board);
    Reversi.Game memory game;
    // Game memory game;
    game.board = board;

    game = Reversi.isSymmetrical(game);
    // game = isSymmetrical(game);
    if (game.symmetrical) {
      clovers[board].findersFee = findersFee(game);
      balances[msg.sender] += clovers[board].findersFee;
      totalSupply_ += clovers[board].findersFee;
      addToSymmTallys(game);
    }
    clovers[board].first32Moves = first32Moves;
    clovers[board].lastMoves = lastMoves;
    clovers[board].previousOwners.push(msg.sender);
    clovers[board].lastPaidAmount = startPrice;
    clovers[board].exists = true;
    clovers[board].created = now;
    clovers[board].modified = now;
    Registered(msg.sender, startPrice, board, true, first32Moves, lastMoves, now, clovers[board].findersFee);
    return cloverKeys.push(board);
  }

  function flipClover (bytes16 b) exists(b) public{
    // every clover asset is for sale determined on an initial start price
    // if that clover is purchased, the proceeds are divided evenly among the last two buyers
    // cant flip board you currently own
    if (clovers[b].previousOwners[ clovers[b].previousOwners.length - 1 ] == msg.sender) revert();
    uint nextPrice = clovers[b].previousOwners.length == 1 ? clovers[b].lastPaidAmount : clovers[b].lastPaidAmount.mul(2);
    if (balances[msg.sender] < nextPrice) revert();
    registerPlayer();
    for (uint8 i = 1; i < 3; i++) {
      if (i <= clovers[b].previousOwners.length) {
        uint256 lastOwnerKey = clovers[b].previousOwners.length - uint(i);
        address lastOwner = clovers[b].previousOwners[ lastOwnerKey ];

        balances[msg.sender] = balances[msg.sender].sub(clovers[b].lastPaidAmount);

        balances[lastOwner] = balances[lastOwner].add(clovers[b].lastPaidAmount);
        if (i == 1) {
          players[lastOwner].currentCount -= 1;
        }
      }
    }
    addCloverToPlayer(b);
    clovers[b].previousOwners.push(msg.sender);
    clovers[b].lastPaidAmount = nextPrice;
    clovers[b].modified = now;
    Registered(msg.sender, nextPrice, b, false, clovers[b].first32Moves, clovers[b].lastMoves, clovers[b].modified, clovers[b].findersFee);
  }


  // Game Management
  //
  // see ./Reversi.sol for playGame(), isSymmetrical() and Game struct


  function gameIsValid(bytes28 first32Moves, bytes28 lastMoves) public constant returns(bool) {
    Reversi.Game memory game = Reversi.playGame(first32Moves, lastMoves);
    // Game memory game = playGame(first32Moves, lastMoves);
    if (game.error) return false;
    if (!game.complete) return false;
    if (!game.symmetrical) return false;
    return true;
  }

  function gameExists(bytes28 first32Moves, bytes28 lastMoves) public constant returns(bool) {
    Reversi.Game memory game = Reversi.playGame(first32Moves, lastMoves);
    // Game memory game = playGame(first32Moves, lastMoves);
    if (game.error) revert();
    if (!game.complete) revert();
    return clovers[game.board].exists;
  }

  function debugGame(bytes28 first32Moves, bytes28 lastMoves) public{
    Reversi.Game memory game = Reversi.playGame(first32Moves, lastMoves);
    // Game memory game = playGame(first32Moves, lastMoves);
  }
  function showGame(bytes28 first32Moves, bytes28 lastMoves) public constant returns(bool error, bool complete, bool symmetrical, bool RotSym, bool Y0Sym, bool X0Sym, bool XYSym, bool XnYSym) {
    Reversi.Game memory game = Reversi.playGame(first32Moves, lastMoves);
    // Game memory game = playGame(first32Moves, lastMoves);
    return returnGame(game);
  }

  function showGame2(bytes28 first32Moves, bytes28 lastMoves) public constant returns(bytes16 board, uint8 blackScore, uint8 whiteScore, uint8 currentPlayer, uint8 moveKey) {
    Reversi.Game memory game = Reversi.playGame(first32Moves, lastMoves);
    // Game memory game = playGame(first32Moves, lastMoves);
    return (game.board, game.blackScore, game.whiteScore, game.currentPlayer, game.moveKey);
  }


  function getSymmetry(bytes16 b) public constant returns(bool error, bool complete, bool symmetrical, bool RotSym, bool Y0Sym, bool X0Sym, bool XYSym, bool XnYSym) {
    Reversi.Game memory game;
    // Game memory game;
    game.board = b;
    game = Reversi.isSymmetrical(game);
    // game = isSymmetrical(game);
    return returnGame(game);
  }

  function getFindersFee(bytes16 b) public constant returns(uint256) {
    Reversi.Game memory game;
    // Game memory game;
    game.board = b;
    game = Reversi.isSymmetrical(game);
    // game = isSymmetrical(game);
    return findersFee(game);
  }

  function returnGame(Reversi.Game game) internal returns(bool error, bool complete, bool symmetrical, bool RotSym, bool Y0Sym, bool X0Sym, bool XYSym, bool XnYSym){
  // function returnGame(Game game) internal returns(bool error, bool complete, bool symmetrical, bool RotSym, bool Y0Sym, bool X0Sym, bool XYSym, bool XnYSym){
    return (game.error, game.complete, game.symmetrical, game.RotSym, game.Y0Sym, game.X0Sym, game.XYSym, game.XnYSym);
  }

  function saveGame(Reversi.Game game, uint256 startPrice) internal returns(uint){
  // function saveGame(Game game, uint256 startPrice) internal returns(uint){
    if (game.error) revert();
    if (!game.complete) revert();
    if (clovers[game.board].exists) revert();
    
    registerPlayer();
    addCloverToPlayer(game.board);
    clovers[game.board].first32Moves = game.first32Moves;
    clovers[game.board].lastMoves = game.lastMoves;
    clovers[game.board].previousOwners.push(msg.sender);
    clovers[game.board].lastPaidAmount = startPrice;
    clovers[game.board].exists = true;
    clovers[game.board].created = now;
    clovers[game.board].modified = now;
    if (game.symmetrical) {
      clovers[game.board].findersFee = findersFee(game);
      balances[msg.sender] += clovers[game.board].findersFee;
      totalSupply_ += clovers[game.board].findersFee;
      addToSymmTallys(game);
    }
    Registered(msg.sender, startPrice, game.board, true, game.first32Moves, game.lastMoves, now, clovers[game.board].findersFee);
    return cloverKeys.push(game.board);
  }

  function addToSymmTallys (Reversi.Game game) internal {
    // if (game.symmetrical) Symmetricals += 1;
    // if (game.RotSym) RotSym += 1;
    // if (game.Y0Sym) Y0Sym += 1;
    // if (game.X0Sym) X0Sym += 1;
    // if (game.XYSym) XYSym += 1;
    // if (game.XnYSym) XnYSym += 1;
  }

  function findersFee (Reversi.Game game) internal constant returns(uint256) {
    uint256 base = 0;

    if (game.RotSym) base = base.add( payMultiplier.mul( Symmetricals + 1 ).div( RotSym + 1 ) );
    if (game.Y0Sym) base = base.add( payMultiplier.mul( Symmetricals + 1 ).div( Y0Sym + 1 ) );
    if (game.X0Sym) base = base.add( payMultiplier.mul( Symmetricals + 1 ).div( X0Sym + 1 ) );
    if (game.XYSym) base = base.add( payMultiplier.mul( Symmetricals + 1 ).div( XYSym + 1 ) );
    if (game.XnYSym) base = base.add( payMultiplier.mul( Symmetricals + 1 ).div( XnYSym + 1 ) );

    return base;
  }


  // // Oraclize Management


  // function claimClover (bytes16 board, bytes28 first32Moves, bytes28 lastMoves, uint256 startPrice) public {
  //   registerPlayer();

  //   Clover storage clover;
  //   clover.first32Moves = first32Moves;
  //   clover.lastMoves = lastMoves;
  //   clover.lastPaidAmount = startPrice;
  //   clover.exists = true;


  //   clover.previousOwners.push(msg.sender);

  //   clover.validated = false; // redundant

  //   Game memory game;
  //   game.board = board;
  //   clover.findersFee = findersFee(game);

  //   clovers[board] = clover;

  // }

  // // = "json(https://api.infura.io/v1/jsonrpc/rinkeby/eth_call?to="
  // string validateEndpoint = "json(https://api.infura.io/v1/jsonrpc/rinkeby/eth_call?to=";
  // mapping(bytes32=>bytes16) validIds;

  // function updateValidateEndpoint (string endpoint) public onlyAdmin() {
  //   validateEndpoint = endpoint;
  // }

  // function __callback(bytes32 myid, bool valid, bytes proof) {
  //   if (uint8 (validIds[myid]) == 0) throw;
  //   if (msg.sender != oraclize_cbAddress()) revert();
  //   if (!valid) revert();
  //   bytes16 board = validIds[myid];
  //   address player = clovers[board].previousOwners[0];
  //   if (!clovers[board].exists) revert();
  //   if (clovers[board].validated) revert();
  //   delete validIds[myid];


  //   addCloverToPlayerExplicit(board, player);

  //   balances[player] += clovers[board].findersFee;
  //   clovers[board].validated = valid;

  //   cloverKeys.push(board);  
  //   Registered(player, clovers[board].lastPaidAmount, board);
  // }

  // function returnAddress() public constant returns(address) {
  //   return this;
  // }

  // function buildString(bytes28 first32Moves, bytes28 lastMoves) public constant returns(string) {
  //   string query2 = addressToString(address(this));
  //   // string memory query3 = "&data=";
  //   // string memory func = bytes32ToString(bytes32(bytes4(sha3("gameIsValid(bytes28,bytes28)"))));
  //   // string memory param1 = bytes32ToString(bytes32(first32Moves));
  //   // string memory param2 = bytes32ToString(bytes32(lastMoves));
  //   // string memory closing = ").result";

  //   return query2;//strConcat(strConcat(validateEndpoint, query2, query3, func, param1), param2, closing);

  // }

  // function verifyGame(bytes16 board, bytes28 first32Moves, bytes28 lastMoves) payable {
  //   if (oraclize_getPrice("URL") > this.balance) {
  //       // newOraclizeQuery("Oraclize query was NOT sent, please add some ETH to cover for the query fee");
  //   } else {

  //       // newOraclizeQuery("Oraclize query was sent, standing by for the answer..");
  //       bytes32 queryId = oraclize_query("URL", buildString(first32Moves, lastMoves));
  //       validIds[queryId] = board;
  //   }
  // }

  // function addressToString(address x) returns (string) {
  //     bytes memory b = new bytes(20);
  //     for (uint i = 0; i < 20; i++)
  //       b[i] = byte(uint8(uint256(x) / (2**(8*(19 - i)))));
  //     return string(b);
  // }
  // function bytes32ToString (bytes32 data) constant returns (string) {
  //   bytes memory bytesString = new bytes(32);
  //   for (uint j=0; j<32; j++) {
  //     byte char = byte(bytes32(uint(data) * 2 ** (8 * j)));
  //     if (char != 0) {
  //       bytesString[j] = char;
  //     }
  //   }
  //   return string(bytesString);
  // }
  // function bytes4ToString (bytes4 data) constant returns (string) {
  //   bytes memory bytesString = new bytes(4);
  //   for (uint j=0; j<4; j++) {
  //     byte char = byte(bytes4(uint(data) * 2 ** (8 * j)));
  //     if (char != 0) {
  //       bytesString[j] = char;
  //     }
  //   }
  //   return string(bytesString);
  // }

  // function strConcat(string _a, string _b, string _c, string _d, string _e) internal returns (string) {
  //     bytes memory _ba = bytes(_a);
  //     bytes memory _bb = bytes(_b);
  //     bytes memory _bc = bytes(_c);
  //     bytes memory _bd = bytes(_d);
  //     bytes memory _be = bytes(_e);
  //     string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
  //     bytes memory babcde = bytes(abcde);
  //     uint k = 0;
  //     for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
  //     for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
  //     for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
  //     for (i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
  //     for (i = 0; i < _be.length; i++) babcde[k++] = _be[i];
  //     return string(babcde);
  // }

  // function strConcat(string _a, string _b, string _c, string _d) internal returns (string) {
  //     return strConcat(_a, _b, _c, _d, "");
  // }

  // function strConcat(string _a, string _b, string _c) internal returns (string) {
  //     return strConcat(_a, _b, _c, "", "");
  // }

  // function strConcat(string _a, string _b) internal returns (string) {
  //     return strConcat(_a, _b, "", "", "");
  // }


}