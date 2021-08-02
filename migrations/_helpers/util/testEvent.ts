export function testEvent(
  transaction: Truffle.TransactionResponse<any>,
  eventName: string,
  argums: { [key: string]: string | number | BN } = {}
) {
  const event = transaction.logs.filter((log) => log.event === eventName)[0];
  assert.isOk(event);
  const args: any = {};
  Object.keys(event.args).forEach((argName) => {
    args[argName] = event.args[argName].toString();
  });
  assert.include(args, argums, `${eventName} (${JSON.stringify(args)}) should contain ${JSON.stringify(argums)}`);
}
