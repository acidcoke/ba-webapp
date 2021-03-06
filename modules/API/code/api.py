import boto3
import json
import logging
import os
import time
import urllib.parse
import bson.json_util

from pymongo import MongoClient

SECRET_ARN = os.environ.get('SECRET_ARN')
MONGO_BASE_URL = os.environ.get('MONGO_BASE_URL')

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def handler(event, context):
    logger.info(f"EVENT: {event}")
    if event['resource'] == '/entries':
        secret = get_secret(SECRET_ARN)
        uri = create_uri(secret, MONGO_BASE_URL)
        entries = MongoClient(uri).guestbook.entries
        if event['httpMethod'] == 'GET':
            logging.info(f"Method: GET")
            entry_cursor = entries.find()
            logging.info(f"RESULT: {entry_cursor}")
            entry_cursor_list = list(entry_cursor)
            for cursor in entry_cursor_list:
                logging.info(f"CURSOR: {cursor}")
                del cursor['_id']
            json_data = bson.json_util.dumps(entry_cursor_list)
            return {
                "statusCode": 202,
                "body": json_data
            }

        elif event['httpMethod'] == 'POST':
            logging.info(f"Method: POST")
            entry = json.loads(event['body'])
            logging.info(f"ENTRY: {entry}")
            entry["date"] = time.time()
            result = entries.insert_one(entry)
            logging.info(f"RESULT: {result}")
            return {
                "statusCode": 201
            }


def get_secret(secret_arn):
    client = boto3.client('secretsmanager')
    get_secret_value_response = client.get_secret_value(
        SecretId=secret_arn
    )
    if 'SecretString' in get_secret_value_response:
        secret = get_secret_value_response['SecretString']
    elif 'SecretBinary' in get_secret_value_response:
        secret = base64.b64decode(get_secret_value_response['SecretBinary'])
    return json.loads(secret)


def create_uri(secret, url):
    username = urllib.parse.quote_plus(secret['username'])
    password = urllib.parse.quote_plus(secret['password'])
    uri = f"mongodb://{username}:{password}@{url}"
    logging.info(f"URI: {uri}")
    return uri
