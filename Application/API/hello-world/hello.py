import json
import logging
import os
import datetime

from pymongo import MongoClient
from bson.json_util import dumps

MONGO_URI = os.environ.get('MONGO_URI')

ENTRIES_RESOURCE = '/entries'
GET = 'GET'
POST = 'POST'

client = MongoClient(MONGO_URI)


logger = logging.getLogger()
logger.setLevel(logging.DEBUG)


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
        entry["date"]=datetime.datetime.utcnow
        entries.insert_one(entry)
        return {
            "statusCode": 201,
            "headers": {
                "Content-Type": "application/json"
            }
        }