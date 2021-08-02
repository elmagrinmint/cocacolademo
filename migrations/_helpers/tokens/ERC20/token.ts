import web3 from 'web3';

import { getNewAddressFromEvents } from '../../util/deploy';

import { IERC20Token, IERC20TokenIssuance, IERC20TokenSet } from './index';

export async function deployIERC20Token(tokenSet: IERC20TokenSet, tokenInstance: IERC20Token, factory: any) {
  const tokenDeployTransaction = await factory.createToken(
    tokenInstance.name,
    tokenInstance.decimals,
    ...tokenInstance.extraParams
  );

  const newTokenAddress = getNewAddressFromEvents(tokenDeployTransaction, 'TokenCreated');

  const token = await tokenSet.token.contract.at(newTokenAddress);

  return token;
}

export async function issueERC20Tokens(token: any, tokenInstance: IERC20Token, tokenIssuance: IERC20TokenIssuance) {
  for (const recipientGroups of tokenIssuance.recipientGroups) {
    const deployedRecipientGroup = await recipientGroups.deployed();

    await token.mintToRoleRegistry(
      deployedRecipientGroup.address,
      web3.utils
        .toBN(tokenIssuance.amount)
        .mul(web3.utils.toBN('10').pow(web3.utils.toBN(tokenInstance.decimals))) as any
    );
  }
}
