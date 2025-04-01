package test

import (
	"context"
	"strings"
	"testing"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/ec2"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestEC2InstanceIsRunning(t *testing.T) {
	t.Parallel()

	
	terraformOptions := &terraform.Options{
		TerraformDir: "../",
	}


	awsRegion := "us-east-1"

	instanceID := terraform.Output(t, terraformOptions, "blue_instance_id")


	cfg, err := config.LoadDefaultConfig(context.TODO(), config.WithRegion(awsRegion))
	if err != nil {
		t.Fatalf("Failed to load AWS config: %v", err)
	}


	client := ec2.NewFromConfig(cfg)


	resp, err := client.DescribeInstances(context.TODO(), &ec2.DescribeInstancesInput{
		InstanceIds: []string{instanceID},
	})
	if err != nil {
		t.Fatalf("Failed to describe instance: %v", err)
	}

	instance := resp.Reservations[0].Instances[0]
	state := string(instance.State.Name)

	assert.True(t, strings.EqualFold(state, "running"), "EC2 instance is not running")
}
