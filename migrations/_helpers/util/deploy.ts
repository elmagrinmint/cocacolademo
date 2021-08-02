export async function deploy<Contract extends Truffle.Contract<any>>(
  contract: Contract,
  params: any[],
  deployer?: Truffle.Deployer
) {
  if (deployer) {
    // eslint-disable-next-line @typescript-eslint/await-thenable
    await deployer.deploy((contract as unknown) as Truffle.ContractNew<any[]>, ...params);

    return await contract.deployed();
  }

  return ((contract as unknown) as Truffle.ContractNew<any[]>).new(...params);
}

export function getNewAddressFromEvents(transaction: Truffle.TransactionResponse<any>, name: string) {
  return transaction.logs.filter((log) => log.event === name)[0].args._address;
}
