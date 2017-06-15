# Fastly Altitude 2017 Load Balancing Workshop

Below you will find resources required for the workshop on Load Balancing at Fastly's Altitude 2017 in San Francisco. 

Clone this repo and refer to the sheet given to you at the workshop which contains your specific Fastly Service ID, and the domain attached to your specific service.

## Suggested Reading

Fastly documentation:

* [API documentation](https://docs.fastly.com/api/)
* [Dynamic servers documentation](https://docs.fastly.com/guides/dynamic-servers/)
* [Working with services](https://docs.fastly.com/api/config#service)
* [Working with service versions](https://docs.fastly.com/api/config#version)
* [Conditions documentation](https://docs.fastly.com/guides/conditions/)
* [GeoIP related features](https://docs.fastly.com/guides/vcl/geoip-related-vcl-features)

## Load Balancing Information

For all workshops, we will be working directly with the Fastly API. You can use the following API key in your workshops:

* **API Key**: 

For workshops 1 & 3, we will be using two instances in a single load balancing pool:

* **GCS** (us-west1): **104.196.253.201**
* **EC2** (us-east2): **13.58.97.100**

## General Tips

We will be working with an API that returns JSON as its response. 

**Make sure you are taking note of the responses!** We will be working with data from these API responses to complete the different parts of the workshop.

In order to read the JSON in a human friendly way, it is suggested you install some sort of JSON parser.

[JQ](https://stedolan.github.io/jq/) can be used for this purpose. A tutorial for basic usage can be found [here](https://stedolan.github.io/jq/tutorial/).


## Workshop 1: Load Balancing Between Cloud Providers

### Step 1: Cloning a new version
In order to begin adding Dynamic Server Pools, we will first need to clone your service and create a new pool

In this case we will be cloning version 1 of your service to version 2:

`curl -sv -H "Fastly-Key: api_key" https://api.fastly.com/service/service_id/version/1/clone`

### Step 2: Upload boilerplate VCL for service

In this repo there is includd a `main.vcl` which we will upload to our service. Two things to note:

1. There is a clearly defined space in `vcl_recv` where we will be doing our custom VCL for this workshop.
2. Immediately below you will see `return(pass)`. For the purposes of this workshop we are passing all traffic to the backend so that we can see immediate responses (and not cached responses)

### Step 2: Create dynamic server pool

Next, we will need to create a Dynamic Server Pool to add our servers to (*note we are now working with version 2*):

`curl -sv -H "Fastly-Key: api_key" -X POST https://api.fastly.com/service/service_id/version/2/pool -d 'name=cloudpool&comment=cloudpool'`

**Grab the pool ID in the response as we will be using this in the next step**

### Step 3: Add servers to the pool

We can now begin to start adding servers to the pool (use the IPs listed above to add the servers)

*You will run this command twice with the different IP addresses:*

`curl -vs -H "Fastly-Key: api_key" -X POST https://api.fastly.com/service/service_id/pool/pool_id/server -d 'address=X.X.X.X'`


### Step 4: Activate our new version

Our last configuration step. Now we have added our pool (dynamic pools are tied to a version, the dynamic servers in the pool are not):

`curl -vs -H "Fastly-Key: api_key" -X PUT https://api.fastly.com/service/service_id/version/2/activate`

### Step 5: Browse the new load balanced pool

Open your browser and navigate to your supplied domain (_\<num>.lbworkshop.tech_)

You should now be able to see something like this:

GCS serving the request:

![GCS](https://github.com/chrisbuckley/altitude-2017-lb-workshop/raw/master/images/gcs.png "GCS instance serving the request")

EC2 serving the request:

![EC2](https://github.com/chrisbuckley/altitude-2017-lb-workshop/raw/master/images/ec2.png "EC2 instance serving the request")

Keep refreshing and you will see both instances displaying at one time or another. This have been configure with defaults, so request are _random_ to each origin server.

## Workshop 2: SOA / Microservice Routing


