import { GateKeeperContract } from '../../../types/truffle-contracts/GateKeeper';
import { StateMachineImplHappyContract } from '../../../types/truffle-contracts/StateMachineImplHappy';

const StateMachineImplHappyArtifact: StateMachineImplHappyContract = artifacts.require('StateMachineImplHappy');
const GateKeeperArtifact: GateKeeperContract = artifacts.require('GateKeeper');

contract('StateMachine', (accounts) => {
  it('should be possible to setup up a new state machine', async () => {
    const GateKeeper = await GateKeeperArtifact.new();
    const StateMachine = await StateMachineImplHappyArtifact.new(GateKeeper.address, accounts[0], accounts[1]);
    const currentState = await StateMachine.getCurrentState();
    assert.equal(web3.utils.hexToString(currentState), 'CREATED', 'the initial state is not set correctly');

    const allStates = await StateMachine.getAllStates();
    allStates.forEach((state) => {
      assert(
        ['CREATED', 'MODIFIED', 'ACCEPTED', 'REJECTED', 'TEMPORARY', 'ENDED'].includes(web3.utils.hexToString(state)),
        `the ${web3.utils.hexToString(state)} state was not found`
      );
    });

    // const nextStates = await StateMachine.getNextStates();
    // assert.sameMembers(
    //   [
    //     `${web3.utils.asciiToHex('MODIFIED').replace(/0+$/, '')}`,
    //     `${web3.utils.asciiToHex('ACCEPTED').replace(/0+$/, '')}`,
    //     `${web3.utils.asciiToHex('REJECTED').replace(/0+$/, '')}`,
    //   ],
    //   nextStates,
    //   `the nextStates are not the same`
    // );
  });

  it('should be possible to transition states', async () => {
    const GateKeeper = await GateKeeperArtifact.new();
    const StateMachine = await StateMachineImplHappyArtifact.new(GateKeeper.address, accounts[0], accounts[1]);

    const roleEditor = await StateMachine.ROLE_EDITOR();
    await GateKeeper.createPermission(accounts[0], StateMachine.address, roleEditor, accounts[0]);

    const roleCounterparty = await StateMachine.ROLE_COUNTERPARTY();
    await GateKeeper.createPermission(accounts[1], StateMachine.address, roleCounterparty, accounts[0]);

    await StateMachine.transitionState(web3.utils.asciiToHex('MODIFIED'));

    const modificationTransitionHandled = await StateMachine.modificationTransitionHandled();
    assert(modificationTransitionHandled, 'callback for modification was not called');

    let currentState = await StateMachine.getCurrentState();
    assert.equal(web3.utils.hexToString(currentState), 'MODIFIED', 'the state is not set correctly');

    let nextStates = await StateMachine.getNextStates();
    // assert.sameMembers(
    //   [
    //     `${web3.utils.asciiToHex('MODIFIED').replace(/0+$/, '')}`,
    //     `${web3.utils.asciiToHex('ACCEPTED').replace(/0+$/, '')}`,
    //     `${web3.utils.asciiToHex('REJECTED').replace(/0+$/, '')}`,
    //   ],
    //   nextStates,
    //   `the nextStates are not the same`
    // );

    await StateMachine.transitionState(web3.utils.asciiToHex('MODIFIED'));

    currentState = await StateMachine.getCurrentState();
    assert.equal(web3.utils.hexToString(currentState), 'MODIFIED', 'the state is not set correctly');

    nextStates = await StateMachine.getNextStates();
    // assert.sameMembers(
    //   [
    //     `${web3.utils.asciiToHex('MODIFIED').replace(/0+$/, '')}`,
    //     `${web3.utils.asciiToHex('ACCEPTED').replace(/0+$/, '')}`,
    //     `${web3.utils.asciiToHex('REJECTED').replace(/0+$/, '')}`,
    //   ],
    //   nextStates,
    //   `the nextStates are not the same`
    // );

    await StateMachine.transitionState(web3.utils.asciiToHex('REJECTED'), {
      from: accounts[1],
    });

    currentState = await StateMachine.getCurrentState();
    assert.equal(web3.utils.hexToString(currentState), 'REJECTED', 'the state is not set correctly');

    nextStates = await StateMachine.getNextStates();
    // assert.sameMembers(
    //   [`${web3.utils.asciiToHex('MODIFIED')}`],
    //   nextStates,
    //   `the nextStates are not the same`
    // );

    await StateMachine.transitionState(web3.utils.asciiToHex('MODIFIED'));

    currentState = await StateMachine.getCurrentState();
    assert.equal(web3.utils.hexToString(currentState), 'MODIFIED', 'the state is not set correctly');

    nextStates = await StateMachine.getNextStates();
    // assert.sameMembers(
    //   [
    //     `${web3.utils.asciiToHex('MODIFIED').replace(/0+$/, '')}`,
    //     `${web3.utils.asciiToHex('ACCEPTED').replace(/0+$/, '')}`,
    //     `${web3.utils.asciiToHex('REJECTED').replace(/0+$/, '')}`,
    //   ],
    //   nextStates,
    //   `the nextStates are not the same`
    // );

    await StateMachine.sign({ from: accounts[0] });
    await StateMachine.sign({ from: accounts[1] });

    await StateMachine.transitionState(web3.utils.asciiToHex('ACCEPTED'), {
      from: accounts[1],
    });

    currentState = await StateMachine.getCurrentState();
    assert.equal(web3.utils.hexToString(currentState), 'ACCEPTED', 'the state is not set correctly');

    nextStates = await StateMachine.getNextStates();
    // assert.sameMembers(
    //   [
    //     `${web3.utils.asciiToHex('ENDED').replace(/0+$/, '')}`,
    //     `${web3.utils.asciiToHex('TEMPORARY').replace(/0+$/, '')}`,
    //   ],
    //   nextStates,
    //   `the nextStates are not the same`
    // );

    // Temporary state callback will internally transition to ENDED
    await StateMachine.transitionState(web3.utils.asciiToHex('TEMPORARY'));

    currentState = await StateMachine.getCurrentState();
    assert.equal(web3.utils.hexToString(currentState), 'ENDED', 'the state is not set correctly');

    nextStates = await StateMachine.getNextStates();
    assert.sameMembers([], nextStates, `the nextStates are not the same`);
  });
});
