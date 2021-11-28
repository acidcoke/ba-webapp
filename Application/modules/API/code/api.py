import json
import logging
import os
import time
import datetime

from pymongo import MongoClient
from bson.json_util import dumps

MONGO_URI = os.environ.get('MONGO_URI')
SECRET_ARN = os.environ.get('SECRET_ARN')

ENTRIES_RESOURCE = '/entries'
GET = 'GET'
POST = 'POST'


logger = logging.getLogger()
logger.setLevel(logging.DEBUG)
logger.debug(f"JURI {MONGO_URI}")
client = MongoClient(MONGO_URI)




def handler(event, context):
    logging.info(event)
    db = client.guestbooking
    logging.info(db)
    entries = db.entries
    if event['httpMethod'] == GET:
        mcursor = entries.find()
        list_cur = list(mcursor)
        for cursor in list_cur:
            del cursor['_id']
        json_data = dumps(list_cur)

        logging.debug(json_data)
        return {
            "statusCode": 202,
            "body": json_data
        }

    if event['httpMethod'] == POST:
        entry=json.loads(event['body'])
        logging.info(datetime.datetime.utcnow())
        entry["date"]=time.time()
        logging.info(entry)
        entries.insert_one(entry)
        return {
            "statusCode": 201,
            "headers": {
                "Content-Type": "application/json"
            }
        }