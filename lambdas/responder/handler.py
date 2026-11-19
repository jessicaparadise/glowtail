import json


def handler(event, context):
    print("Glowtail responder is awake!")
    print(json.dumps(event))
    return {"status": "received"}