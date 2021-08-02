import { createPermission } from '../../authentication/permissions';
import { deploy } from '../../util/deploy';

import { IERC721TokenSet } from './index';

export async function deployERC721Registry(
  tokenSet: IERC721TokenSet,
  tokenSystemOwner: string,
  deployer?: Truffle.Deployer
) {
  const registry = await deploy(
    tokenSet.registry.contract,
    [tokenSet.gatekeeper.address, ...tokenSet.registry.extraParams],
    deployer
  );
  await createPermission(tokenSet.gatekeeper, registry, 'LIST_TOKEN_ROLE', tokenSystemOwner, tokenSystemOwner);

  return registry;
}
