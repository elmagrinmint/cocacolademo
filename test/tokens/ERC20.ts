import { deployERC20TokenSystem } from '../../migrations/_helpers/tokens/ERC20';
import { testEvent } from '../../migrations/_helpers/util/testEvent';
import { GateKeeperContract, GateKeeperInstance } from '../../types/truffle-contracts/GateKeeper';
import {
  TestApproveAndCallableContract,
  TestApproveAndCallableInstance,
} from '../../types/truffle-contracts/TestApproveAndCallable';
import { TestTokenContract, TestTokenInstance } from '../../types/truffle-contracts/TestToken';
import { TestTokenFactoryContract, TestTokenFactoryInstance } from '../../types/truffle-contracts/TestTokenFactory';
import { TestTokenRegistryContract } from '../../types/truffle-contracts/TestTokenRegistry';

const Token: TestTokenContract = artifacts.require('TestToken');
const ERC20TokenRegistry: TestTokenRegistryContract = artifacts.require('TestTokenRegistry');
const ERC20TokenFactory: TestTokenFactoryContract = artifacts.require('TestTokenFactory');
const GateKeeper: GateKeeperContract = artifacts.require('GateKeeper');
const ApproveAndCallable: TestApproveAndCallableContract = artifacts.require('TestApproveAndCallable');

// eslint-disable-next-line @typescript-eslint/no-var-requires
const { storeIpfsHash } = require('../../truffle-config.js'); // two dirs up, because it is compiled into ./dist/migrations

contract('ERC20 TokenSystem', (accounts) => {
  let dApproveAndCallable: TestApproveAndCallableInstance;
  let dGateKeeper: GateKeeperInstance;
  let dToken: TestTokenInstance;
  let dFactory: TestTokenFactoryInstance;

  beforeEach(async () => {
    // eslint-disable-next-line @typescript-eslint/no-var-requires
    const uiDefinitions = require('./UIDefinitions.json');
    dApproveAndCallable = await ApproveAndCallable.new();
    dGateKeeper = await GateKeeper.new();
    const { tokens, factory } = await deployERC20TokenSystem(
      {
        gatekeeper: dGateKeeper,
        registry: {
          contract: ERC20TokenRegistry,
          extraParams: [],
        },
        factory: {
          contract: ERC20TokenFactory,
          extraParams: [],
        },
        token: {
          contract: Token,
          instances: [
            {
              name: 'Test Token',
              decimals: 18,
              extraParams: [],
            },
          ],
        },
      },
      accounts[0],
      uiDefinitions,
      storeIpfsHash
    );

    dToken = tokens[0];
    dFactory = factory;
  });

  /** FACTORY */

  // function getUIFieldDefinitionsHash() public view returns (string memory)
  it('has UI definitions', async () => {
    const uiFieldDefinitionsHash = await dFactory.getUIFieldDefinitionsHash();
    assert.isNotNull(uiFieldDefinitionsHash);
  });

  /** TOKEN */

  // function mint(address _to, uint256 _amount) onlyOwner public returns (bool success) {
  //    Mint(_to, _amount);
  //    Transfer(0x0, _to, _amount);
  it('mint new tokens', async () => {
    const balanceBefore = await dToken.balanceOf(accounts[1]);
    assert.equal(balanceBefore.toNumber(), 0);
    const tx = await dToken.mint(accounts[1], 123);
    testEvent(tx, 'Mint', { to: accounts[1], amount: '123' });
    testEvent(tx, 'Transfer', {
      from: '0x0000000000000000000000000000000000000000',
      to: accounts[1],
      value: '123',
    });
    const balanceAfter = await dToken.balanceOf(accounts[1]);
    assert.equal(balanceAfter.toNumber(), 123);
  });

  // function burn(address _from, uint256 _amount) onlyOwner public returns (bool success) {
  //   Burn(_from, _amount);
  //   Transfer(_from, 0x0, _amount);
  it('burn tokens', async () => {
    await dToken.mint(accounts[1], 123);
    const balanceBefore = await dToken.balanceOf(accounts[1]);
    assert.equal(balanceBefore.toNumber(), 123);
    const tx = await dToken.burn(accounts[1], 120);
    testEvent(tx, 'Burn', { from: accounts[1], amount: '120' });
    testEvent(tx, 'Transfer', {
      from: accounts[1],
      to: '0x0000000000000000000000000000000000000000',
      value: '120',
    });
    const balanceAfter = await dToken.balanceOf(accounts[1]);
    assert.equal(balanceAfter.toNumber(), 3);
  });

  // function transfer(address _to, uint256 _value) public returns (bool success) {
  //   Transfer(msg.sender, _to, _value);
  it('transfer tokens', async () => {
    await dToken.mint(accounts[0], 123);
    const balanceBefore = await dToken.balanceOf(accounts[0]);
    assert.equal(balanceBefore.toNumber(), 123);
    const tx = await dToken.transfer(accounts[1], 120);
    testEvent(tx, 'Transfer', {
      from: accounts[0],
      to: accounts[1],
      value: '120',
    });
    // testing for 2 events with the same name is a hassle
    const balanceAfter0 = await dToken.balanceOf(accounts[0]);
    assert.equal(balanceAfter0.toNumber(), 3);
    const balanceAfter1 = await dToken.balanceOf(accounts[1]);
    assert.equal(balanceAfter1.toNumber(), 120);
  });

  // function transferWithData(address _to, uint256 _value, bytes _data) public returns (bool success) {
  //   TransferData(msg.sender, _to, _data);
  //   Transfer(msg.sender, _to, _value);
  it('transfer tokens with data', async () => {
    await dToken.mint(accounts[0], 123);
    const balanceBefore = await dToken.balanceOf(accounts[0]);
    assert.equal(balanceBefore.toNumber(), 123);
    const tx = await dToken.transferWithData(accounts[1], 120, web3.utils.asciiToHex('some-payment-reference'));
    testEvent(tx, 'Transfer', {
      from: accounts[0],
      to: accounts[1],
      value: '120',
    });
    testEvent(tx, 'TransferData', {
      from: accounts[0],
      to: accounts[1],
      data: '0x736f6d652d7061796d656e742d7265666572656e6365',
    });
    const balanceAfter0 = await dToken.balanceOf(accounts[0]);
    assert.equal(balanceAfter0.toNumber(), 3);
    const balanceAfter1 = await dToken.balanceOf(accounts[1]);
    assert.equal(balanceAfter1.toNumber(), 120);
  });

  // function transferFrom (address _from, address _to, uint256 _value ) public returns (bool success) {
  //   Transfer(_from, _to, _value);
  it('transfer tokens from', async () => {
    await dToken.mint(accounts[1], 123);
    const balanceBefore1 = await dToken.balanceOf(accounts[1]);
    assert.equal(balanceBefore1.toNumber(), 123);
    const balanceBefore2 = await dToken.balanceOf(accounts[2]);
    assert.equal(balanceBefore2.toNumber(), 0);
    await dToken.approve(accounts[0], 120, { from: accounts[1] });
    const tx = await dToken.transferFrom(accounts[1], accounts[2], 120);
    testEvent(tx, 'Transfer', {
      from: accounts[1],
      to: accounts[2],
      value: '120',
    });
    const balanceAfter0 = await dToken.balanceOf(accounts[1]);
    assert.equal(balanceAfter0.toNumber(), 3);
    const balanceAfter1 = await dToken.balanceOf(accounts[2]);
    assert.equal(balanceAfter1.toNumber(), 120);
  });

  // function transferFromWithData(address _from,address _to,uint256 _value,bytes _data) public returns (bool success){ TransferData(_from, _to, _data); Transfer(_from, _to, _value); (_from); (_to);
  it('transfer tokens from with data', async () => {
    await dToken.mint(accounts[1], 123);
    const balanceBefore1 = await dToken.balanceOf(accounts[1]);
    assert.equal(balanceBefore1.toNumber(), 123);
    const balanceBefore2 = await dToken.balanceOf(accounts[2]);
    assert.equal(balanceBefore2.toNumber(), 0);
    await dToken.approve(accounts[0], 120, { from: accounts[1] });
    const tx = await dToken.transferFromWithData(
      accounts[1],
      accounts[2],
      120,
      web3.utils.asciiToHex('some-payment-reference')
    );
    testEvent(tx, 'Transfer', {
      from: accounts[1],
      to: accounts[2],
      value: '120',
    });
    testEvent(tx, 'TransferData', {
      from: accounts[1],
      to: accounts[2],
      data: '0x736f6d652d7061796d656e742d7265666572656e6365',
    });
    // testing for 2 events with the same name is a hassle
    const balanceAfter0 = await dToken.balanceOf(accounts[1]);
    assert.equal(balanceAfter0.toNumber(), 3);
    const balanceAfter1 = await dToken.balanceOf(accounts[2]);
    assert.equal(balanceAfter1.toNumber(), 120);
  });

  // function approve(address _spender, uint256 _value) public returns (bool) {
  //   Approval(msg.sender, _spender, _value);
  it('approve transfers', async () => {
    await dToken.mint(accounts[0], 123);
    const allowanceBefore = await dToken.allowance(accounts[0], accounts[1]);
    assert.equal(allowanceBefore.toNumber(), 0);
    const tx = await dToken.approve(accounts[1], 120);
    testEvent(tx, 'Approval', {
      owner: accounts[0],
      spender: accounts[1],
      value: '120',
    });
    const allowanceAfter = await dToken.allowance(accounts[0], accounts[1]);
    assert.equal(allowanceAfter.toNumber(), 120);
  });

  // function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
  //   Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
  it('increase approval', async () => {
    await dToken.mint(accounts[0], 123);
    await dToken.approve(accounts[1], 100);
    const allowanceBefore = await dToken.allowance(accounts[0], accounts[1]);
    assert.equal(allowanceBefore.toNumber(), 100);
    const tx = await dToken.increaseApproval(accounts[1], 10);
    testEvent(tx, 'Approval', {
      owner: accounts[0],
      spender: accounts[1],
      value: '110',
    });
    const allowanceAfter = await dToken.allowance(accounts[0], accounts[1]);
    assert.equal(allowanceAfter.toNumber(), 110);
  });

  // function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) { Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
  it('decrease approval', async () => {
    await dToken.mint(accounts[0], 123);
    await dToken.approve(accounts[1], 100);
    const allowanceBefore = await dToken.allowance(accounts[0], accounts[1]);
    assert.equal(allowanceBefore.toNumber(), 100);
    const tx = await dToken.decreaseApproval(accounts[1], 10);
    testEvent(tx, 'Approval', {
      owner: accounts[0],
      spender: accounts[1],
      value: '90',
    });
    const allowanceAfter = await dToken.allowance(accounts[0], accounts[1]);
    assert.equal(allowanceAfter.toNumber(), 90);
    await dToken.decreaseApproval(accounts[1], 1000);
    const allowanceAfter2 = await dToken.allowance(accounts[0], accounts[1]);
    assert.equal(allowanceAfter2.toNumber(), 0);
  });

  // function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
  // Approval(msg.sender, _spender, _value);
  // ReceivedApproval(from, amount, token, data)
  it('approve and call', async () => {
    await dToken.mint(accounts[0], 123);
    const allowanceBefore = await dToken.allowance(accounts[0], dApproveAndCallable.address);
    assert.equal(allowanceBefore.toNumber(), 0);
    const tx = await dToken.approveAndCall(
      dApproveAndCallable.address,
      120,
      web3.utils.asciiToHex('some-payment-reference')
    );

    testEvent(tx, 'Approval', {
      owner: accounts[0],
      spender: dApproveAndCallable.address,
      value: '120',
    });

    // Assert the allowance has been spent
    const allowanceAfter = await dToken.allowance(accounts[0], dApproveAndCallable.address);
    assert.equal(allowanceAfter.toNumber(), 0);

    testEvent(tx, 'Transfer', {
      from: accounts[0],
      to: dApproveAndCallable.address,
      value: '120',
    });
  });

  // function getIndexLength() public view returns (uint length) {
  // function getByIndex(uint index) view public returns (address key, uint256 balance) {
  // function getByKey(address _key) view public returns (address key, uint256 balance) {
});
