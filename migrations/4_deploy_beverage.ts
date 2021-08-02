import dayjs from 'dayjs';

import { AdminRoleRegistryContract } from '../types/truffle-contracts/AdminRoleRegistry';
import { BeverageContract, BeverageInstance } from '../types/truffle-contracts/Beverage';
import { BeverageRegistryContract } from '../types/truffle-contracts/BeverageRegistry';
import { GateKeeperContract } from '../types/truffle-contracts/GateKeeper';
import { deployFiniteStateMachineSystem } from './_helpers/provenance/statemachine';
import { ResellerRoleRegistryContract } from '../types/truffle-contracts/ResellerRoleRegistry';
import { CarrierRoleRegistryContract } from '../types/truffle-contracts/CarrierRoleRegistry';
import { SupplierRoleRegistryContract } from '../types/truffle-contracts/SupplierRoleRegistry';
 


const GateKeeper: GateKeeperContract = artifacts.require('GateKeeper');

// Beverage
const BeverageRegistry: BeverageRegistryContract = artifacts.require('BeverageRegistry');
const Beverage: BeverageContract = artifacts.require('Beverage');
const AdminRoleRegistry: AdminRoleRegistryContract = artifacts.require('AdminRoleRegistry');
const ResellerRoleRegistry: ResellerRoleRegistryContract = artifacts.require('ResellerRoleRegistry');
const CarrierRoleRegistry: CarrierRoleRegistryContract = artifacts.require('CarrierRoleRegistry');
const SupplierRoleRegistry: SupplierRoleRegistryContract = artifacts.require('SupplierRoleRegistry');

// eslint-disable-next-line @typescript-eslint/no-var-requires
const { enabledFeatures, storeIpfsHash } = require('../../truffle-config.js'); // two dirs up, because it is compiled into ./dist/migrations

module.exports = async (deployer: Truffle.Deployer, network: string, accounts: string[]) => {
  if (enabledFeatures().includes('BEVERAGE')) {
    // eslint-disable-next-line @typescript-eslint/no-var-requires
    const uiDefinitions = require('../../contracts/Beverage/UIDefinitions.json');
    await deployFiniteStateMachineSystem(
      deployer,
      accounts,
      GateKeeper,
      Beverage,
      BeverageRegistry,
      [AdminRoleRegistry, SupplierRoleRegistry, ResellerRoleRegistry, CarrierRoleRegistry ],
      uiDefinitions,
      [],
      storeIpfsHash
    );
    const dBeverage = await Beverage.deployed();

    const dGateKeeper = await GateKeeper.deployed();
    const allRoles = await dBeverage.allRoles();
    for (const role of allRoles) {
      await dGateKeeper.createPermission(accounts[0], dBeverage.address, role, accounts[0]);
    }

    const roleToRoleRegistries = {
      ROLE_ADMIN: AdminRoleRegistry,
      ROLE_SUPPLIER: SupplierRoleRegistry,
      ROLE_CARRIER: CarrierRoleRegistry,
      ROLE_RESELLER: ResellerRoleRegistry,
    };

    for (const role of Object.keys(roleToRoleRegistries)) {
      await dGateKeeper.grantPermission(
        roleToRoleRegistries[role].address,
        dBeverage.address,
        web3.eth.abi.encodeParameter('bytes32', web3.utils.fromAscii(role))
      );
    }

    const beverages = [
      { 
        requestDate: dayjs('2021-08-01').unix(),
        bottlingDate: dayjs('2021-07-10').unix(),
        shipmentDate: dayjs('2021-08-02').unix(),
        product: 'Coca Cola',
        bottling: 'Can500ml',
      },
    ];

    for (const beverage of beverages) {
      await createBeverage(dBeverage, beverage, accounts[0]);
    }
  }
};

async function createBeverage(beverageInstance: BeverageInstance, beverageData: IBeverageData, owner: string) {
  const ipfsHash = await storeIpfsHash({
    
    requestDate: beverageData.requestDate,
    bottlingDate: beverageData.bottlingDate,
    bottling: beverageData.bottling,
    product: beverageData.product,
    shipmentDate: beverageData.shipmentDate,
  });

  await beverageInstance.create(beverageData.requestDate, beverageData.bottlingDate, beverageData.shipmentDate, beverageData.product, beverageData.bottling, ipfsHash, owner);
}

interface IBeverageData {
  requestDate: number;
  bottlingDate: number;
  shipmentDate: number;
  product: string;
  bottling: string;
}
