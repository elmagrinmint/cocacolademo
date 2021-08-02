import faker from 'faker';

import { AdminRoleRegistryContract, AdminRoleRegistryInstance } from '../types/truffle-contracts/AdminRoleRegistry';
import { CarrierRoleRegistryContract } from '../types/truffle-contracts/CarrierRoleRegistry';
import { ResellerRoleRegistryContract } from '../types/truffle-contracts/ResellerRoleRegistry';
import { SupplierRoleRegistryContract } from '../types/truffle-contracts/SupplierRoleRegistry';

import { GateKeeperContract, GateKeeperInstance } from '../types/truffle-contracts/GateKeeper';
import { createMintAccounts, deployRoleRegistry, IMintUser } from './_helpers/authentication/accounts';
import { grantPermission } from './_helpers/authentication/permissions';

// eslint-disable-next-line @typescript-eslint/no-var-requires
const { enabledFeatures } = require('../../truffle-config.js'); // two dirs up, because it is compiled into ./dist/migrations

const GateKeeper: GateKeeperContract = artifacts.require('GateKeeper');

const AdminRoleRegistry: AdminRoleRegistryContract = artifacts.require('AdminRoleRegistry');
const ResellerRoleRegistry: ResellerRoleRegistryContract = artifacts.require('ResellerRoleRegistry');
const CarrierRoleRegistry: CarrierRoleRegistryContract = artifacts.require('CarrierRoleRegistry');
const SupplierRoleRegistry: SupplierRoleRegistryContract = artifacts.require('SupplierRoleRegistry');




const roleRegistries: Array<{
  registry: Truffle.Contract<any>;
  role: string;
  prefix: string;
  seed: string;
}> = [];

const found = (features: string[]) => enabledFeatures().some((feature: string) => features.includes(feature));


if (found(['BEVERAGE'])) {
  roleRegistries.push(
    {
      registry: ResellerRoleRegistry,
      role: 'ROLE_RESELLER',
      prefix: 'reseller',
      seed: 'elder pass group bacon equal adapt fish birth search goose garage slush',
    },
    {
      registry: SupplierRoleRegistry,
      role: 'ROLE_SUPPLIER',
      prefix: 'supplier',
      seed: 'infant transfer spatial warfare chief mandate ahead execute grit vessel domain clay',
    },
    {
      registry: CarrierRoleRegistry,
      role: 'ROLE_CARRIER',
      prefix: 'carrier',
      seed: 'infant transfer spatial warfare chief mandate ahead execute grit vessel domain clay',
    }
  );
}


module.exports = async (deployer: Truffle.Deployer, network: string, accounts: string[]) => {
  const userData: IMintUser[] = [];
  let bipIndex = 0;

  const dGateKeeper: GateKeeperInstance = await GateKeeper.deployed();

  // Admin
  const dAdminRoleRegistry: AdminRoleRegistryInstance = await deployRoleRegistry(
    AdminRoleRegistry,
    dGateKeeper,
    accounts[0],
    deployer
  );

  const hasRole = await dAdminRoleRegistry.hasRole(accounts[0]);
  if (!hasRole) {
    await dAdminRoleRegistry.designate(accounts[0]);
  }

  // admin key
  const adminKeyAsBytes32 = web3.utils.fromAscii('ROLE_ADMIN');
  const adminZeroPaddedKey = web3.eth.abi.encodeParameter('bytes32', adminKeyAsBytes32);

  // add roleregistry to gatekeeper and roleregistrymap
  await dGateKeeper.addRoleRegistry(dAdminRoleRegistry.address);
  await dGateKeeper.setRoleRegistryAddress(adminZeroPaddedKey, dAdminRoleRegistry.address);

  // Give to role registry the permission to designate admin roles to others
  await grantPermission(dGateKeeper, dAdminRoleRegistry, 'DESIGNATE_ROLE', dAdminRoleRegistry.address);

  for (const roleRegistry of roleRegistries) {
    const dRoleRegistry = await deployRoleRegistry(
      roleRegistry.registry,
      dGateKeeper,
      accounts[0], // only admin can do this
      deployer
    );

    const amount = 2;
    for (let i = 0; i < amount; i++) {
      userData.push({
        mnemonic: roleRegistry.seed,
        bip39Path: `m/44'/60'/0'/0/${bipIndex++}`,
        username: `${roleRegistry.prefix}${i}@example.com`,
        firstname: faker.name.firstName(),
        lastname: `(${roleRegistry.role.replace('ROLE_', '').replace('_ROLE', '')})`,
        company: faker.company.companyName(),
        password: 'settlemint',
        role: 'USER',
        roleRegistry: dRoleRegistry,
      });
    }

    // create keys again
    const keyAsBytes32 = web3.utils.fromAscii(roleRegistry.role);
    const zeroPaddedKey = web3.eth.abi.encodeParameter('bytes32', keyAsBytes32);

    // Add roleregistry to gatekeeper and roleregistrymap
    await dGateKeeper.addRoleRegistry(dRoleRegistry.address);
    await dGateKeeper.setRoleRegistryAddress(zeroPaddedKey, dRoleRegistry.address);

    // Give to role registry the permission to designate role registry roles to others
    await grantPermission(dGateKeeper, dRoleRegistry, 'DESIGNATE_ROLE', dRoleRegistry.address);
  }

  // eslint-disable-next-line @typescript-eslint/no-var-requires
  const { entethMiddleware } = require('../../truffle-config.js'); // two dirs up, because it is compiled into ./dist/migrations
  await createMintAccounts({
    userData,
    mintHost: entethMiddleware,
  });
};
