import { promisify } from 'util';

export async function timeTravel(seconds: number) {
  await promisify((web3.currentProvider as any).send.bind(web3.currentProvider))({
    jsonrpc: '2.0',
    method: 'evm_increaseTime',
    params: [seconds],
    id: new Date().getTime(),
  });

  return promisify((web3.currentProvider as any).send.bind(web3.currentProvider))({
    jsonrpc: '2.0',
    method: 'evm_mine',
    id: new Date().getTime(),
  });
}
