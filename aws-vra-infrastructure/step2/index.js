const AWS = require('aws-sdk')
AWS.config.update({region: process.env.AWS_REGION})
const eventbridge = new AWS.EventBridge()


exports.handler = async (event) => {
    // TODO implement


    console.log(event.Input)

    return event.Input;
};

