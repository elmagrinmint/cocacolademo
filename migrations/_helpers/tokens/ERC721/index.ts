import { createPermission } from '../../authentication/permissions';

import { deployERC721Factory } from './factory';
import { deployERC721Registry } from './registry';
import { deployIERC721Token, issueERC721Tokens } from './token';

export interface IERC721TokenSet {
  gatekeeper: any;
  registry: {
    contract: any;
    extraParams: any[];
  };
  factory: {
    contract: any;
    extraParams: any[];
  };
  token: {
    contract: any;
    instances: IERC721Token[];
  };
  roles?: Array<Truffle.Contract<any>>;
}

export interface IERC721Token {
  name: string;
  tokenId: number;
  URI: string;
  extraParams: any[];
  issuance?: IERC721TokenIssuance[];
}

export interface IERC721TokenIssuance {
  recipientGroups: any[],
  tokenId: number;
}

export async function deployERC721TokenSystem(
  tokenSet: IERC721TokenSet,
  tokenSystemOwner: string,
  uiDefinitions: any,
  storeIpfsHash: (data: any) => Promise<string>,
  deployer?: Truffle.Deployer
) {
  const registry: any = await deployERC721Registry(tokenSet, tokenSystemOwner, deployer);
  const factory: any = await deployERC721Factory(tokenSet, tokenSystemOwner, registry, deployer);

  const tokens: any[] = [];
  for (const tokenInstance of tokenSet.token.instances) {
    const token = await deployIERC721Token(tokenSet, tokenInstance, factory);
    tokens.push(token);
    if (tokenInstance.issuance) {
      for (const tokenIssuance of tokenInstance.issuance) {
        await issueERC721Tokens(token, tokenInstance, tokenIssuance);
      }
    }
  }

  await createPermission(
    tokenSet.gatekeeper,
    factory,
    'UPDATE_UIFIELDDEFINITIONS_ROLE',
    tokenSystemOwner,
    tokenSystemOwner
  );

  const hash = await storeIpfsHash(uiDefinitions);
  await factory.setUIFieldDefinitionsHash(hash);

  return {
    registry,
    factory,
    tokens,
  };
}
