import json
import os
import time

import boto3

logs = boto3.client("logs")
sns = boto3.client("sns")

TOPIC_ARN = os.environ["TOPIC_ARN"]
LOOKBACK_MINUTES = 10


def find_function_name(event):
    metrics = event["detail"]["configuration"]["metrics"]
    return metrics[0]["metricStat"]["metric"]["dimensions"]["FunctionName"]


def get_error_logs(function_name):
    start = int((time.time() - LOOKBACK_MINUTES * 60) * 1000)
    response = logs.filter_log_events(
        logGroupName=f"/aws/lambda/{function_name}",
        startTime=start,
        filterPattern="?ERROR ?Exception ?Traceback",
        limit=50,
    )
    return [e["message"].rstrip() for e in response["events"]]


def handler(event, context):
    print("Glowtail responder is awake!")
    print(json.dumps(event))

    detail = event["detail"]
    alarm_name = detail["alarmName"]
    reason = detail["state"]["reason"]
    function_name = find_function_name(event)

    lines = get_error_logs(function_name)
    if lines:
        log_text = "\n\n".join(lines)
    else:
        log_text = f"No error lines found in the last {LOOKBACK_MINUTES} minutes."

    message = (
        f"Alarm: {alarm_name}\n"
        f"Function: {function_name}\n"
        f"Why: {reason}\n\n"
        f"Latest error logs:\n\n{log_text}\n"
    )

    sns.publish(
        TopicArn=TOPIC_ARN,
        Subject=f"Glowtail: {alarm_name} is in ALARM"[:100],
        Message=message,
    )
    print(f"Sent alert with {len(lines)} log lines.")
    return {"status": "sent", "lines": len(lines)}