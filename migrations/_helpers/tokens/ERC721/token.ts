import web3 from 'web3';

import { getNewAddressFromEvents } from '../../util/deploy';

import { IERC721Token, IERC721TokenIssuance, IERC721TokenSet } from './index';

export async function deployIERC721Token(tokenSet: IERC721TokenSet, tokenInstance: IERC721Token, factory: any) {
  const tokenDeployTransaction = await factory.createToken(
    tokenInstance.name,
    tokenInstance.tokenId,
    ...tokenInstance.extraParams
  );

  const newTokenAddress = getNewAddressFromEvents(tokenDeployTransaction, 'TokenCreated');

  const token = await tokenSet.token.contract.at(newTokenAddress);

  return token;
}

export async function issueERC721Tokens(token: any, tokenInstance: IERC721Token, tokenIssuance: IERC721TokenIssuance) {
  for (const recipientGroups of tokenIssuance.recipientGroups) {
    const deployedRecipientGroup = await recipientGroups.deployed();

    await token.mintToRoleRegistry(
      deployedRecipientGroup.address,
      web3.utils
        .toBN(tokenIssuance.tokenId) as any
    );
  }
}
