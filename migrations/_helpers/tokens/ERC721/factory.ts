import { createPermission, grantPermission } from '../../authentication/permissions';
import { deploy } from '../../util/deploy';

import { IERC721TokenSet } from './index';

export async function deployERC721Factory(
  tokenSet: IERC721TokenSet,
  tokenSystemOwner: string,
  registry: any,
  deployer?: Truffle.Deployer
) {
  const factory: any = await deploy(
    tokenSet.factory.contract,
    [registry.address, tokenSet.gatekeeper.address, ...tokenSet.factory.extraParams],
    deployer
  );
  await createPermission(tokenSet.gatekeeper, factory, 'CREATE_TOKEN_ROLE', tokenSystemOwner, tokenSystemOwner);
  // Set create expense permissions on the relevant role registries
  if (tokenSet.roles) {
    for (const role of tokenSet.roles) {
      await grantPermission(tokenSet.gatekeeper, factory, 'CREATE_TOKEN_ROLE', role.address);
    }
  }

  await grantPermission(tokenSet.gatekeeper, registry, 'LIST_TOKEN_ROLE', factory.address);
  await grantPermission(tokenSet.gatekeeper, tokenSet.gatekeeper, 'CREATE_PERMISSIONS_ROLE', factory.address);

  return factory;
}
