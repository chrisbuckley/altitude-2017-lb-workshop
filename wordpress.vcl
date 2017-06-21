  # Adding conditional routing to our Wordpress service
  if (req.url == "/blog") {
    set req.backend = wordpress;
    # We will also need to change the host header and modify the request url
    # so that we hit the right endpoint.
    set req.http.Host = "altitude2017blog.wordpress.com";
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