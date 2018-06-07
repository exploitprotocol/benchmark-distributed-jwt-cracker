variable "token" {
  type = "string"
}

variable "num_clients" {
  type    = "string"
  default = 4
}

# Create policy with
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Action": [
#         "logs:CreateLogGroup",
#         "logs:CreateLogStream",
#         "logs:PutLogEvents",
#         "logs:DescribeLogStreams"
#     ],
#       "Resource": [
#         "arn:aws:logs:*:*:*"
#     ]
#   }
#  ]
# }

