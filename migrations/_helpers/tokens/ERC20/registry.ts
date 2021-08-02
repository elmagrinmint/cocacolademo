import { createPermission } from '../../authentication/permissions';
import { deploy } from '../../util/deploy';

import { IERC20TokenSet } from './index';

export async function deployERC20Registry(
  tokenSet: IERC20TokenSet,
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
