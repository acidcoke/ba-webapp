import json
import os
import uuid
from pymongo import MongoClient

MONGO_URI = os.environment.get('MONGO_URI')

USER_RESOURCE = '/user'
GET = 'GET'
POST = 'POST'

client = MongoClient(MONGO_URI)

def handler(event, context):
    print(event)
    db = client.get_default_database()
    if client:
        if event['resource'] == USER_RESOURCE:
            if event['httpMethod'] == GET:
                name = event['queryStringParameters']['name']
                return {
                    'statusCode': 200,
                    'body': json.dumps(name)
                }
            elif event['httpMethod'] == POST:
                pass
        else:
            pass