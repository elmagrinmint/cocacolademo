import { GateKeeperContract } from '../types/truffle-contracts';

const GateKeeper: GateKeeperContract = artifacts.require('GateKeeper');

module.exports = async (deployer: Truffle.Deployer, network: string, accounts: string[]) => deployer.deploy(GateKeeper);
