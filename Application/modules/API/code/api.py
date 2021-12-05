import boto3
import json
import os
import time
import urllib.parse
import bson.json_util

from pymongo import MongoClient

SECRET_ARN = os.environ.get('SECRET_ARN')
MONGO_BASE_URL = os.environ.get('MONGO_BASE_URL')

ENTRIES_RESOURCE = '/entries'

def handler(event, context):
    secret = get_secret(SECRET_ARN)
    uri = create_uri(json.loads(secret), MONGO_BASE_URL)
    client = MongoClient(uri)
    db = client.guestbook
    entries = db.entries

    if event['httpMethod'] == 'GET':
        entry_cursor = entries.find()
        entry_cursor_list = list(entry_cursor)
        for cursor in entry_cursor_list:
            del cursor['_id']
        json_data = bson.json_util.dumps(entry_cursor_list)
        return {
            "statusCode": 202,
            "body": json_data
        }

    elif event['httpMethod'] == 'POST':
        entry = json.loads(event['body'])
        entry["date"] = time.time()
        entries.insert_one(entry)
        return {
            "statusCode": 201,
            "headers": {
                "Content-Type": "application/json"
            }
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
    return secret


def create_uri(secret, url):
    username = urllib.parse.quote_plus(secret['username'])
    password = urllib.parse.quote_plus(secret['password'])
    uri = f"mongodb://{username}:{password}@{url}"
    return uri
