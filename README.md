# Fastly Altitude 2017 Load Balancing Workshop

Below you will find resources required for the workshop on Load Balancing at Fastly's Altitude 2017 in San Francisco. 

Clone this repo and refer to the sheet given to you at the workshop which contains your specific Fastly Service ID, and the domain attached to your specific service.

## Prerequisite Reading

Fastly documentation:

* [API documentation](https://docs.fastly.com/api/)
* [Dynamic servers documentation](https://docs.fastly.com/guides/dynamic-servers/)
* [Working with service versions in the API](https://docs.fastly.com/api/config#version)
* [Conditions documentation](https://docs.fastly.com/guides/conditions/)

## Load Balancing Origin Information

For all workshops, we will be working directly with the Fastly API. You can use the following API key in your workshops:

* **API Key**: 

For workshops 1 & 3, we will be using two instances in a single load balancing pool:

* **GCS** (us-west1): **104.196.253.201**
* **EC2** (us-east2): **13.58.97.100**


## Workshop 1: Load Balancing Between Cloud Providers

In order to begin adding Dynamic Server Pools, we will first need to clone your service and create a new pool

In this case we will be cloning version 1 of your service to version 2:

`curl -sv -H "Fastly-Key: api_key" https://api.fastly.com/service/service_id/version/1/clone`



## Workshop 2: 


