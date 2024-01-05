import json
import boto3

dynamodb = boto3.resource('dynamodb')
table_name = "students"  

table = dynamodb.Table(table_name)
def lambda_handler(event, context):
   try:
       body = json.loads(event['body'])
       student_id = body['studentId']
       student_name = body['studentName']
       # Put item into DynamoDB
       table.put_item(Item={'studentId': student_id, 'studentName': student_name})
       return {
           'statusCode': 200,
           'body': json.dumps('Student added successfully')
       }
   except Exception as e:
       return {
           'statusCode': 500,
           'body': json.dumps(f'Error: {str(e)}')
       }