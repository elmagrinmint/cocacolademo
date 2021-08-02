import { createPermission } from '../../migrations/_helpers/authentication/permissions';
import { RoleRegistryContract, RoleRegistryInstance } from '../../types/truffle-contracts/RoleRegistry';
import { GateKeeperContract } from '../../types/truffle-contracts/GateKeeper';


const RoleRegistry: RoleRegistryContract = artifacts.require('RoleRegistry');
const GateKeeper: GateKeeperContract = artifacts.require('GateKeeper');

contract('RoleRegistry', (accounts) => {
  let DeployedRoleRegistry: RoleRegistryInstance;

  beforeEach(async () => {
    const DeployedGateKeeper = await GateKeeper.new();
    DeployedRoleRegistry = await RoleRegistry.new(DeployedGateKeeper.address);
    await createPermission<RoleRegistryInstance>(
      DeployedGateKeeper,
      DeployedRoleRegistry,
      'DESIGNATE_ROLE',
      accounts[0],
      accounts[0]
    );
  });

  it('should return false for random addresses', async () => {
    const hasRole = await DeployedRoleRegistry.hasRole(accounts[1]);
    assert.isFalse(hasRole);
  });

  it('should be able to designate', async () => {
    const hasRoleBefore = await DeployedRoleRegistry.hasRole(accounts[1]);
    assert.isFalse(hasRoleBefore);
    await DeployedRoleRegistry.designate(accounts[1], { from: accounts[0] });
    const hasRoleAfter = await DeployedRoleRegistry.hasRole(accounts[1]);
    assert.isTrue(hasRoleAfter);
  });

  it('should be able to discharge', async () => {
    const hasRoleBefore = await DeployedRoleRegistry.hasRole(accounts[1]);
    assert.isFalse(hasRoleBefore);
    await DeployedRoleRegistry.designate(accounts[1], { from: accounts[0] });
    const hasRoleDuring = await DeployedRoleRegistry.hasRole(accounts[1]);
    assert.isTrue(hasRoleDuring);
    await DeployedRoleRegistry.discharge(accounts[1], { from: accounts[0] });
    const hasRoleAfter = await DeployedRoleRegistry.hasRole(accounts[1]);
    assert.isFalse(hasRoleAfter);
  });

  it('should be able to designate a known address', async () => {
    await DeployedRoleRegistry.designate(accounts[1], { from: accounts[0] });
    const hasRoleInit = await DeployedRoleRegistry.hasRole(accounts[1]);
    assert.isTrue(hasRoleInit);
    await DeployedRoleRegistry.discharge(accounts[1], { from: accounts[0] });
    const hasRoleBefore = await DeployedRoleRegistry.hasRole(accounts[1]);
    assert.isFalse(hasRoleBefore);
    await DeployedRoleRegistry.designate(accounts[1], { from: accounts[0] });
    const hasRoleAfter = await DeployedRoleRegistry.hasRole(accounts[1]);
    assert.isTrue(hasRoleAfter);
  });

  it('should be able to get the amount of items in the index array', async () => {
    const hasRoleBefore = await DeployedRoleRegistry.hasRole(accounts[1]);
    assert.isFalse(hasRoleBefore);
    await DeployedRoleRegistry.designate(accounts[1], { from: accounts[0] });
    const hasRoleAfter = await DeployedRoleRegistry.hasRole(accounts[1]);
    assert.isTrue(hasRoleAfter);
    const indexLength = await DeployedRoleRegistry.getIndexLength();
    assert.equal(indexLength.toNumber(), 1);
  });

  it('should be able to get an item by index', async () => {
    const hasRoleBefore = await DeployedRoleRegistry.hasRole(accounts[1]);
    assert.isFalse(hasRoleBefore);
    await DeployedRoleRegistry.designate(accounts[1], { from: accounts[0] });
    const hasRoleAfter = await DeployedRoleRegistry.hasRole(accounts[1]);
    assert.isTrue(hasRoleAfter);
    const item = await DeployedRoleRegistry.getByIndex(0);
    assert.isTrue(item[1]);
  });

  it('should be able to get an item by key', async () => {
    const hasRoleBefore = await DeployedRoleRegistry.hasRole(accounts[1]);
    assert.isFalse(hasRoleBefore);
    await DeployedRoleRegistry.designate(accounts[1], { from: accounts[0] });
    const hasRoleAfter = await DeployedRoleRegistry.hasRole(accounts[1]);
    assert.isTrue(hasRoleAfter);
    const item = await DeployedRoleRegistry.getByKey(accounts[1]);
    assert.isTrue(item[1]);
  });
});
