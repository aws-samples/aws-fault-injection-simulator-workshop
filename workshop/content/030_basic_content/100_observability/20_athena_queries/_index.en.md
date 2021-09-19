---
title: "Athena queries for FIS"
weight: 20
draft: true
---

Draft section. Idea: how would we figure out what FIS did and what events might be related to FIS. This section should show how to use Athena / CloudTrail to build some basic queries.


{{%expand "TODO: build Athena queries  section click to expand" %}}

```sql
SELECT *
FROM cloudtrail_logs_aws_cloudtrail_logs_238810465798_e649b22c
WHERE sourceipaddress = 'fis.amazonaws.com' limit 10

WHERE eventname = 'TerminateInstances' limit 10

SELECT json_extract(responseelements, '$.instancesSet.items')

-- What did FIS do
SELECT cast(eventtime as varchar),eventname,*
FROM cloudtrail_logs_aws_cloudtrail_logs_238810465798_e649b22c
WHERE useridentity.invokedby = 'fis.amazonaws.com' order by eventtime

-- tie stuff to an event ...
SELECT cast(eventtime as varchar),eventname,*
FROM cloudtrail_logs_aws_cloudtrail_logs_238810465798_e649b22c
WHERE
    useragent = 'fis.amazonaws.com' and
    (
        useridentity.principalId LIKE '%EXPLAMUGrokQJrV4hw%' OR
        requestparameters LIKE '%EXPLAMUGrokQJrV4hw%' OR
        responseelements LIKE '%EXPLAMUGrokQJrV4hw%'
    )
order by eventtime

-- Comment
WITH
    c AS
        (SELECT
            concat('%','EXPLAMUGrokQJrV4hw','%') AS experimentId ),
    v AS
        (SELECT
            cast(eventtime AS varchar) timestamp,
            eventname AS evn,
            *
        FROM cloudtrail_logs_aws_cloudtrail_logs_238810465798_e649b22c
        WHERE useridentity.invokedby = 'fis.amazonaws.com' )
SELECT
    v.timestamp,
    v.eventname,
    c.experimentId,
    *
FROM v LEFT JOIN c ON 1=1
WHERE
    useridentity.principalId LIKE experimentId OR
    requestparameters        LIKE experimentId OR
    responseelements         LIKE experimentId
ORDER BY
    v.timestamp


-- just instances
WITH
    c AS
        (SELECT
            concat('%','EXPLAMUGrokQJrV4hw','%') AS experimentId ),
    v AS
        (SELECT
            cast(eventtime AS varchar) as timestamp,
            *
        FROM cloudtrail_logs_aws_cloudtrail_logs_238810465798_e649b22c
        WHERE useridentity.invokedby = 'fis.amazonaws.com' )
SELECT
    v.timestamp,
    v.eventname,
    json_extract(v.requestparameters,'$.instancesSet.items') as instance
FROM v LEFT JOIN c ON 1=1
WHERE
    useridentity.principalId LIKE experimentId OR
    requestparameters        LIKE experimentId OR
    responseelements         LIKE experimentId
ORDER BY
    v.timestamp    
```

```bash
  --work-group 'primary' \
export EXPERIMENT_ID="EXPLAMUGrokQJrV4hw"
export CLOUD_TRAIL="cloudtrail_logs_aws_cloudtrail_logs_238810465798_e649b22c"
export OUTPUT_LOCATION="s3://aws-cloudtrail-logs-238810465798-e649b22c/query-results/"
aws athena start-query-execution \
  --result-configuration "OutputLocation=${OUTPUT_LOCATION}" \
  --query-string "
WITH
    c AS
        (SELECT
            concat('%','${EXPERIMENT_ID}','%') AS experimentId ),
    v AS
        (SELECT
            cast(eventtime AS varchar) as timestamp,
            *
        FROM ${CLOUD_TRAIL}
        WHERE useridentity.invokedby = 'fis.amazonaws.com' )
SELECT
    v.timestamp,
    v.eventname,
    json_extract(v.requestparameters,'\$.instancesSet.items') as instance
FROM v LEFT JOIN c ON 1=1
WHERE
    useridentity.principalId LIKE experimentId OR
    requestparameters        LIKE experimentId OR
    responseelements         LIKE experimentId
ORDER BY
    v.timestamp    
" \
| tee query_execution_id.json

export LAST_QUERY_ID=$( jq -rc .QueryExecutionId query_execution_id.json )

aws athena get-query-results --query-execution-id ${LAST_QUERY_ID} \
| tee query_results.json

jq -c '.ResultSet.Rows[].Data | [ .[0].VarCharValue, .[1].VarCharValue, .[2].VarCharValue // "" ] ' query_results.json
```

```bash
  --work-group 'primary' \
export EXPERIMENT_ID="EXPLAMUGrokQJrV4hw"
export EXPERIMENT_ID="EXPYbnYRHvgU6bHc5o"
export CLOUD_TRAIL="cloudtrail_logs_aws_cloudtrail_logs_238810465798_e649b22c"
export OUTPUT_LOCATION="s3://aws-cloudtrail-logs-238810465798-e649b22c/query-results/"
export EXPERIMENT_QUERY_STRING="%${EXPERIMENT_ID}%"
aws athena start-query-execution \
  --result-configuration "OutputLocation=${OUTPUT_LOCATION}" \
  --query-string "
SELECT
    cast(eventtime AS varchar) as timestamp,
    eventname,
    json_extract(requestparameters,'\$.instancesSet.items') as instance
FROM ${CLOUD_TRAIL}
WHERE
    useridentity.invokedby = 'fis.amazonaws.com' AND (
        useridentity.principalId LIKE '${EXPERIMENT_QUERY_STRING}' OR
        requestparameters        LIKE '${EXPERIMENT_QUERY_STRING}' OR
        responseelements         LIKE '${EXPERIMENT_QUERY_STRING}'
    )
ORDER BY
    timestamp    
" \
| tee query_execution_id.json

export LAST_QUERY_ID=$( jq -rc .QueryExecutionId query_execution_id.json )

aws athena get-query-results --query-execution-id ${LAST_QUERY_ID} \
| tee query_results.json

jq -c '.ResultSet.Rows[].Data | [ .[0].VarCharValue, .[1].VarCharValue, .[2].VarCharValue // "" ] ' query_results.json
```

```bash
# Get the template that we manually created
aws fis get-experiment-template --id EXT5KVPKSbd2fEr5n
```

{{% /expand %}}






