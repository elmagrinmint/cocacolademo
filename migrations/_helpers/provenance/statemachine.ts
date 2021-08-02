/* eslint-disable @typescript-eslint/await-thenable */
import { createPermission, grantPermission } from '../authentication/permissions';

export async function deployFiniteStateMachineSystem(
  deployer: Truffle.Deployer,
  accounts: string[],
  gatekeeper: Truffle.Contract<any>,
  stateMachine: Truffle.Contract<any>,
  upgradeableRegistry: Truffle.Contract<any>,
  roleRegistries: Array<Truffle.Contract<any>> = [],
  uiDefinitions: object = {},
  extraParams: any[] = [],
  storeIpfsHash: (data: any) => Promise<string>
) {
  const dGateKeeper = await gatekeeper.deployed();

  await deployer.deploy(upgradeableRegistry, dGateKeeper.address);
  const dRegistry = await upgradeableRegistry.deployed();

  const params = [dGateKeeper.address, dRegistry.address, ...extraParams];
  await deployer.deploy(stateMachine, ...params);
  const dStateMachine = await stateMachine.deployed();

  // Give UPGRADE_CONTRACT permissions to accounts[0]
  await createPermission(dGateKeeper, dRegistry, 'UPGRADE_CONTRACT', accounts[0], accounts[0]);
  await dRegistry.upgrade(dStateMachine.address);

  // Give admin permission to accounts[0]
  await createPermission(dGateKeeper, dStateMachine, 'CREATE_STATEMACHINE_ROLE', accounts[0], accounts[0]);

  // Set create state machine role permissions on the relevant role registries
  for (const roleRegistry of roleRegistries) {
    await grantPermission(dGateKeeper, dStateMachine, 'CREATE_STATEMACHINE_ROLE', roleRegistry.address);
  }

  // Give admin permission to accounts[0]
  await createPermission(dGateKeeper, dStateMachine, 'UPDATE_UIFIELDDEFINITIONS_ROLE', accounts[0], accounts[0]);

  if (Object.keys(uiDefinitions).length) {
    const hash = await storeIpfsHash(uiDefinitions);
    await dStateMachine.setUIFieldDefinitionsHash(hash);
  }
}

export async function deployStateMachineSystem(
  deployer: Truffle.Deployer,
  accounts: string[],
  gatekeeper: Truffle.Contract<any>,
  registry: Truffle.Contract<any>,
  factory: Truffle.Contract<any>,
  roles: Array<Truffle.Contract<any>>,
  uiDefinitions: object = {},
  storeIpfsHash: (data: any) => Promise<string>
) {
  const dGateKeeper = await gatekeeper.deployed();

  await deployer.deploy(registry, dGateKeeper.address);
  const deployedRegistry = await registry.deployed();

  await createPermission(dGateKeeper, deployedRegistry, 'INSERT_STATEMACHINE_ROLE', accounts[0], accounts[0]);

  await deployer.deploy(factory, dGateKeeper.address, deployedRegistry.address);
  const deployedFactory = await factory.deployed();

  // Give admin permission to accounts[0]
  await createPermission(dGateKeeper, deployedFactory, 'CREATE_STATEMACHINE_ROLE', accounts[0], accounts[0]);

  await createPermission(dGateKeeper, deployedFactory, 'UPDATE_UIFIELDDEFINITIONS_ROLE', accounts[0], accounts[0]);

  // Set create expense permissions on the relevant role registries
  for (const role of roles) {
    await grantPermission(dGateKeeper, deployedFactory, 'CREATE_STATEMACHINE_ROLE', role.address);
  }

  // set the permissions on the factory
  await grantPermission(dGateKeeper, dGateKeeper, 'CREATE_PERMISSIONS_ROLE', deployedFactory.address);

  await grantPermission(dGateKeeper, deployedRegistry, 'INSERT_STATEMACHINE_ROLE', deployedFactory.address);

  if (Object.keys(uiDefinitions).length) {
    const hash = await storeIpfsHash(uiDefinitions);
    await deployedFactory.setUIFieldDefinitionsHash(hash);
  }

  return {
    registry: deployedRegistry,
    factory: deployedFactory,
  };
}
