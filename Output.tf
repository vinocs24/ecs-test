output "instance_security_group" {
  value = aws_security_group.ecs-securitygroup.id
}

output "launch_configuration" {
  value = aws_launch_configuration.ecs-test-launchconfig.id
}

output "asg_name" {
  value = aws_autoscaling_group.ecs-test-autoscaling.id
}
/*
output "elb_hostname" {
  value = aws_alb.test-http.dns_name
}*/
