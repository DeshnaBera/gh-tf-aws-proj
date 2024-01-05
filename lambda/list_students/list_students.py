import json
import boto3

dynamodb = boto3.resource('dynamodb')
table_name = "students"  

table = dynamodb.Table(table_name)
def lambda_handler(event, context):
   try:
       # Scan DynamoDB table to get all students
       response = table.scan()
       students = response.get('Items', [])
       return {
           'statusCode': 200,
           'headers': {
            'Content-Type': 'application/json'
        },
           'body': json.dumps(students)
       }
   except Exception as e:
       return {
           'statusCode': 500,
           'body': json.dumps(f'Error: {str(e)}')
       }