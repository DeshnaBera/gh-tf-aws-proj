provider "aws" {
 region = "us-east-1" 
}

resource "aws_dynamodb_table" "students" {
 name           = "students"
 billing_mode   = "PROVISIONED"
 read_capacity  = 1
 write_capacity = 1
 hash_key       = "studentId"
 attribute {
   name = "studentId"
   type = "S"
 }
}

resource "aws_lambda_function" "add_student" {
    filename = "add_student.zip"
    function_name = "add_student"
    handler      = "add_student.lambda_handler"
    runtime      = "python3.8"
    memory_size = 128
    role = aws_iam_role.lambda.arn
    environment {
        variables = {
            DYNAMODB_TABLE = aws_dynamodb_table.students.name
        }
    }
}

resource "aws_lambda_function" "list_students" {
    filename = "list_students.zip"
    function_name = "list_students"
    handler      = "list_students.lambda_handler"
    runtime      = "python3.8"
    role = aws_iam_role.lambda.arn
    environment {
        variables = {
            DYNAMODB_TABLE = aws_dynamodb_table.students.name
        }
    }
}

resource "aws_iam_role" "lambda" {
 name = "lambda_execution_role"
 assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "lambda.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF

# Attach the DynamoDB policy
 inline_policy {
   name = "dynamodb_policy"
   policy = <<EOF
   {
      "Version": "2012-10-17",
      "Statement": [
      {
        "Effect": "Allow",
        "Action": "dynamodb:*",
        "Resource": "*"
      }
      ]
    }
  EOF
 }

}

resource "aws_api_gateway_rest_api" "students_api" {
 name        = "students_api"
 description = "API for managing students"
}

resource "aws_api_gateway_resource" "add_student_resource" {
 rest_api_id = aws_api_gateway_rest_api.students_api.id
 parent_id   = aws_api_gateway_rest_api.students_api.root_resource_id
 path_part   = "addStudent"
}

resource "aws_api_gateway_resource" "list_students_resource" {
 rest_api_id = aws_api_gateway_rest_api.students_api.id
 parent_id   = aws_api_gateway_rest_api.students_api.root_resource_id
 path_part   = "listStudent"
}

resource "aws_api_gateway_method" "add_student_method" {
 rest_api_id   = aws_api_gateway_rest_api.students_api.id
 resource_id   = aws_api_gateway_resource.add_student_resource.id
 http_method   = "POST"
 authorization = "NONE"
}

resource "aws_api_gateway_method" "list_students_method" {
 rest_api_id   = aws_api_gateway_rest_api.students_api.id
 resource_id   = aws_api_gateway_resource.list_students_resource.id
 http_method   = "GET"
 authorization = "NONE"
}

resource "aws_api_gateway_integration" "add_student_integration" {
 rest_api_id             = aws_api_gateway_rest_api.students_api.id
 resource_id             = aws_api_gateway_resource.add_student_resource.id
 http_method             = aws_api_gateway_method.add_student_method.http_method
 integration_http_method = "POST"
 type                    = "AWS_PROXY"
 uri                     = aws_lambda_function.add_student.invoke_arn
}

resource "aws_api_gateway_integration" "list_students_integration" {
 rest_api_id             = aws_api_gateway_rest_api.students_api.id
 resource_id             = aws_api_gateway_resource.list_students_resource.id
 http_method             = aws_api_gateway_method.list_students_method.http_method
 integration_http_method = "GET"
 type                    = "AWS_PROXY"
 uri                     = aws_lambda_function.list_students.invoke_arn
}

resource "aws_lambda_permission" "add_student_permission" {
 statement_id  = "AddStudentPermission"
 action        = "lambda:InvokeFunction"
 function_name = aws_lambda_function.add_student.function_name
 principal     = "apigateway.amazonaws.com"
}

resource "aws_lambda_permission" "list_students_permission" {
 statement_id  = "ListStudentsPermission"
 action        = "lambda:InvokeFunction"
 function_name = aws_lambda_function.list_students.function_name
 principal     = "apigateway.amazonaws.com"
}

resource "aws_api_gateway_deployment" "students_api_deployment" {
 depends_on = [
   aws_api_gateway_integration.add_student_integration,
   aws_api_gateway_integration.list_students_integration
 ]
 rest_api_id = aws_api_gateway_rest_api.students_api.id
 stage_name  = "prod"
}

output "api_gateway_url" {
 value = aws_api_gateway_deployment.students_api_deployment.invoke_url
}