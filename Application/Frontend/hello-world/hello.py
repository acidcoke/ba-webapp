import json
import logging
import os
import sys
import uuid

from pymongo import MongoClient

MONGO_URI = os.environment.get('MONGO_URI')

ENTRIES_RESOURCE = '/entries'
GET = 'GET'
POST = 'POST'

client = MongoClient(MONGO_URI)

def handler(event, context):
    print(event)
    logging.info(db = client.get_database())
    if client:
        if event['resource'] == ENTRIES_RESOURCE and event['httpMethod']:
            httpMethod = event['httpMethod']
            if httpMethod == GET:
                if isEmpty():
                    return response(None, 204)
                else:
                    return response(None, 200)
            elif httpMethod == POST:
                pass
            else:
                pass 
            

def isEmpty():
    return true

def respond(entries, statusCode):
    if statusCode==200:
        return {
            "statusCode": statusCode,
            "body": entries,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Methods": "GET, POST", 
                "Access-Control-Allow-Origin": "*"
            }
        }
    else:
        return {
            "statusCode": 204
        }