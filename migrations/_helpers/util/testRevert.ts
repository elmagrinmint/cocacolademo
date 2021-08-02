export async function testRevert(call: Promise<Truffle.TransactionResponse<any>>, errorMessage?: string) {
  let expectedError = null;
  try {
    await call;
  } catch (error) {
    expectedError = error;
    if (errorMessage) {
      assert.equal(error.message.replace('Returned error: ', ''), errorMessage);
    }
  }
  assert.isNotNull(expectedError, 'Transition should have thrown an exception');
}
