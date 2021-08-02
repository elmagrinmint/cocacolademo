import dayjs from 'dayjs';

import { AdminRoleRegistryContract } from '../types/truffle-contracts/AdminRoleRegistry';
import { ResellerRoleRegistryContract } from '../types/truffle-contracts/ResellerRoleRegistry';
import { CarrierRoleRegistryContract } from '../types/truffle-contracts/CarrierRoleRegistry';
import { SupplierRoleRegistryContract } from '../types/truffle-contracts/SupplierRoleRegistry';

import { GateKeeperContract } from '../types/truffle-contracts/GateKeeper';

import { BeverageFactoryContract, BeverageFactoryInstance } from '../types/truffle-contracts/BeverageFactory';
import { BeverageRegistryContract } from '../types/truffle-contracts/BeverageRegistry';
import { deployStateMachineSystem } from './_helpers/provenance/statemachine';
 


const GateKeeper: GateKeeperContract = artifacts.require('GateKeeper');

// Beverage
const BeverageRegistry: BeverageRegistryContract = artifacts.require('BeverageRegistry');
const BeverageFactory: BeverageFactoryContract = artifacts.require('BeverageFactory');
const AdminRoleRegistry: AdminRoleRegistryContract = artifacts.require('AdminRoleRegistry');
const ResellerRoleRegistry: ResellerRoleRegistryContract = artifacts.require('ResellerRoleRegistry');
const CarrierRoleRegistry: CarrierRoleRegistryContract = artifacts.require('CarrierRoleRegistry');
const SupplierRoleRegistry: SupplierRoleRegistryContract = artifacts.require('SupplierRoleRegistry');

// eslint-disable-next-line @typescript-eslint/no-var-requires
const { enabledFeatures, storeIpfsHash } = require('../../truffle-config.js'); // two dirs up, because it is compiled into ./dist/migrations

module.exports = async (deployer: Truffle.Deployer, network: string, accounts: string[]) => {
  if (enabledFeatures().includes('BEVERAGE')) {
    // eslint-disable-next-line @typescript-eslint/no-var-requires
    const uiDefinitions = require('../../contracts/beverage/UIDefinitions.json');
    
    const { factory } = await deployStateMachineSystem(
      deployer,
      accounts,
      GateKeeper,
      BeverageRegistry,
      BeverageFactory,
      [AdminRoleRegistry, SupplierRoleRegistry, ResellerRoleRegistry, CarrierRoleRegistry ],
      uiDefinitions,
      storeIpfsHash
    );


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
      await createBeverage(factory , beverage);
    }
  }
};

async function createBeverage(
  beverageFactoryInstance: BeverageFactoryInstance, beverageData: IBeverageData) {
  const ipfsHash = await storeIpfsHash({
    
    requestDate: beverageData.requestDate,
    bottlingDate: beverageData.bottlingDate,
    bottling: beverageData.bottling,
    product: beverageData.product,
    shipmentDate: beverageData.shipmentDate,
  });

  await beverageFactoryInstance.create(beverageData.requestDate, beverageData.product, beverageData.bottling, beverageData.bottlingDate, beverageData.shipmentDate, ipfsHash);
}

interface IBeverageData {
  requestDate: number;
  bottlingDate: number;
  shipmentDate: number;
  product: string;
  bottling: string;
}
