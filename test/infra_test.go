package test

import (
	"crypto/tls"
	"fmt"
	"strings"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/aws"
	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/retry"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// Custom function which should take a map of EC2 instance tags and a key
// And it should return the value of each tag by its key
func GetTagValue(tags map[string]string, key string) string {
	found := ""
	for mapKey, mapValue := range tags {
		if mapKey == key {
			found = mapValue
		}
	}
	return found
}

func TestingEc2Instance(t *testing.T, terraformOpts *terraform.Options, awsRegion string, NAME_TAG string, OWNER_TAG string) {
	// Get Terraform output
	ec2InstanceID := terraform.Output(t, terraformOpts, "instance_id")
	fmt.Println("DEBUG:::TERRATEST_OUTPUT:: Instance ID:", ec2InstanceID)

	ec2Tags := aws.GetTagsForEc2Instance(t, awsRegion, ec2InstanceID)
	fmt.Println("DEBUG:::INSTANCE_TAGS:: Tags:", ec2Tags)

	nameTag := GetTagValue(ec2Tags, "Name")
	fmt.Println("DEBUG:::INSTANCE_TAGS:: Name Tag:", nameTag)

	ownerTag := GetTagValue(ec2Tags, "Owner")
	fmt.Println("DEBUG:::INSTANCE_TAGS:: Owner Tag:", ownerTag)

	assert.Equal(t, NAME_TAG, nameTag)
	assert.Equal(t, OWNER_TAG, ownerTag)
}

func TestingS3Bucket(t *testing.T, terraformOpts *terraform.Options, awsRegion string, NAME_TAG string, OWNER_TAG string) {
	// Get Terraform output "bucket_id"
	bucketID := terraform.Output(t, terraformOpts, "bucket_id")
	fmt.Println("DEBUG:::TERRATEST_OUTPUT:: Bucket ID:", bucketID)

	// Check if this bucket actually exists
	aws.AssertS3BucketExists(t, awsRegion, bucketID)
}

func TestingAPIGateway(t *testing.T, terraformOpts *terraform.Options) {

	// Get Terraform output "invoke_stop_url"
	stop_url := terraform.Output(t, terraformOpts, "invoke_stop_url")
	fmt.Println("DEBUG:::TERRATEST_OUTPUT:: Invoke URL:", stop_url)

	// Get Terraform output "invoke_tags_url"
	tags_url := terraform.Output(t, terraformOpts, "invoke_tags_url")
	fmt.Println("DEBUG:::TERRATEST_OUTPUT:: Invoke URL:", tags_url)

	// It can take a few minutes for the API GW and CloudFront to finish spinning up, so retry a few times
	//  maxRetries := 30
	timeBetweenRetries := 15 * time.Second

	// Setup a TLS configuration to submit with the helper, a blank struct is acceptable
	tlsConfig := tls.Config{}

	// Verify that the API Gateway returns a proper response
	stop_endpoint := retry.DoInBackgroundUntilStopped(t, fmt.Sprintf("DEBUG:::TERRATEST_OUTPUT:: Check Stop URL %s", stop_url), timeBetweenRetries, func() {
		http_helper.HttpGetWithCustomValidation(t, fmt.Sprintf("%s", stop_url), &tlsConfig, func(statusCode int, body string) bool {
			return statusCode == 200
		})
	})

	// Verify that the API Gateway returns a proper response
	tags_endpoint := retry.DoInBackgroundUntilStopped(t, fmt.Sprintf("DEBUG:::TERRATEST_OUTPUT:: Check Tags URL %s", tags_url), timeBetweenRetries, func() {
		http_helper.HttpGetWithCustomValidation(t, fmt.Sprintf("%s", tags_url), &tlsConfig, func(statusCode int, body string) bool {
			return statusCode == 200
		})
	})

	// Stop checking the API Gateway
	stop_endpoint.Done()
	tags_endpoint.Done()
}

// Wrapper function to prepare the infrastructure, terratest, and terraform variables
func TestInfrastructure(t *testing.T) {
	awsRegion := "us-west-2"
	NameTag := "auto stop"
	OwnerTag := "infra"

	terraformOpts := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"bucket_prefix": fmt.Sprintf("%s", strings.ToLower(random.UniqueId())),
		},
		EnvVars: map[string]string{
			"AWS_DEFAUTL_REGION": awsRegion,
		},
	})

	defer terraform.Destroy(t, terraformOpts)

	terraform.InitAndApply(t, terraformOpts)

	// Test EC2 instance
	TestingEc2Instance(t, terraformOpts, awsRegion, NameTag, OwnerTag)

	// Test S3 bucket
	TestingS3Bucket(t, terraformOpts, awsRegion, NameTag, OwnerTag)

	// Test API Gateway
	TestingAPIGateway(t, terraformOpts)

}
