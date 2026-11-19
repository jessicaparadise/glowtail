def handler(event, context):
    if event.get("break"):
        raise Exception("Patient broke on purpose!")
    return {"status": "healthy"}