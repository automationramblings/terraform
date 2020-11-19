exports.handler = async (event) => {
    // TODO implement
    console.log(event);

    const response = {
        statusCode: 200,
        payload: JSON.parse(event).payload
    };
    console.log(response);
    
    return response;
};
