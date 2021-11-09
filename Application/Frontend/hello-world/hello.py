import json
import logging
import os
import sys
import uuid

from pymongo import MongoClient

MONGO_URI = os.environ.get('MONGO_URI')

ENTRIES_RESOURCE = '/entries'
GET = 'GET'
POST = 'POST'

client = MongoClient(MONGO_URI)

def handler(event, context):
    print(event)
    #db = client.get_database()
    logging.info(event)
    if client:
        if event['resource'] == ENTRIES_RESOURCE and event['httpMethod']:
            httpMethod = event['httpMethod']
            if httpMethod == GET:
                if isEmpty():
                    return response(None, 204)
                else:
                    entry=json.dumps([{'author': 'bla','comment':'hhh'},{'author': 'Peter','comment':'I,m back Fuckerooniessimulationen überhauptetentierten Herrenhaus-Aktivisten und der Berichteten der Anscan den Kriegskurs einer Anschließlich gegen des Internetcafess20/1.html Copyright  1996-2002 Mit der hläge !'}])
                    logging.info(entry)
                    return respond(entry, 200)
            elif httpMethod == POST:
                pass
            else:
                pass 
            

def isEmpty():
    return False

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