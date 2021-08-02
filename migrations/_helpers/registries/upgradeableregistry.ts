import { createPermission } from '../authentication/permissions';
const { storeIpfsHash } = require('../../../truffle-config.js'); // two dirs up, because it is compiled into ./dist/migrations

export async function deployUpgradeableRegistry(
  deployer: Truffle.Deployer,
  accounts: string[],
  gatekeeper: Truffle.Contract<any>,
  registryTarget: Truffle.Contract<any>,
  upgradeableRegistry: Truffle.Contract<any>,
  uiDefinitions: object = {},
  extraParams: any[] = []
) {
  const dGateKeeper = await gatekeeper.deployed();

  // Deploy the registry
  // eslint-disable-next-line @typescript-eslint/await-thenable
  await deployer.deploy(upgradeableRegistry, dGateKeeper.address);
  const dRegistry = await upgradeableRegistry.deployed();

  // Give UPGRADE_CONTRACT permissions
  await createPermission(dGateKeeper, dRegistry, 'UPGRADE_CONTRACT', accounts[0], accounts[0]);

  // Deploy the target
  const params = [dGateKeeper.address, ...extraParams];
  // eslint-disable-next-line @typescript-eslint/await-thenable
  await deployer.deploy(registryTarget, ...params);
  const dRegistryTarget = await registryTarget.deployed();
  await dRegistry.upgrade(dRegistryTarget.address);

  // Take care of UIFieldDefinitions if they are passed
  if (Object.keys(uiDefinitions).length) {
    await createPermission(dGateKeeper, dRegistryTarget, 'UPDATE_UIFIELDDEFINITIONS_ROLE', accounts[0], accounts[0]);
    const hash = await storeIpfsHash(uiDefinitions);
    await dRegistryTarget.setUIFieldDefinitionsHash(hash);
  }
}
