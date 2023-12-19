import json
import boto3

dynamodb = boto3.resource('dynamodb')
table_name = "students"  # Replace with your DynamoDB table name

table = dynamodb.Table(table_name)
def lambda_handler(event, context):
   try:
       # Scan DynamoDB table to get all students
       response = table.scan()
       students = response.get('Items', [])
       return {
           'statusCode': 200,
           'body': json.dumps(students)
       }
   except Exception as e:
       return {
           'statusCode': 500,
           'body': json.dumps(f'Error: {str(e)}')
       }