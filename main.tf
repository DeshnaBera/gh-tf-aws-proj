provider "aws" {
 region = "us-east-1" 
}

terraform {
  backend "s3" {
    bucket = "mytf-state-file"
    key    = "terraform.tfstate"
    region = "us-east-1"

    dynamodb_table = "TfStateLock"
  }
}



resource "aws_dynamodb_table" "students" {
 name           = "students"
 billing_mode   = "PROVISIONED"
 read_capacity = 1
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

}

resource "aws_iam_policy" "policy" {
  name        = "getfromdb_policy"
  description = "My test policy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:DeleteItem",
                "dynamodb:GetItem",
                "dynamodb:PutItem",
                "dynamodb:Scan",
                "dynamodb:UpdateItem"
            ],
            "Resource": "arn:aws:dynamodb:us-east-1:486152014133:table/*"
        }
    ]
})
}

resource "aws_iam_role_policy_attachment" "students" {
  policy_arn = aws_iam_policy.policy.arn
  role       = aws_iam_role.lambda.name
}

resource "aws_api_gateway_rest_api" "students_api" {
 name        = "students_api"
 description = "API for managing students"
}

resource "aws_api_gateway_resource" "add_student_resource" {
 rest_api_id = aws_api_gateway_rest_api.students_api.id
 parent_id   = aws_api_gateway_rest_api.students_api.root_resource_id
 path_part   = "add_student"
}

resource "aws_api_gateway_resource" "list_students_resource" {
 rest_api_id = aws_api_gateway_rest_api.students_api.id
 parent_id   = aws_api_gateway_rest_api.students_api.root_resource_id
 path_part   = "list_students"
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
 integration_http_method = "POST"
 type                    = "AWS_PROXY"
 uri                     = aws_lambda_function.list_students.invoke_arn
}

resource "aws_lambda_permission" "add_student_permission" {
 statement_id  = "AddStudentPermission"
 action        = "lambda:InvokeFunction"
 function_name = aws_lambda_function.add_student.function_name
 principal     = "apigateway.amazonaws.com"
 //source_arn    = aws_api_gateway_rest_api.students_api.execution_arn
}

resource "aws_lambda_permission" "list_students_permission" {
 statement_id  = "ListStudentsPermission"
 action        = "lambda:InvokeFunction"
 function_name = aws_lambda_function.list_students.function_name
 principal     = "apigateway.amazonaws.com"
 //source_arn    = aws_api_gateway_rest_api.students_api.execution_arn
}

resource "aws_api_gateway_deployment" "students_api_deployment" {
  depends_on = [
   aws_api_gateway_integration.add_student_integration,
   aws_api_gateway_integration.list_students_integration
 ]
 rest_api_id = aws_api_gateway_rest_api.students_api.id
}

resource "aws_api_gateway_stage" "example" {
  deployment_id = aws_api_gateway_deployment.students_api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.students_api.id
  stage_name    = "example"
}

output "api_gateway_url" {
 value = aws_api_gateway_deployment.students_api_deployment.invoke_url
}