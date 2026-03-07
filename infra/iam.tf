resource "aws_iam_role" "lambda_exec_role" {
  name = "chaos_lambda_role_${terraform.workspace}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role" "chaos_worker" {
  name = "ChaosWorkerRole"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
  })
}

resource "aws_iam_instance_profile" "chaos_worker" {
  name = "ChaosWorkerRole"
  role = aws_iam_role.chaos_worker.name
}

resource "aws_iam_role_policy_attachment" "chaos_worker_ssm" {
  role       = aws_iam_role.chaos_worker.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "chaos_worker_cloudwatch" {
  role       = aws_iam_role.chaos_worker.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_role" "gitlab_pipeline" {
  name = "GitLabPipelineRole"

  
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::510674263883:user/admin"
            },
            "Action": "sts:AssumeRole"
        },
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::510674263883:oidc-provider/gitlab.com"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringLike": {
                    "gitlab.com:sub": "project_path:piyush169/chaos-resilience:ref_type:branch:ref:main"
                }
            }
        }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "gitlab_pipeline_admin" {
  role       = aws_iam_role.gitlab_pipeline.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_role" "observability" {
  name = "ObservabilityRole"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
  })
}

resource "aws_iam_instance_profile" "observability" {
  name = "ObservabilityRole"
  role = aws_iam_role.observability.name
}

resource "aws_iam_role_policy_attachment" "observability_prometheus" {
  role       = aws_iam_role.observability.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonPrometheusQueryAccess"
}

resource "aws_iam_role_policy_attachment" "observability_cloudwatch" {
  role       = aws_iam_role.observability.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
}