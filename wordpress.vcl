  # Adding conditional routing to our Wordpress service
  if (req.url == "/blog") {
    set req.backend = wordpress;
    # We will also need to change the host header and modify the request url
    # so that we hit the right endpoint.
    set req.http.Host = "blog.lbworkshop.tech";
    # Remove the /blog from the request URL so that we hit the root of the service
    # using regular expressions
    set req.url = regsub(req.url, "^/blog", "/");
  }