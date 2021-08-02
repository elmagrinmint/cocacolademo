import { DispatcherContract } from '../../../types/truffle-contracts/Dispatcher';
import { ExampleV1Contract } from '../../../types/truffle-contracts/ExampleV1';
import { ExampleV2Contract } from '../../../types/truffle-contracts/ExampleV2';
import { GateKeeperContract } from '../../../types/truffle-contracts/GateKeeper';
import { IExampleContract } from '../../../types/truffle-contracts/IExample';
import { SimpleExampleDispatcherContract } from '../../../types/truffle-contracts/SimpleExampleDispatcher';
import { SimpleExampleV1Contract } from '../../../types/truffle-contracts/SimpleExampleV1';
import { SimpleExampleV2Contract } from '../../../types/truffle-contracts/SimpleExampleV2';
import { SimpleIExampleContract } from '../../../types/truffle-contracts/SimpleIExample';

const SimpleDispatcher: SimpleExampleDispatcherContract = artifacts.require('SimpleExampleDispatcher');
const SimpleExampleV1: SimpleExampleV1Contract = artifacts.require('SimpleExampleV1');
const SimpleExampleV2: SimpleExampleV2Contract = artifacts.require('SimpleExampleV2');
const SimpleIExample: SimpleIExampleContract = artifacts.require('SimpleIExample');
const Dispatcher: DispatcherContract = artifacts.require('ExampleDispatcher');
const ExampleV1: ExampleV1Contract = artifacts.require('ExampleV1');
const ExampleV2: ExampleV2Contract = artifacts.require('ExampleV2');
const IExample: IExampleContract = artifacts.require('IExample');
const GateKeeper: GateKeeperContract = artifacts.require('GateKeeper');

contract('Upgrading', (accounts) => {
  it('works simple', async () => {
    const gateKeeper = await GateKeeper.new();
    const contract1 = await SimpleExampleV1.new(gateKeeper.address);

    // create dispatcher
    const dispatcher = await SimpleDispatcher.new(gateKeeper.address);

    // grant permission to change target
    const role = await dispatcher.UPGRADE_CONTRACT();
    await gateKeeper.createPermission(accounts[0], dispatcher.address, role, accounts[0]);

    // set contract address in the dispatcher
    await dispatcher.setTarget(contract1.address, {
      from: accounts[0],
    });

    // using interace to get contract at address of the dispatcher
    const iex = await SimpleIExample.at(dispatcher.address);
    assert.equal((await iex.getUint()).toNumber(), 10);

    // create new target - second contract
    const contract2 = await SimpleExampleV2.new(gateKeeper.address);

    // change target to new
    await dispatcher.setTarget(contract2.address, {
      from: accounts[0],
    });
    assert.equal((await iex.getUint()).toNumber(), 1);
  });

  it('works', async () => {
    const gateKeeper = await GateKeeper.new();
    const contract1 = await ExampleV1.new(gateKeeper.address);

    // set target to first contract
    const dispatcher = await Dispatcher.new(gateKeeper.address);

    // grante permission to change target
    const role = await dispatcher.UPGRADE_CONTRACT();
    await gateKeeper.createPermission(accounts[0], dispatcher.address, role, accounts[0]);

    // set contract address in the dispatcher
    await dispatcher.setTarget(contract1.address, {
      from: accounts[0],
    });

    // using interface to get contract at address of the dispatcher
    const iex = await IExample.at(dispatcher.address);
    assert.equal((await iex.getUint()).toNumber(), 0);
    await iex.setUint(20);
    assert.equal((await iex.getUint()).toNumber(), 20);

    // create new target - second contract
    const contract2 = await ExampleV2.new(gateKeeper.address);
    assert.equal((await contract2.getUint()).toNumber(), 10);

    // change target to new
    await dispatcher.setTarget(contract2.address);
    assert.equal((await iex.getUint()).toNumber(), 30); // 30, because it's the old storage (20) + 10

    await iex.setUint(12);
    assert.equal((await iex.getUint()).toNumber(), 22);

    // second contract state should remain unchanged
    assert.equal((await contract2.getUint()).toNumber(), 10);
  });

  it('does not work without proper permissions', async () => {
    const gateKeeper = await GateKeeper.new();

    const contract1 = await SimpleExampleV1.new(gateKeeper.address);

    // set target to first contract
    const dispatcher = await SimpleDispatcher.new(gateKeeper.address);

    try {
      assert.throws(() => {
        dispatcher.setTarget(contract1.address);
      }, 'revert');
    } catch (e) {
      // console.log(e);
    }
  });
});
