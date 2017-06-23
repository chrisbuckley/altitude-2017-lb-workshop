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
* [Creating health checks via the API](https://docs.fastly.com/api/config#healthcheck)

## Load Balancing Information

For all workshops, we will be working directly with the Fastly API. You can use the following API key in your workshops:

* **API Key**: 

For workshops 1 & 3, we will be using two instances in a single load balancing pool:

* **GCS** (us-west1): **104.196.253.201** (hostname: alt2017-lb-gcs-us-west1)
* **EC2** (us-east2): **13.58.97.100** (hostname: alt2017-lb-ec2-us-east2)

In workshop 2, we will be using a Wordpress blog as an example of SOA / Microservice routing. The blog is listed below:

`https://blog.lbworkshop.tech/`

## Initial Setup
In order to ease usage of the API, let's set a few environment variables for our API key and your personal service ID.

Grab the API key from the readme above, and your service ID from the sheet given to you at the beginning of this workshop (this is assuming a Bash shell):

```
export API_KEY=<api_key>
export SERVICE_ID=<service_id>
```


## General Tips

We will be working with an API that returns JSON as its response. 

**Make sure you are taking note of the responses!**

We will be working with data from these API responses to complete the different parts of the workshop.

In order to read the JSON in a human friendly way, it is suggested you install some sort of JSON parser.

[JQ](https://stedolan.github.io/jq/) can be used for this purpose. A tutorial for basic usage can be found [here](https://stedolan.github.io/jq/tutorial/).

**If at any time you get version drift in this workshop, you can find out your current active version and work from that using the following command:**

`curl sv -H "Fastly-Key: ${API_KEY}" https://api.fastly.com/service/${SERVICE_ID}/details | jq`

You will receive a JSON response listing all versions. You will want to find the one where `"active": true`:

```
{
  "testing": false,
  "locked": true,
  "number": 10,
  "active": true,
  "service_id": "1OPpKYvOlWVx37twfGVsq0",
  "staging": false,
  "created_at": "2017-06-16T01:07:30+00:00",
  "deleted_at": null,
  "comment": "",
  "updated_at": "2017-06-16T01:14:14+00:00",
  "deployed": false
},
```

You can then clone from your current active version and work from there.

## Workshop 1: Load Balancing Between Cloud Providers

### Step 1: Cloning a new version
In order to begin adding Dynamic Server Pools, we will first need to clone your service and create a new pool

In this case we will be cloning version 1 of your service to version 2:

`curl -sv -H "Fastly-Key: ${API_KEY}" -X PUT https://api.fastly.com/service/${SERVICE_ID}/version/1/clone | jq`

### Step 2: Upload boilerplate VCL for service

In this repo there is included a `main.vcl` which we will upload to our service. Two things to note:

1. There is a clearly defined space in `vcl_recv` where we will be doing our custom VCL for this workshop.
2. Immediately below you will see `return(pass)`. For the purposes of this workshop we are passing all traffic to the backends so that we can see immediate responses (and not cached responses)

In order to upload VCL we must URL encode the file so that we can send it via Curl:

`curl -vs -H "Fastly-Key: ${API_KEY}" -X POST -H "Content-Type: application/x-www-form-urlencoded" --data "name=main&main=true" --data-urlencode "content@main.vcl" https://api.fastly.com/service/${SERVICE_ID}/version/2/vcl | jq`

```
{
  "name": "main",
  "main": true,
  "content": "<lots of VCL>,
  "service_id": "1OPpKYvOlWVx37twfGVsq0",
  "version": 2,
  "deleted_at": null,
  "created_at": "2017-06-20T20:23:52+00:00",
  "updated_at": "2017-06-20T20:23:52+00:00"
}
```


### Step 3: Create Dynamic Server Pool

Next, we will need to create a Dynamic Server Pool to add our servers to (*note we are now working with version 2*):

`curl -sv -H "Fastly-Key: ${API_KEY}" -X POST https://api.fastly.com/service/${SERVICE_ID}/version/2/pool -d 'name=cloudpool&comment=cloudpool' | jq`

JSON response:

```
{
  "name": "cloudpool",
  "comment": "cloudpool",
  "service_id": "5wFmyFopB74kQoYtrxY3tw",
  "version": "2",
  "max_tls_version": null,
  "shield": null,
  "tls_ca_cert": null,
  "request_condition": null,
  "first_byte_timeout": "15000",
  "tls_ciphers": null,
  "tls_sni_hostname": null,
  "updated_at": "2017-06-21T20:37:51+00:00",
  "id": "3qoucl7vkyLGf2KXmJ1XIK",
  "max_conn_default": "200",
  "tls_check_cert": 1,
  "min_tls_version": null,
  "connect_timeout": "1000",
  "tls_client_cert": null,
  "deleted_at": null,
  "healthcheck": null,
  "tls_cert_hostname": null,
  "created_at": "2017-06-21T20:37:51+00:00",
  "between_bytes_timeout": "10000",
  "tls_client_key": null,
  "type": "random",
  "use_tls": 0,
  "quorum": "75"
}
```

Let’s add the pool ID as an environment variable...

`export POOL_ID_1=<pool_id>`

### Step 4: Add servers to the pool

We can now begin to start adding servers to the pool (use the IPs listed above to add the servers)

*You will run this command twice with the different IP addresses:*

`curl -vs -H "Fastly-Key: ${API_KEY}" -X POST https://api.fastly.com/service/${SERVICE_ID}/pool/${POOL_ID_1}/server -d 'address=104.196.253.201' | jq`

`curl -vs -H "Fastly-Key: ${API_KEY}" -X POST https://api.fastly.com/service/${SERVICE_ID}/pool/${POOL_ID_1}/server -d 'address=13.58.97.100' | jq`


JSON response:

```
{
  "address": "104.196.253.201",
  "service_id": "1OPpKYvOlWVx37twfGVsq0",
  "pool_id": "49Y2yUtPUukwoGu9KDxFM",
  "deleted_at": null,
  "port": "80",
  "max_conn": 0,
  "created_at": "2017-06-20T20:43:43+00:00",
  "comment": "",
  "weight": "100",
  "updated_at": "2017-06-20T20:43:43+00:00",
  "id": "1AZgxtTsZb3cMAND2LNZBA"
}
```

### Step 5: Activate your new version

Our last configuration step. Now we have added our pool, activate the version.

**Once activated, dynamic servers are not tied to a version and can be added and removed dynamically**:

`curl -vs -H "Fastly-Key: ${API_KEY}" -X PUT https://api.fastly.com/service/${SERVICE_ID}/version/2/activate | jq`

### Step 6: Browse the new load balanced pool

Open your browser and navigate to your supplied domain (_\<num>.lbworkshop.tech_)

You should now be able to see something like this:

GCS serving the request:

![GCS](https://github.com/chrisbuckley/altitude-2017-lb-workshop/raw/master/images/gcs.png "GCS instance serving the request")

EC2 serving the request:

![EC2](https://github.com/chrisbuckley/altitude-2017-lb-workshop/raw/master/images/ec2.png "EC2 instance serving the request")

Keep refreshing and you will see both instances displaying at one time or another. This pool has been configured with defaults, so requests are _random to each origin server_.

## Workshop 2: SOA / Microservice Routing

In this next exercise we will create a pool for hosting our Wordpress blog.

For this, we will create a Dynamic Server Pool with our origin being a TLS endpoint. This will require some further configuration of the origin.

### Step 1: Create Dynamic Server Pool

First we will clone our active service to a new one (this time cloning version 2 to version 3):

`curl -sv -H "Fastly-Key: ${API_KEY}" -X PUT https://api.fastly.com/service/${SERVICE_ID}/version/2/clone | jq`

Create new environment variables (using the Wordpress link above):

```
export BLOG_URL=blog.lbworkshop.tech
```

Now let's create our Server Pool (notice in the data we are sending regarding TLS:

`curl -vs -H "Fastly-Key: ${API_KEY}" -X POST https://api.fastly.com/service/${SERVICE_ID}/version/3/pool -d "name=wordpress&comment=wordpress&use_tls=1&tls_cert_hostname=${BLOG_URL}" | jq`

JSon output:

```{
  "name": "wordpress",
  "comment": "wordpress",
  "use_tls": 1,
  "tls_cert_hostname": "blog.lbworkshop.tech",
  "service_id": "1OPpKYvOlWVx37twfGVsq0",
  "version": "3",
  "max_tls_version": null,
  "shield": null,
  "tls_ca_cert": null,
  "request_condition": null,
  "first_byte_timeout": "15000",
  "tls_ciphers": null,
  "tls_sni_hostname": null,
  "updated_at": "2017-06-21T04:47:40+00:00",
  "id": "5sufVWoTHlOAOYVRm5jg2G",
  "max_conn_default": "200",
  "tls_check_cert": 1,
  "min_tls_version": null,
  "connect_timeout": "1000",
  "tls_client_cert": null,
  "deleted_at": null,
  "healthcheck": null,
  "created_at": "2017-06-21T04:47:40+00:00",
  "between_bytes_timeout": "10000",
  "tls_client_key": null,
  "type": "random",
  "quorum": "75"
}
```

Take note of the new pool ID, we'll use that later:

`export POOL_ID_BLOG=5sufVWoTHlOAOYVRm5jg2G`


### Step 2: Adding conditional routing for blog pool

In your repo you will find a file `wordpress.vcl`. This contains our VCL that will send any requests to our chosen blog endpoint (in this case `/blog`), to our newly created Wordpress load balancer.

Let's add this to our main VCL underneath our workshop 1 `set req.backend = cloudpool;`. It should look something more like this, and you can upload it to oyur new config:

`main.vcl` before:

```
  ###########################################
  # LB WORKSHOP - DO STUFF HERE
  ###########################################

  # Workshop 1 default backend.
  set req.backend = cloudpool;

  





  ###########################################
  # END LB WORKSHOP
  ###########################################
```

`main.vcl` after:

```
  ###########################################
  # LB WORKSHOP - DO STUFF HERE
  ###########################################

  # Workshop 1 default backend.
  set req.backend = cloudpool;

  # Adding conditional routing to our Wordpress service
  if (req.url == "/blog") {
    set req.backend = wordpress;
    # We will also need to change the host header and modify the request url
    # so that we hit the right endpoint.
    set req.http.Host = "blog.lbworkshop.tech";
    # Remove the /blog from the request URL so that we hit the root of the service
    # using regular expressions
    set req.url = regsub(req.url, "^/blog", "/");
    # Do not cache admin, login, or includes
    if(req.url ~ "^/wp-(admin|login|includes)") {
      return(pass);
    }
    # We'll cache the rest
    return(lookup);
  }

  ###########################################
  # END LB WORKSHOP
  ###########################################
```

Let's upload this as `main-blog` so we can use this new configuration and backend for our blog:

`curl -vs -H "Fastly-Key: ${API_KEY}" -X POST -H "Content-Type: application/x-www-form-urlencoded" --data "name=main-blog&main=true" --data-urlencode "content@main.vcl" https://api.fastly.com/service/${SERVICE_ID}/version/3/vcl | jq`

JSON output:

```
{
  "name": "main-blog",
  "main": true,
  "content": <lots of vcl>,
  "service_id": "1OPpKYvOlWVx37twfGVsq0",
  "version": 3,
  "deleted_at": null,
  "created_at": "2017-06-21T05:04:54+00:00",
  "updated_at": "2017-06-21T05:04:54+00:00"
}
```


### Step 3: Add TLS backend to Server Pool

We can now add our Wordpress TLS endpoint to the blog pool (using our previously added `POOL_ID_BLOG` environment variable):

`curl -vs -H "Fastly-Key: ${API_KEY}" -X POST https://api.fastly.com/service/${SERVICE_ID}/pool/${POOL_ID_BLOG}/server -d "address=${BLOG_URL}&comment=wp&port=443" | jq`

JSON output:

```
{
  "address": "blog.lbworkshop.tech",
  "comment": "wp",
  "service_id": "1OPpKYvOlWVx37twfGVsq0",
  "pool_id": "5sufVWoTHlOAOYVRm5jg2G",
  "deleted_at": null,
  "port": "443",
  "max_conn": 0,
  "created_at": "2017-06-21T05:11:18+00:00",
  "weight": "100",
  "updated_at": "2017-06-21T05:11:18+00:00",
  "id": "RzWDZMrMIV1FiHYUY4k5k"
}
```

Lastly, let's activate the new version (ensuring we're activating our new version 3):

`curl -vs -H "Fastly-Key: ${API_KEY}" -X PUT https://api.fastly.com/service/${SERVICE_ID}/version/3/activate | jq`

### Step 4: Check out your new blog!

Now we can navigate to our new endpoint and see our blog in all its glory (replace the boilerplate URL with your custom service URL):

`http://X.lbworkshop.tech/blog`

**Bear in mind links in the blog will take you out of your service. This is a POC at best, not a production ready configuration!**

## Workshop 3: Geographical Routing (with Failover)

Now that we've covered some of the basics of Load Balancing with Fastly, lets take a look at a more interesting scenario: Geo-based routing to the closest origin, with failover to an alternate origin.

### Step 1: Create origin health check

As we will be introducing code to fail over to a secondary origin (in the case of the primary origin failing or being unavailable), we will need to add health checks to our service.

We will set a simple check to test the index of the site, with default health check settings.

First, clone our current version (this time to version 4):

`curl -sv -H "Fastly-Key: ${API_KEY}" -X PUT https://api.fastly.com/service/${SERVICE_ID}/version/3/clone | jq`

We can now add our health check to our new version. As the healthcheck is being done over HTTP/1.1 we will also add a host header in the check:

`curl -vs -H "Fastly-Key: ${API_KEY}" -X POST https://api.fastly.com/service/${SERVICE_ID}/version/4/healthcheck -d "name=geo-healthcheck&host=lbworkshop.tech&path=/" | jq`

You should see a response like this:

```
{
  "name": "geo-healthcheck",
  "path": "/",
  "service_id": "1OPpKYvOlWVx37twfGVsq0",
  "version": 4,
  "threshold": 3,
  "window": 5,
  "http_version": "1.1",
  "timeout": 500,
  "method": "HEAD",
  "updated_at": "2017-06-16T19:05:02+00:00",
  "expected_response": 200,
  "deleted_at": null,
  "host": "lbworkshop.tech",
  "created_at": "2017-06-16T19:05:02+00:00",
  "comment": "",
  "check_interval": 5000,
  "initial": 2
}
```

### Step 2: Create geographical Dynamic Server Pools

We've had some practice at this so lets get these pools made. We will call one "west" and one "east". 

We will attach the health check created above to each pool:

`curl -vs -H "Fastly-Key: ${API_KEY}" -X POST https://api.fastly.com/service/${SERVICE_ID}/version/4/pool -d 'name=east&comment=east&healthcheck=geo-healthcheck' | jq`

Add the pool ID as an environment variable:

`export POOL_ID_EAST=<pool_id>`

And for west:

`curl -vs -H "Fastly-Key: ${API_KEY}" -X POST https://api.fastly.com/service/${SERVICE_ID}/version/4/pool -d 'name=west&comment=west&healthcheck=geo-healthcheck' | jq`

`export POOL_ID_WEST=<pool_id>`

Next, we'll add our two instances from workshop 1 into separate pools; the GCS instance into west, and the EC2 instance into east (run twice, with the different pool IDs and the instance for each pool):

`curl -vs -H "Fastly-Key: ${API_KEY}" -X POST https://api.fastly.com/service/${SERVICE_ID}/pool/${POOL_ID_EAST}/server -d 'address=13.58.97.100&comment=ec2' | jq`

`curl -vs -H "Fastly-Key: ${API_KEY}" -X POST https://api.fastly.com/service/${SERVICE_ID}/pool/${POOL_ID_WEST}/server -d 'address=104.196.253.201&comment=gcs' | jq`


### Step 3: Adding custom VCL for backend/origin selection:

In your repo you will find a file `geo.vcl`. This contains our logic for backend selection based on geography, with failover to the secondary origin in case the specified pool is unavailable (based on our health checks).

Edit your main.vcl file, and replace the following code:

```
  # Workshop 1 default backend.
  set req.backend = cloudpool;
```

with your new `geo.vcl` code:

```
  # APAC, Asia, and US West all go to US West backend.
  if (server.region ~ "^(US-West|APAC|Asia)") {
    set req.backend = west;
  # All other regions default to US East
  } else {
    set req.backend = east;
  }

  # West failover to East
  # from unhealthy backend or from restart because of backend status code
  if(req.backend == west && (!req.backend.healthy || req.restarts > 0)) {
    set req.backend = east;
  # East failover to West
  } else if(req.backend == east && (!req.backend.healthy || req.restarts > 0)) {
    set req.backend = west;
  }
```

You can then upload our main.vcl as an update to our version (we have given the new VCL a new name to distinguish from the old, so that we can set this as the new "main":

`curl -vs -H "Fastly-Key: ${API_KEY}" -X POST -H "Content-Type: application/x-www-form-urlencoded" https://api.fastly.com//service/${SERVICE_ID}/version/4/vcl --data "name=main-blog-geo&main=true" --data-urlencode "content@main.vcl" | jq`

Let's activate our new version and see our new Geo Load Balancing in effect:

`curl -vs -H "Fastly-Key: ${API_KEY}" -X PUT https://api.fastly.com/service/${SERVICE_ID}/version/4/activate | jq`

As this workshop is being held in San Francisco, we should be hitting the GCS instance. After I shut down Apache on the GCS `us-west1` instance, we should see failover to our EC2 instance in `us-east2`.

## Conclusion

In this workshop we've covered several topics, and have worked through creating multiple load balancing server pools for multi-cloud, microsevrices, and geographic routing and failover.







