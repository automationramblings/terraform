exports.handler = async (event) => {
    // TODO implement

    const payload = {
            event: "ACCOUNT_CREATION",
            status: "SUCCESS",
            acount_number: 1234567890,
            region: "us-east-1"
    };

    const response = {
        payload: payload
    };
    console.log(event);
    console.log(response);
    
    return response;
};
