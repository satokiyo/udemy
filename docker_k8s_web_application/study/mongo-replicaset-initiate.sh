#!/bin/bash

# inside mongodb pod and hit mongo command, then...
rs.initiate({
    _id: "rs0",
    members: [
        {_id: 0, host: "mongodb-0.db-svc:27017"},
        {_id: 1, host: "mongodb-1.db-svc:27017"},
        {_id: 2, host: "mongodb-2.db-svc:27017"}
    ]
})