exports.handler = async function (event, context) {

  // raise an error
  throw new Error('This is a fail');

  const response = {
    statusCode: 200,
    body: JSON.stringify('Hello from Lambda!'),
  };
  return response;
};
