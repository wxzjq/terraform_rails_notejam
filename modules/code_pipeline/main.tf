resource "aws_s3_bucket" "source" {
  bucket        = "rails-terraform-notejam"
  acl           = "private"
  force_destroy = true
}

resource "aws_iam_role" "codepipeline_role" {
  name = "codepipeline-role-notejam"

  assume_role_policy = file("${path.module}/policies/codepipeline_role.json")
}

/* policies */
data "template_file" "codepipeline_policy" {
  template = file("${path.module}/policies/codepipeline.json")

  vars = {
    aws_s3_bucket_arn = "${aws_s3_bucket.source.arn}"
  }
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name   = "codepipeline_policy_notejam"
  role   = aws_iam_role.codepipeline_role.id
  policy = data.template_file.codepipeline_policy.rendered
}

/*
/* CodeBuild
*/
resource "aws_iam_role" "codebuild_role" {
  name               = "codebuild-role-notejam"
  assume_role_policy = file("${path.module}/policies/codebuild_role.json")
}

data "template_file" "codebuild_policy" {
  template = file("${path.module}/policies/codebuild_policy.json")

  vars = {
    aws_s3_bucket_arn = "${aws_s3_bucket.source.arn}"
  }
}

resource "aws_iam_role_policy" "codebuild_policy" {
  name   = "codebuild-policy-notejam"
  role   = aws_iam_role.codebuild_role.id
  policy = data.template_file.codebuild_policy.rendered
}

data "template_file" "buildspec" {
  template = file("${path.module}/buildspec.yml")

  vars = {
    repository_url     = "${var.repository_url}"
    region             = "${var.region}"
    cluster_name       = "${var.ecs_cluster_name}"
    subnet_id          = "${var.run_task_subnet_id}"
    security_group_ids = "${join(",", var.run_task_security_group_ids)}"
  }
}


resource "aws_codebuild_project" "rails_terraform_build" {
  name          = "rails_terraform-codebuild-notejam"
  build_timeout = "10"
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    // https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-available.html
    image           = "aws/codebuild/docker:1.12.1"
    type            = "LINUX_CONTAINER"
    privileged_mode = true
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = data.template_file.buildspec.rendered
  }
}

/* CodePipeline */

resource "aws_codepipeline" "pipeline" {
  name     = "rails_terraform-pipeline-notejam"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.source.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source"]

      configuration = {
        Owner      = "wxzjq"
        Repo       = "terraform_rails_notejam"
        Branch     = "master"
        OAuthToken = "fbc98a2463381ebcfecdcbcb2dfd802384c78cf7"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source"]
      output_artifacts = ["imagedefinitions"]

      configuration = {
        ProjectName = "rails_terraform-codebuild-notejam"
      }
    }
  }

  stage {
    name = "Production"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["imagedefinitions"]
      version         = "1"

      configuration = {
        ClusterName = "${var.ecs_cluster_name}"
        ServiceName = "${var.ecs_service_name}"
        FileName    = "imagedefinitions.json"
      }
    }
  }
}


### CodeDeploy Deployment Group

# resource "aws_codedeploy_deployment_group" "this" {
#   app_name               = "${aws_codedeploy_app.this.name}"
#   deployment_group_name  = "${var.service_name}-service-deploy-group"
#   deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
#   service_role_arn       = "${aws_iam_role.codedeploy.arn}"

#   blue_green_deployment_config {
#     deployment_ready_option {
#       action_on_timeout = "CONTINUE_DEPLOYMENT"
#     }

#     terminate_blue_instances_on_deployment_success {
#       action                           = "TERMINATE"
#       termination_wait_time_in_minutes = 60
#     }
#   }

#   ecs_service {
#     cluster_name = "${aws_ecs_cluster.this.name}"
#     service_name = "${aws_ecs_service.this.name}"
#   }

#   deployment_style {
#     deployment_option = "WITH_TRAFFIC_CONTROL"
#     deployment_type   = "BLUE_GREEN"
#   }

#   load_balancer_info {
#     target_group_pair_info {
#       prod_traffic_route {
#         listener_arns = ["${aws_lb_listener.this.arn}"]
#       }

#       target_group {
#         name = "${aws_lb_target_group.this.*.name[0]}"
#       }

#       target_group {
#         name = "${aws_lb_target_group.this.*.name[1]}"
#       }
#     }
#   }
