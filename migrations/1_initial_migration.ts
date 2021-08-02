import { MigrationsContract } from '../types/truffle-contracts';

const Migrations: MigrationsContract = artifacts.require('Migrations');

module.exports = async (deployer: Truffle.Deployer, network: string, accounts: string[]) => deployer.deploy(Migrations);
