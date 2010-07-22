#!/bin/bash

psql84 -U postgres template_postgis -c "GRANT ALL ON geometry_columns TO PUBLIC"
psql84 -U postgres template_postgis -c "GRANT ALL ON spatial_ref_sys TO PUBLIC"
psql84 -U postgres template_postgis -c "VACUUM FREEZE"
