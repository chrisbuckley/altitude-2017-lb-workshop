  # APAC, Asia, and US West all go to US West backend.
  if (server.region == "US-West" || server.region == "APAC" || server.region == "Asia" ) {
    set req.backend = west;
  # All other regions default to US East
  } else {
    set req.backend = east;
  }

  # West failover to East
  # from unhealthy backend or from restart becuase of backend status code
  if(req.backend == west && (!req.backend.healthy || req.restarts > 0)) {
    set req.backend = east;
  # East failover to West
  } else if(req.backend == east && (!req.backend.healthy || req.restarts > 0)) {
    set req.backend = west;
  }