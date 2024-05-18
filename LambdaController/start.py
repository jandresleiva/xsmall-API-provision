import boto3

def lambda_handler(event, context):
    client = boto3.client('rds')
    response = client.start_db_instance(
        DBInstanceIdentifier='your-db-instance-id'
    )
    return response
