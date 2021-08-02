export async function createPermission<ContractInstance extends Truffle.ContractInstance>(
  gateKeeper: any,
  securedContractInstance: ContractInstance,
  permissionName: string,
  permissionManagerAddress: string,
  permissionRecipientAddress: string
) {
  const role: string = await securedContractInstance[permissionName].call();

  await gateKeeper.createPermission(
    permissionRecipientAddress,
    securedContractInstance.address,
    role,
    permissionManagerAddress
  );
}

export async function grantPermission<ContractInstance extends Truffle.ContractInstance>(
  gateKeeper: any,
  securedContractInstance: ContractInstance,
  permissionName: string,
  permissionRecipientAddress: string
) {
  const role: string = await securedContractInstance[permissionName].call();
  await gateKeeper.grantPermission(permissionRecipientAddress, securedContractInstance.address, role);
}

export async function hasPermission<ContractInstance extends Truffle.ContractInstance>(
  gateKeeper: any,
  securedContractInstance: ContractInstance,
  permissionName: string,
  potentialPermissionRecipientHolder: string
) {
  const role: string = await securedContractInstance[permissionName].call();

  return gateKeeper.hasPermission(potentialPermissionRecipientHolder, securedContractInstance.address, role);
}
