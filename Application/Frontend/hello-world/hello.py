import json
import logging
import os
import sys
import uuid
import datetime

from pymongo import MongoClient
from bson.json_util import dumps, loads

MONGO_URI = os.environ.get('MONGO_URI')

ENTRIES_RESOURCE = '/entries'
GET = 'GET'
POST = 'POST'

client = MongoClient(MONGO_URI)



logger = logging.getLogger()
logger.setLevel(logging.DEBUG)


def handler(event, context):
    logging.info(event)
    db = client.guestboo
    logging.info(db)
    entries=db.entries
    if event['httpMethod'] == GET:
        mcursor = entries.find()
        
        # Converting cursor to the list 
        # of dictionaries
        list_cur = list(mcursor)
        for cursor in list_cur:
            del cursor['_id']
        # Converting to the JSON
        json_data = dumps(list_cur) 

        logging.debug(json_data)
        return {
                "statusCode": 202,
                "body": json_data
            }

    if event['httpMethod'] == POST:
        id=entries.insert_one(json.loads(event['body']))
        logging.debug(id)
        return {
                "statusCode": 201,
                "headers": {
                    "Content-Type": "application/json"
                }
            }
    
    """ if client:
        if event['resource'] == ENTRIES_RESOURCE and event['httpMethod']:
            httpMethod = event['httpMethod']
            if httpMethod == GET:
                if isEmpty():
                    return response(None, 204)
                else:
                    entry=json.dumps([{'author': 'bla','comment':'hhh'},{'author': 'Peter','comment':'I,m back Fuckerooniessimulationen überhauptetentierten Herrenhaus-Aktivisten und der'}])
                    logging.info(entry)
                    return respond(entry, 200)
            elif httpMethod == POST:
                pass
            else:
                pass   """
            

def isEmpty():
    return False

def postRespond(statusCode):
    if statusCode==200:
        return {
            "statusCode": statusCode
        }

